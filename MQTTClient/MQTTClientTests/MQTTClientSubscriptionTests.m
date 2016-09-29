//
//  MQTTClientSubscriptionTests.m
//  MQTTClient
//
//  Created by Christoph Krey on 14.01.14.
//  Copyright © 2014-2016 Christoph Krey. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "MQTTLog.h"
#import "MQTTClient.h"
#import "MQTTTestHelpers.h"

@interface MQTTClientSubscriptionTests : MQTTTestHelpers
@end

@implementation MQTTClientSubscriptionTests

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

- (void)testSubscribe_with_wrong_flags_MQTT_3_8_1_1 {
    DDLogVerbose(@"can't test [MQTT-3.8.1-1]");
}

- (void)testUnsubscribe_with_wrong_flags_MQTT_3_10_1_1 {
    DDLogVerbose(@"can't test [MQTT-3.10.1-1]");
}

- (void)testSubscribeWMultipleTopics_None_MQTT_3_8_3_3 {
    for (NSString *broker in self.brokers.allKeys) {
        DDLogVerbose(@"testing broker %@", broker);
        NSDictionary *parameters = self.brokers[broker];
        [self connect:parameters];
        [self testMultiSubscribeCloseExpected:@{}];
        [self shutdown:parameters];
    }
}

- (void)testSubscribeWMultipleTopics_One {
    for (NSString *broker in self.brokers.allKeys) {
        DDLogVerbose(@"testing broker %@", broker);
        NSDictionary *parameters = self.brokers[broker];
        [self connect:parameters];
        [self testMultiSubscribeSubackExpected:@{@"MQTTClient": @(2)}];
        [self shutdown:parameters];
    }
}

- (void)testSubscribeWMultipleTopics_more {
    for (NSString *broker in self.brokers.allKeys) {
        DDLogVerbose(@"testing broker %@", broker);
        NSDictionary *parameters = self.brokers[broker];
        [self connect:parameters];
        [self testMultiSubscribeSubackExpected:@{@"MQTTClient": @(0), @"MQTTClient/abc": @(0), @"MQTTClient/#": @(1)}];
        [self shutdown:parameters];
    }
}

- (void)testSubscribeWMultipleTopics_16_to_256 {
    for (NSString *broker in self.brokers.allKeys) {
        DDLogVerbose(@"testing broker %@", broker);
        NSDictionary *parameters = self.brokers[broker];
        [self connect:parameters];
        for (int TOPICS = 16; TOPICS <= 256; TOPICS += 16) {
            NSMutableDictionary *topics = [[NSMutableDictionary alloc] initWithCapacity:TOPICS];
            for (int i = 0; i < TOPICS; i++) {
                [topics setObject:@(1) forKey:[NSString stringWithFormat:@"MQTTClient/a/lot/%d", i]];
            }
            DDLogVerbose(@"testing %d subscriptions", TOPICS);
            [self testMultiSubscribeSubackExpected:topics];
        }
        [self shutdown:parameters];
    }
}

- (void)testSubscribeQoS0 {
    for (NSString *broker in self.brokers.allKeys) {
        DDLogVerbose(@"testing broker %@", broker);
        NSDictionary *parameters = self.brokers[broker];
        [self connect:parameters];
        [self testSubscribeSubackExpected:@"MQTTClient/#" atLevel:0];
        [self shutdown:parameters];
    }
}

- (void)testSubscribeQoS1 {
    for (NSString *broker in self.brokers.allKeys) {
        DDLogVerbose(@"testing broker %@", broker);
        NSDictionary *parameters = self.brokers[broker];
        [self connect:parameters];
        [self testSubscribeSubackExpected:@"MQTTClient/#" atLevel:1];
        [self shutdown:parameters];
    }
}

- (void)testSubscribeQoS2 {
    for (NSString *broker in self.brokers.allKeys) {
        DDLogVerbose(@"testing broker %@", broker);
        NSDictionary *parameters = self.brokers[broker];
        [self connect:parameters];
        [self testSubscribeSubackExpected:@"MQTTClient/#" atLevel:2];
        [self shutdown:parameters];
    }
}

