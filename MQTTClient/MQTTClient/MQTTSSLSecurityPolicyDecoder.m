//
// MQTTSSLSecurityPolicyDecoder.m
// MQTTClient.framework
//
// Copyright © 2013-2017, Christoph Krey. All rights reserved.
//

#import "MQTTSSLSecurityPolicyDecoder.h"

#import "MQTTLog.h"

@interface MQTTSSLSecurityPolicyDecoder()
@property (nonatomic) BOOL securityPolicyApplied;

@end

@implementation MQTTSSLSecurityPolicyDecoder

- (instancetype)init {
    self = [super init];
    self.securityPolicy = nil;
    self.securityDomain = nil;
    
    return self;
}

- (BOOL)applySSLSecurityPolicy:(NSStream *)readStream withEvent:(NSStreamEvent)eventCode{
    if (!self.securityPolicy) {
        return YES;
    }

    if (self.securityPolicyApplied) {
        return YES;
    }

    SecTrustRef serverTrust = (__bridge SecTrustRef) [readStream propertyForKey: (__bridge NSString *)kCFStreamPropertySSLPeerTrust];
    if (!serverTrust) {
        return NO;
    }

    self.securityPolicyApplied = [self.securityPolicy evaluateServerTrust:serverTrust forDomain:self.securityDomain];
    return self.securityPolicyApplied;
}

- (void)stream:(NSStream *)sender handleEvent:(NSStreamEvent)eventCode {    
    if (eventCode & NSStreamEventHasBytesAvailable) {
        DDLogVerbose(@"[MQTTCFSocketDecoder] NSStreamEventHasBytesAvailable");
        if (![self applySSLSecurityPolicy:sender withEvent:eventCode]){
            self.state = MQTTCFSocketDecoderStateError;
            self.error = [NSError errorWithDomain:@"MQTT"
                                             code:errSSLXCertChainInvalid
                                         userInfo:@{NSLocalizedDescriptionKey: @"Unable to apply security policy, the SSL connection is insecure!"}];
            [self.delegate decoder:self didFailWithError:self.error];
            return;
        }
    }
    [super stream:sender handleEvent:eventCode];
}

@end
