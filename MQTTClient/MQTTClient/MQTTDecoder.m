//
// MQTTDecoder.m
// MQTTClient.framework
//
// Copyright (c) 2013-2015, Christoph Krey
//
// based on
//
// Copyright (c) 2011, 2013, 2lemetry LLC
// 
// All rights reserved. This program and the accompanying materials
// are made available under the terms of the Eclipse Public License v1.0
// which accompanies this distribution, and is available at
// http://www.eclipse.org/legal/epl-v10.html
// 
// Contributors:
//    Kyle Roche - initial API and implementation and/or initial documentation
// 

#import "MQTTDecoder.h"

#ifdef DEBUG
#define DEBUGDEC FALSE
#else
#define DEBUGDEC FALSE
#endif

@interface MQTTDecoder()
@property BOOL securityPolicyAlreadyApplied;
@property(strong, nonatomic) MQTTSSLSecurityPolicy *securityPolicy;
@property(strong, nonatomic) NSString *securityDomain;
- (BOOL)applySSLSecurityPolicy:(NSStream *)readStream withEvent:(NSStreamEvent)eventCode;
@end

@implementation MQTTDecoder

- (id)initWithStream:(NSInputStream *)stream
             runLoop:(NSRunLoop *)runLoop
         runLoopMode:(NSString *)mode {
    return [self initWithStream:stream
                       runLoop:runLoop
                   runLoopMode:mode
                securityPolicy:nil
                securityDomain:nil];
}

- (id)initWithStream:(NSInputStream *)stream
             runLoop:(NSRunLoop *)runLoop
         runLoopMode:(NSString *)mode
      securityPolicy:(MQTTSSLSecurityPolicy *)securityPolicy
      securityDomain:(NSString *)securityDomain
{
    self.status = MQTTDecoderStatusInitializing;
    self.stream = stream;
    [self.stream setDelegate:self];
    self.runLoop = runLoop;
    self.runLoopMode = mode;
    self.securityPolicy = securityPolicy;
    self.securityDomain = securityDomain;
    self.securityPolicyAlreadyApplied = NO;
    return self;
}

- (void)open {
    [self.stream setDelegate:self];
    [self.stream scheduleInRunLoop:self.runLoop forMode:self.runLoopMode];
    [self.stream open];
}

- (void)close {
    [self.stream close];
    [self.stream removeFromRunLoop:self.runLoop forMode:self.runLoopMode];
    [self.stream setDelegate:nil];
}

- (BOOL)applySSLSecurityPolicy:(NSStream *)readStream withEvent:(NSStreamEvent)eventCode{
    if(!self.securityPolicy){
        return YES;
    }

    // apply the policy only once.
    if(self.securityPolicyAlreadyApplied){
        return YES;
    }

    SecTrustRef serverTrust = (__bridge SecTrustRef) [readStream propertyForKey: (__bridge NSString *)kCFStreamPropertySSLPeerTrust];
    if(!serverTrust){
        return NO;
    }

    BOOL isValid = [self.securityPolicy evaluateServerTrust:serverTrust forDomain:self.securityDomain];
    self.securityPolicyAlreadyApplied = isValid;
    return isValid;
}

