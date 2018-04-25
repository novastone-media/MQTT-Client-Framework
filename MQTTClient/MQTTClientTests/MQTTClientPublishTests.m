//
//  MQTTClientPublishTests.m
//  MQTTClient
//
//  Created by Christoph Krey on 05.02.14.
//  Copyright © 2014-2017 Christoph Krey. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "MQTTLog.h"
#import "MQTTStrict.h"
#import "MQTTTestHelpers.h"

@interface MQTTClientPublishTests : MQTTTestHelpers
@property (nonatomic) NSInteger qos;
@property (nonatomic) BOOL blockQos2;
@property (strong, nonatomic) NSMutableDictionary *inflight;

@end

@implementation MQTTClientPublishTests

- (void)setUp {
    [super setUp];
    MQTTStrict.strict = NO;
}

- (void)SLOWtestPublish_r0_q0_noPayload {
    NSDictionary *parameters = MQTTTestHelpers.broker;
    [self connect:parameters];
    [self testPublish:nil
              onTopic:[NSString stringWithFormat:@"%@/%s", TOPIC, __FUNCTION__]
               retain:NO
              atLevel:0];
    [self shutdown:parameters];
}

- (void)testPublish_r0_q0_zeroLengthPayload {
    NSDictionary *parameters = MQTTTestHelpers.broker;
    [self connect:parameters];
    [self.session publishData:[[NSData alloc] init]
                      onTopic:[NSString stringWithFormat:@"%@/%s", TOPIC, __FUNCTION__]
                       retain:NO
                          qos:0];
    [self shutdown:parameters];
}

- (void)SLOWtestPublish_r1_q0_zeroLengthPayload {
    NSDictionary *parameters = MQTTTestHelpers.broker;
    [self connect:parameters];
    [self testPublish:[@"data" dataUsingEncoding:NSUTF8StringEncoding]
              onTopic:[NSString stringWithFormat:@"%@/%s", TOPIC, __FUNCTION__]
               retain:TRUE
              atLevel:0];
    [self testPublish:[[NSData alloc] init]
              onTopic:[NSString stringWithFormat:@"%@/%s", TOPIC, __FUNCTION__]
               retain:TRUE
              atLevel:0];
    [self testPublish:[[NSData alloc] init]
              onTopic:[NSString stringWithFormat:@"%@/%s", TOPIC, __FUNCTION__]
               retain:TRUE
              atLevel:0];
    [self shutdown:parameters];
}

- (void)SLOWtestPublish_r0_q0 {
    NSDictionary *parameters = MQTTTestHelpers.broker;
    [self connect:parameters];
    [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
              onTopic:[NSString stringWithFormat:@"%@/%s", TOPIC, __FUNCTION__]
               retain:NO
              atLevel:0];
    [self shutdown:parameters];
    
}

/*
 * [MQTT-1.5.3-3]
 * A UTF-8 encoded sequence 0xEF 0xBB 0xBF is always to be interpreted to mean
 * U+FEFF ("ZERO WIDTH NO-BREAK SPACE") wherever it appears in a string and
 * MUST NOT be skipped over or stripped off by a packet receiver.
 */
- (void)SLOWtestPublish_r0_q0_0xFEFF_MQTT_1_5_3_3 {
    unichar feff = 0xFEFF;
    
    NSDictionary *parameters = MQTTTestHelpers.broker;
    [self connect:parameters];
    [self testPublishCloseExpected:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
                           onTopic:[NSString stringWithFormat:@"%@<%C>/%s", TOPIC, feff, __FUNCTION__]
                            retain:NO
                           atLevel:0];
    [self shutdown:parameters];
    
}

/*
 * [MQTT-1.5.3-1]
 * The character data in a UTF-8 encoded string MUST be well-formed UTF-8 as defined by the
 * Unicode specification [Unicode] and restated in RFC 3629 [RFC3629]. In particular this data MUST NOT
 * include encodings of code points between U+D800 and U+DFFF. If a Server or Client receives a Control
 * Packet containing ill-formed UTF-8 it MUST close the Network Connection.
 */
