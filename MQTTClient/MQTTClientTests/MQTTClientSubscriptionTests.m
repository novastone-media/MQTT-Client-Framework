//
//  MQTTClientSubscriptionTests.m
//  MQTTClient
//
//  Created by Christoph Krey on 14.01.14.
//  Copyright (c) 2014 Christoph Krey. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MQTTClient.h"
#import "MQTTClientTests.h"

@interface MQTTClientSubscriptionTests : XCTestCase <MQTTSessionDelegate>
@property (strong, nonatomic) MQTTSession *session;
@property (nonatomic) int event;
@property (nonatomic) UInt16 mid;
@property (nonatomic) UInt16 sentMid;
@property (nonatomic) NSArray *qoss;
@property (nonatomic) BOOL timeout;
@property (nonatomic) NSTimeInterval timeoutValue;
@property (nonatomic) int type;

@end

@implementation MQTTClientSubscriptionTests

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testSubscribe_with_wrong_flags_MQTT_3_8_1_1
{
    NSLog(@"can't test [MQTT-3.8.1-1]");
}

- (void)testUnsubscribe_with_wrong_flags_MQTT_3_10_1_1
{
    NSLog(@"can't test [MQTT-3.10.1-1]");
}

- (void)testSubscribeWMultipleTopics_None
{
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        [self connect:parameters];
        [self testMultiSubscribeCloseExpected:@{}];
        [self shutdown:parameters];
    }
}

- (void)testSubscribeWMultipleTopics_One
{
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        [self connect:parameters];
        [self testMultiSubscribeSubackExpected:@{@"MQTTClient": @(2)}];
        [self shutdown:parameters];
    }
}

- (void)testSubscribeWMultipleTopics_more
{
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        [self connect:parameters];
        [self testMultiSubscribeSubackExpected:@{@"MQTTClient": @(0), @"MQTTClient/abc": @(0), @"MQTTClient/#": @(1)}];
        [self shutdown:parameters];
    }
}

- (void)testSubscribeWMultipleTopics_a_lot
{
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        [self connect:parameters];
#define TOPICS 256
        NSMutableDictionary *topics = [[NSMutableDictionary alloc] initWithCapacity:TOPICS];
        for (int i = 0; i < TOPICS; i++) {
            [topics setObject:@(1) forKey:[NSString stringWithFormat:@"MQTTClient/a/lot/%d", i]];
        }

        [self testMultiSubscribeSubackExpected:topics];
        [self shutdown:parameters];
    }
}

- (void)testSubscribeQoS0
{
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        [self connect:parameters];
        [self testSubscribeSubackExpected:@"MQTTClient/#" atLevel:0];
        [self shutdown:parameters];
    }
}

- (void)testSubscribeQoS1
{
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        [self connect:parameters];
        [self testSubscribeSubackExpected:@"MQTTClient/#" atLevel:1];
        [self shutdown:parameters];
    }
}

- (void)testSubscribeQoS2
{
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        [self connect:parameters];
        [self testSubscribeSubackExpected:@"MQTTClient/#" atLevel:2];
        [self shutdown:parameters];
    }
}

- (void)testSubscribeTopicPlain
{
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        [self connect:parameters];
        [self testSubscribeSubackExpected:@"MQTTClient" atLevel:0];
        [self shutdown:parameters];
    }
}

- (void)testSubscribeTopicHash {
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        [self connect:parameters];
        [self testSubscribeSubackExpected:@"#" atLevel:0];
        [self shutdown:parameters];
    }
}

- (void)testSubscribeTopicHashnotalone
{
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        [self connect:parameters];
        [self testSubscribeCloseExpected:@"#MQTTClient" atLevel:0];
        [self shutdown:parameters];
    }
}

- (void)testSubscribeTopicEmpty
{
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        [self connect:parameters];
        [self testSubscribeCloseExpected:@"" atLevel:0];
        [self shutdown:parameters];
    }
}