- (void)stream:(NSStream*)sender handleEvent:(NSStreamEvent)eventCode {
    if (DEBUGDEC) NSLog(@"%@ handleEvent 0x%02lx", self, (long)eventCode);
    if(self.stream == nil) {
        if (DEBUGDEC) NSLog(@"%@ self.stream == nil", self);
        return;
    }
    assert(sender == self.stream);
    switch (eventCode) {
        case NSStreamEventOpenCompleted:
            self.status = MQTTDecoderStatusDecodingHeader;
            break;
        case NSStreamEventHasBytesAvailable:
            // apply security before process any data
            if(![self applySSLSecurityPolicy:sender withEvent:eventCode]){
                self.status = MQTTDecoderStatusConnectionError;
                NSError * sslError = [NSError errorWithDomain:@"MQTT"
                                                         code:errSSLXCertChainInvalid
                                                     userInfo:@{NSLocalizedDescriptionKey : @"Unable to apply security policy, the SSL connection is insecure!"}];
                [self.delegate decoder:self handleEvent:MQTTDecoderEventProtocolError error:sslError];
            }

            if (self.status == MQTTDecoderStatusDecodingHeader) {
                UInt8 buffer;
                NSInteger n = [self.stream read:&buffer maxLength:1];
                self.header = buffer;
                if (n == -1) {
                    self.status = MQTTDecoderStatusConnectionError;
                    [self.delegate decoder:self handleEvent:MQTTDecoderEventConnectionError error:self.stream.streamError];
                } else if (n == 1) {
                    self.length = 0;
                    self.lengthMultiplier = 1;
                    self.status = MQTTDecoderStatusDecodingLength;
                }
            }
            while (self.status == MQTTDecoderStatusDecodingLength) {
                // TODO: check max packet length(prevent evil server response)
                UInt8 digit;
                NSInteger n = [self.stream read:&digit maxLength:1];
                if (n == -1) {
                    self.status = MQTTDecoderStatusConnectionError;
                    [self.delegate decoder:self handleEvent:MQTTDecoderEventConnectionError error:self.stream.streamError];
                    break;
                } else if (n == 0) {
                    break;
                }
                self.length += (digit & 0x7f) * self.lengthMultiplier;
                if ((digit & 0x80) == 0x00) {
                    self.dataBuffer = [NSMutableData dataWithCapacity:self.length];
                    self.status = MQTTDecoderStatusDecodingData;
                } else {
                    self.lengthMultiplier *= 128;
                }
            }
            if (self.status == MQTTDecoderStatusDecodingData) {
                if (self.length > 0) {
                    NSInteger n, toRead;
                    UInt8 buffer[768];
                    toRead = self.length - [self.dataBuffer length];
                    if (toRead > sizeof buffer) {
                        toRead = sizeof buffer;
                    }
                    n = [self.stream read:buffer maxLength:toRead];
                    if (n == -1) {
                        self.status = MQTTDecoderStatusConnectionError;
                        [self.delegate decoder:self handleEvent:MQTTDecoderEventConnectionError error:self.stream.streamError];
                    } else {
                        [self.dataBuffer appendBytes:buffer length:n];
                    }
                }
                if ([self.dataBuffer length] == self.length) {
                    MQTTMessage* msg;
                    UInt8 type, qos;
                    BOOL isDuplicate, retainFlag;
                    type = (self.header >> 4) & 0x0f;
                    isDuplicate = NO;
                    if ((self.header & 0x08) == 0x08) {
                        isDuplicate = YES;
                    }
                    // XXX qos > 2
                    qos = (self.header >> 1) & 0x03;
                    retainFlag = NO;
                    if ((self.header & 0x01) == 0x01) {
                        retainFlag = YES;
                    }
                    msg = [[MQTTMessage alloc] initWithType:type
                                                        qos:qos
                                                 retainFlag:retainFlag
                                                    dupFlag:isDuplicate
                                                       data:self.dataBuffer];
                    if (DEBUGDEC) NSLog(@"%@ received (%lu)=%@...", self, (unsigned long)self.dataBuffer.length,
                          [self.dataBuffer subdataWithRange:NSMakeRange(0, MIN(16, self.dataBuffer.length))]);
                    [self.delegate decoder:self newMessage:msg];
                    self.dataBuffer = NULL;
                    self.status = MQTTDecoderStatusDecodingHeader;
                }
            }
            break;
        case NSStreamEventEndEncountered:
            self.status = MQTTDecoderStatusConnectionClosed;
            [self.delegate decoder:self handleEvent:MQTTDecoderEventConnectionClosed error:nil];
            break;
        case NSStreamEventErrorOccurred:
        {
            self.status = MQTTDecoderStatusConnectionError;
            NSError *error = [self.stream streamError];
            [self.delegate decoder:self handleEvent:MQTTDecoderEventConnectionError error:error];
            break;
        }
        default:
            if (DEBUGDEC) NSLog(@"%@ unhandled event code 0x%02lx", self, (long)eventCode);
            break;
    }
}

@end
