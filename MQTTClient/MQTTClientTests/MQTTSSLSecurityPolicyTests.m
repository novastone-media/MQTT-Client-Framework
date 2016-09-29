//
//  MQTTSSLSecurityPolicyTests.m
//  MQTTClient.framework
//
//  Created by @bobwenx on 15/6/1.
//

#import <XCTest/XCTest.h>

#import "MQTTLog.h"
#import "MQTTSSLSecurityPolicy.h"
#import "MQTTTestHelpers.h"

@interface MQTTSSLSecurityPolicyTests : MQTTTestHelpers
@end

static SecTrustRef UTTrustChainForCertsInDirectory(NSString *directoryPath) {
    NSArray *certFileNames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directoryPath error:nil];
    NSMutableArray *certs  = [NSMutableArray arrayWithCapacity:[certFileNames count]];
    for (NSString *path in certFileNames) {
        NSData *certData = [NSData dataWithContentsOfFile:[directoryPath stringByAppendingPathComponent:path]];
        SecCertificateRef cert = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)(certData));
        [certs addObject:(__bridge id)(cert)];
    }

    SecPolicyRef policy = SecPolicyCreateBasicX509();
    SecTrustRef trust = NULL;
    SecTrustCreateWithCertificates((__bridge CFTypeRef)(certs), policy, &trust);
    CFRelease(policy);

    return trust;
}

static SecTrustRef UTHTTPBinOrgServerTrust() {
    NSString *bundlePath = [[NSBundle bundleForClass:[MQTTSSLSecurityPolicyTests class]] resourcePath];
    NSString *serverCertDirectoryPath = [bundlePath stringByAppendingPathComponent:@"HTTPBinOrgServerTrustChain"];

    return UTTrustChainForCertsInDirectory(serverCertDirectoryPath);
}

static SecCertificateRef UTHTTPBinOrgCertificate() {
    NSString *certPath = [[NSBundle bundleForClass:[MQTTSSLSecurityPolicyTests class]] pathForResource:@"httpbinorg_01162016" ofType:@"cer"];
    NSCAssert(certPath != nil, @"Path for certificate should not be nil");
    NSData *certData = [NSData dataWithContentsOfFile:certPath];

    return SecCertificateCreateWithData(NULL, (__bridge CFDataRef)(certData));
}

static SecCertificateRef UTCOMODORSADomainValidationSecureServerCertificate() {
    NSString *certPath = [[NSBundle bundleForClass:[MQTTSSLSecurityPolicyTests class]] pathForResource:@"COMODO_RSA_Domain_Validation_Secure_Server_CA" ofType:@"cer"];
    NSCAssert(certPath != nil, @"Path for certificate should not be nil");
    NSData *certData = [NSData dataWithContentsOfFile:certPath];

    return SecCertificateCreateWithData(NULL, (__bridge CFDataRef)(certData));
}

static SecCertificateRef UTCOMODORSACertificate() {
    NSString *certPath = [[NSBundle bundleForClass:[MQTTSSLSecurityPolicyTests class]] pathForResource:@"COMODO_RSA_Certification_Authority" ofType:@"cer"];
    NSCAssert(certPath != nil, @"Path for certificate should not be nil");
    NSData *certData = [NSData dataWithContentsOfFile:certPath];

    return SecCertificateCreateWithData(NULL, (__bridge CFDataRef)(certData));
}

static SecCertificateRef UTAddTrustExternalRootCertificate() {
    NSString *certPath = [[NSBundle bundleForClass:[MQTTSSLSecurityPolicyTests class]] pathForResource:@"AddTrust_External_CA_Root" ofType:@"cer"];
    NSCAssert(certPath != nil, @"Path for certificate should not be nil");
    NSData *certData = [NSData dataWithContentsOfFile:certPath];

    return SecCertificateCreateWithData(NULL, (__bridge CFDataRef)(certData));
}

static SecCertificateRef UTSelfSignedCertificateWithoutDomain() {
    NSString *certPath = [[NSBundle bundleForClass:[MQTTSSLSecurityPolicyTests class]] pathForResource:@"NoDomains" ofType:@"cer"];
    NSCAssert(certPath != nil, @"Path for certificate should not be nil");
    NSData *certData = [NSData dataWithContentsOfFile:certPath];

    return SecCertificateCreateWithData(NULL, (__bridge CFDataRef)(certData));
}