- (void)testSubscribeTopicPlain {
    for (NSString *broker in self.brokers.allKeys) {
        DDLogVerbose(@"testing broker %@", broker);
        NSDictionary *parameters = self.brokers[broker];
        [self connect:parameters];
        [self testSubscribeSubackExpected:@"MQTTClient" atLevel:0];
        [self shutdown:parameters];
    }
}

- (void)testSubscribeTopicHash {
    for (NSString *broker in self.brokers.allKeys) {
        DDLogVerbose(@"testing broker %@", broker);
        NSDictionary *parameters = self.brokers[broker];
        [self connect:parameters];
        [self testSubscribeSubackExpected:@"#" atLevel:0];
        [self shutdown:parameters];
    }
}

- (void)testSubscribeTopicHashnotalone_MQTT_4_7_1_2 {
    for (NSString *broker in self.brokers.allKeys) {
        DDLogVerbose(@"testing broker %@", broker);
        NSDictionary *parameters = self.brokers[broker];
        [self connect:parameters];
        NSString *topic = @"#MQTTClient";
        DDLogVerbose(@"subscribing to topic %@", topic);
        [self testSubscribeCloseExpected:topic atLevel:0];
        [self shutdown:parameters];
    }
}

- (void)testSubscribeTopicEmpty_MQTT_4_7_3_1 {
    for (NSString *broker in self.brokers.allKeys) {
        DDLogVerbose(@"testing broker %@", broker);
        NSDictionary *parameters = self.brokers[broker];
        [self connect:parameters];
        [self testSubscribeCloseExpected:@"" atLevel:0];
        [self shutdown:parameters];
    }
}

- (void)testSubscribeTopicHashnotlast_MQTT_4_7_1_2 {
    for (NSString *broker in self.brokers.allKeys) {
        DDLogVerbose(@"testing broker %@", broker);
        NSDictionary *parameters = self.brokers[broker];
        [self connect:parameters];
        [self testSubscribeCloseExpected:@"MQTTClient/#/def" atLevel:0];
        [self shutdown:parameters];
    }
}

- (void)testSubscribeTopicPlus {
    for (NSString *broker in self.brokers.allKeys) {
        DDLogVerbose(@"testing broker %@", broker);
        NSDictionary *parameters = self.brokers[broker];
        [self connect:parameters];
        [self testSubscribeSubackExpected:@"+" atLevel:0];
        [self shutdown:parameters];
    }
}

- (void)testSubscribeTopicSlash {
    for (NSString *broker in self.brokers.allKeys) {
        DDLogVerbose(@"testing broker %@", broker);
        NSDictionary *parameters = self.brokers[broker];
        [self connect:parameters];
        [self testSubscribeSubackExpected:@"/" atLevel:0];
        [self shutdown:parameters];
    }
}

- (void)testSubscribeTopicPlusnotalone_MQTT_4_7_1_3 {
    for (NSString *broker in self.brokers.allKeys) {
        DDLogVerbose(@"testing broker %@", broker);
        NSDictionary *parameters = self.brokers[broker];
        [self connect:parameters];
        NSString *topic = @"MQTTClient+";
        DDLogVerbose(@"subscribing to topic %@", topic);
        [self testSubscribeCloseExpected:topic atLevel:0];
        [self shutdown:parameters];
    }
}

- (void)testSubscribeTopicNone_MQTT_3_8_3_3 {
    for (NSString *broker in self.brokers.allKeys) {
        DDLogVerbose(@"testing broker %@", broker);
        NSDictionary *parameters = self.brokers[broker];
        [self connect:parameters];
        [self testSubscribeCloseExpected:nil atLevel:0];
        [self shutdown:parameters];
    }
}

