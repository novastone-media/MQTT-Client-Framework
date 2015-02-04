//
//  MQTTClientTests.m
//  MQTTClientTests
//
//  Created by Christoph Krey on 13.01.14.
//  Copyright (c) 2014 Christoph Krey. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MQTTClient.h"
#import "MQTTClientTests.h"

@interface MQTTClientTests : XCTestCase <MQTTSessionDelegate>
@property (strong, nonatomic) MQTTSession *session;
@property (nonatomic) int event;
@property (strong, nonatomic) NSError *error;
@property (nonatomic) BOOL timeout;
@property (nonatomic) int type;
@property (nonatomic) BOOL ungraceful;
@end

@implementation MQTTClientTests

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
}

- (void)test_init {
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        self.session = [[MQTTSession alloc] init];
        [self connect:self.session parameters:parameters];
        XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
        [self shutdown:parameters];
    }
}

- (void)test_init_short_clientId {
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        self.session = [[MQTTSession alloc] initWithClientId:@""
                                                    userName:nil
                                                    password:nil
                                                   keepAlive:60
                                                cleanSession:YES
                                                        will:NO
                                                   willTopic:nil
                                                     willMsg:nil
                                                     willQoS:0
                                              willRetainFlag:NO
                                               protocolLevel:4
                                                     runLoop:[NSRunLoop currentRunLoop]
                                                     forMode:NSRunLoopCommonModes];
        [self connect:self.session parameters:parameters];
        XCTAssert(!self.timeout, @"timeout");
        XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
        [self shutdown:parameters];
    }
}

- (void)test_init_long_clientId {
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        self.session = [[MQTTSession alloc] initWithClientId:@"123456789.123456789.1234"
                                                    userName:nil
                                                    password:nil
                                                   keepAlive:60
                                                cleanSession:YES
                                                        will:NO
                                                   willTopic:nil
                                                     willMsg:nil
                                                     willQoS:0
                                              willRetainFlag:NO
                                               protocolLevel:4
                                                     runLoop:[NSRunLoop currentRunLoop]
                                                     forMode:NSRunLoopCommonModes];
        [self connect:self.session parameters:parameters];
        XCTAssert(!self.timeout, @"timeout");
        XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
        [self shutdown:parameters];
    }
}

- (void)test_init_no_clientId {
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
                                               protocolLevel:4
                                                     runLoop:[NSRunLoop currentRunLoop]
                                                     forMode:NSRunLoopCommonModes];
        [self connect:self.session parameters:parameters];
        XCTAssert(!self.timeout, @"timeout");
        XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
        [self shutdown:parameters];
    }
}

- (void)test_connect_1883 {
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
                                               protocolLevel:4
                                                     runLoop:[NSRunLoop currentRunLoop]
                                                     forMode:NSRunLoopCommonModes];
        [self connect:self.session parameters:parameters];
        XCTAssert(!self.timeout, @"timeout");
        XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
        [self shutdown:parameters];
    }
}

- (void)test_connect_will {
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        self.session = [[MQTTSession alloc] initWithClientId:nil
                                                    userName:nil
                                                    password:nil
                                                   keepAlive:10
                                                cleanSession:YES
                                                        will:YES
                                                   willTopic:@"MQTTClient/will-qos0"
                                                     willMsg:[@"will-qos0" dataUsingEncoding:NSUTF8StringEncoding]
                                                     willQoS:0
                                              willRetainFlag:NO
                                               protocolLevel:4
                                                     runLoop:[NSRunLoop currentRunLoop]
                                                     forMode:NSRunLoopCommonModes];
        [self connect:self.session parameters:parameters];
        XCTAssert(!self.timeout, @"timeout");
        XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);

        self.ungraceful = TRUE;
        [self shutdown:parameters];
    }
}

- (void)test_connect_other_protocollevel3__MQTT_3_1_2_1 {
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
                                               protocolLevel:3
                                                     runLoop:[NSRunLoop currentRunLoop]
                                                     forMode:NSRunLoopCommonModes];
        [self connect:self.session parameters:parameters];
        XCTAssert(!self.timeout, @"timeout");
        XCTAssertEqual(self.event, MQTTSessionEventConnected, @"No MQTTSessionEventConnected %@", self.error);

        [self shutdown:parameters];
    }
}