static SecCertificateRef UTSelfSignedCertificateWithCommonNameDomain() {
    NSString *certPath = [[NSBundle bundleForClass:[MQTTSSLSecurityPolicyTests class]] pathForResource:@"foobar.com" ofType:@"cer"];
    NSCAssert(certPath != nil, @"Path for certificate should not be nil");
    NSData *certData = [NSData dataWithContentsOfFile:certPath];

    return SecCertificateCreateWithData(NULL, (__bridge CFDataRef)(certData));
}

static SecCertificateRef UTSelfSignedCertificateWithDNSNameDomain() {
    NSString *certPath = [[NSBundle bundleForClass:[MQTTSSLSecurityPolicyTests class]] pathForResource:@"AltName" ofType:@"cer"];
    NSCAssert(certPath != nil, @"Path for certificate should not be nil");
    NSData *certData = [NSData dataWithContentsOfFile:certPath];

    return SecCertificateCreateWithData(NULL, (__bridge CFDataRef)(certData));
}

static NSArray * CertificateTrustChainForServerTrust(SecTrustRef serverTrust) {
    CFIndex certificateCount = SecTrustGetCertificateCount(serverTrust);
    NSMutableArray *trustChain = [NSMutableArray arrayWithCapacity:(NSUInteger)certificateCount];

    for (CFIndex i = 0; i < certificateCount; i++) {
        SecCertificateRef certificate = SecTrustGetCertificateAtIndex(serverTrust, i);
        [trustChain addObject:(__bridge_transfer NSData *)SecCertificateCopyData(certificate)];
    }

    return [NSArray arrayWithArray:trustChain];
}

static SecTrustRef UTTrustWithCertificate(SecCertificateRef certificate) {
    NSArray *certs  = @[(__bridge id) (certificate)];

    SecPolicyRef policy = SecPolicyCreateBasicX509();
    SecTrustRef trust = NULL;
    SecTrustCreateWithCertificates((__bridge CFTypeRef)(certs), policy, &trust);
    CFRelease(policy);

    return trust;
}

#pragma mark - MQTTSSLSecurityPolicy Tests

@implementation MQTTSSLSecurityPolicyTests

- (void)setUp {
    [super setUp];
#ifdef LUMBERJACK
    if (![[DDLog allLoggers] containsObject:[DDTTYLogger sharedInstance]])
        [DDLog addLogger:[DDTTYLogger sharedInstance] withLevel:DDLogLevelAll];
    if (![[DDLog allLoggers] containsObject:[DDASLLogger sharedInstance]])
        [DDLog addLogger:[DDASLLogger sharedInstance] withLevel:DDLogLevelWarning];
#endif
}

- (void)tearDown {
    [super tearDown];
}

- (void)testLeafPublicKeyPinningIsEnforcedForHTTPBinOrgPinnedCertificateAgainstHTTPBinOrgServerTrust {
    MQTTSSLSecurityPolicy *policy = [MQTTSSLSecurityPolicy policyWithPinningMode:MQTTSSLPinningModePublicKey];

    SecCertificateRef addtrustRootCertificate = UTAddTrustExternalRootCertificate();
    SecCertificateRef comodoRsaCACertificate = UTCOMODORSACertificate();
    SecCertificateRef comodoRsaDomainValidationCertificate = UTCOMODORSADomainValidationSecureServerCertificate();
    SecCertificateRef httpBinCertificate = UTHTTPBinOrgCertificate();

    [policy setPinnedCertificates:@[(__bridge_transfer NSData *)SecCertificateCopyData(addtrustRootCertificate),
            (__bridge_transfer NSData *)SecCertificateCopyData(comodoRsaCACertificate),
            (__bridge_transfer NSData *)SecCertificateCopyData(comodoRsaDomainValidationCertificate),
            (__bridge_transfer NSData *)SecCertificateCopyData(httpBinCertificate)]];

    CFRelease(addtrustRootCertificate);
    CFRelease(comodoRsaCACertificate);
    CFRelease(comodoRsaDomainValidationCertificate);
    CFRelease(httpBinCertificate);

    [policy setValidatesCertificateChain:NO];

    SecTrustRef trust = UTHTTPBinOrgServerTrust();
    XCTAssert([policy evaluateServerTrust:trust forDomain:nil], @"HTTPBin.org Public Key Pinning Mode Failed");
    CFRelease(trust);
}