- (void)testSubscribeWildcardSYS_MQTT_4_7_2_1 {
    for (NSString *broker in self.brokers.allKeys) {
        DDLogVerbose(@"testing broker %@", broker);
        NSDictionary *parameters = self.brokers[broker];
        [self connect:parameters];
        [self testSubscribeSubackExpected:@"#" atLevel:0];

        self.timedout = false;
        self.SYSreceived = false;
        [self performSelector:@selector(timedout:)
                   withObject:nil
                   afterDelay:self.timeoutValue];

        while (!self.SYSreceived && !self.timedout) {
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }
        XCTAssertFalse(self.SYSreceived, @"The Server MUST NOT match Topic Filters starting with a wildcard character (# or +) with Topic Names beginning with a $ character [MQTT-4.7.2-1].");
        [NSObject cancelPreviousPerformRequestsWithTarget:self];

        [self shutdown:parameters];
    }
}

- (void)testSubscribeTopic_0x00_in_topic {
    DDLogVerbose(@"can't test [MQTT-4.7.3-2]");
}

- (void)testSubscribeLong_MQTT_4_7_3_3 {
    for (NSString *broker in self.brokers.allKeys) {
        DDLogVerbose(@"testing broker %@", broker);
        NSDictionary *parameters = self.brokers[broker];
        [self connect:parameters];
        
        NSString *topic = @"aa";
        for (UInt32 i = 2; i <= 64; i *= 2) {
            topic = [topic stringByAppendingString:topic];
        }
        DDLogVerbose(@"LongSubscribe (%lu)", strlen([[topic substringFromIndex:1] UTF8String]));
        [self testSubscribeSubackExpected:[topic substringFromIndex:1] atLevel:0];

        topic = @"bb";
        for (UInt32 i = 2; i <= 1024; i *= 2) {
            topic = [topic stringByAppendingString:topic];
        }
        DDLogVerbose(@"LongSubscribe (%lu)", strlen([[topic substringFromIndex:1] UTF8String]));
        [self testSubscribeSubackExpected:[topic substringFromIndex:1] atLevel:0];

        topic = @"cc";
        for (UInt32 i = 2; i <= 10000; i *= 2) {
            topic = [topic stringByAppendingString:topic];
        }
        DDLogVerbose(@"LongSubscribe (%lu)", strlen([[topic substringFromIndex:1] UTF8String]));
        [self testSubscribeSubackExpected:[topic substringFromIndex:1] atLevel:0];

        topic = @"dd";
        for (UInt32 i = 2; i < 32768; i *= 2) {
            topic = [topic stringByAppendingString:topic];
        }
        DDLogVerbose(@"LongSubscribe (%lu)", strlen([[topic substringFromIndex:1] UTF8String]));
        [self testSubscribeSubackExpected:[topic substringFromIndex:1] atLevel:0];

        topic = @"ee";
        for (UInt32 i = 2; i <= 32768; i *= 2) {
            topic = [topic stringByAppendingString:topic];
        }
        DDLogVerbose(@"LongSubscribe (%lu)", strlen([[topic substringFromIndex:15] UTF8String]));
        [self testSubscribeSubackExpected:[topic substringFromIndex:15] atLevel:0];
        
        topic = @"ff";
        for (UInt32 i = 2; i <= 32768; i *= 2) {
            topic = [topic stringByAppendingString:topic];
        }
        DDLogVerbose(@"LongSubscribe (%lu)", strlen([[topic substringFromIndex:2] UTF8String]));
        [self testSubscribeSubackExpected:[topic substringFromIndex:2] atLevel:0];
        
        topic = @"gg";
        for (UInt32 i = 2; i <= 32768; i *= 2) {
            topic = [topic stringByAppendingString:topic];
        }
        DDLogVerbose(@"LongSubscribe (%lu)", strlen([[topic substringFromIndex:1] UTF8String]));
        [self testSubscribeSubackExpected:[topic substringFromIndex:1] atLevel:0];

        [self shutdown:parameters];
    }
}


