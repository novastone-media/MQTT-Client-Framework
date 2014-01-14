//
//  MQTTClientSubscriptionTests.m
//  MQTTClient
//
//  Created by Christoph Krey on 14.01.14.
//  Copyright (c) 2014 Christoph Krey. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MQTTClient.h"

@interface MQTTClientSubscriptionTests : XCTestCase <MQTTSessionDelegate>
@property (strong, nonatomic) MQTTSession *session;
@property (nonatomic) MQTTSessionEvent event;
@property (nonatomic) UInt16 mid;
@property (nonatomic) UInt8 qos;
@property (nonatomic) BOOL timeout;
@property (nonatomic) BOOL closed;
@end

@implementation MQTTClientSubscriptionTests

- (void)setUp
{
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.
    
    self.session = [[MQTTSession alloc] initWithClientId:@"__FUNCTION__" userName:nil password:nil keepAlive:60 cleanSession:YES will:NO willTopic:nil willMsg:nil willQoS:0 willRetainFlag:NO protocolLevel:3 runLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    self.session.delegate = self;
    self.event = -1;
    [self.session connectToHost:@"test.mosquitto.org" port:1883 usingSSL:NO];
    while (self.event == -1) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    self.timeout = FALSE;
    self.mid = 0;
    self.qos = 0;
    self.event = -1;
}

- (void)tearDown
{
    [self.session close];
    self.session.delegate = nil;
    self.session = nil;

    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

- (void)testSubscribeQoS0
{
    [self testSubscribeQoS:0];
}

- (void)testSubscribeQoS1
{
    [self testSubscribeQoS:1];
}

- (void)testSubscribeQoS2
{
    [self testSubscribeQoS:2];
}

- (void)testSubscribeQoS3
{
    [self testSubscribeQoS:4];
}

- (void)testSubscribeQoS4
{
    [self testSubscribeQoS:4];
}

- (void)testSubscribeQoS:(UInt8)qos
{
    UInt16 mid = [self.session subscribeToTopic:@"mqttitude/#" atLevel:qos];
    [self performSelector:@selector(subackTimeout:) withObject:@(10) afterDelay:10];
    while (self.mid == 0 && !self.timeout && self.event == -1) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    XCTAssertFalse(self.timeout, @"No SUBACK received within %d seconds", 10);
    XCTAssertEqual(self.mid, mid, @"msgID(%d) in SUBACK does not match msgID(%d) in SUBSCRIBE [MQTT-3.9.3-1]", self.mid, mid);
    XCTAssertNotEqual(self.qos, 0x80, @"Returncode in SUBACK is 0x80");
    XCTAssert(self.qos == 0x00 || self.qos == 0x01 || self.qos == 0x02, @"Returncode in SUBACK invavalid [MQTT-3.9.3-2]");
}

- (void)testSubscribeTopicPlain
{
    [self testSubscribeTopic:@"abc"];
}

- (void)testSubscribeTopicHash {
    [self testSubscribeTopic:@"#"];
}

- (void)testSubscribeTopicHashnotalone
{
    [self testSubscribeTopic:@"#abc"];
}

- (void)testSubscribeTopicPlus
{
    [self testSubscribeTopic:@"+"];
}

- (void)testSubscribeTopicEmpty
{
    [self testSubscribeTopic:@""];
}

- (void)testSubscribeTopicNone
{
    [self testSubscribeTopic:nil];
}

- (void)testSubscribeTopicZero
{
    [self testSubscribeTopic:@"a\0b"];
}

- (void)testSubscribeTopic:(NSString *)topic
{
    UInt16 mid = [self.session subscribeToTopic:topic atLevel:0];
    [self performSelector:@selector(subackTimeout:) withObject:@(10) afterDelay:10];
    while (self.mid == 0 && !self.timeout && self.event == -1) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    XCTAssertFalse(self.timeout, @"No SUBACK received within %d seconds", 10);
    XCTAssertEqual(self.mid, mid, @"msgID(%d) in SUBACK does not match msgID(%d) in SUBSCRIBE [MQTT-3.9.3-1]", self.mid, mid);
    XCTAssertNotEqual(self.qos, 0x80, @"Returncode in SUBACK is 0x80");
    XCTAssert(self.qos == 0x00 || self.qos == 0x01 || self.qos == 0x02, @"Returncode in SUBACK invavalid [MQTT-3.9.3-2]");
}

- (void)subackTimeout:(NSNumber *)timeout
{
    self.timeout = TRUE;
}

- (void)testUnsubscribeTopicPlain
{
    [self testUnsubscribeTopic:@"abc"];
}

- (void)testUnubscribeTopicHash {
    [self testUnsubscribeTopic:@"#"];
}

- (void)testUnsubscribeTopicHashnotalone
{
    [self testUnsubscribeTopic:@"#abc"];
}

- (void)testUnsubscribeTopicPlus
{
    [self testUnsubscribeTopic:@"+"];
}

- (void)testUnsubscribeTopicEmpty
{
    [self testUnsubscribeTopic:@""];
}

- (void)testUnsubscribeTopicNone
{
    [self testUnsubscribeTopic:nil];
}

- (void)testUnsubscribeTopicZero
{
    [self testUnsubscribeTopic:@"a\0b"];
}

- (void)testUnsubscribeTopic:(NSString *)topic
{
    UInt16 mid = [self.session unsubscribeTopic:topic];
    [self performSelector:@selector(unsubackTimeout:) withObject:@(10) afterDelay:10];
    while (self.mid == 0 && !self.timeout && self.event == -1) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    XCTAssertFalse(self.timeout, @"No UNSUBACK received [MQTT-3.10.3-5] within %d seconds", 10);
    XCTAssertEqual(self.mid, mid, @"msgID(%d) in UNSUBACK does not match msgID(%d) in UNSUBSCRIBE [MQTT-3.10.3-4]", self.mid, mid);
}

- (void)unsubackTimeout:(NSTimeInterval)timeout
{
    self.timeout = TRUE;
}

- (void)newMessage:(MQTTSession *)session data:(NSData *)data onTopic:(NSString *)topic qos:(int)qos retained:(BOOL)retained mid:(unsigned int)mid
{
    NSLog(@"newMessage:%@ onTopic:%@ qos:%d retained:%d mid:%d", data, topic, qos, retained, mid);
}

- (void)handleEvent:(MQTTSession *)session event:(MQTTSessionEvent)eventCode error:(NSError *)error
{
    NSLog(@"handleEvent:%d error:%@", eventCode, error);
    self.event = eventCode;
}

- (void)subAckReceived:(MQTTSession *)session msgID:(UInt16)msgID grantedQos:(int)qos
{
    NSLog(@"subAckReceived:%d grantedQos:%d", msgID, qos);
    self.mid = msgID;
    self.qos = qos;
}

- (void)unsubAckReceived:(MQTTSession *)session msgID:(UInt16)msgID
{
    NSLog(@"unsubAckReceived:%d", msgID);
    self.mid = msgID;
}



@end