- (void)test_connect_illegal_protocollevel5_MQTT_3_1_2_2 {
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
                                               protocolLevel:5
                                                     runLoop:[NSRunLoop currentRunLoop]
                                                     forMode:NSRunLoopCommonModes];
        [self connect:self.session parameters:parameters];
        XCTAssert(!self.timeout, @"timeout");
        XCTAssertEqual(self.event, MQTTSessionEventConnectionRefused, @"MQTTSessionEventConnectionRefused %@", self.error);

        XCTAssert(self.error.code == 0x01, @"error = %@", self.error);
        [self shutdown:parameters];
    }
}

- (void)test_connect_illegal_protocollevel0_MQTT_3_1_2_1 {
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
                                               protocolLevel:0
                                                     runLoop:[NSRunLoop currentRunLoop]
                                                     forMode:NSRunLoopCommonModes];
        [self connect:self.session parameters:parameters];
        XCTAssert(!self.timeout, @"timeout");
        if (self.event == MQTTSessionEventConnectionClosedByBroker || (self.event == MQTTSessionEventConnectionRefused && self.error && self.error.code == 0x01)) {
            // Success, although week definition
        } else {
            XCTFail(@"connect returned event:%d, error:%@", self.event, self.error);
        }
        [self shutdown:parameters];
    }
}

- (void)test_ping {
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        self.session = [[MQTTSession alloc] initWithClientId:nil
                                                    userName:nil
                                                    password:nil
                                                   keepAlive:5
                                                cleanSession:YES
                                                        will:NO
                                                   willTopic:nil
                                                     willMsg:nil
                                                     willQoS:0
                                              willRetainFlag:NO
                                               protocolLevel:4
                                                     runLoop:[NSRunLoop currentRunLoop]
                                                     forMode:NSRunLoopCommonModes];
        [self connect:self.session parameters:parameters];
        XCTAssert(!self.timeout, @"timeout");
        XCTAssertEqual(self.event, MQTTSessionEventConnected, @"No MQTTSessionEventConnected %@", self.error);

        self.event = -1;
        self.type = 0xff;
        [self performSelector:@selector(ackTimeout:)
                   withObject:parameters[@"timeout"]
                   afterDelay:[parameters[@"timeout"] intValue]];

        while (!self.timeout && self.event == -1 && self.type == 0xff) {
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }
        XCTAssertEqual(self.type, MQTTPingresp, @"No PingResp received %u", self.type);
        XCTAssertNotEqual(self.event, MQTTSessionEventConnectionClosed, @"MQTTSessionEventConnectionClosed %@", self.error);
        XCTAssertNotEqual(self.event, MQTTSessionEventProtocolError, @"MQTTSessionEventProtocolError %@", self.error);
        XCTAssertNotEqual(self.event, MQTTSessionEventConnectionClosedByBroker, @"MQTTSessionEventConnectionClosedByBroker %@", self.error);
        XCTAssert(!self.timeout, @"Timeout 200%% keepalive");
        [self shutdown:parameters];
    }
}

- (void)test_no_cleansession_qos2 {
    [self no_cleansession:MQTTQosLevelExactlyOnce];
}

- (void)test_no_cleansession_qos1 {
    [self no_cleansession:MQTTQosLevelAtLeastOnce];
}

- (void)test_no_cleansession_qos0 {
    [self no_cleansession:MQTTQoSLevelAtMostOnce];
}

- (void)test_disconnect_wrong_flags_MQTT_3_14_1_1 {
    NSLog(@"can't test [MQTT-3.14.1-1]");
}

#pragma mark helpers