- (void)testSubscribeSameTopicDifferentQoS_MQTT_3_8_4_3 {
    for (NSString *broker in self.brokers.allKeys) {
        DDLogVerbose(@"testing broker %@", broker);
        NSDictionary *parameters = self.brokers[broker];
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
- (void)test_delivery_max_QoS_MQTT_3_3_5_1 {
    for (NSString *broker in self.brokers.allKeys) {
        DDLogVerbose(@"testing broker %@", broker);
        NSDictionary *parameters = self.brokers[broker];
        [self connect:parameters];
        [self testSubscribeSubackExpected:[NSString stringWithFormat:@"%@/#", TOPIC] atLevel:MQTTQosLevelAtMostOnce];
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
- (void)test_unsubscribe_byte_by_byte_MQTT_3_10_4_1 {
    for (NSString *broker in self.brokers.allKeys) {
        DDLogVerbose(@"testing broker %@", broker);
        NSDictionary *parameters = self.brokers[broker];
        [self connect:parameters];
        [self testSubscribeSubackExpected:TOPIC atLevel:MQTTQosLevelAtMostOnce];
        [self testUnsubscribeTopic:TOPIC];
        [self shutdown:parameters];
    }
}

/*
 * [MQTT-3.10.4-2]
 * If a Server deletes a Subscription It MUST stop adding any new messages for delivery to the Client.
 */
- (void)test_stop_delivering_after_unsubscribe_MQTT_3_10_4_2 {
    for (NSString *broker in self.brokers.allKeys) {
        DDLogVerbose(@"testing broker %@", broker);
        NSDictionary *parameters = self.brokers[broker];
        [self connect:parameters];
        [self testSubscribeSubackExpected:TOPIC atLevel:MQTTQosLevelAtMostOnce];
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
- (void)test_complete_delivering_qos12_after_unsubscribe_MQTT_3_10_4_3 {
    for (NSString *broker in self.brokers.allKeys) {
        DDLogVerbose(@"testing broker %@", broker);
        NSDictionary *parameters = self.brokers[broker];
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


- (void)testUnsubscribeTopicPlain {
    for (NSString *broker in self.brokers.allKeys) {
        DDLogVerbose(@"testing broker %@", broker);
        NSDictionary *parameters = self.brokers[broker];
        [self connect:parameters];
        [self testUnsubscribeTopic:@"abc"];
        [self shutdown:parameters];
    }
}

- (void)testUnubscribeTopicHash {
    for (NSString *broker in self.brokers.allKeys) {
        DDLogVerbose(@"testing broker %@", broker);
        NSDictionary *parameters = self.brokers[broker];
        [self connect:parameters];
        [self testUnsubscribeTopic:@"#"];
        [self shutdown:parameters];
    }
}

- (void)testUnsubscribeTopicHashnotalone_MQTT_4_7_1_2 {
    for (NSString *broker in self.brokers.allKeys) {
        DDLogVerbose(@"testing broker %@", broker);
        NSDictionary *parameters = self.brokers[broker];
        [self connect:parameters];
        [self testUnsubscribeTopicCloseExpected:@"#abc"];
        [self shutdown:parameters];
    }
}

- (void)testUnsubscribeTopicPlus {
    for (NSString *broker in self.brokers.allKeys) {
        DDLogVerbose(@"testing broker %@", broker);
        NSDictionary *parameters = self.brokers[broker];
        [self connect:parameters];
        [self testUnsubscribeTopic:@"+"];
        [self shutdown:parameters];
    }
}

- (void)testUnsubscribeTopicEmpty_MQTT_4_7_3_1 {
    for (NSString *broker in self.brokers.allKeys) {
        DDLogVerbose(@"testing broker %@", broker);
        NSDictionary *parameters = self.brokers[broker];
        [self connect:parameters];
        [self testUnsubscribeTopicCloseExpected:@""];
        [self shutdown:parameters];
    }
}

- (void)testUnsubscribeTopicNone_MQTT_3_10_3_2 {
    for (NSString *broker in self.brokers.allKeys) {
        DDLogVerbose(@"testing broker %@", broker);
        NSDictionary *parameters = self.brokers[broker];
        [self connect:parameters];
        [self testUnsubscribeTopicCloseExpected:nil];
        [self shutdown:parameters];
    }
}

- (void)testUnsubscribeTopicZero_MQTT_4_7_3_1 {
    for (NSString *broker in self.brokers.allKeys) {
        DDLogVerbose(@"testing broker %@", broker);
        NSDictionary *parameters = self.brokers[broker];
        [self connect:parameters];
        [self testUnsubscribeTopic:@"a\0b"];
        [self shutdown:parameters];
    }
}

- (void)testMultiUnsubscribe_None_MQTT_3_10_3_2 {
    for (NSString *broker in self.brokers.allKeys) {
        DDLogVerbose(@"testing broker %@", broker);
        NSDictionary *parameters = self.brokers[broker];
        [self connect:parameters];
        [self testMultiUnsubscribeTopicCloseExpected:@[]];
        [self shutdown:parameters];
    }
}

- (void)testMultiUnsubscribe_One {
    for (NSString *broker in self.brokers.allKeys) {
        DDLogVerbose(@"testing broker %@", broker);
        NSDictionary *parameters = self.brokers[broker];
        [self connect:parameters];
        [self testMultiUnsubscribeTopic:@[@"abc"]];
        [self shutdown:parameters];
    }
}

- (void)testMultiUnsubscribe_more {
    for (NSString *broker in self.brokers.allKeys) {
        DDLogVerbose(@"testing broker %@", broker);
        NSDictionary *parameters = self.brokers[broker];
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
    XCTAssertFalse(self.timedout, @"No SUBACK received within %f seconds [MQTT-3.8.4-1]", self.timeoutValue);
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    XCTAssert(self.event == -1, @"Event %ld happened", (long)self.event);
    XCTAssertEqual(self.subMid, self.sentSubMid, @"msgID(%d) in SUBACK does not match msgID(%d) in SUBSCRIBE [MQTT-3.8.4-2]", self.subMid, self.sentSubMid);
    for (NSNumber *qos in self.qoss) {
        XCTAssertNotEqual([qos intValue], 0x80, @"Returncode in SUBACK is 0x80");
        XCTAssert([qos intValue] == 0x00 || [qos intValue] == 0x01 || [qos intValue] == 0x02, @"Returncode in SUBACK invalid [MQTT-3.9.3-2]");
    }
}

- (void)testMultiSubscribeSubackExpected:(NSDictionary *)topics
{
    [self testMultiSubscribe:topics];
    XCTAssertFalse(self.timedout, @"No SUBACK received within %f seconds [MQTT-3.8.4-1]", self.timeoutValue);
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    XCTAssert(self.event == -1, @"Event %ld happened", (long)self.event);
    XCTAssertEqual(self.subMid, self.sentSubMid, @"msgID(%d) in SUBACK does not match msgID(%d) in SUBSCRIBE [MQTT-3.8.4-2]", self.subMid, self.sentSubMid);
    for (NSNumber *qos in self.qoss) {
        XCTAssertNotEqual([qos intValue], 0x80, @"Returncode in SUBACK is 0x80");
        XCTAssert([qos intValue] == 0x00 || [qos intValue] == 0x01 || [qos intValue] == 0x02, @"Returncode %d in SUBACK invalid [MQTT-3.9.3-2]", [qos intValue]);
    }
}

- (void)testSubscribeCloseExpected:(NSString *)topic atLevel:(UInt8)qos
{
    [self testSubscribe:topic atLevel:qos];
    XCTAssertFalse(self.timedout, @"No close within %f seconds", self.timeoutValue);
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    if (self.event == MQTTSessionEventConnectionClosedByBroker) {
        XCTAssert(self.subMid == 0, @"SUBACK received");
        XCTAssert(self.event == MQTTSessionEventConnectionClosedByBroker, @"Event %ld happened", (long)self.event);
    } else {
        XCTAssertEqual(self.subMid, self.sentSubMid, @"msgID(%d) in SUBACK does not match msgID(%d) in SUBSCRIBE [MQTT-3.8.4-2]", self.subMid, self.sentSubMid);
        for (NSNumber *qos in self.qoss) {
            XCTAssertEqual([qos intValue], 0x80, @"Returncode in SUBACK is not 0x80");
        }
    }
}

- (void)testMultiSubscribeCloseExpected:(NSDictionary *)topics
{
    [self testMultiSubscribe:topics];
    XCTAssertFalse(self.timedout, @"No close within %f seconds", self.timeoutValue);
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    if (self.event == MQTTSessionEventConnectionClosedByBroker) {
        XCTAssert(self.subMid == 0, @"SUBACK received");
        XCTAssert(self.event == MQTTSessionEventConnectionClosedByBroker, @"Event %ld happened", (long)self.event);
    }
    XCTAssertEqual(self.subMid, self.sentSubMid, @"msgID(%d) in SUBACK does not match msgID(%d) in SUBSCRIBE [MQTT-3.8.4-2]", self.subMid, self.sentSubMid);
    for (NSNumber *qos in self.qoss) {
        XCTAssertEqual([qos intValue], 0x80, @"Returncode in SUBACK is not 0x80");
    }
}

- (void)testSubscribeFailureExpected:(NSString *)topic atLevel:(UInt8)qos
{
    [self testSubscribe:topic atLevel:qos];
    XCTAssertFalse(self.timedout, @"No SUBACK received within %f seconds [MQTT-3.8.4-1]", self.timeoutValue);
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    XCTAssert(self.event == -1, @"Event %ld happened", (long)self.event);
    XCTAssertEqual(self.subMid, self.sentSubMid, @"msgID(%d) in SUBACK does not match msgID(%d) in SUBSCRIBE [MQTT-3.8.4-2]", self.subMid, self.sentSubMid);
    for (NSNumber *qos in self.qoss) {
        XCTAssertEqual([qos intValue], 0x80, @"Returncode in SUBACK is not 0x80");
    }
}

- (void)testSubscribe:(NSString *)topic atLevel:(UInt8)qos
{
    self.subMid = 0;
    self.qoss = nil;
    self.event = -1;
    self.timedout = false;
    self.sentSubMid = [self.session subscribeToTopic:topic atLevel:qos];
    DDLogVerbose(@"sent mid(SUBSCRIBE): %d", self.sentSubMid);
    [self performSelector:@selector(timedout:)
               withObject:nil
               afterDelay:self.timeoutValue];

    while (self.subMid == 0 && !self.qoss && !self.timedout && self.event == -1) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
}

- (void)testMultiSubscribe:(NSDictionary *)topics
{
    self.subMid = 0;
    self.qoss = nil;
    self.event = -1;
    self.timedout = false;
    self.sentSubMid = [self.session subscribeToTopics:topics];
    DDLogVerbose(@"sent mid(SUBSCRIBE multi): %d", self.sentSubMid);
    [self performSelector:@selector(timedout:)
               withObject:nil
               afterDelay:self.timeoutValue];

    while (self.subMid == 0 && !self.timedout && self.event == -1) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
}

- (void)testUnsubscribeTopic:(NSString *)topic
{
    self.unsubMid = 0;
    self.event = -1;
    self.timedout = false;
    self.sentUnsubMid = [self.session unsubscribeTopic:topic];
    DDLogVerbose(@"sent mid(UNSUBSCRIBE): %d", self.sentUnsubMid);

    [self performSelector:@selector(timedout:)
               withObject:nil
               afterDelay:self.timeoutValue];

    while (self.unsubMid == 0 && !self.timedout && self.event == -1) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    XCTAssertFalse(self.timedout, @"No UNSUBACK received [MQTT-3.10.3-5] within %f seconds", self.timeoutValue);
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    XCTAssertEqual(self.unsubMid, self.sentUnsubMid, @"msgID(%d) in UNSUBACK does not match msgID(%d) in UNSUBSCRIBE [MQTT-3.10.3-4]", self.unsubMid, self.sentUnsubMid);
}

- (void)testUnsubscribeTopicCloseExpected:(NSString *)topic
{
    self.unsubMid = 0;
    self.event = -1;
    self.timedout = false;
    self.sentUnsubMid = [self.session unsubscribeTopic:topic];
    DDLogVerbose(@"sent mid(UNSUBSCRIBE): %d", self.sentUnsubMid);
    [self performSelector:@selector(timedout:)
               withObject:nil
               afterDelay:self.timeoutValue];

    while (self.unsubMid == 0 && !self.timedout && self.event == -1) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    XCTAssertFalse(self.timedout, @"No close within %f seconds",self.timeoutValue);
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    XCTAssert(self.event == MQTTSessionEventConnectionClosedByBroker, @"Event %ld happened", (long)self.event);
}

- (void)testMultiUnsubscribeTopic:(NSArray *)topics
{
    self.unsubMid = 0;
    self.event = -1;
    self.timedout = false;
    self.sentUnsubMid = [self.session unsubscribeTopics:topics];
    DDLogVerbose(@"sent mid(UNSUBSCRIBE multi): %d", self.sentUnsubMid);
    [self performSelector:@selector(timedout:)
               withObject:nil
               afterDelay:self.timeoutValue];
    
    while (self.unsubMid == 0 && !self.timedout && self.event == -1) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    XCTAssertFalse(self.timedout, @"No UNSUBACK received [MQTT-3.10.3-5] within %f seconds", self.timeoutValue);
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    XCTAssertEqual(self.unsubMid, self.sentUnsubMid, @"msgID(%d) in UNSUBACK does not match msgID(%d) in UNSUBSCRIBE [MQTT-3.10.3-4]", self.unsubMid, self.sentUnsubMid);
}

- (void)testMultiUnsubscribeTopicCloseExpected:(NSArray *)topics
{
    self.unsubMid = 0;
    self.event = -1;
    self.timedout = false;
    self.sentUnsubMid = [self.session unsubscribeTopics:topics];
    DDLogVerbose(@"sent mid(UNSUBSCRIBE multi): %d", self.sentUnsubMid);
    [self performSelector:@selector(timedout:)
               withObject:nil
               afterDelay:self.timeoutValue];
    
    while (self.unsubMid == 0 && !self.timedout && self.event == -1) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    XCTAssertFalse(self.timedout, @"No close within %f seconds",self.timeoutValue);
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    XCTAssert(self.event == MQTTSessionEventConnectionClosedByBroker, @"Event %ld happened", (long)self.event);
}

- (void)connect:(NSDictionary *)parameters {
    self.session = [MQTTTestHelpers session:parameters];
    self.session.delegate = self;
    self.event = -1;

    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    self.timedout = FALSE;
    self.timeoutValue = [parameters[@"timeout"] doubleValue];
    [self performSelector:@selector(timedout:)
               withObject:nil
               afterDelay:self.timeoutValue];

    [self.session connect];

    while (self.event == -1 && !self.timedout) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }

    XCTAssert(!self.timedout, @"timedout");
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);

    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)shutdown:(NSDictionary *)parameters {
    self.event = -1;


    self.timedout = false;
    [self performSelector:@selector(timedout:)
               withObject:nil
               afterDelay:self.timeoutValue];

    [self.session close];

    while (self.event == -1 && !self.timedout) {
        DDLogVerbose(@"waiting for disconnect");
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    
    XCTAssert(!self.timedout, @"timedout");
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    self.session.delegate = nil;
    self.session = nil;
}




@end