- (void)testSubscribeTopicHashnotlast
{
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        [self connect:parameters];
        [self testSubscribeCloseExpected:@"MQTTClient/#/def" atLevel:0];
        [self shutdown:parameters];
    }
}

- (void)testSubscribeTopicPlus
{
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        [self connect:parameters];
        [self testSubscribeSubackExpected:@"+" atLevel:0];
        [self shutdown:parameters];
    }
}

- (void)testSubscribeTopicSlash
{
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        [self connect:parameters];
        [self testSubscribeSubackExpected:@"/" atLevel:0];
        [self shutdown:parameters];
    }
}

- (void)testSubscribeTopicPlusnotalone_MQTT_4_7_1_3
{
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        [self connect:parameters];
        [self testSubscribeCloseExpected:@"MQTTClient+" atLevel:0];
        [self shutdown:parameters];
    }
}

- (void)testSubscribeTopicEmpty_MQTT_4_7_3_1
{
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        [self connect:parameters];
        [self testSubscribeCloseExpected:@"" atLevel:0];
        [self shutdown:parameters];
    }
}

- (void)testSubscribeTopicNone
{
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        [self connect:parameters];
        [self testSubscribeCloseExpected:nil atLevel:0];
        [self shutdown:parameters];
    }
}

- (void)testSubscribeTopic_0x00_in_topic
{
    NSLog(@"can't test [MQTT-4.7.3-2]");
}


- (void)testSubscribeLong_MQTT_4_7_3_3
{
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        [self connect:parameters];
        NSString *topic = @"aa";
        for (UInt32 i = 2; i <= 32768; i *= 2) {
            topic = [topic stringByAppendingString:topic];
        }
        NSLog(@"LongSubscribe (%lu)", strlen([[topic substringFromIndex:1] UTF8String]));
        [self testSubscribeSubackExpected:[topic substringFromIndex:1] atLevel:0];
        [self shutdown:parameters];
    }
}


- (void)testSubscribeSameTopicDifferentQoS_MQTT_3_8_4_3
{
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        [self connect:parameters];
        [self testSubscribeSubackExpected:TOPIC atLevel:0];
        [self testSubscribeSubackExpected:TOPIC atLevel:1];
        [self testSubscribeSubackExpected:TOPIC atLevel:2];
        [self testSubscribeSubackExpected:TOPIC atLevel:1];
        [self testSubscribeSubackExpected:TOPIC atLevel:0];
        [self shutdown:parameters];
    }
}

/*
 * [MQTT-3.3.5-1]
 * The Server MUST deliver the message to the Client respecting the maximum QoS of all the matching subscriptions.
 */
- (void)test_delivery_max_QoS_MQTT_3_3_5_1
{
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        [self connect:parameters];
        [self testSubscribeSubackExpected:[NSString stringWithFormat:@"%@/#", TOPIC] atLevel:MQTTQoSLevelAtMostOnce];
        [self testSubscribeSubackExpected:[NSString stringWithFormat:@"%@/2", TOPIC] atLevel:MQTTQosLevelExactlyOnce];
        [self.session publishAndWaitData:[@"Should be delivered with qos 1" dataUsingEncoding:NSUTF8StringEncoding]
                                 onTopic:[NSString stringWithFormat:@"%@/2", TOPIC]
                                  retain:NO
                                     qos:MQTTQosLevelAtLeastOnce];
        [self shutdown:parameters];
    }
}

/*
 * [MQTT-3.10.4-1]
 * The Topic Filters (whether they contain wildcards or not) supplied in an UNSUBSCRIBE
 * packet MUST be compared character-by-character with the current set of Topic Filters
 * held by the Server for the Client. If any filter matches exactly then its owning Subscription
 * is deleted, otherwise no additional processing occurs.
 */
- (void)test_unsubscribe_byte_by_byte_MQTT_3_10_4_1
{
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        [self connect:parameters];
        [self testSubscribeSubackExpected:TOPIC atLevel:MQTTQoSLevelAtMostOnce];
        [self testUnsubscribeTopic:TOPIC];
        [self shutdown:parameters];
    }
}

