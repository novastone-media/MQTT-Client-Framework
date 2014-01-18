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
@property (nonatomic) UInt16 sentMid;
@property (nonatomic) NSArray *qoss;
@property (nonatomic) BOOL timeout;
@property (nonatomic) int type;

@end

@implementation MQTTClientSubscriptionTests

#define HOST @"localhost"

- (void)setUp
{
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.
    
    self.session = [[MQTTSession alloc] initWithClientId:[NSString stringWithFormat:@"MQTTClient-%f", [NSDate timeIntervalSinceReferenceDate]]
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
    self.session.delegate = self;
    self.event = -1;
    [self.session connectToHost:HOST port:1883 usingSSL:NO];
    while (self.event == -1) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    self.timeout = FALSE;
    self.mid = 0;
    self.qoss = @[];
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

/*
 * Subscriptions
 */

- (void)testSubscribe_with_wrong_flags
{
    XCTFail(@"can't test [MQTT-3.8.1-1]");
}

- (void)testUnsubscribe_with_wrong_flags
{
    XCTFail(@"can't test [MQTT-3.10.1-1]");
}

- (void)testSubscribeWOTopic
{
    [self testMultiSubscribeCloseExpected:@{}];
}

- (void)testSubscribeWMultipleTopics_None
{
    [self testMultiSubscribeCloseExpected:@{}];
}

- (void)testSubscribeWMultipleTopics_One
{
    [self testMultiSubscribeSubackExpected:@{@"abc": @(2)}];
}

- (void)testSubscribeWMultipleTopics_more
{
    [self testMultiSubscribeSubackExpected:@{@"abc": @(0), @"#": @(0), @"mqttitude/#": @(1)}];
}

- (void)testSubscribeQoS0
{
    [self testSubscribeSubackExpected:@"mqttitude/#" atLevel:0];
}

- (void)testSubscribeQoS1
{
    [self testSubscribeSubackExpected:@"mqttitude/#" atLevel:1];
}

- (void)testSubscribeQoS2
{
    [self testSubscribeSubackExpected:@"mqttitude/#" atLevel:2];
}

- (void)testSubscribeQoS3
{
    [self testSubscribeCloseExpected:@"mqttitude/#" atLevel:3];
}

- (void)testSubscribeQoS4
{
    // [MQTT-3-8.3-2]
    [self testSubscribeCloseExpected:@"mqttitude/#" atLevel:4];
}

- (void)testSubscribeTopicPlain
{
    [self testSubscribeSubackExpected:@"abc" atLevel:0];
}

- (void)testSubscribeTopicHash {
    [self testSubscribeSubackExpected:@"#" atLevel:0];
}

- (void)testSubscribeTopicHashnotalone
{
    [self testSubscribeFailureExpected:@"#abc" atLevel:0];
}

- (void)testSubscribeTopicHashnotlast
{
    [self testSubscribeFailureExpected:@"abc/#/def" atLevel:0];
}

- (void)testSubscribeTopicPlus
{
    [self testSubscribeSubackExpected:@"+" atLevel:0];
}

- (void)testSubscribeTopicSlash
{
    [self testSubscribeSubackExpected:@"/" atLevel:0];
}

- (void)testSubscribeTopicPlusnotalone
{
    [self testSubscribeFailureExpected:@"abc+" atLevel:0];
}

- (void)testSubscribeTopicEmpty
{
    // [MQTT-4.7.3-1]
    [self testSubscribeCloseExpected:@"" atLevel:0];
}

- (void)testSubscribeTopicNone
{
    [self testSubscribeCloseExpected:nil atLevel:0];
}

- (void)testSubscribeTopic_0x00_in_topic
{
    // [MQTT-4.7.3-2]
    [self testSubscribeCloseExpected:@"a\0b" atLevel:0];
}


- (void)testSubscribeLong
{
    // [MQTT-4.7.3-3]
    
    NSString *topic = @"aa";
    for (UInt32 i = 2; i <= 32768; i *= 2) {
        topic = [topic stringByAppendingString:topic];
    }
    NSLog(@"LongSubscribe (%d)", strlen([[topic substringFromIndex:1] UTF8String]));
    [self testSubscribeSubackExpected:[topic substringFromIndex:1] atLevel:0];
}


- (void)testSubscribeSameTopicDifferentQoSa
{
    // [MQTT-3.8.4-3]
    [self testSubscribeSubackExpected:@"mqttitude/#" atLevel:0];
}
- (void)testSubscribeSameTopicDifferentQoSb
{
    // [MQTT-3.8.4-3]
    [self testSubscribeSubackExpected:@"mqttitude/#" atLevel:1];
}
- (void)testSubscribeSameTopicDifferentQoSc
{
    // [MQTT-3.8.4-3]
    [self testSubscribeSubackExpected:@"mqttitude/#" atLevel:2];
}
- (void)testSubscribeSameTopicDifferentQoSd
{
    // [MQTT-3.8.4-3]
    [self testSubscribeSubackExpected:@"mqttitude/#" atLevel:1];
}
- (void)testSubscribeSameTopicDifferentQoSe
{
    // [MQTT-3.8.4-3]
    [self testSubscribeSubackExpected:@"mqttitude/#" atLevel:0];
}


/*
 * Unsubscribe tests
 */
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

- (void)testMultiUnsubscribe_None
{
    [self testMultiUnsubscribeTopic:@[]];
}

- (void)testMultiUnsubscribe_One
{
    [self testMultiUnsubscribeTopic:@[@"abc"]];
}

- (void)testMultiUnsubscribe_more
{
    [self testMultiUnsubscribeTopic:@[@"abc", @"ab/+/ef", @"+", @"#", @"abc/d+f", @"#/b/c"]];
}

/*
 * helpers
 */

- (void)testSubscribeSubackExpected:(NSString *)topic atLevel:(UInt8)qos
{
    [self testSubscribe:topic atLevel:qos];
    XCTAssertFalse(self.timeout, @"No SUBACK received within %d seconds [MQTT-3.8.4-1]", 10);
    XCTAssert(self.event == -1, @"Event %d happened", self.event);
    XCTAssertEqual(self.mid, self.sentMid, @"msgID(%d) in SUBACK does not match msgID(%d) in SUBSCRIBE [MQTT-3.8.4-2]", self.mid, self.sentMid);
    for (NSNumber *qos in self.qoss) {
        XCTAssertNotEqual([qos intValue], 0x80, @"Returncode in SUBACK is 0x80");
        XCTAssert([qos intValue] == 0x00 || [qos intValue] == 0x01 || [qos intValue] == 0x02, @"Returncode in SUBACK invavalid [MQTT-3.9.3-2]");
    }
}

- (void)testMultiSubscribeSubackExpected:(NSDictionary *)topics
{
    [self testMultiSubscribe:topics];
    XCTAssertFalse(self.timeout, @"No SUBACK received within %d seconds [MQTT-3.8.4-1]", 10);
    XCTAssert(self.event == -1, @"Event %d happened", self.event);
    XCTAssertEqual(self.mid, self.sentMid, @"msgID(%d) in SUBACK does not match msgID(%d) in SUBSCRIBE [MQTT-3.8.4-2]", self.mid, self.sentMid);
    for (NSNumber *qos in self.qoss) {
        XCTAssertNotEqual([qos intValue], 0x80, @"Returncode in SUBACK is 0x80");
        XCTAssert([qos intValue] == 0x00 || [qos intValue] == 0x01 || [qos intValue] == 0x02, @"Returncode in SUBACK invavalid [MQTT-3.9.3-2]");
    }
}

- (void)testSubscribeCloseExpected:(NSString *)topic atLevel:(UInt8)qos
{
    [self testSubscribe:topic atLevel:qos];
    XCTAssertFalse(self.timeout, @"No close within %d seconds", 10);
    XCTAssert(self.mid == 0, @"SUBACK received");
    XCTAssert(self.event == MQTTSessionEventConnectionClosed, @"Event %d happened", self.event);
}

- (void)testMultiSubscribeCloseExpected:(NSDictionary *)topics
{
    [self testMultiSubscribe:topics];
    XCTAssertFalse(self.timeout, @"No close within %d seconds", 10);
    XCTAssert(self.mid == 0, @"SUBACK received");
    XCTAssert(self.event == MQTTSessionEventConnectionClosed, @"Event %d happened", self.event);
}

- (void)testSubscribeFailureExpected:(NSString *)topic atLevel:(UInt8)qos
{
    [self testSubscribe:topic atLevel:qos];
    XCTAssertFalse(self.timeout, @"No SUBACK received within %d seconds [MQTT-3.8.4-1]", 10);
    XCTAssert(self.event == -1, @"Event %d happened", self.event);
    XCTAssertEqual(self.mid, self.sentMid, @"msgID(%d) in SUBACK does not match msgID(%d) in SUBSCRIBE [MQTT-3.8.4-2]", self.mid, self.sentMid);
    for (NSNumber *qos in self.qoss) {
        XCTAssertEqual([qos intValue], 0x80, @"Returncode in SUBACK is not 0x80");
    }
}

- (void)testSubscribe:(NSString *)topic atLevel:(UInt8)qos
{
    self.sentMid = [self.session subscribeToTopic:topic atLevel:qos];
    [self performSelector:@selector(ackTimeout:) withObject:@(10) afterDelay:10];
    while (self.mid == 0 && !self.timeout && self.event == -1) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
}

- (void)testMultiSubscribe:(NSDictionary *)topics
{
    self.sentMid = [self.session subscribeToTopics:topics];
    [self performSelector:@selector(ackTimeout:) withObject:@(10) afterDelay:10];
    while (self.mid == 0 && !self.timeout && self.event == -1) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
}

- (void)testUnsubscribeTopic:(NSString *)topic
{
    self.sentMid = [self.session unsubscribeTopic:topic];
    [self performSelector:@selector(ackTimeout:) withObject:@(10) afterDelay:10];
    while (self.mid == 0 && !self.timeout && self.event == -1) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    XCTAssertFalse(self.timeout, @"No UNSUBACK received [MQTT-3.10.3-5] within %d seconds", 10);
    XCTAssertEqual(self.mid, self.sentMid, @"msgID(%d) in UNSUBACK does not match msgID(%d) in UNSUBSCRIBE [MQTT-3.10.3-4]", self.mid, self.sentMid);
}

- (void)testMultiUnsubscribeTopic:(NSArray *)topics
{
    self.sentMid = [self.session unsubscribeTopics:topics];
    [self performSelector:@selector(ackTimeout:) withObject:@(10) afterDelay:10];
    while (self.mid == 0 && !self.timeout && self.event == -1) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    XCTAssertFalse(self.timeout, @"No UNSUBACK received [MQTT-3.10.3-5] within %d seconds", 10);
    XCTAssertEqual(self.mid, self.sentMid, @"msgID(%d) in UNSUBACK does not match msgID(%d) in UNSUBSCRIBE [MQTT-3.10.3-4]", self.mid, self.sentMid);
}

- (void)ackTimeout:(NSTimeInterval)timeout
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

- (void)subAckReceived:(MQTTSession *)session msgID:(UInt16)msgID grantedQoss:(NSArray *)qoss
{
    NSLog(@"subAckReceived:%d grantedQoss:%@", msgID, qoss);
    self.mid = msgID;
    self.qoss = qoss;
}

- (void)unsubAckReceived:(MQTTSession *)session msgID:(UInt16)msgID
{
    NSLog(@"unsubAckReceived:%d", msgID);
    self.mid = msgID;
}

- (void)received:(int)type qos:(int)qos retained:(BOOL)retained duped:(BOOL)duped mid:(UInt16)mid data:(NSData *)data
{
    NSLog(@"received:%d qos:%d retained:%d duped:%d mid:%d data:%@", type, qos, retained, duped, mid, data);
    
    self.type = type;
}



@end