- (void)no_cleansession:(MQTTQosLevel)qos {
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];

        NSLog(@"Cleaning topic");
        MQTTSession *sendingSession = [[MQTTSession alloc] initWithClientId:@"MQTTClient-pub"
                                                                   userName:nil
                                                                   password:nil
                                                                  keepAlive:60
                                                               cleanSession:YES
                                                                       will:NO
                                                                  willTopic:nil
                                                                    willMsg:nil
                                                                    willQoS:0
                                                             willRetainFlag:NO
                                                              protocolLevel:4
                                                                    runLoop:[NSRunLoop currentRunLoop]
                                                                    forMode:NSRunLoopCommonModes];
        if (![sendingSession connectAndWaitToHost:parameters[@"host"] port:[parameters[@"port"] intValue] usingSSL:[parameters[@"tls"] boolValue]]) {
            XCTFail(@"no connection for pub to %@", broker);
        }
        [sendingSession publishAndWaitData:[[NSData alloc] init] onTopic:TOPIC retain:true qos:qos];

        NSLog(@"Subscribing to topic");
        self.session = [[MQTTSession alloc] initWithClientId:@"MQTTClient-sub"
                                                    userName:nil
                                                    password:nil
                                                   keepAlive:60
                                                cleanSession:NO
                                                        will:NO
                                                   willTopic:nil
                                                     willMsg:nil
                                                     willQoS:0
                                              willRetainFlag:NO
                                               protocolLevel:4
                                                     runLoop:[NSRunLoop currentRunLoop]
                                                     forMode:NSRunLoopCommonModes];
        [self connect:self.session parameters:parameters];
        [self.session subscribeAndWaitToTopic:TOPIC atLevel:qos];
        [self shutdown:parameters];

        for (int i = 1; i < BULK; i++) {
            NSLog(@"publishing to topic %d", i);
            NSString *payload = [NSString stringWithFormat:@"payload %d", i];
            [sendingSession publishAndWaitData:[payload dataUsingEncoding:NSUTF8StringEncoding] onTopic:TOPIC retain:false qos:qos];
        }
        [sendingSession closeAndWait];

        NSLog(@"receiving from topic");
        self.session = [[MQTTSession alloc] initWithClientId:@"MQTTClient-sub"
                                                    userName:nil
                                                    password:nil
                                                   keepAlive:60
                                                cleanSession:NO
                                                        will:NO
                                                   willTopic:nil
                                                     willMsg:nil
                                                     willQoS:0
                                              willRetainFlag:NO
                                               protocolLevel:4
                                                     runLoop:[NSRunLoop currentRunLoop]
                                                     forMode:NSRunLoopCommonModes];
        [self connect:self.session parameters:parameters];
        XCTAssertEqual(self.event, MQTTSessionEventConnected, @"No MQTTSessionEventConnected %@", self.error);

        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        self.timeout = FALSE;
        [self performSelector:@selector(ackTimeout:)
                   withObject:parameters[@"timeout"]
                   afterDelay:[parameters[@"timeout"] intValue]];

        while (!self.timeout) {
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }

        [self shutdown:parameters];
    }
}

- (void)received:(MQTTSession *)session type:(int)type qos:(MQTTQosLevel)qos retained:(BOOL)retained duped:(BOOL)duped mid:(UInt16)mid data:(NSData *)data {
    //NSLog(@"received:%d qos:%d retained:%d duped:%d mid:%d data:%@", type, qos, retained, duped, mid, data);
    self.type = type;
}

- (void)newMessage:(MQTTSession *)session data:(NSData *)data onTopic:(NSString *)topic qos:(MQTTQosLevel)qos retained:(BOOL)retained mid:(unsigned int)mid {
    NSLog(@"newMessage:%@ onTopic:%@ qos:%d retained:%d mid:%d", data, topic, qos, retained, mid);
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

    /* NSLog(@"connecting to:%@ port:%d tls:%d",
          parameters[@"host"],
          [parameters[@"port"] intValue],
          [parameters[@"tls"] boolValue],
          self.);
     */
    
    [session connectToHost:parameters[@"host"]
                      port:[parameters[@"port"] intValue]
                  usingSSL:[parameters[@"tls"] boolValue]];

    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    self.timeout = FALSE;
    [self performSelector:@selector(ackTimeout:)
               withObject:parameters[@"timeout"]
               afterDelay:[parameters[@"timeout"] intValue]];
     

    while (!self.timeout && self.event == -1) {
        //NSLog(@"waiting for connection");
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
}

- (void)shutdown:(NSDictionary *)parameters {
    if (!self.ungraceful) {
        self.event = -1;

        [NSObject cancelPreviousPerformRequestsWithTarget:self];
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
}

@end
