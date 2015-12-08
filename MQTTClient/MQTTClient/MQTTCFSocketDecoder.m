//
// MQTTCFSocketDecoder.m
// MQTTClient.framework
//
// Copyright (c) 2013-2015, Christoph Krey
//

#import "MQTTCFSocketDecoder.h"

#ifdef DEBUG
#define DEBUGDEC TRUE
#else
#define DEBUGDEC FALSE
#endif

@interface MQTTCFSocketDecoder()
@property (nonatomic) BOOL securityPolicyApplied;
@end

@implementation MQTTCFSocketDecoder

- (instancetype)init {
    self = [super init];
    self.state = MQTTCFSocketDecoderStateInitializing;
    self.securityPolicyApplied = NO;
    
    self.stream = nil;
    self.runLoop = [NSRunLoop currentRunLoop];
    self.runLoopMode = NSRunLoopCommonModes;
    self.securityPolicy = nil;
    self.securityDomain = nil;
    
    return self;
}

- (void)open {
    if (self.state == MQTTCFSocketDecoderStateInitializing) {
        [self.stream setDelegate:self];
        [self.stream scheduleInRunLoop:self.runLoop forMode:self.runLoopMode];
        [self.stream open];
    }
}

- (void)close {
    if (self.state == MQTTCFSocketDecoderStateReady || self.state == MQTTCFSocketDecoderStateError) {
        [self.stream close];
        [self.stream removeFromRunLoop:self.runLoop forMode:self.runLoopMode];
        [self.stream setDelegate:nil];
        self.state = MQTTCFSocketDecoderStateInitializing;
    }
}

- (BOOL)applySSLSecurityPolicy:(NSStream *)readStream withEvent:(NSStreamEvent)eventCode{
    if(!self.securityPolicy){
        return YES;
    }

    if(self.securityPolicyApplied){
        return YES;
    }

    SecTrustRef serverTrust = (__bridge SecTrustRef) [readStream propertyForKey: (__bridge NSString *)kCFStreamPropertySSLPeerTrust];
    if(!serverTrust){
        return NO;
    }

    self.securityPolicyApplied = [self.securityPolicy evaluateServerTrust:serverTrust forDomain:self.securityDomain];
    return self.securityPolicyApplied;
}

- (void)stream:(NSStream*)sender handleEvent:(NSStreamEvent)eventCode {
    
    if (eventCode & NSStreamEventOpenCompleted) {
        if (DEBUGDEC) if (eventCode & NSStreamEventOpenCompleted) NSLog(@"[MQTTCFSocketDecoder] NSStreamEventOpenCompleted");
        self.state = MQTTCFSocketDecoderStateReady;
        [self.delegate decoderDidOpen:self];
    }

    if (eventCode &  NSStreamEventHasBytesAvailable) {
        if (DEBUGDEC) if (eventCode & NSStreamEventHasBytesAvailable) NSLog(@"[MQTTCFSocketDecoder] NSStreamEventHasBytesAvailable");
        if (![self applySSLSecurityPolicy:sender withEvent:eventCode]){
            self.state = MQTTCFSocketDecoderStateError;
            self.error = [NSError errorWithDomain:@"MQTT"
                                             code:errSSLXCertChainInvalid
                                         userInfo:@{NSLocalizedDescriptionKey: @"Unable to apply security policy, the SSL connection is insecure!"}];
        }
        
        if (self.state == MQTTCFSocketDecoderStateInitializing) {
            self.state = MQTTCFSocketDecoderStateReady;
            
        }
        
        if (self.state == MQTTCFSocketDecoderStateReady) {
            NSInteger n;
            UInt8 buffer[768];
            
            n = [self.stream read:buffer maxLength:sizeof(buffer)];
            if (n == -1) {
                self.state = MQTTCFSocketDecoderStateError;
                [self.delegate decoder:self didFailWithError:nil];
            } else {
                NSData *data = [NSData dataWithBytes:buffer length:n];
                [self.delegate decoder:self didReceiveMessage:data];
            }
        }
    }
    if (eventCode &  NSStreamEventHasSpaceAvailable) {
        if (DEBUGDEC) NSLog(@"[MQTTCFSocketDecoder] NSStreamEventHasSpaceAvailable");
    }
    
    if (eventCode &  NSStreamEventEndEncountered) {
        if (DEBUGDEC) NSLog(@"[MQTTCFSocketDecoder] NSStreamEventEndEncountered");
        self.state = MQTTCFSocketDecoderStateInitializing;
        self.error = nil;
        [self.delegate decoderdidClose:self];
    }
    
    if (eventCode &  NSStreamEventErrorOccurred) {
        if (DEBUGDEC) NSLog(@"[MQTTCFSocketDecoder] NSStreamEventErrorOccurred");
        self.state = MQTTCFSocketDecoderStateError;
        self.error = self.stream.streamError;
        [self.delegate decoder:self didFailWithError:self.error];
    }
}

@end