- (void)testPublicKeyChainPinningIsEnforcedForHTTPBinOrgPinnedCertificateAgainstHTTPBinOrgServerTrust {
    MQTTSSLSecurityPolicy *policy = [MQTTSSLSecurityPolicy policyWithPinningMode:MQTTSSLPinningModePublicKey];

    SecTrustRef clientTrust = UTHTTPBinOrgServerTrust();
    NSArray * certificates = CertificateTrustChainForServerTrust(clientTrust);
    CFRelease(clientTrust);
    [policy setPinnedCertificates:certificates];

    SecTrustRef trust = UTHTTPBinOrgServerTrust();
    XCTAssert([policy evaluateServerTrust:trust forDomain:@"httpbin.org"], @"HTTPBin.org Public Key Pinning Mode Failed");
    CFRelease(trust);
}

- (void)testLeafCertificatePinningIsEnforcedForHTTPBinOrgPinnedCertificateAgainstHTTPBinOrgServerTrust {
    MQTTSSLSecurityPolicy *policy = [MQTTSSLSecurityPolicy policyWithPinningMode:MQTTSSLPinningModeCertificate];

    SecCertificateRef addtrustRootCertificate = UTAddTrustExternalRootCertificate();
    SecCertificateRef comodoRsaCACertificate = UTCOMODORSACertificate();
    SecCertificateRef comodoRsaDomainValidationCertificate = UTCOMODORSADomainValidationSecureServerCertificate();
    SecCertificateRef httpBinCertificate = UTHTTPBinOrgCertificate();

    [policy setPinnedCertificates:@[(__bridge_transfer NSData *)SecCertificateCopyData(addtrustRootCertificate),
            (__bridge_transfer NSData *)SecCertificateCopyData(comodoRsaCACertificate),
            (__bridge_transfer NSData *)SecCertificateCopyData(comodoRsaDomainValidationCertificate),
            (__bridge_transfer NSData *)SecCertificateCopyData(httpBinCertificate)]];

    CFRelease(addtrustRootCertificate);
    CFRelease(comodoRsaCACertificate);
    CFRelease(comodoRsaDomainValidationCertificate);
    CFRelease(httpBinCertificate);

    [policy setValidatesCertificateChain:NO];

    SecTrustRef trust = UTHTTPBinOrgServerTrust();
    XCTAssert([policy evaluateServerTrust:trust forDomain:nil], @"HTTPBin.org Public Key Pinning Mode Failed");
    CFRelease(trust);
}

- (void)testCertificateChainPinningIsEnforcedForHTTPBinOrgPinnedCertificateAgainstHTTPBinOrgServerTrust {
    MQTTSSLSecurityPolicy *policy = [MQTTSSLSecurityPolicy policyWithPinningMode:MQTTSSLPinningModeCertificate];
    SecTrustRef clientTrust = UTHTTPBinOrgServerTrust();
    NSArray * certificates = CertificateTrustChainForServerTrust(clientTrust);
    CFRelease(clientTrust);
    [policy setPinnedCertificates:certificates];

    SecTrustRef trust = UTHTTPBinOrgServerTrust();
    XCTAssert([policy evaluateServerTrust:trust forDomain:@"httpbin.org"], @"HTTPBin.org Public Key Pinning Mode Failed");
    CFRelease(trust);
}

- (void)testNoPinningIsEnforcedForHTTPBinOrgPinnedCertificateAgainstHTTPBinOrgServerTrust {
    MQTTSSLSecurityPolicy *policy = [MQTTSSLSecurityPolicy policyWithPinningMode:MQTTSSLPinningModeNone];

    SecCertificateRef certificate = UTHTTPBinOrgCertificate();
    [policy setPinnedCertificates:@[(__bridge_transfer NSData *)SecCertificateCopyData(certificate)]];
    CFRelease(certificate);
    [policy setAllowInvalidCertificates:YES];

    SecTrustRef trust = UTHTTPBinOrgServerTrust();
    XCTAssert([policy evaluateServerTrust:trust forDomain:@"httpbin.org"], @"HTTPBin.org Pinning should not have been enforced");
    CFRelease(trust);
}

- (void)testPublicKeyPinningFailsForHTTPBinOrgIfNoCertificateIsPinned {
    MQTTSSLSecurityPolicy *policy = [MQTTSSLSecurityPolicy policyWithPinningMode:MQTTSSLPinningModePublicKey];
    [policy setPinnedCertificates:@[]];

    SecTrustRef trust = UTHTTPBinOrgServerTrust();
    XCTAssert([policy evaluateServerTrust:trust forDomain:@"httpbin.org"] == NO, @"HTTPBin.org Public Key Pinning Should have failed with no pinned certificate");
    CFRelease(trust);
}