/*
 * [MQTT-3.10.4-2]
 * If a Server deletes a Subscription It MUST stop adding any new messages for delivery to the Client.
 */
- (void)test_stop_delivering_after_unsubscribe_MQTT_3_10_4_2
{
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        [self connect:parameters];
        [self testSubscribeSubackExpected:TOPIC atLevel:MQTTQoSLevelAtMostOnce];
        [self.session publishAndWaitData:[@"Should be delivered" dataUsingEncoding:NSUTF8StringEncoding]
                                 onTopic:TOPIC
                                  retain:NO
                                     qos:MQTTQosLevelAtLeastOnce];
        [self testUnsubscribeTopic:TOPIC];
        [self.session publishAndWaitData:[@"Should not be delivered" dataUsingEncoding:NSUTF8StringEncoding]
                                 onTopic:TOPIC
                                  retain:NO
                                     qos:MQTTQosLevelAtLeastOnce];
        [self shutdown:parameters];
    }
}

/*
 * [MQTT-3.10.4-3]
 * If a Server deletes a Subscription It MUST complete the delivery of any QoS 1 or
 * QoS 2 messages which it has started to send to the Client.
 */
- (void)test_complete_delivering_qos12_after_unsubscribe_MQTT_3_10_4_3
{
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        [self connect:parameters];
        [self testSubscribeSubackExpected:TOPIC atLevel:MQTTQosLevelExactlyOnce];
        [self.session publishAndWaitData:[@"Should be delivered" dataUsingEncoding:NSUTF8StringEncoding]
                                 onTopic:TOPIC
                                  retain:NO
                                     qos:MQTTQosLevelAtLeastOnce];
        [self testUnsubscribeTopic:TOPIC];
        [self.session publishAndWaitData:[@"Should not be delivered" dataUsingEncoding:NSUTF8StringEncoding]
                                 onTopic:TOPIC
                                  retain:NO
                                     qos:MQTTQosLevelAtLeastOnce];
        [self shutdown:parameters];
    }
}


- (void)testUnsubscribeTopicPlain
{
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        [self connect:parameters];
        [self testUnsubscribeTopic:@"abc"];
        [self shutdown:parameters];
    }
}

- (void)testUnubscribeTopicHash {
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        [self connect:parameters];
        [self testUnsubscribeTopic:@"#"];
        [self shutdown:parameters];
    }
}

- (void)testUnsubscribeTopicHashnotalone
{
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        [self connect:parameters];
        [self testUnsubscribeTopicCloseExpected:@"#abc"];
        [self shutdown:parameters];
    }
}

- (void)testUnsubscribeTopicPlus
{
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        [self connect:parameters];
        [self testUnsubscribeTopic:@"+"];
        [self shutdown:parameters];
    }
}

- (void)testUnsubscribeTopicEmpty
{
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        [self connect:parameters];
        [self testUnsubscribeTopicCloseExpected:@""];
        [self shutdown:parameters];
    }
}

- (void)testUnsubscribeTopicNone
{
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        [self connect:parameters];
        [self testUnsubscribeTopic:nil];
        [self shutdown:parameters];
    }
}

- (void)testUnsubscribeTopicZero
{
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        [self connect:parameters];
        [self testUnsubscribeTopic:@"a\0b"];
        [self shutdown:parameters];
    }
}

- (void)testMultiUnsubscribe_None
{
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        [self connect:parameters];
        [self testMultiUnsubscribeTopic:@[]];
        [self shutdown:parameters];
    }
}

- (void)testMultiUnsubscribe_One
{
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        [self connect:parameters];
        [self testMultiUnsubscribeTopic:@[@"abc"]];
        [self shutdown:parameters];
    }
}

- (void)testMultiUnsubscribe_more
{
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        [self connect:parameters];
        [self testMultiUnsubscribeTopic:@[@"abc", @"ab/+/ef", @"+", @"#", @"abc/df", @"a/b/c/#"]];
        [self shutdown:parameters];
    }
}

