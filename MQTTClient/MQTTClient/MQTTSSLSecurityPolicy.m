//
// MQTTSSLSecurityPolicy.m
// MQTTClient.framework
//
// Created by @bobwenx on 15/6/1.
//
// based on
//
// Copyright (c) 2011–2015 AFNetwork (http://alamofire.org/)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "MQTTSSLSecurityPolicy.h"
#import <AssertMacros.h>

#import "MQTTLog.h"

static BOOL SSLSecKeyIsEqualToKey(SecKeyRef key1, SecKeyRef key2) {
    return [(__bridge id) key1 isEqual:(__bridge id) key2];
}

static id SSLPublicKeyForCertificate(NSData *certificate) {
    id allowedPublicKey = nil;
    SecCertificateRef allowedCertificate;
    SecCertificateRef allowedCertificates[1];
    CFArrayRef tempCertificates = nil;
    SecPolicyRef policy = nil;
    SecTrustRef allowedTrust = nil;
    SecTrustResultType result;

    allowedCertificate = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)certificate);
    __Require_Quiet(allowedCertificate != NULL, _out);

    allowedCertificates[0] = allowedCertificate;
    tempCertificates = CFArrayCreate(NULL, (const void **)allowedCertificates, 1, NULL);

    policy = SecPolicyCreateBasicX509();
    __Require_noErr_Quiet(SecTrustCreateWithCertificates(tempCertificates, policy, &allowedTrust), _out);
    __Require_noErr_Quiet(SecTrustEvaluate(allowedTrust, &result), _out);

    allowedPublicKey = (__bridge_transfer id)SecTrustCopyPublicKey(allowedTrust);

    _out:
    if (allowedTrust) {
        CFRelease(allowedTrust);
    }

    if (policy) {
        CFRelease(policy);
    }

    if (tempCertificates) {
        CFRelease(tempCertificates);
    }

    if (allowedCertificate) {
        CFRelease(allowedCertificate);
    }

    return allowedPublicKey;
}

static BOOL SSLServerTrustIsValid(SecTrustRef serverTrust) {
    BOOL isValid = NO;
    SecTrustResultType result;
    __Require_noErr_Quiet(SecTrustEvaluate(serverTrust, &result), _out);

    isValid = (result == kSecTrustResultUnspecified      // The OS trusts this certificate implicitly.
                || result == kSecTrustResultProceed);    // The user explicitly told the OS to trust it.

    // else?  It's somebody else's key. Fall immediately.

    _out:
    return isValid;
}

static NSArray * SSLCertificateTrustChainForServerTrust(SecTrustRef serverTrust) {
    CFIndex certificateCount = SecTrustGetCertificateCount(serverTrust);
    NSMutableArray *trustChain = [NSMutableArray arrayWithCapacity:(NSUInteger)certificateCount];

    for (CFIndex i = 0; i < certificateCount; i++) {
        SecCertificateRef certificate = SecTrustGetCertificateAtIndex(serverTrust, i);
        [trustChain addObject:(__bridge_transfer NSData *)SecCertificateCopyData(certificate)];
    }

    return [NSArray arrayWithArray:trustChain];
}

static NSArray * SSLPublicKeyTrustChainForServerTrust(SecTrustRef serverTrust) {
    SecPolicyRef policy = SecPolicyCreateBasicX509();
    CFIndex certificateCount = SecTrustGetCertificateCount(serverTrust);
    NSMutableArray *trustChain = [NSMutableArray arrayWithCapacity:(NSUInteger)certificateCount];
    for (CFIndex i = 0; i < certificateCount; i++) {
        SecCertificateRef certificate = SecTrustGetCertificateAtIndex(serverTrust, i);

        SecCertificateRef someCertificates[] = {certificate};
        CFArrayRef certificates = CFArrayCreate(NULL, (const void **)someCertificates, 1, NULL);

        SecTrustRef trust;
        __Require_noErr_Quiet(SecTrustCreateWithCertificates(certificates, policy, &trust), _out);

        SecTrustResultType result;
        __Require_noErr_Quiet(SecTrustEvaluate(trust, &result), _out);

        [trustChain addObject:(__bridge_transfer id)SecTrustCopyPublicKey(trust)];

        _out:
        if (trust) {
            CFRelease(trust);
        }

        if (certificates) {
            CFRelease(certificates);
        }

        continue;
    }
    CFRelease(policy);

    return [NSArray arrayWithArray:trustChain];
}

@interface MQTTSSLSecurityPolicy()
@property (readwrite, nonatomic, assign) MQTTSSLPinningMode SSLPinningMode;
@property (readwrite, nonatomic, strong) NSArray *pinnedPublicKeys;
@end

@implementation MQTTSSLSecurityPolicy

#pragma mark - SSL Security Policy

+ (NSArray *)defaultPinnedCertificates {
    static NSArray *_defaultPinnedCertificates = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSBundle *bundle = [NSBundle bundleForClass:[self class]];
        NSArray *paths = [bundle pathsForResourcesOfType:@"cer" inDirectory:@"."];

        NSMutableArray *certificates = [NSMutableArray arrayWithCapacity:[paths count]];
        for (NSString *path in paths) {
            NSData *certificateData = [NSData dataWithContentsOfFile:path];
            [certificates addObject:certificateData];
        }

        _defaultPinnedCertificates = [[NSArray alloc] initWithArray:certificates];
    });

    return _defaultPinnedCertificates;
}