- (void)testPublish_r0_q0_0xD800_MQTT_1_5_3_1 {
    DDLogInfo(@"can't test [MQTT-1.5.3-1]");
    NSString *stringWithD800 = [NSString stringWithFormat:@"%@/%C/%s", TOPIC, 0xD800, __FUNCTION__];
    DDLogVerbose(@"stringWithD800(%lu) %@", (unsigned long)stringWithD800.length, stringWithD800.description);
    
    NSDictionary *parameters = MQTTTestHelpers.broker;
    [self connect:parameters];
    [self testPublishCloseExpected:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
                           onTopic:stringWithD800
                            retain:NO
                           atLevel:MQTTQosLevelExactlyOnce];
    [self shutdown:parameters];
    
}

/*
 * [MQTT-1.5.3-1]
 * The character data in a UTF-8 encoded string MUST be well-formed UTF-8 as defined by the
 * Unicode specification [Unicode] and restated in RFC 3629 [RFC3629]. In particular this data MUST NOT
 * include encodings of code points between U+D800 and U+DFFF. If a Server or Client receives a Control
 * Packet containing ill-formed UTF-8 it MUST close the Network Connection.
 */
- (void)SLOWtestPublish_r0_q0_0x9c_MQTT_1_5_3_1 {
    NSData *data = [NSData dataWithBytes:"MQTTClient/abc\x9c\x9dxyz" length:19];
    NSString *stringWith9c = [[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding];
    DDLogVerbose(@"stringWith9c(%lu) %@", (unsigned long)stringWith9c.length, stringWith9c.description);
    
    NSDictionary *parameters = MQTTTestHelpers.broker;
    [self connect:parameters];
    [self testPublishCloseExpected:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
                           onTopic:stringWith9c
                            retain:TRUE
                           atLevel:MQTTQosLevelAtMostOnce];
    [self shutdown:parameters];
    
}

/*
 * [MQTT-1.5.3-2]
 * A UTF-8 encoded string MUST NOT include an encoding of the null character U+0000.
 * If a receiver (Server or Client) receives a Control Packet containing U+0000 it MUST close the Network Connection.
 */
- (void)SLOWtestPublish_r0_q0_0x0000_MQTT_1_5_3_2 {
    NSString *stringWithNull = [NSString stringWithFormat:@"%@/%C/%s", TOPIC, 0, __FUNCTION__];
    DDLogVerbose(@"stringWithNull(%lu) %@", (unsigned long)stringWithNull.length, stringWithNull.description);
    
    NSDictionary *parameters = MQTTTestHelpers.broker;
    [self connect:parameters];
    [self testPublishCloseExpected:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
                           onTopic:stringWithNull
                            retain:NO
                           atLevel:MQTTQosLevelAtMostOnce];
    [self shutdown:parameters];
    
}

/*
 * [MQTT-1.5.3-2]
 * A UTF-8 encoded string MUST NOT include an encoding of the null character U+0000.
 * If a receiver (Server or Client) receives a Control Packet containing U+0000 it MUST close the Network Connection.
 */
- (void)SLOWtestPublish_r0_q0_illegal_topic_strict {
    MQTTStrict.strict = YES;
    
    NSDictionary *parameters = MQTTTestHelpers.broker;
    [self connect:parameters];
    
    NSData *data = [NSData dataWithBytes:"MQTTClient/abc\x9c\x9dxyz" length:19];
    NSString *stringWith9c = [[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding];
    
    NSString *stringWithD800 = [NSString stringWithFormat:@"%@/%C/%s", TOPIC, 0xD800, __FUNCTION__];
    
    NSString *stringWithFEFF = [NSString stringWithFormat:@"%@<%C>/%s", TOPIC, 0xfeff, __FUNCTION__];
    
    NSString *stringWithNull = [NSString stringWithFormat:@"%@/%C/%s", TOPIC, 0, __FUNCTION__];
    
    @try {
        [self.session publishData:[[NSData alloc] init]
                          onTopic:stringWith9c retain:0 qos:0];
        [self.session publishData:[[NSData alloc] init]
                          onTopic:stringWithNull retain:0 qos:0];
        [self.session publishData:[[NSData alloc] init]
                          onTopic:stringWithFEFF retain:0 qos:0];
        [self.session publishData:[[NSData alloc] init]
                          onTopic:stringWithD800 retain:0 qos:0];
        [self.session connect];
        XCTFail(@"Should not get here but throw exception before");
    } @catch (NSException *exception) {
    } @finally {
    }
    
}


- (void)testPublish_r0_q1 {
    NSDictionary *parameters = MQTTTestHelpers.broker;
    [self connect:parameters];
    [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
              onTopic:[NSString stringWithFormat:@"%@/%s", TOPIC, __FUNCTION__]
               retain:NO
              atLevel:1];
    [self shutdown:parameters];
}

- (void)testPublish_a_lot_of_q0 {
    NSDictionary *parameters = MQTTTestHelpers.broker;
    [self connect:parameters];
    for (int i = 0; i < ALOT; i++) {
        NSData *data = [[NSString stringWithFormat:@"%@/%s/%d", TOPIC, __FUNCTION__, i] dataUsingEncoding:NSUTF8StringEncoding];
        NSString *topic = [NSString stringWithFormat:@"%@/%s/%d", TOPIC, __FUNCTION__, i];
        self.sentMessageMid = [self.session publishData:data onTopic:topic retain:false qos:MQTTQosLevelAtMostOnce];
        DDLogInfo(@"testing publish %d/%d", i, self.sentMessageMid);
    }
    [self shutdown:parameters];
}

- (void)testPublish_a_lot_of_q1 {
    NSDictionary *parameters = MQTTTestHelpers.broker;
    [self connect:parameters];
    
    self.inflight = [[NSMutableDictionary alloc] init];
    
    for (int i = 0; i < ALOT; i++) {
        NSData *data = [[NSString stringWithFormat:@"%@/%s/%d", TOPIC, __FUNCTION__, i] dataUsingEncoding:NSUTF8StringEncoding];
        NSString *topic = [NSString stringWithFormat:@"%@/%s/%d", TOPIC, __FUNCTION__, i];
        self.sentMessageMid = [self.session publishData:data onTopic:topic retain:false qos:MQTTQosLevelAtLeastOnce];
        DDLogInfo(@"testing publish %d/%d", i, self.sentMessageMid);
        (self.inflight)[@(self.sentMessageMid)] = @"PUBLISHED";
    }
    
    self.timedout = false;
    self.event = -1;
    [self performSelector:@selector(timedout:)
               withObject:nil
               afterDelay:self.timeoutValue];
    
    while (self.inflight.count && !self.timedout && self.event == -1) {
        DDLogInfo(@"[MQTTClientPublishTests] waiting for %lu", (unsigned long)self.inflight.count);
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    XCTAssertFalse(self.timedout, @"Timeout after %f seconds", self.timeoutValue);
    XCTAssert(self.event == -1, @"Event %d happened", self.event);
    [self shutdown:parameters];
}

- (void)testPublish_a_lot_of_q2 {
    NSDictionary *parameters = MQTTTestHelpers.broker;
    [self connect:parameters];
    
    self.inflight = [[NSMutableDictionary alloc] init];
    
    for (int i = 0; i < ALOT; i++) {
        NSData *data = [[NSString stringWithFormat:@"%@/%s/%d", TOPIC, __FUNCTION__, i] dataUsingEncoding:NSUTF8StringEncoding];
        NSString *topic = [NSString stringWithFormat:@"%@/%s/%d", TOPIC, __FUNCTION__, i];
        self.sentMessageMid = [self.session publishData:data onTopic:topic retain:false qos:MQTTQosLevelExactlyOnce];
        DDLogInfo(@"testing publish %d/%d", i, self.sentMessageMid);
        (self.inflight)[@(self.sentMessageMid)] = @"PUBLISHED";
    }
    
    self.timedout = false;
    self.event = -1;
    [self performSelector:@selector(timedout:)
               withObject:nil
               afterDelay:self.timeoutValue];
    
    while (self.inflight.count && !self.timedout && self.event == -1) {
        DDLogInfo(@"[MQTTClientPublishTests] waiting for %lu", (unsigned long)self.inflight.count);
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    XCTAssertFalse(self.timedout, @"Timeout after %f seconds", self.timeoutValue);
    XCTAssert(self.event == -1, @"Event %d happened", self.event);
    [self shutdown:parameters];
}

/*
 * [MQTT-3.3.1-11]
 * A zero byte retained message MUST NOT be stored as a retained message on the Server.
 */
- (void)testPublish_r1_MQTT_3_3_1_11 {
    NSDictionary *parameters = MQTTTestHelpers.broker;
    [self connect:parameters];
    [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
              onTopic:[NSString stringWithFormat:@"%@/%s", TOPIC, __FUNCTION__]
               retain:YES
              atLevel:MQTTQosLevelAtLeastOnce];
    [self testPublish:[@"" dataUsingEncoding:NSUTF8StringEncoding]
              onTopic:[NSString stringWithFormat:@"%@/%s", TOPIC, __FUNCTION__]
               retain:YES
              atLevel:MQTTQosLevelAtLeastOnce];
    [self shutdown:parameters];
}

- (void)testPublish_r0_q2 {
    NSDictionary *parameters = MQTTTestHelpers.broker;
    [self connect:parameters];
    [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
              onTopic:[NSString stringWithFormat:@"%@/%s", TOPIC, __FUNCTION__]
               retain:NO
              atLevel:2];
    [self shutdown:parameters];
}

- (void)testPublish_r0_q3 {
    NSDictionary *parameters = MQTTTestHelpers.broker;
    [self connect:parameters];
    [self testPublishCloseExpected:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
                           onTopic:[NSString stringWithFormat:@"%@/%s", TOPIC, __FUNCTION__]
                            retain:NO
                           atLevel:3];
    [self shutdown:parameters];
}

- (void)testPublish_r0_q3_strict {
    NSDictionary *parameters = MQTTTestHelpers.broker;
    MQTTStrict.strict = NO;
    [self connect:parameters];
    MQTTStrict.strict = YES;
    @try {
        [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
                  onTopic:[NSString stringWithFormat:@"%@/%s", TOPIC, __FUNCTION__]
                   retain:NO
                  atLevel:3];
        XCTFail(@"Should not get here but throw exception before");
    } @catch (NSException *exception) {
    } @finally {
    }
}

- (void)testPublish_r1_q2 {
    NSDictionary *parameters = MQTTTestHelpers.broker;
    [self connect:parameters];
    [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
              onTopic:[NSString stringWithFormat:@"%@/%s", TOPIC, __FUNCTION__]
               retain:YES
              atLevel:2];
    [self shutdown:parameters];
}

- (void)testPublish_r1_q2_long_topic {
    NSDictionary *parameters = MQTTTestHelpers.broker;
    [self connect:parameters];
    
    NSString *topic = @"gg";
    while (strlen([topic substringFromIndex:1].UTF8String) <= 32768) {
        DDLogVerbose(@"LongPublishTopic (%lu)", strlen([[topic substringFromIndex:1] UTF8String]));
        [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
                  onTopic:[NSString stringWithFormat:@"%@/%@", TOPIC, topic]
                   retain:YES
                  atLevel:2];
        topic = [topic stringByAppendingString:topic];
    }
    
    [self shutdown:parameters];
}

- (void)testPublish_r1_q2_long_payload {
    NSDictionary *parameters = MQTTTestHelpers.broker;
    [self connect:parameters];
    
    NSString *payload = @"gg";
    while (strlen([payload substringFromIndex:1].UTF8String) <= 1000000) {
        DDLogVerbose(@"LongPublishPayload (%lu)", strlen([[payload substringFromIndex:1] UTF8String]));
        [self testPublish:[payload dataUsingEncoding:NSUTF8StringEncoding]
                  onTopic:[NSString stringWithFormat:@"%@", TOPIC]
                   retain:YES
                  atLevel:2];
        payload = [payload stringByAppendingString:payload];
    }
    
    [self shutdown:parameters];
}


/*
 * [MQTT-3.3.2-1]
 * The Topic Name MUST be present as the first field in the PUBLISH Packet Variable header.
 * It MUST be a UTF-8 encoded string.
 */
- (void)testPublishNoUTF8_MQTT_3_3_2_1 {
    DDLogInfo(@"Can't test[MQTT-3.3.2-1]");
}

/*
 * [MQTT-3.3.2-2]
 *
 * The Topic Name in the PUBLISH Packet MUST NOT contain wildcard characters.
 */
- (void)testPublishWithPlus_MQTT_3_3_2_2 {
    NSDictionary *parameters = MQTTTestHelpers.broker;
    [self connect:parameters];
    
    NSString *topic = [NSString stringWithFormat:@"%@/+%s", TOPIC, __FUNCTION__];
    DDLogVerbose(@"publishing to topic:%@", topic);
    
    [self testPublishCloseExpected:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
                           onTopic:topic
                            retain:YES
                           atLevel:2];
    [self shutdown:parameters];
}

/*
 * [MQTT-3.3.2-2]
 *
 * The Topic Name in the PUBLISH Packet MUST NOT contain wildcard characters.
 */
- (void)testPublishWithHash_MQTT_3_3_2_2 {
    NSDictionary *parameters = MQTTTestHelpers.broker;
    [self connect:parameters];
    NSString *topic = [NSString stringWithFormat:@"%@/#%s", TOPIC, __FUNCTION__];
    DDLogVerbose(@"publishing to topic:%@", topic);
    
    [self testPublishCloseExpected:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
                           onTopic:topic
                            retain:YES
                           atLevel:2];
    [self shutdown:parameters];
}

/*
 * [MQTT-4.7.3-1]
 *
 * All Topic Names and Topic Filters MUST be at least one character long.
 */
- (void)testPublishEmptyTopic_MQTT_4_7_3_1 {
    NSDictionary *parameters = MQTTTestHelpers.broker;
    [self connect:parameters];
    [self testPublishCloseExpected:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
                           onTopic:@""
                            retain:YES
                           atLevel:2];
    [self shutdown:parameters];
}

- (void)testPublish_q1 {
    NSDictionary *parameters = MQTTTestHelpers.broker;
    [self connect:parameters];
    [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
              onTopic:[NSString stringWithFormat:@"%@/%s", TOPIC, __FUNCTION__]
               retain:NO
              atLevel:MQTTQosLevelAtLeastOnce];
    [self shutdown:parameters];
}

- (void)testPublish_q1_x2 {
    NSDictionary *parameters = MQTTTestHelpers.broker;
    [self connect:parameters];
    [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
              onTopic:[NSString stringWithFormat:@"%@/1%s", TOPIC, __FUNCTION__]
               retain:NO
              atLevel:MQTTQosLevelAtLeastOnce];
    
    [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
              onTopic:[NSString stringWithFormat:@"%@/2%s", TOPIC, __FUNCTION__]
               retain:NO
              atLevel:MQTTQosLevelAtLeastOnce];
    [self shutdown:parameters];
    [self connect:parameters];
    [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
              onTopic:[NSString stringWithFormat:@"%@/3%s", TOPIC, __FUNCTION__]
               retain:NO
              atLevel:MQTTQosLevelAtLeastOnce];
    [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
              onTopic:[NSString stringWithFormat:@"%@/4%s", TOPIC, __FUNCTION__]
               retain:NO
              atLevel:MQTTQosLevelAtLeastOnce];
    [self shutdown:parameters];
}

- (void)testPublish_q2 {
    NSDictionary *parameters = MQTTTestHelpers.broker;
    [self connect:parameters];
    [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
              onTopic:[NSString stringWithFormat:@"%@/1%s", TOPIC, __FUNCTION__]
               retain:NO
              atLevel:MQTTQosLevelExactlyOnce];
    [self shutdown:parameters];
}

- (void)testPublish_q2_x2 {
    NSDictionary *parameters = MQTTTestHelpers.broker;
    [self connect:parameters];
    [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
              onTopic:[NSString stringWithFormat:@"%@/1%s", TOPIC, __FUNCTION__]
               retain:NO
              atLevel:MQTTQosLevelExactlyOnce];
    [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
              onTopic:[NSString stringWithFormat:@"%@/2%s", TOPIC, __FUNCTION__]
               retain:NO
              atLevel:MQTTQosLevelExactlyOnce];
    [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
              onTopic:[NSString stringWithFormat:@"%@/3%s", TOPIC, __FUNCTION__]
               retain:NO
              atLevel:MQTTQosLevelExactlyOnce];
    [self shutdown:parameters];
    [self connect:parameters];
    [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
              onTopic:[NSString stringWithFormat:@"%@/4%s", TOPIC, __FUNCTION__]
               retain:NO
              atLevel:MQTTQosLevelExactlyOnce];
    [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
              onTopic:[NSString stringWithFormat:@"%@/5%s", TOPIC, __FUNCTION__]
               retain:NO
              atLevel:MQTTQosLevelExactlyOnce];
    [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
              onTopic:[NSString stringWithFormat:@"%@/6%s", TOPIC, __FUNCTION__]
               retain:NO
              atLevel:MQTTQosLevelExactlyOnce];
    [self shutdown:parameters];
}

/**
 [MQTT-3.3.1-1]
 The DUP flag MUST be set to 1 by the Client or Server when it attempts to re- deliver a PUBLISH Packet.
 */
- (void)SLOWtestPublish_q2_dup_MQTT_3_3_1_1 {
    NSDictionary *parameters = MQTTTestHelpers.broker;
    [self connect:parameters];
    self.timeoutValue= 90;
    self.blockQos2 = true;
    [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
              onTopic:[NSString stringWithFormat:@"%@/1%s", TOPIC, __FUNCTION__]
               retain:NO
              atLevel:MQTTQosLevelExactlyOnce];
    [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
              onTopic:[NSString stringWithFormat:@"%@/2%s", TOPIC, __FUNCTION__]
               retain:NO
              atLevel:MQTTQosLevelExactlyOnce];
    self.blockQos2 = true;
    [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
              onTopic:[NSString stringWithFormat:@"%@/3%s", TOPIC, __FUNCTION__]
               retain:NO
              atLevel:MQTTQosLevelExactlyOnce];
    [self shutdown:parameters];
}



/*
 * helpers
 */

- (void)testPublishCloseExpected:(NSData *)data onTopic:(NSString *)topic retain:(BOOL)retain atLevel:(UInt8)qos
{
    [self testPublishCore:data onTopic:topic retain:retain atLevel:qos];
    DDLogVerbose(@"testPublishCloseExpected event:%ld", (long)self.event);
    XCTAssert(
              (self.event == MQTTSessionEventConnectionClosedByBroker) ||
              (self.event == MQTTSessionEventConnectionError) ||
              (self.event == MQTTSessionEventConnectionClosed),
              @"No MQTTSessionEventConnectionClosedByBroker or MQTTSessionEventConnectionError happened");
}

- (void)testPublish:(NSData *)data onTopic:(NSString *)topic retain:(BOOL)retain atLevel:(UInt8)qos
{
    [self testPublishCore:data onTopic:topic retain:retain atLevel:qos];
    switch (qos % 4) {
        case 0:
            XCTAssert(self.event == -1, @"Event %ld happened", (long)self.event);
            XCTAssert(self.timedout, @"Responses during %f seconds timeout", self.timeoutValue);
            break;
        case 1:
            XCTAssert(self.event == -1, @"Event %ld happened", (long)self.event);
            XCTAssertFalse(self.timedout, @"Timeout after %f seconds", self.timeoutValue);
            XCTAssert(self.deliveredMessageMid == self.sentMessageMid, @"sentMid(%ld) != mid(%ld)",
                      (long)self.sentMessageMid, (long)self.deliveredMessageMid);
            break;
        case 2:
            XCTAssert(self.event == -1, @"Event %ld happened", (long)self.event);
            XCTAssertFalse(self.timedout, @"Timeout after %f seconds", self.timeoutValue);
            XCTAssert(self.deliveredMessageMid == self.sentMessageMid, @"sentMid(%ld) != mid(%ld)",
                      (long)self.sentMessageMid, (long)self.deliveredMessageMid);
            break;
        case 3:
        default:
            XCTAssert(self.event == (long)MQTTSessionEventConnectionClosed, @"no close received");
            break;
    }
}

- (void)testPublishCore:(NSData *)data onTopic:(NSString *)topic retain:(BOOL)retain atLevel:(UInt8)qos
{
    self.deliveredMessageMid = -1;
    self.sentMessageMid = [self.session publishData:data onTopic:topic retain:retain qos:qos];
    
    self.timedout = false;
    [self performSelector:@selector(timedout:)
               withObject:nil
               afterDelay:self.timeoutValue];
    
    while (self.deliveredMessageMid != self.sentMessageMid && !self.timedout && self.event == -1) {
        DDLogVerbose(@"[MQTTClientPublishTests] waiting for %d", self.sentMessageMid);
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
}

- (BOOL)ignoreReceived:(MQTTSession *)session type:(MQTTCommandType)type qos:(MQTTQosLevel)qos retained:(BOOL)retained duped:(BOOL)duped mid:(UInt16)mid data:(NSData *)data {
    DDLogVerbose(@"ignoreReceived:%d qos:%d retained:%d duped:%d mid:%d data:%@", type, qos, retained, duped, mid, data);
    if (self.blockQos2 && type == MQTTPubrec) {
        self.blockQos2 = false;
        return true;
    }
    return false;
}

- (void)connect:(NSDictionary *)parameters {
    self.session = [MQTTTestHelpers session:parameters];
    self.session.delegate = self;
    
    self.event = -1;
    
    self.timedout = FALSE;
    self.timeoutValue = [parameters[@"timeout"] doubleValue];
    [self performSelector:@selector(timedout:)
               withObject:nil
               afterDelay:self.timeoutValue];
    
    [self.session connect];
    
    while (self.event == -1 && !self.timedout) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    
    XCTAssert(!self.timedout, @"timeout");
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    self.timedout = FALSE;
    self.type = -1;
    self.messageMid = 0;
    self.qos = -1;
    self.event = -1;
}

- (void)shutdown:(NSDictionary *)parameters {
    self.event = -1;
    
    self.timedout = FALSE;
    [self performSelector:@selector(timedout:)
               withObject:nil
               afterDelay:[parameters[@"timeout"] intValue]];
    
    [self.session closeWithReturnCode:MQTTSuccess
                sessionExpiryInterval:nil
                         reasonString:nil
                         userProperty:nil
                    disconnectHandler:nil];
    
    while (self.event == -1 && !self.timedout) {
        DDLogVerbose(@"waiting for disconnect");
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    
    XCTAssert(!self.timedout, @"timeout");
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    self.session.delegate = nil;
    self.session = nil;
}

- (void)messageDelivered:(MQTTSession *)session msgID:(UInt16)msgID {
    DDLogInfo(@"messageDelivered %d", msgID);
    
    if (self.inflight) {
        [self.inflight removeObjectForKey:@(msgID)];
    }
    [super messageDelivered:session msgID:msgID];
}

- (void)newMessage:(MQTTSession *)session data:(NSData *)data onTopic:(NSString *)topic
               qos:(MQTTQosLevel)qos retained:(BOOL)retained mid:(unsigned int)mid {
    DDLogInfo(@"newMessage %d", mid);
    
    if (self.inflight) {
        [self.inflight removeObjectForKey:@(mid)];
    }
    [super newMessage:session data:data onTopic:topic
                  qos:qos retained:retained mid:mid];
}


@end
