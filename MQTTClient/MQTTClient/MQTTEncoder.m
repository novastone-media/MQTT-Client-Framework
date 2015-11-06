//
// MQTTEncoder.m
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

#import "MQTTEncoder.h"

#ifdef DEBUG
#define DEBUGENC FALSE
#else
#define DEBUGENC FALSE
#endif

@interface MQTTEncoder()
@property BOOL securityPolicyAlreadyApplied;
@property(strong, nonatomic) MQTTSSLSecurityPolicy *securityPolicy;
@property(strong, nonatomic) NSString *securityDomain;
- (BOOL)applySSLSecurityPolicy:(NSStream *)writeStream withEvent:(NSStreamEvent)eventCode;
@end

@implementation MQTTEncoder

- (id)initWithStream:(NSOutputStream *)stream
             runLoop:(NSRunLoop *)runLoop
         runLoopMode:(NSString *)mode {
    return [self initWithStream:stream
                        runLoop:runLoop
                    runLoopMode:mode
                 securityPolicy:nil
                 securityDomain:nil];
}

- (id)initWithStream:(NSOutputStream *)stream
             runLoop:(NSRunLoop *)runLoop
         runLoopMode:(NSString *)mode
      securityPolicy:(MQTTSSLSecurityPolicy *)securityPolicy
      securityDomain:(NSString *)securityDomain
{
    self.status = MQTTEncoderStatusInitializing;
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

- (BOOL)applySSLSecurityPolicy:(NSStream *)writeStream withEvent:(NSStreamEvent)eventCode;
{
    if(!self.securityPolicy){
        return YES;
    }
    
    // apply the policy only once.
    if(self.securityPolicyAlreadyApplied){
        return YES;
    }
    
    SecTrustRef serverTrust = (__bridge SecTrustRef) [writeStream propertyForKey: (__bridge NSString *)kCFStreamPropertySSLPeerTrust];
    if(!serverTrust){
        return NO;
    }
    
    BOOL isValid = [self.securityPolicy evaluateServerTrust:serverTrust forDomain:self.securityDomain];
    self.securityPolicyAlreadyApplied = isValid;
    return isValid;
}

- (void)stream:(NSStream*)sender handleEvent:(NSStreamEvent)eventCode {
    if (DEBUGENC) NSLog(@"%@ handleEvent 0x%02lx", self, (long)eventCode);
    if(self.stream == nil) {
        if (DEBUGENC) NSLog(@"%@ self.stream == nil", self);
        return;
    }
    assert(sender == self.stream);
    switch (eventCode) {
        case NSStreamEventOpenCompleted:
            break;
        case NSStreamEventHasSpaceAvailable: {
            // apply security before process any data
            if(![self applySSLSecurityPolicy:sender withEvent:eventCode]){
                self.status = MQTTEncoderStatusError;
                NSError * sslError = [NSError errorWithDomain:@"MQTT"
                                                         code:errSSLXCertChainInvalid
                                                     userInfo:@{NSLocalizedDescriptionKey : @"Unable to apply security policy, the SSL connection is insecure!"}];
                [self.delegate encoder:self handleEvent:MQTTEncoderEventErrorOccurred error:sslError];
            }
            
            if (self.status == MQTTEncoderStatusInitializing) {
                self.status = MQTTEncoderStatusReady;
                [self.delegate encoder:self handleEvent:MQTTEncoderEventReady error:nil];
            }
            else if (self.status == MQTTEncoderStatusReady) {
                // notify handler that we are ready and waiting for send event.
                [self.delegate encoder:self handleEvent:MQTTEncoderEventReady error:nil];
            }
            else if (self.status == MQTTEncoderStatusSending) {
                UInt8* ptr;
                NSInteger n, length;
                
                ptr = (UInt8*) [self.buffer bytes] + self.byteIndex;
                // Number of bytes pending for transfer
                length = [self.buffer length] - self.byteIndex;
                n = [self.stream write:ptr maxLength:length];
                if (n == -1) {
                    self.status = MQTTEncoderStatusError;
                    [self.delegate encoder:self handleEvent:MQTTEncoderEventErrorOccurred error:self.stream.streamError];
                }
                else if (n < length) {
                    self.byteIndex += n;
                }
                else {
                    self.buffer = NULL;
                    self.byteIndex = 0;
                    self.status = MQTTEncoderStatusReady;
                }
            }
            break;
        }
        case NSStreamEventErrorOccurred:
        case NSStreamEventEndEncountered:
            if (self.status != MQTTEncoderStatusError) {
                self.status = MQTTEncoderStatusError;
                NSError *error = [self.stream streamError];
                [self.delegate encoder:self handleEvent:MQTTEncoderEventErrorOccurred error:error];
            }
            break;
        default:
            if (DEBUGENC) NSLog(@"%@ unhandled event code 0x%02lx", self, (long)eventCode);
            break;
    }
}

- (BOOL)encodeMessage:(MQTTMessage*)msg {
    @synchronized(self) {
        UInt8 header;
        NSInteger n, length;
        
        if (self.status != MQTTEncoderStatusReady) {
            if (DEBUGENC) NSLog(@"%@ not status ready %d", self, self.status);
            return FALSE;
        }
        
        assert (self.buffer == NULL);
        assert (self.byteIndex == 0);
        
        self.buffer = [[NSMutableData alloc] init];
        
        // encode fixed header
        header = ([msg type] & 0x0f) << 4;
        if (msg.dupFlag) {
            header |= 0x08;
        }
        header |= ([msg qos] & 0x03) << 1;
        if ([msg retainFlag]) {
            header |= 0x01;
        }
        [self.buffer appendBytes:&header length:1];
        
        // encode remaining length
        length = [[msg data] length];
        do {
            UInt8 digit = length % 128;
            length /= 128;
            if (length > 0) {
                digit |= 0x80;
            }
            [self.buffer appendBytes:&digit length:1];
        }
        while (length > 0);
        
        
        // encode message data
        if ([msg data] != NULL) {
            [self.buffer appendData:[msg data]];
        }
        
        if (DEBUGENC) NSLog(@"%@ buffer to write (%lu)=%@...", self, (unsigned long)self.buffer.length,
                            [self.buffer subdataWithRange:NSMakeRange(0, MIN(16, self.buffer.length))]);
        
        [self.delegate encoder:self sending:msg.type qos:msg.qos retained:msg.retainFlag duped:msg.dupFlag mid:msg.mid data:self.buffer];
        
        n = [self.stream write:[self.buffer bytes] maxLength:[self.buffer length]];
        if (n == -1) {
            self.status = MQTTEncoderStatusError;
            [self.delegate encoder:self handleEvent:MQTTEncoderEventErrorOccurred error:self.stream.streamError];
        }
        else if (n < [self.buffer length]) {
            self.byteIndex += n;
            self.status = MQTTEncoderStatusSending;
        }
        else {
            self.buffer = NULL;
            // XXX [delegate encoder:self handleEvent:MQTTEncoderEventReady];
        }
        return TRUE;
    }
}

@end