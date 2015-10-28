//
//  MultiThreadingTests.m
//  MQTTClient
//
//  Created by Christoph Krey on 08.07.14.
//  Copyright (c) 2014 Christoph Krey. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MQTTClient.h"
#import "MQTTClientTests.h"

@interface OneTest : NSObject <MQTTSessionDelegate>
@property (strong, nonatomic) MQTTSession *session;
@property (nonatomic) NSInteger event;
@property (strong, nonatomic) NSError *error;
@property (strong, nonatomic) NSDictionary *parameters;
@end

@implementation OneTest

- (id)setup:(NSDictionary *)parameters
{
    self.parameters = parameters;

    self.session = [[MQTTSession alloc] initWithClientId:nil
                                                userName:parameters[@"user"]
                                                password:parameters[@"pass"]
                                               keepAlive:60
                                            cleanSession:YES
                                                    will:NO
                                               willTopic:nil
                                                 willMsg:nil
                                                 willQoS:0
                                          willRetainFlag:NO
                                           protocolLevel:[parameters[@"protocollevel"] intValue]
                                                 runLoop:[NSRunLoop currentRunLoop]
                                                 forMode:NSRunLoopCommonModes
                                          securityPolicy:[self securityPolicy:parameters]
                                            certificates:[self clientCerts:parameters]];

    self.session.delegate = self;
    self.session.persistence.persistent = PERSISTENT;
    return self;
}

- (BOOL)runSynch {
    NSLog(@"%@ connecting", self.session.clientId);

    if ([self.session connectAndWaitToHost:self.parameters[@"host"]
                                      port:[self.parameters[@"port"] intValue]
                                  usingSSL:[self.parameters[@"tls"] boolValue]]) {

        [self.session subscribeAndWaitToTopic:@"#" atLevel:MQTTQosLevelAtLeastOnce];

        [self.session publishAndWaitData:[@"data" dataUsingEncoding:NSUTF8StringEncoding]
                                 onTopic:@"MQTTClient"
                                  retain:NO
                                     qos:2];

        [self.session closeAndWait];
        return true;
    } else {
        return false;
    }
}

- (void)start
{
    self.event = -1;
    [self.session connectToHost:self.parameters[@"host"]
                           port:[self.parameters[@"port"] intValue]
                       usingSSL:[self.parameters[@"tls"] boolValue]];
    NSLog(@"%@ connecting", self.session.clientId);


}

- (void)sub
{
    self.event = -1;
    [self.session subscribeToTopic:@"MQTTClient/#" atLevel:1];
}

- (void)pub
{
    self.event = -1;
    [self.session publishData:[@"data" dataUsingEncoding:NSUTF8StringEncoding] onTopic:@"MQTTClient" retain:NO qos:2];
}

- (void)close
{
    self.event = -1;
    [self.session close];
}

- (void)stop
{
    self.session.delegate = nil;
    self.session = nil;
}

- (void)subAckReceived:(MQTTSession *)session msgID:(UInt16)msgID grantedQoss:(NSArray *)qoss
{
    self.event = 999;
}

- (void)messageDelivered:(MQTTSession *)session msgID:(UInt16)msgID
{
    self.event = 999;
}

- (void)newMessage:(MQTTSession *)session data:(NSData *)data onTopic:(NSString *)topic qos:(MQTTQosLevel)qos retained:(BOOL)retained mid:(unsigned int)mid
{
    //NSLog(@"newMessage:%@ onTopic:%@ qos:%d retained:%d mid:%d", data, topic, qos, retained, mid);
}

- (void)handleEvent:(MQTTSession *)session event:(MQTTSessionEvent)eventCode error:(NSError *)error
{
    //NSLog(@"handleEvent:%ld error:%@", eventCode, error);
    self.event = eventCode;
    self.error = error;
}

- (NSArray *)clientCerts:(NSDictionary *)parameters {
    NSArray *clientCerts = nil;
    if (parameters[@"clientp12"] && parameters[@"clientp12pass"]) {
        
        NSString *path = [[NSBundle bundleForClass:[OneTest class]] pathForResource:parameters[@"clientp12"]
                                                                                         ofType:@"p12"];
        
        clientCerts = [MQTTSession clientCertsFromP12:path passphrase:parameters[@"clientp12pass"]];
    }
    return clientCerts;
}