- (void)testCertificatePinningIsEnforcedForHTTPBinOrgPinnedCertificateWithDomainNameValidationAgainstHTTPBinOrgServerTrust {
    MQTTSSLSecurityPolicy *policy = [MQTTSSLSecurityPolicy policyWithPinningMode:MQTTSSLPinningModeCertificate];

    SecCertificateRef addtrustRootCertificate = UTAddTrustExternalRootCertificate();
    SecCertificateRef comodoRsaCACertificate = UTCOMODORSACertificate();
    SecCertificateRef comodoRsaDomainValidationCertificate = UTCOMODORSADomainValidationSecureServerCertificate();
    SecCertificateRef httpBinCertificate = UTHTTPBinOrgCertificate();

    [policy setPinnedCertificates:@[(__bridge_transfer NSData *)SecCertificateCopyData(addtrustRootCertificate),
            (__bridge_transfer NSData *)SecCertificateCopyData(comodoRsaCACertificate),
            (__bridge_transfer NSData *)SecCertificateCopyData(comodoRsaDomainValidationCertificate),
            (__bridge_transfer NSData *)SecCertificateCopyData(httpBinCertificate)]];

    CFRelease(addtrustRootCertificate);
    CFRelease(comodoRsaCACertificate);
    CFRelease(comodoRsaDomainValidationCertificate);
    CFRelease(httpBinCertificate);

    policy.validatesDomainName = YES;

    SecTrustRef trust = UTHTTPBinOrgServerTrust();
    XCTAssert([policy evaluateServerTrust:trust forDomain:@"httpbin.org"], @"HTTPBin.org Public Key Pinning Mode Failed");
    CFRelease(trust);
}

- (void)testCertificatePinningIsEnforcedForHTTPBinOrgPinnedCertificateWithCaseInsensitiveDomainNameValidationAgainstHTTPBinOrgServerTrust {
    MQTTSSLSecurityPolicy *policy = [MQTTSSLSecurityPolicy policyWithPinningMode:MQTTSSLPinningModePublicKey];

    SecCertificateRef addtrustRootCertificate = UTAddTrustExternalRootCertificate();
    SecCertificateRef comodoRsaCACertificate = UTCOMODORSACertificate();
    SecCertificateRef comodoRsaDomainValidationCertificate = UTCOMODORSADomainValidationSecureServerCertificate();
    SecCertificateRef httpBinCertificate = UTHTTPBinOrgCertificate();

    [policy setPinnedCertificates:@[(__bridge_transfer NSData *)SecCertificateCopyData(addtrustRootCertificate),
            (__bridge_transfer NSData *)SecCertificateCopyData(comodoRsaCACertificate),
            (__bridge_transfer NSData *)SecCertificateCopyData(comodoRsaDomainValidationCertificate),
            (__bridge_transfer NSData *)SecCertificateCopyData(httpBinCertificate)]];

    CFRelease(addtrustRootCertificate);
    CFRelease(comodoRsaCACertificate);
    CFRelease(comodoRsaDomainValidationCertificate);
    CFRelease(httpBinCertificate);

    policy.validatesDomainName = YES;

    SecTrustRef trust = UTHTTPBinOrgServerTrust();
    XCTAssert([policy evaluateServerTrust:trust forDomain:@"httpBin.org"], @"HTTPBin.org Public Key Pinning Mode Failed");
    CFRelease(trust);
}

- (void)testCertificatePinningIsEnforcedForHTTPBinOrgPinnedPublicKeyWithDomainNameValidationAgainstHTTPBinOrgServerTrust {
    MQTTSSLSecurityPolicy *policy = [MQTTSSLSecurityPolicy policyWithPinningMode: MQTTSSLPinningModePublicKey];

    SecCertificateRef addtrustRootCertificate = UTAddTrustExternalRootCertificate();
    SecCertificateRef comodoRsaCACertificate = UTCOMODORSACertificate();
    SecCertificateRef comodoRsaDomainValidationCertificate = UTCOMODORSADomainValidationSecureServerCertificate();
    SecCertificateRef httpBinCertificate = UTHTTPBinOrgCertificate();

    [policy setPinnedCertificates:@[(__bridge_transfer NSData *)SecCertificateCopyData(addtrustRootCertificate),
            (__bridge_transfer NSData *)SecCertificateCopyData(comodoRsaCACertificate),
            (__bridge_transfer NSData *)SecCertificateCopyData(comodoRsaDomainValidationCertificate),
            (__bridge_transfer NSData *)SecCertificateCopyData(httpBinCertificate)]];

    CFRelease(addtrustRootCertificate);
    CFRelease(comodoRsaCACertificate);
    CFRelease(comodoRsaDomainValidationCertificate);
    CFRelease(httpBinCertificate);

    policy.validatesDomainName = YES;

    SecTrustRef trust = UTHTTPBinOrgServerTrust();
    XCTAssert([policy evaluateServerTrust:trust forDomain:@"httpbin.org"], @"HTTPBin.org Public Key Pinning Mode Failed");
    CFRelease(trust);
}