+ (instancetype)defaultPolicy {
    MQTTSSLSecurityPolicy *securityPolicy = [[self alloc] init];
    securityPolicy.SSLPinningMode = MQTTSSLPinningModeNone;

    return securityPolicy;
}

+ (instancetype)policyWithPinningMode:(MQTTSSLPinningMode)pinningMode {
    MQTTSSLSecurityPolicy *securityPolicy = [[self alloc] init];
    securityPolicy.SSLPinningMode = pinningMode;

    [securityPolicy setPinnedCertificates:[self defaultPinnedCertificates]];

    return securityPolicy;
}

- (id)init {
    self = [super init];
    if (!self) {
        return nil;
    }

    self.validatesCertificateChain = YES;
    self.validatesDomainName = YES;

    return self;
}

- (void)setPinnedCertificates:(NSArray *)pinnedCertificates {
    _pinnedCertificates = [[NSOrderedSet orderedSetWithArray:pinnedCertificates] array];
    
    if (self.pinnedCertificates) {
        NSMutableArray *mutablePinnedPublicKeys = [NSMutableArray arrayWithCapacity:[self.pinnedCertificates count]];
        for (NSData *certificate in self.pinnedCertificates) {
            id publicKey = SSLPublicKeyForCertificate(certificate);
            if (!publicKey) {
                continue;
            }
            [mutablePinnedPublicKeys addObject:publicKey];
        }
        self.pinnedPublicKeys = [NSArray arrayWithArray:mutablePinnedPublicKeys];
    } else {
        self.pinnedPublicKeys = nil;
    }
}

- (BOOL)evaluateServerTrust:(SecTrustRef)serverTrust
                  forDomain:(NSString *)domain
{
    NSMutableArray *policies = [NSMutableArray array];
    if (self.validatesDomainName) {
        [policies addObject:(__bridge_transfer id)SecPolicyCreateSSL(true, (__bridge CFStringRef)domain)];
    } else {
        [policies addObject:(__bridge_transfer id)SecPolicyCreateBasicX509()];
    }

    SecTrustSetPolicies(serverTrust, (__bridge CFArrayRef)policies);

    if (self.SSLPinningMode == MQTTSSLPinningModeNone) {
        return self.allowInvalidCertificates || SSLServerTrustIsValid(serverTrust);
    }
    // if client didn't allow invalid certs, it must pass CA infrastructure
    else if (!SSLServerTrustIsValid(serverTrust) && !self.allowInvalidCertificates) {
        return NO;
    }

    NSArray *serverCertificates = SSLCertificateTrustChainForServerTrust(serverTrust);
    switch (self.SSLPinningMode) {
        case MQTTSSLPinningModeNone:
        default:
            return NO;
        case MQTTSSLPinningModeCertificate: {
            NSMutableArray *pinnedCertificates = [NSMutableArray array];
            for (NSData *certificateData in self.pinnedCertificates) {
                @try {
                    [pinnedCertificates addObject:(__bridge_transfer id)SecCertificateCreateWithData(NULL, (__bridge CFDataRef)certificateData)];
                } @catch (NSException *exception) {
                    //fix issue #151, if the pinnedCertification is not a valid DER-encoded X.509 certificate, for example it is the PEM format, SecCertificateCreateWithData will return nil, and application will crash
                    if ([exception.name isEqual:NSInvalidArgumentException]) {
                        return NO;
                    }
                }
            }
            SecTrustSetAnchorCertificates(serverTrust, (__bridge CFArrayRef)pinnedCertificates);

            if (!SSLServerTrustIsValid(serverTrust)) {
                return NO;
            }

            if (!self.validatesCertificateChain) {
                return YES;
            }

            NSUInteger trustedCertificateCount = 0;
            for (NSData *trustChainCertificate in serverCertificates) {
                if ([self.pinnedCertificates containsObject:trustChainCertificate]) {
                    trustedCertificateCount++;
                }
            }

            return trustedCertificateCount == [serverCertificates count];
        }
        case MQTTSSLPinningModePublicKey: {
            NSUInteger trustedPublicKeyCount = 0;
            NSArray *publicKeys = SSLPublicKeyTrustChainForServerTrust(serverTrust);
            if (!self.validatesCertificateChain && [publicKeys count] > 0) {
                publicKeys = @[[publicKeys firstObject]];
            }

            for (id trustChainPublicKey in publicKeys) {
                for (id pinnedPublicKey in self.pinnedPublicKeys) {
                    if (SSLSecKeyIsEqualToKey((__bridge SecKeyRef)trustChainPublicKey, (__bridge SecKeyRef)pinnedPublicKey)) {
                        trustedPublicKeyCount += 1;
                    }
                }
            }

            return trustedPublicKeyCount > 0 && ((self.validatesCertificateChain && trustedPublicKeyCount == [serverCertificates count]) || (!self.validatesCertificateChain && trustedPublicKeyCount >= 1));
        }
    }

    return NO;
}

#pragma mark - NSKeyValueObserving

+ (NSSet *)keyPathsForValuesAffectingPinnedPublicKeys {
    return [NSSet setWithObject:@"pinnedCertificates"];
}
@end