- (MQTTSSLSecurityPolicy *)securityPolicy:(NSDictionary *)parameters {
    MQTTSSLSecurityPolicy *securityPolicy = nil;
    
    if (parameters[@"serverCER"]) {
        
        NSString *path = [[NSBundle bundleForClass:[OneTest class]] pathForResource:parameters[@"serverCER"]
                                                                                         ofType:@"cer"];
        if (path) {
            NSData *certificateData = [NSData dataWithContentsOfFile:path];
            if (certificateData) {
                securityPolicy = [MQTTSSLSecurityPolicy policyWithPinningMode:MQTTSSLPinningModeCertificate];
                securityPolicy.pinnedCertificates = [[NSArray alloc] initWithObjects:certificateData, nil];
                securityPolicy.validatesCertificateChain = TRUE;
                securityPolicy.allowInvalidCertificates = FALSE;
                securityPolicy.validatesDomainName = TRUE;
            }
        }
    }
    return securityPolicy;
}




@end

@interface MultiThreadingTests : XCTestCase <MQTTSessionDelegate>

@end

@implementation MultiThreadingTests

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testAsynch
{
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        [self runAsynch:parameters];
    }
}

- (void)testSynch
{
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        [self runSynch:parameters];
    }
}

- (void)testMultiConnect
{
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        NSMutableArray *connections = [[NSMutableArray alloc] initWithCapacity:MULTI];

        for (int i = 0; i < MULTI; i++) {
            OneTest *oneTest = [[OneTest alloc] init];
            [connections addObject:oneTest];
        }

        for (OneTest *oneTest in connections) {
            [oneTest setup:parameters];
        }

        for (OneTest *oneTest in connections) {
            [oneTest start];
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }

        for (OneTest *oneTest in connections) {
            XCTAssertEqual(oneTest.event, MQTTSessionEventConnected, @"%@ Not Connected %ld %@", oneTest.session.clientId, (long)oneTest.event, oneTest.error);
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }

        for (OneTest *oneTest in connections) {
            [oneTest sub];
        }

        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:10]];

        for (OneTest *oneTest in connections) {
            [oneTest pub];
        }

        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:10]];

        for (OneTest *oneTest in connections) {
            [oneTest close];
        }

        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:10]];

        for (OneTest *oneTest in connections) {
            [oneTest stop];
        }
    }
}

- (void)testAsynchThreads
{
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];

        NSMutableArray *threads = [[NSMutableArray alloc] initWithCapacity:MULTI];

        for (int i = 0; i < MULTI; i++) {
            NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(runAsynch:) object:parameters];
            [threads addObject:thread];
        }

        for (NSThread *thread in threads) {
            [thread start];
        }

        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:10]];

        for (NSThread *thread in threads) {
            [thread cancel];
        }
    }
}

- (void)testSynchThreads
{
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];

        NSMutableArray *threads = [[NSMutableArray alloc] initWithCapacity:MULTI];

        for (int i = 0; i < MULTI; i++) {
            NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(runSynch:) object:parameters];
            [threads addObject:thread];
        }

        for (NSThread *thread in threads) {
            [thread start];
        }

        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:10]];

        for (NSThread *thread in threads) {
            [thread cancel];
        }
    }
}

- (void)runAsynch:(NSDictionary *)parameters
{
    OneTest *test = [[OneTest alloc] init];
    [test setup:parameters];
    [test start];

    while (test.event == -1) {
        //NSLog(@"waiting for connection");
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }

    XCTAssertEqual(test.event, MQTTSessionEventConnected, @"%@ Not Connected %ld %@", test.session.clientId, (long)test.event, test.error);

    if (test.session.status == MQTTSessionStatusConnected) {

        [test sub];

        while (test.event == -1) {
            //NSLog(@"%@ waiting for suback", test.session.clientId);
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }

        [test pub];

        while (test.event == -1) {
            //NSLog(@"%@ waiting for puback", test.session.clientId);
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }

        [test close];
        
        while (test.event == -1) {
            //NSLog(@"%@ waiting for close", test.session.clientId);
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }
    }
    
    [test stop];
}

- (void)runSynch:(NSDictionary *)parameters
{
    OneTest *test = [[OneTest alloc] init];
    [test setup:parameters];
    
    if (![test runSynch]) {
        XCTFail(@"%@ Not Connected %ld %@", test.session.clientId, (long)test.event, test.error);
    }
}

@end