- (void)testCertificatePinningFailsForHTTPBinOrgIfNoCertificateIsPinned {
    MQTTSSLSecurityPolicy *policy = [MQTTSSLSecurityPolicy policyWithPinningMode:MQTTSSLPinningModeCertificate];
    [policy setPinnedCertificates:@[]];

    SecTrustRef trust = UTHTTPBinOrgServerTrust();
    XCTAssert([policy evaluateServerTrust:trust forDomain:@"httpbin.org"] == NO, @"HTTPBin.org Certificate Pinning Should have failed with no pinned certificate");
    CFRelease(trust);
}

- (void)testCertificatePinningFailsForHTTPBinOrgIfDomainNameDoesntMatch {
    MQTTSSLSecurityPolicy *policy = [MQTTSSLSecurityPolicy policyWithPinningMode:MQTTSSLPinningModePublicKey];
    SecCertificateRef certificate = UTHTTPBinOrgCertificate();
    [policy setPinnedCertificates:@[(__bridge_transfer NSData *)SecCertificateCopyData(certificate)]];
    CFRelease(certificate);
    policy.validatesDomainName = YES;

    SecTrustRef trust = UTHTTPBinOrgServerTrust();
    XCTAssert([policy evaluateServerTrust:trust forDomain:@"www.httpbin.org"] == NO, @"HTTPBin.org Certificate Pinning Should have failed with no pinned certificate");
    CFRelease(trust);
}

- (void)testNoPinningIsEnforcedForHTTPBinOrgIfNoCertificateIsPinned {
    MQTTSSLSecurityPolicy *policy = [MQTTSSLSecurityPolicy policyWithPinningMode:MQTTSSLPinningModeNone];
    [policy setPinnedCertificates:@[]];

    SecTrustRef trust = UTHTTPBinOrgServerTrust();
    XCTAssert([policy evaluateServerTrust:trust forDomain:@"httpbin.org"], @"HTTPBin.org Pinning should not have been enforced");
    CFRelease(trust);
}

- (void)testDefaultPolicyContainsHTTPBinOrgCertificate {
    MQTTSSLSecurityPolicy *policy = [MQTTSSLSecurityPolicy defaultPolicy];
    SecCertificateRef cert = UTHTTPBinOrgCertificate();
    NSData *certData = (__bridge NSData *)(SecCertificateCopyData(cert));
    CFRelease(cert);
    NSInteger index = [policy.pinnedCertificates indexOfObjectPassingTest:^BOOL(NSData *data, NSUInteger idx, BOOL *stop) {
        return [data isEqualToData:certData];
    }];

    XCTAssert(index!=NSNotFound, @"HTTPBin.org certificate not found in the default certificates");
}

- (void)testCertificatePinningIsEnforcedWhenPinningSelfSignedCertificateWithoutDomain {
    SecCertificateRef certificate = UTSelfSignedCertificateWithoutDomain();
    SecTrustRef trust = UTTrustWithCertificate(certificate);

    MQTTSSLSecurityPolicy *policy = [MQTTSSLSecurityPolicy policyWithPinningMode:MQTTSSLPinningModeCertificate];
    policy.pinnedCertificates = @[ (__bridge_transfer id)SecCertificateCopyData(certificate) ];
    policy.allowInvalidCertificates = YES;
    policy.validatesDomainName = NO;
    XCTAssert([policy evaluateServerTrust:trust forDomain:@"foo.bar"], @"Certificate should be trusted");

    CFRelease(trust);
    CFRelease(certificate);
}