/*
 * helpers
 */

- (void)testSubscribeSubackExpected:(NSString *)topic atLevel:(UInt8)qos
{
    [self testSubscribe:topic atLevel:qos];
    XCTAssertFalse(self.timeout, @"No SUBACK received within %d seconds [MQTT-3.8.4-1]", 10);
    XCTAssert(self.event == -1, @"Event %ld happened", (long)self.event);
    XCTAssertEqual(self.mid, self.sentMid, @"msgID(%d) in SUBACK does not match msgID(%d) in SUBSCRIBE [MQTT-3.8.4-2]", self.mid, self.sentMid);
    for (NSNumber *qos in self.qoss) {
        XCTAssertNotEqual([qos intValue], 0x80, @"Returncode in SUBACK is 0x80");
        XCTAssert([qos intValue] == 0x00 || [qos intValue] == 0x01 || [qos intValue] == 0x02, @"Returncode in SUBACK invalid [MQTT-3.9.3-2]");
    }
}

- (void)testMultiSubscribeSubackExpected:(NSDictionary *)topics
{
    [self testMultiSubscribe:topics];
    XCTAssertFalse(self.timeout, @"No SUBACK received within %d seconds [MQTT-3.8.4-1]", 10);
    XCTAssert(self.event == -1, @"Event %ld happened", (long)self.event);
    XCTAssertEqual(self.mid, self.sentMid, @"msgID(%d) in SUBACK does not match msgID(%d) in SUBSCRIBE [MQTT-3.8.4-2]", self.mid, self.sentMid);
    for (NSNumber *qos in self.qoss) {
        XCTAssert([qos intValue] == 0x00 || [qos intValue] == 0x01 || [qos intValue] == 0x02, @"Returncode %d in SUBACK invalid [MQTT-3.9.3-2]", [qos intValue]);
    }
}

- (void)testSubscribeCloseExpected:(NSString *)topic atLevel:(UInt8)qos
{
    [self testSubscribe:topic atLevel:qos];
    XCTAssertFalse(self.timeout, @"No close within %d seconds", 10);
    XCTAssert(self.event == MQTTSessionEventConnectionClosedByBroker, @"Event %ld happened", (long)self.event);
}

- (void)testMultiSubscribeCloseExpected:(NSDictionary *)topics
{
    [self testMultiSubscribe:topics];
    XCTAssertFalse(self.timeout, @"No close within %d seconds", 10);
    XCTAssert(self.mid == 0, @"SUBACK received");
    XCTAssert(self.event == MQTTSessionEventConnectionClosedByBroker, @"Event %ld happened", (long)self.event);
}

- (void)testSubscribeFailureExpected:(NSString *)topic atLevel:(UInt8)qos
{
    [self testSubscribe:topic atLevel:qos];
    XCTAssertFalse(self.timeout, @"No SUBACK received within %d seconds [MQTT-3.8.4-1]", 10);
    XCTAssert(self.event == -1, @"Event %ld happened", (long)self.event);
    XCTAssertEqual(self.mid, self.sentMid, @"msgID(%d) in SUBACK does not match msgID(%d) in SUBSCRIBE [MQTT-3.8.4-2]", self.mid, self.sentMid);
    for (NSNumber *qos in self.qoss) {
        XCTAssertEqual([qos intValue], 0x80, @"Returncode in SUBACK is not 0x80");
    }
}

- (void)testSubscribe:(NSString *)topic atLevel:(UInt8)qos
{
    self.mid = 0;
    self.sentMid = [self.session subscribeToTopic:topic atLevel:qos];
    [self performSelector:@selector(ackTimeout:)
               withObject:nil
               afterDelay:self.timeoutValue];

    while (self.mid == 0 && !self.timeout && self.event == -1) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
}

- (void)testMultiSubscribe:(NSDictionary *)topics
{
    self.mid = 0;
    self.sentMid = [self.session subscribeToTopics:topics];
    [self performSelector:@selector(ackTimeout:)
               withObject:nil
               afterDelay:self.timeoutValue];

    while (self.mid == 0 && !self.timeout && self.event == -1) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
}

