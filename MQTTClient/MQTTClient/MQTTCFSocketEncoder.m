//
// MQTTCFSocketEncoder.m
// MQTTClient.framework
//
// Copyright (c) 2013-2015, Christoph Krey
//

#import "MQTTCFSocketEncoder.h"

#ifdef DEBUG
#define DEBUGENC TRUE
#else
#define DEBUGENC FALSE
#endif

@interface MQTTCFSocketEncoder()
@property (nonatomic, readwrite) MQTTCFSocketEncoderState state;
@property (nonatomic, readwrite) NSError *error;

@property (nonatomic) BOOL securityPolicyApplied;
@property (strong, nonatomic) NSMutableData *buffer;

@end

@implementation MQTTCFSocketEncoder

- (instancetype)init {
    self = [super init];
    self.state = MQTTCFSocketEncoderStateInitializing;
    self.securityPolicyApplied = NO;
    self.buffer = [[NSMutableData alloc] init];
    
    self.stream = nil;
    self.runLoop = [NSRunLoop currentRunLoop];
    self.runLoopMode = NSRunLoopCommonModes;
    self.securityPolicy = nil;
    self.securityDomain = nil;
    
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
    
    if(self.securityPolicyApplied){
        return YES;
    }
    
    SecTrustRef serverTrust = (__bridge SecTrustRef) [writeStream propertyForKey: (__bridge NSString *)kCFStreamPropertySSLPeerTrust];
    if(!serverTrust){
        return NO;
    }
    
    self.securityPolicyApplied = [self.securityPolicy evaluateServerTrust:serverTrust forDomain:self.securityDomain];
    return self.securityPolicyApplied;
}

- (void)stream:(NSStream*)sender handleEvent:(NSStreamEvent)eventCode {
    
    if (eventCode & NSStreamEventOpenCompleted) {
        if (DEBUGENC) NSLog(@"[MQTTCFSocketEncoder] NSStreamEventOpenCompleted");

    }
    if (eventCode & NSStreamEventHasBytesAvailable) {
        if (DEBUGENC)  NSLog(@"[MQTTCFSocketEncoder] NSStreamEventHasBytesAvailable");
    }
    
    if (eventCode &  NSStreamEventHasSpaceAvailable) {
        if (DEBUGENC) NSLog(@"[MQTTCFSocketEncoder] NSStreamEventHasSpaceAvailable");
        if(![self applySSLSecurityPolicy:sender withEvent:eventCode]){
            self.state = MQTTCFSocketEncoderStateError;
            self.error = [NSError errorWithDomain:@"MQTT"
                                             code:errSSLXCertChainInvalid
                                         userInfo:@{NSLocalizedDescriptionKey: @"Unable to apply security policy, the SSL connection is insecure!"}];
        }
        
        if (self.state == MQTTCFSocketEncoderStateInitializing) {
            self.state = MQTTCFSocketEncoderStateReady;
            [self.delegate encoderDidOpen:self];
        }
        
        if (self.state == MQTTCFSocketEncoderStateReady) {
            if (self.buffer.length) {
                [self send:nil];
            }
        }
    }
    
    if (eventCode &  NSStreamEventEndEncountered) {
        if (DEBUGENC) NSLog(@"[MQTTCFSocketEncoder] NSStreamEventEndEncountered");
        self.state = MQTTCFSocketEncoderStateInitializing;
        self.error = nil;
        [self.delegate encoderdidClose:self];
    }
    
    if (eventCode &  NSStreamEventErrorOccurred) {
        if (DEBUGENC) NSLog(@"[MQTTCFSocketEncoder] NSStreamEventErrorOccurred");
        self.state = MQTTCFSocketEncoderStateError;
        self.error = self.stream.streamError;
        [self.delegate encoder:self didFailWithError:self.error];
    }
}

- (BOOL)send:(NSData *)data {
    @synchronized(self) {
        if (self.state != MQTTCFSocketEncoderStateReady) {
            if (DEBUGENC) NSLog(@"[MQTTCFSocketEncoder] not MQTTCFSocketEncoderStateReady");
            return FALSE;
        }
        
        if (data) {
            [self.buffer appendData:data];
        }
        
        if (self.buffer.length) {
            if (DEBUGENC) NSLog(@"[MQTTCFSocketEncoder] buffer to write (%lu)=%@...", (unsigned long)self.buffer.length,
                                [self.buffer subdataWithRange:NSMakeRange(0, MIN(16, self.buffer.length))]);
            
            NSInteger n = [self.stream write:self.buffer.bytes maxLength:self.buffer.length];
            
            if (n == -1) {
                if (DEBUGENC) NSLog(@"[MQTTCFSocketEncoder] streamError: %@", self.error);
                self.state = MQTTCFSocketEncoderStateError;
                self.error = self.stream.streamError;
                return FALSE;
            } else {
                if (n < self.buffer.length) {
                    if (DEBUGENC) NSLog(@"[MQTTCFSocketEncoder] buffer partially written: %ld", n);
                }
                [self.buffer replaceBytesInRange:NSMakeRange(0, n) withBytes:NULL length:0];
            }
        }
        return TRUE;
    }
}

@end