- (void)testCertificatePinningWhenPinningSelfSignedCertificateWithoutDomain {
    SecCertificateRef certificate = UTSelfSignedCertificateWithoutDomain();
    SecTrustRef trust = UTTrustWithCertificate(certificate);

    MQTTSSLSecurityPolicy *policy = [MQTTSSLSecurityPolicy policyWithPinningMode:MQTTSSLPinningModeCertificate];
    policy.pinnedCertificates = @[ (__bridge_transfer id)SecCertificateCopyData(certificate) ];
    policy.allowInvalidCertificates = YES;
    XCTAssert([policy evaluateServerTrust:trust forDomain:@"foo.bar"] == NO, @"Certificate should not be trusted");

    CFRelease(trust);
    CFRelease(certificate);
}

- (void)testCertificatePinningIsEnforcedWhenPinningSelfSignedCertificateWithCommonNameDomain {
    SecCertificateRef certificate = UTSelfSignedCertificateWithCommonNameDomain();
    SecTrustRef trust = UTTrustWithCertificate(certificate);

    MQTTSSLSecurityPolicy *policy = [MQTTSSLSecurityPolicy policyWithPinningMode:MQTTSSLPinningModeCertificate];
    policy.pinnedCertificates = @[ (__bridge_transfer id)SecCertificateCopyData(certificate) ];
    policy.allowInvalidCertificates = YES;
    XCTAssert([policy evaluateServerTrust:trust forDomain:@"foobar.com"], @"Certificate should be trusted");

    CFRelease(trust);
    CFRelease(certificate);
}

- (void)testCertificatePinningWhenPinningSelfSignedCertificateWithCommonNameDomain {
    SecCertificateRef certificate = UTSelfSignedCertificateWithCommonNameDomain();
    SecTrustRef trust = UTTrustWithCertificate(certificate);

    MQTTSSLSecurityPolicy *policy = [MQTTSSLSecurityPolicy policyWithPinningMode:MQTTSSLPinningModeCertificate];
    policy.pinnedCertificates = @[ (__bridge_transfer id)SecCertificateCopyData(certificate) ];
    policy.allowInvalidCertificates = YES;
    XCTAssert([policy evaluateServerTrust:trust forDomain:@"foo.bar"] == NO, @"Certificate should not be trusted");

    CFRelease(trust);
    CFRelease(certificate);
}

- (void)testCertificatePinningIsEnforcedWhenPinningSelfSignedCertificateWithDNSNameDomain {
    SecCertificateRef certificate = UTSelfSignedCertificateWithDNSNameDomain();
    SecTrustRef trust = UTTrustWithCertificate(certificate);

    MQTTSSLSecurityPolicy *policy = [MQTTSSLSecurityPolicy policyWithPinningMode:MQTTSSLPinningModeCertificate];
    policy.pinnedCertificates = @[ (__bridge_transfer id)SecCertificateCopyData(certificate) ];
    policy.allowInvalidCertificates = YES;
    XCTAssert([policy evaluateServerTrust:trust forDomain:@"foobar.com"], @"Certificate should be trusted");

    CFRelease(trust);
    CFRelease(certificate);
}

- (void)testCertificatePinningWhenPinningSelfSignedCertificateWithDNSNameDomain {
    SecCertificateRef certificate = UTSelfSignedCertificateWithDNSNameDomain();
    SecTrustRef trust = UTTrustWithCertificate(certificate);

    MQTTSSLSecurityPolicy *policy = [MQTTSSLSecurityPolicy policyWithPinningMode:MQTTSSLPinningModeCertificate];
    policy.pinnedCertificates = @[ (__bridge_transfer id)SecCertificateCopyData(certificate) ];
    policy.allowInvalidCertificates = YES;
    XCTAssert([policy evaluateServerTrust:trust forDomain:@"foo.bar"] == NO, @"Certificate should not be trusted");

    CFRelease(trust);
    CFRelease(certificate);
}