- (void)testUnsubscribeTopic:(NSString *)topic
{
    self.mid = 0;
    self.sentMid = [self.session unsubscribeTopic:topic];
    [self performSelector:@selector(ackTimeout:)
               withObject:nil
               afterDelay:self.timeoutValue];

    while (self.mid == 0 && !self.timeout && self.event == -1) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    XCTAssertFalse(self.timeout, @"No UNSUBACK received [MQTT-3.10.3-5] within %d seconds", 10);
    XCTAssertEqual(self.mid, self.sentMid, @"msgID(%d) in UNSUBACK does not match msgID(%d) in UNSUBSCRIBE [MQTT-3.10.3-4]", self.mid, self.sentMid);
}

- (void)testUnsubscribeTopicCloseExpected:(NSString *)topic
{
    self.mid = 0;
    self.sentMid = [self.session unsubscribeTopic:topic];
    [self performSelector:@selector(ackTimeout:)
               withObject:nil
               afterDelay:self.timeoutValue];

    while (self.mid == 0 && !self.timeout && self.event == -1) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    XCTAssertFalse(self.timeout, @"No close within %d seconds", 10);
    XCTAssert(self.event == MQTTSessionEventConnectionClosedByBroker, @"Event %ld happened", (long)self.event);
}

- (void)testMultiUnsubscribeTopic:(NSArray *)topics
{
    self.mid = 0;
    self.sentMid = [self.session unsubscribeTopics:topics];
    [self performSelector:@selector(ackTimeout:)
               withObject:nil
               afterDelay:self.timeoutValue];

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

- (void)newMessage:(MQTTSession *)session data:(NSData *)data onTopic:(NSString *)topic qos:(MQTTQosLevel)qos retained:(BOOL)retained mid:(unsigned int)mid
{
    //NSLog(@"newMessage:%@ onTopic:%@ qos:%d retained:%d mid:%d", data, topic, qos, retained, mid);
}

- (void)handleEvent:(MQTTSession *)session event:(MQTTSessionEvent)eventCode error:(NSError *)error
{
    //NSLog(@"handleEvent:%ld error:%@", (long)eventCode, error);
    self.event = eventCode;
}

- (void)subAckReceived:(MQTTSession *)session msgID:(UInt16)msgID grantedQoss:(NSArray *)qoss
{
    //NSLog(@"subAckReceived:%d grantedQoss:%@", msgID, qoss);
    self.mid = msgID;
    self.qoss = qoss;
}

- (void)unsubAckReceived:(MQTTSession *)session msgID:(UInt16)msgID
{
    //NSLog(@"unsubAckReceived:%d", msgID);
    self.mid = msgID;
}

- (void)received:(int)type qos:(int)qos retained:(BOOL)retained duped:(BOOL)duped mid:(UInt16)mid data:(NSData *)data
{
    //NSLog(@"received:%d qos:%d retained:%d duped:%d mid:%d data:%@", type, qos, retained, duped, mid, data);

    self.type = type;
}

- (void)connect:(NSDictionary *)parameters {
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
                                                 forMode:NSRunLoopCommonModes];
    self.session.delegate = self;
    self.event = -1;

    self.timeout = FALSE;
    self.timeoutValue = [parameters[@"timeout"] doubleValue];
    [self performSelector:@selector(ackTimeout:)
               withObject:nil
               afterDelay:self.timeoutValue];

    [self.session connectToHost:parameters[@"host"]
                           port:[parameters[@"port"] intValue]
                       usingSSL:[parameters[@"tls"] boolValue]];

    while (self.event == -1 && !self.timeout) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }

    XCTAssert(!self.timeout, @"timeout");
    [NSObject cancelPreviousPerformRequestsWithTarget:self];

    self.timeout = FALSE;
    self.type = -1;
    self.mid = 0;
    self.qoss = @[];
    self.event = -1;
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
