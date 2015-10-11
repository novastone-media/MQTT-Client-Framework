//
//  MQTTACLTests.m
//  MQTTClient
//
//  Created by Christoph Krey on 03.02.15.
//  Copyright (c) 2015 Christoph Krey. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MQTTClient.h"
#import "MQTTClientTests.h"

@interface MQTTACLTests : XCTestCase <MQTTSessionDelegate>
@property (strong, nonatomic) MQTTSession *session;
@property (nonatomic) int event;
@property (strong, nonatomic) NSError *error;
@property (nonatomic) BOOL timeout;
@property (nonatomic) int type;

@end

@implementation MQTTACLTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

/*
 * [MQTT-3.1.2-19]
 * If the User Name Flag is set to 1, a user name MUST be present in the payload.
 * [MQTT-3.1.2-21]
 * If the Password Flag is set to 1, a password MUST be present in the payload.
 */
- (void)test_connect_user_pwd_MQTT_3_1_2_19_MQTT_3_1_2_21 {
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
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
        self.session.persistence.persistent = PERSISTENT;
        [self connect:self.session parameters:parameters];
        XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
        [self shutdown:parameters];
    }
}

/*
 * [MQTT-3.1.2-19]
 * If the User Name Flag is set to 1, a user name MUST be present in the payload.
 * [MQTT-3.1.2-20]
 * If the Password Flag is set to 0, a password MUST NOT be present in the payload.
 */
- (void)test_connect_user_no_pwd_MQTT_3_1_2_19_MQTT_3_1_2_20 {
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        self.session = [[MQTTSession alloc] initWithClientId:nil
                                                    userName:@"user w/o password"
                                                    password:nil
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
        self.session.persistence.persistent = PERSISTENT;

        [self connect:self.session parameters:parameters];
        XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
        [self shutdown:parameters];
    }
}

/*
 * [MQTT-3.1.2-18]
 * If the User Name Flag is set to 0, a user name MUST NOT be present in the payload.
 * [MQTT-3.1.2-20]
 * If the Password Flag is set to 0, a password MUST NOT be present in the payload.
 */
- (void)test_connect_no_user_no_pwd_MQTT_3_1_2_18_MQTT_3_1_2_20 {
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        self.session = [[MQTTSession alloc] initWithClientId:nil
                                                    userName:nil
                                                    password:nil
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
        self.session.persistence.persistent = PERSISTENT;

        [self connect:self.session parameters:parameters];
        XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
        [self shutdown:parameters];
    }
}

/*
 * [MQTT-3.1.2-22]
 * If the User Name Flag is set to 0, the Password Flag MUST be set to 0.
 */

- (void)test_connect_no_user_but_pwd_MQTT_3_1_2_22 {
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        self.session = [[MQTTSession alloc] initWithClientId:nil
                                                    userName:nil
                                                    password:@"password w/o user"
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
        self.session.persistence.persistent = PERSISTENT;

        [self connect:self.session parameters:parameters];
        XCTAssertEqual(self.event, MQTTSessionEventConnectionClosedByBroker, @"Not Rejected %ld %@", (long)self.event, self.error);
        [self shutdown:parameters];
    }
}
 
#pragma mark helpers

- (NSArray *)clientCerts:(NSDictionary *)parameters {
    NSArray *clientCerts = nil;
    if (parameters[@"clientp12"] && parameters[@"clientp12pass"]) {
        
        NSString *path = [[NSBundle bundleForClass:[MQTTACLTests class]] pathForResource:parameters[@"clientp12"]
                                                                                     ofType:@"p12"];
        
        clientCerts = [MQTTSession clientCertsFromP12:path passphrase:parameters[@"clientp12pass"]];
        if (!clientCerts) {
            XCTFail(@"invalid p12 file");
        }
    }
    return clientCerts;
}

- (MQTTSSLSecurityPolicy *)securityPolicy:(NSDictionary *)parameters {
    MQTTSSLSecurityPolicy *securityPolicy = nil;
    
    if (parameters[@"serverCER"]) {
        
        NSString *path = [[NSBundle bundleForClass:[MQTTACLTests class]] pathForResource:parameters[@"serverCER"]
                                                                                     ofType:@"cer"];
        if (path) {
            NSData *certificateData = [NSData dataWithContentsOfFile:path];
            if (certificateData) {
                securityPolicy = [MQTTSSLSecurityPolicy policyWithPinningMode:MQTTSSLPinningModeCertificate];
                securityPolicy.pinnedCertificates = [[NSArray alloc] initWithObjects:certificateData, nil];
                securityPolicy.validatesCertificateChain = TRUE;
                securityPolicy.allowInvalidCertificates = FALSE;
                securityPolicy.validatesDomainName = TRUE;
            } else {
                XCTFail(@"error reading cer file");
            }
        } else {
            XCTFail(@"cer file not found");
        }
    }
    return securityPolicy;
}

- (void)received:(MQTTSession *)session type:(int)type qos:(MQTTQosLevel)qos retained:(BOOL)retained duped:(BOOL)duped mid:(UInt16)mid data:(NSData *)data {
    //NSLog(@"received:%d qos:%d retained:%d duped:%d mid:%d data:%@", type, qos, retained, duped, mid, data);
    self.type = type;
}

- (void)newMessage:(MQTTSession *)session data:(NSData *)data onTopic:(NSString *)topic qos:(MQTTQosLevel)qos retained:(BOOL)retained mid:(unsigned int)mid {
    //NSLog(@"newMessage:%@ onTopic:%@ qos:%d retained:%d mid:%d", data, topic, qos, retained, mid);
}

- (void)handleEvent:(MQTTSession *)session event:(MQTTSessionEvent)eventCode error:(NSError *)error {
    //NSLog(@"handleEvent:%ld error:%@", (long)eventCode, error);
    self.event = eventCode;
    self.error = error;
}

- (void)ackTimeout:(NSNumber *)timeout {
    //NSLog(@"ackTimeout: %f", [timeout doubleValue]);
    self.timeout = TRUE;
}

- (void)connect:(MQTTSession *)session parameters:(NSDictionary *)parameters{
    session.delegate = self;
    self.event = -1;
    self.timeout = FALSE;

    /* NSLog(@"connecting to:%@ port:%d tls:%d",
     parameters[@"host"],
     [parameters[@"port"] intValue],
     [parameters[@"tls"] boolValue],
     self.);
     */

    [session connectToHost:parameters[@"host"]
                      port:[parameters[@"port"] intValue]
                  usingSSL:[parameters[@"tls"] boolValue]];

    [self performSelector:@selector(ackTimeout:)
               withObject:parameters[@"timeout"]
               afterDelay:[parameters[@"timeout"] intValue]];


    while (!self.timeout && self.event == -1) {
        //NSLog(@"waiting for connection");
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
}

- (void)shutdown:(NSDictionary *)parameters {
    self.event = -1;

    self.timeout = FALSE;
    [self performSelector:@selector(ackTimeout:)
               withObject:parameters[@"timeout"]
               afterDelay:[parameters[@"timeout"] intValue]];

    [self.session close];

    while (self.event == -1 && !self.timeout) {
        //NSLog(@"waiting for disconnect");
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }

    XCTAssert(!self.timeout, @"timeout");
    [NSObject cancelPreviousPerformRequestsWithTarget:self];

    self.session.delegate = nil;
    self.session = nil;
}

@end