// ADN example cert expired
//
// 
// static SecTrustRef UTADNNetServerTrust() {
// NSString *bundlePath = [[NSBundle bundleForClass:[MQTTSSLSecurityPolicyTests class]] resourcePath];
// NSString *serverCertDirectoryPath = [bundlePath stringByAppendingPathComponent:@"ADNNetServerTrustChain"];
// 
// return UTTrustChainForCertsInDirectory(serverCertDirectoryPath);
// }
// 
// - (void)testPublicKeyPinningForHTTPBinOrgFailsWhenPinnedAgainstADNServerTrust {
// MQTTSSLSecurityPolicy *policy = [MQTTSSLSecurityPolicy policyWithPinningMode:MQTTSSLPinningModePublicKey];
// SecCertificateRef certificate = UTHTTPBinOrgCertificate();
// [policy setPinnedCertificates:@[(__bridge_transfer NSData *)SecCertificateCopyData(certificate)]];
// [policy setValidatesCertificateChain:NO];
// 
// SecTrustRef trust = UTADNNetServerTrust();
// XCTAssert([policy evaluateServerTrust:trust forDomain:@"httpbin.org"] == NO, @"HTTPBin.org Public Key Pinning Should have failed against ADN");
// CFRelease(trust);
// }
// 
// - (void)testCertificatePinningForHTTPBinOrgFailsWhenPinnedAgainstADNServerTrust {
// MQTTSSLSecurityPolicy *policy = [MQTTSSLSecurityPolicy policyWithPinningMode:MQTTSSLPinningModeCertificate];
// SecCertificateRef certificate = UTHTTPBinOrgCertificate();
// [policy setPinnedCertificates:@[(__bridge_transfer NSData *)SecCertificateCopyData(certificate)]];
// [policy setValidatesCertificateChain:NO];
// 
// SecTrustRef trust = UTADNNetServerTrust();
// XCTAssert([policy evaluateServerTrust:trust forDomain:@"httpbin.org"] == NO, @"HTTPBin.org Certificate Pinning Should have failed against ADN");
// CFRelease(trust);
// }
// 
//- (void)testDefaultPolicySetToCertificateChain {
//    MQTTSSLSecurityPolicy *policy = [MQTTSSLSecurityPolicy policyWithPinningMode:MQTTSSLPinningModeCertificate];
//    SecTrustRef trust = UTADNNetServerTrust();
//    XCTAssert([policy evaluateServerTrust:trust forDomain:nil], @"Pinning with Default Certficiate Chain Failed");
//    CFRelease(trust);
//}
//
//- (void)testDefaultPolicySetToLeafCertificate {
//    MQTTSSLSecurityPolicy *policy = [MQTTSSLSecurityPolicy policyWithPinningMode:MQTTSSLPinningModeCertificate];
//    [policy setValidatesCertificateChain:NO];
//    SecTrustRef trust = UTADNNetServerTrust();
//    XCTAssert([policy evaluateServerTrust:trust forDomain:nil], @"Pinning with Default Leaf Certficiate Failed");
//    CFRelease(trust);
//}
//
//- (void)testDefaultPolicySetToPublicKeyChain {
//    MQTTSSLSecurityPolicy *policy = [MQTTSSLSecurityPolicy policyWithPinningMode:MQTTSSLPinningModePublicKey];
//    SecTrustRef trust = UTADNNetServerTrust();
//    XCTAssert([policy evaluateServerTrust:trust forDomain:nil], @"Pinning with Default Public Key Chain Failed");
//    CFRelease(trust);
//}
//
//- (void)testDefaultPolicySetToLeafPublicKey {
//    MQTTSSLSecurityPolicy *policy = [MQTTSSLSecurityPolicy policyWithPinningMode:MQTTSSLPinningModePublicKey];
//    [policy setValidatesCertificateChain:NO];
//    SecTrustRef trust = UTADNNetServerTrust();
//    XCTAssert([policy evaluateServerTrust:trust forDomain:nil], @"Pinning with Default Leaf Public Key Failed");
//    CFRelease(trust);
//}

- (void)testDefaultPolicySetToCertificateChainFailsWithMissingChain {
    MQTTSSLSecurityPolicy *policy = [MQTTSSLSecurityPolicy policyWithPinningMode:MQTTSSLPinningModeCertificate];

    // By default the cer files are picked up from the bundle, this forces them to be cleared to emulate having none available
    [policy setPinnedCertificates:@[]];

    SecTrustRef trust = UTHTTPBinOrgServerTrust();
    XCTAssert([policy evaluateServerTrust:trust forDomain:nil] == NO, @"Pinning with Certificate Chain Mode and Missing Chain should have failed");
    CFRelease(trust);
}

- (void)testDefaultPolicySetToPublicKeyChainFailsWithMissingChain {
    MQTTSSLSecurityPolicy *policy = [MQTTSSLSecurityPolicy policyWithPinningMode:MQTTSSLPinningModePublicKey];

    // By default the cer files are picked up from the bundle, this forces them to be cleared to emulate having none available
    [policy setPinnedCertificates:@[]];

    SecTrustRef trust = UTHTTPBinOrgServerTrust();
    XCTAssert([policy evaluateServerTrust:trust forDomain:nil] == NO, @"Pinning with Public Key Chain Mode and Missing Chain should have failed");
    CFRelease(trust);
}

- (void)testDefaultPolicyIsSetToAFSSLPinningModeNone {
    MQTTSSLSecurityPolicy *policy = [MQTTSSLSecurityPolicy defaultPolicy];

    XCTAssert(policy.SSLPinningMode==MQTTSSLPinningModeNone, @"Default policy is not set to AFSSLPinningModeNone.");
}

- (void)testDefaultPolicyMatchesTrustedCertificateWithMatchingHostnameAndRejectsOthers {
    {
        //check non-trusted certificate, incorrect domain
        MQTTSSLSecurityPolicy *policy = [MQTTSSLSecurityPolicy defaultPolicy];
        SecTrustRef trust = UTTrustWithCertificate(UTSelfSignedCertificateWithCommonNameDomain());
        XCTAssert([policy evaluateServerTrust:trust forDomain:@"different.foobar.com"] == NO, @"Invalid certificate with mismatching domain should fail");
        CFRelease(trust);
    }
    {
        //check non-trusted certificate, correct domain
        MQTTSSLSecurityPolicy *policy = [MQTTSSLSecurityPolicy defaultPolicy];
        SecTrustRef trust = UTTrustWithCertificate(UTSelfSignedCertificateWithCommonNameDomain());
        XCTAssert([policy evaluateServerTrust:trust forDomain:@"foobar.com"] == NO, @"Invalid certificate with matching domain should fail");
        CFRelease(trust);
    }
    {
        //check trusted certificate, wrong domain
        MQTTSSLSecurityPolicy *policy = [MQTTSSLSecurityPolicy defaultPolicy];
        SecTrustRef trust = UTHTTPBinOrgServerTrust();
        XCTAssert([policy evaluateServerTrust:trust forDomain:@"nothttpbin.org"] == NO, @"Valid certificate with mismatching domain should fail");
        CFRelease(trust);
    }
    {
        //check trusted certificate, correct domain
        MQTTSSLSecurityPolicy *policy = [MQTTSSLSecurityPolicy defaultPolicy];
        SecTrustRef trust = UTHTTPBinOrgServerTrust();
        XCTAssert([policy evaluateServerTrust:trust forDomain:@"httpbin.org"] == YES, @"Valid certificate with matching domain should pass");
        CFRelease(trust);
    }
}

- (void)testDefaultPolicyIsSetToNotAllowInvalidSSLCertificates {
    MQTTSSLSecurityPolicy *policy = [MQTTSSLSecurityPolicy defaultPolicy];

    XCTAssert(policy.allowInvalidCertificates == NO, @"Default policy should not allow invalid ssl certificates");
}

- (void)testPolicyWithPinningModeIsSetToNotAllowInvalidSSLCertificates {
    MQTTSSLSecurityPolicy *policy = [MQTTSSLSecurityPolicy policyWithPinningMode:MQTTSSLPinningModeNone];

    XCTAssert(policy.allowInvalidCertificates == NO, @"policyWithPinningMode: should not allow invalid ssl certificates by default.");
}

- (void)testPolicyWithPinningModeIsSetToValidatesDomainName {
    MQTTSSLSecurityPolicy *policy = [MQTTSSLSecurityPolicy policyWithPinningMode:MQTTSSLPinningModeNone];

    XCTAssert(policy.validatesDomainName == YES, @"policyWithPinningMode: should validate domain names by default.");
}

- (void)testThatSSLPinningPolicyClassMethodContainsDefaultCertificates{
    MQTTSSLSecurityPolicy *policy = [MQTTSSLSecurityPolicy policyWithPinningMode:MQTTSSLPinningModePublicKey];
    [policy setValidatesCertificateChain:NO];
    XCTAssertNotNil(policy.pinnedCertificates, @"Default certificate array should not be empty for SSL pinning mode policy");
}

- (void)testThatDefaultPinningPolicyClassMethodContainsNoDefaultCertificates{
    MQTTSSLSecurityPolicy *policy = [MQTTSSLSecurityPolicy defaultPolicy];
    XCTAssertNil(policy.pinnedCertificates, @"Default certificate array should be empty for default policy.");
}

@end
