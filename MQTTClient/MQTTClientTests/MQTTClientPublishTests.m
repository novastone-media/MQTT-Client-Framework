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
@property (strong, nonatomic) NSMutableArray *inflight;
@property (strong, nonatomic) NSDictionary *parameters;

@end

@implementation MQTTClientPublishTests

- (void)setUp {
    [super setUp];
    MQTTStrict.strict = NO;
    self.inflight = [NSMutableArray array];
    self.parameters = MQTTTestHelpers.broker;
    [self connect:self.parameters];
}

- (void)tearDown {
    [self shutdown:self.parameters];
    [super tearDown];
}

- (void)testPublishNoPayloadAtMostOnce {
    self.timeoutValue = 1;
    [self testPublish:nil
              onTopic:[NSString stringWithFormat:@"%@/%s", TOPIC, __FUNCTION__]
               retain:NO
              atLevel:MQTTQosLevelAtMostOnce];
}

- (void)testPublishZeroLengthPayloadAtMostOnce {
    [self.session publishData:[[NSData alloc] init]
                      onTopic:[NSString stringWithFormat:@"%@/%s", TOPIC, __FUNCTION__]
                       retain:NO
                          qos:MQTTQosLevelAtMostOnce];
}

- (void)testPublishZeroLengthPayloadAtMostOnceRetain {
    self.timeoutValue = 1;
    [self testPublish:[@"data" dataUsingEncoding:NSUTF8StringEncoding]
              onTopic:[NSString stringWithFormat:@"%@/%s", TOPIC, __FUNCTION__]
               retain:YES
              atLevel:MQTTQosLevelAtMostOnce];
    [self testPublish:[[NSData alloc] init]
              onTopic:[NSString stringWithFormat:@"%@/%s", TOPIC, __FUNCTION__]
               retain:YES
              atLevel:MQTTQosLevelAtMostOnce];
    [self testPublish:[[NSData alloc] init]
              onTopic:[NSString stringWithFormat:@"%@/%s", TOPIC, __FUNCTION__]
               retain:YES
              atLevel:MQTTQosLevelAtMostOnce];
}

- (void)testPublishAtMostOnce {
    self.timeoutValue = 1;
    [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
              onTopic:[NSString stringWithFormat:@"%@/%s", TOPIC, __FUNCTION__]
               retain:NO
              atLevel:MQTTQosLevelAtMostOnce];
}

/*
 * [MQTT-1.5.3-3]
 * A UTF-8 encoded sequence 0xEF 0xBB 0xBF is always to be interpreted to mean
 * U+FEFF ("ZERO WIDTH NO-BREAK SPACE") wherever it appears in a string and
 * MUST NOT be skipped over or stripped off by a packet receiver.
 */
- (void)SLOWtestPublish_r0_q0_0xFEFF_MQTT_1_5_3_3 {
    unichar feff = 0xFEFF;
    [self testPublishCloseExpected:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
                           onTopic:[NSString stringWithFormat:@"%@<%C>/%s", TOPIC, feff, __FUNCTION__]
                            retain:NO
                           atLevel:MQTTQosLevelAtMostOnce];
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
    
    [self testPublishCloseExpected:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
                           onTopic:stringWithD800
                            retain:NO
                           atLevel:MQTTQosLevelExactlyOnce];
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
    
    [self testPublishCloseExpected:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
                           onTopic:stringWith9c
                            retain:TRUE
                           atLevel:MQTTQosLevelAtMostOnce];
}

/*
 * [MQTT-1.5.3-2]
 * A UTF-8 encoded string MUST NOT include an encoding of the null character U+0000.
 * If a receiver (Server or Client) receives a Control Packet containing U+0000 it MUST close the Network Connection.
 */
- (void)SLOWtestPublish_r0_q0_0x0000_MQTT_1_5_3_2 {
    NSString *stringWithNull = [NSString stringWithFormat:@"%@/%C/%s", TOPIC, 0, __FUNCTION__];
    
    [self testPublishCloseExpected:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
                           onTopic:stringWithNull
                            retain:NO
                           atLevel:MQTTQosLevelAtMostOnce];
}

/*
 * [MQTT-1.5.3-2]
 * A UTF-8 encoded string MUST NOT include an encoding of the null character U+0000.
 * If a receiver (Server or Client) receives a Control Packet containing U+0000 it MUST close the Network Connection.
 */
- (void)SLOWtestPublish_r0_q0_illegal_topic_strict {
    MQTTStrict.strict = YES;
    
    NSData *data = [NSData dataWithBytes:"MQTTClient/abc\x9c\x9dxyz" length:19];
    NSString *stringWith9c = [[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding];
    
    NSString *stringWithD800 = [NSString stringWithFormat:@"%@/%C/%s", TOPIC, 0xD800, __FUNCTION__];
    
    NSString *stringWithFEFF = [NSString stringWithFormat:@"%@<%C>/%s", TOPIC, 0xfeff, __FUNCTION__];
    
    NSString *stringWithNull = [NSString stringWithFormat:@"%@/%C/%s", TOPIC, 0, __FUNCTION__];
    XCTAssertThrows([self.session publishData:[[NSData alloc] init] onTopic:stringWith9c retain:NO qos:MQTTQosLevelAtMostOnce]);
    XCTAssertThrows([self.session publishData:[[NSData alloc] init] onTopic:stringWithNull retain:NO qos:MQTTQosLevelAtMostOnce]);
    XCTAssertThrows([self.session publishData:[[NSData alloc] init] onTopic:stringWithFEFF retain:NO qos:MQTTQosLevelAtMostOnce]);
    XCTAssertThrows([self.session publishData:[[NSData alloc] init] onTopic:stringWithD800 retain:NO qos:MQTTQosLevelAtMostOnce]);
    XCTAssertThrows([self.session connect]);
    
}

- (void)testPublish_r0_q1 {
    [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
              onTopic:[NSString stringWithFormat:@"%@/%s", TOPIC, __FUNCTION__]
               retain:NO
              atLevel:1];
}

- (void)testPublish_a_lot_of_q0 {
    for (int i = 0; i < ALOT; i++) {
        NSData *data = [[NSString stringWithFormat:@"%@/%s/%d", TOPIC, __FUNCTION__, i] dataUsingEncoding:NSUTF8StringEncoding];
        NSString *topic = [NSString stringWithFormat:@"%@/%s/%d", TOPIC, __FUNCTION__, i];
        self.sentMessageMid = [self.session publishData:data onTopic:topic retain:false qos:MQTTQosLevelAtMostOnce];
    }
}

- (void)testPublishALotOfAtLeastOnce {
    for (int i = 0; i < ALOT; i++) {
        NSData *data = [[NSString stringWithFormat:@"%@/%s/%d", TOPIC, __FUNCTION__, i] dataUsingEncoding:NSUTF8StringEncoding];
        NSString *topic = [NSString stringWithFormat:@"%@/%s/%d", TOPIC, __FUNCTION__, i];
        self.sentMessageMid = [self.session publishData:data
                                                onTopic:topic
                                                 retain:NO
                                                    qos:MQTTQosLevelAtLeastOnce];
        [self.inflight addObject:@(self.sentMessageMid)];
    }
    XCTNSPredicateExpectation *expectation = [[XCTNSPredicateExpectation alloc] initWithPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary<NSString *,id> *bindings) {
        return self.inflight.count == 0;
    }] object:self];
    [self waitForExpectations:@[expectation] timeout:self.timeoutValue];
}

- (void)testPublishALotOfExactlyOnce {
    for (int i = 0; i < ALOT; i++) {
        NSData *data = [[NSString stringWithFormat:@"%@/%s/%d", TOPIC, __FUNCTION__, i] dataUsingEncoding:NSUTF8StringEncoding];
        NSString *topic = [NSString stringWithFormat:@"%@/%s/%d", TOPIC, __FUNCTION__, i];
        self.sentMessageMid = [self.session publishData:data
                                                onTopic:topic
                                                 retain:NO
                                                    qos:MQTTQosLevelExactlyOnce];
        [self.inflight addObject:@(self.sentMessageMid)];
    }
    XCTNSPredicateExpectation *expectation = [[XCTNSPredicateExpectation alloc] initWithPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary<NSString *,id> *bindings) {
        return self.inflight.count == 0;
    }] object:self];
    [self waitForExpectations:@[expectation] timeout:self.timeoutValue];
}

/*
 * [MQTT-3.3.1-11]
 * A zero byte retained message MUST NOT be stored as a retained message on the Server.
 */
- (void)testPublish_r1_MQTT_3_3_1_11 {
    [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
              onTopic:[NSString stringWithFormat:@"%@/%s", TOPIC, __FUNCTION__]
               retain:YES
              atLevel:MQTTQosLevelAtLeastOnce];
    [self testPublish:[@"" dataUsingEncoding:NSUTF8StringEncoding]
              onTopic:[NSString stringWithFormat:@"%@/%s", TOPIC, __FUNCTION__]
               retain:YES
              atLevel:MQTTQosLevelAtLeastOnce];
}

- (void)testPublish_r0_q2 {
    [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
              onTopic:[NSString stringWithFormat:@"%@/%s", TOPIC, __FUNCTION__]
               retain:NO
              atLevel:2];
}

- (void)testPublish_r0_q3 {
    [self testPublishCloseExpected:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
                           onTopic:[NSString stringWithFormat:@"%@/%s", TOPIC, __FUNCTION__]
                            retain:NO
                           atLevel:3];
}

- (void)testPublish_r0_q3_strict {
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
    [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
              onTopic:[NSString stringWithFormat:@"%@/%s", TOPIC, __FUNCTION__]
               retain:YES
              atLevel:MQTTQosLevelExactlyOnce];
}

- (void)testPublish_r1_q2_long_topic {
    NSString *topic = [@"g" stringByPaddingToLength:32768 withString:@"g" startingAtIndex:0];
    [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
              onTopic:[NSString stringWithFormat:@"%@/%@", TOPIC, topic]
               retain:YES
              atLevel:MQTTQosLevelExactlyOnce];
}

- (void)testPublish_r1_q2_long_payload {
    NSString *payload = [@"g" stringByPaddingToLength:3000000 withString:@"g" startingAtIndex:0];
    [self testPublish:[payload dataUsingEncoding:NSUTF8StringEncoding]
              onTopic:TOPIC
               retain:YES
              atLevel:MQTTQosLevelExactlyOnce];
}

/*
 * [MQTT-3.3.2-2]
 *
 * The Topic Name in the PUBLISH Packet MUST NOT contain wildcard characters.
 */
- (void)testPublishWithPlus_MQTT_3_3_2_2 {
    NSString *topic = [NSString stringWithFormat:@"%@/+%s", TOPIC, __FUNCTION__];
    DDLogVerbose(@"publishing to topic:%@", topic);
    
    [self testPublishCloseExpected:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
                           onTopic:topic
                            retain:YES
                           atLevel:2];
}

/*
 * [MQTT-3.3.2-2]
 *
 * The Topic Name in the PUBLISH Packet MUST NOT contain wildcard characters.
 */
- (void)testPublishWithHash_MQTT_3_3_2_2 {
    NSString *topic = [NSString stringWithFormat:@"%@/#%s", TOPIC, __FUNCTION__];
    DDLogVerbose(@"publishing to topic:%@", topic);
    
    [self testPublishCloseExpected:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
                           onTopic:topic
                            retain:YES
                           atLevel:2];
}

/*
 * [MQTT-4.7.3-1]
 *
 * All Topic Names and Topic Filters MUST be at least one character long.
 */
- (void)testPublishEmptyTopic_MQTT_4_7_3_1 {
    [self testPublishCloseExpected:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
                           onTopic:@""
                            retain:YES
                           atLevel:2];
}

- (void)testPublish_q1 {
    [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
              onTopic:[NSString stringWithFormat:@"%@/%s", TOPIC, __FUNCTION__]
               retain:NO
              atLevel:MQTTQosLevelAtLeastOnce];
}

- (void)testPublish_q1_x2 {
    [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
              onTopic:[NSString stringWithFormat:@"%@/1%s", TOPIC, __FUNCTION__]
               retain:NO
              atLevel:MQTTQosLevelAtLeastOnce];
    
    [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
              onTopic:[NSString stringWithFormat:@"%@/2%s", TOPIC, __FUNCTION__]
               retain:NO
              atLevel:MQTTQosLevelAtLeastOnce];
    [self shutdown:self.parameters];
    [self connect:self.parameters];
    [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
              onTopic:[NSString stringWithFormat:@"%@/3%s", TOPIC, __FUNCTION__]
               retain:NO
              atLevel:MQTTQosLevelAtLeastOnce];
    [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
              onTopic:[NSString stringWithFormat:@"%@/4%s", TOPIC, __FUNCTION__]
               retain:NO
              atLevel:MQTTQosLevelAtLeastOnce];
}

- (void)testPublish_q2 {
    [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
              onTopic:[NSString stringWithFormat:@"%@/1%s", TOPIC, __FUNCTION__]
               retain:NO
              atLevel:MQTTQosLevelExactlyOnce];
}

- (void)testPublish_q2_x2 {
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
    [self shutdown:self.parameters];
    [self connect:self.parameters];
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
}

/**
 [MQTT-3.3.1-1]
 The DUP flag MUST be set to 1 by the Client or Server when it attempts to re- deliver a PUBLISH Packet.
 */
- (void)SLOWtestPublish_q2_dup_MQTT_3_3_1_1 {
    self.timeoutValue = 90;
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
}



/*
 * helpers
 */

- (void)testPublishCloseExpected:(NSData *)data onTopic:(NSString *)topic retain:(BOOL)retain atLevel:(UInt8)qos {
    [self testPublishCore:data onTopic:topic retain:retain atLevel:qos];
    DDLogVerbose(@"testPublishCloseExpected event:%ld", (long)self.event);
    XCTAssert(
              (self.event == MQTTSessionEventConnectionClosedByBroker) ||
              (self.event == MQTTSessionEventConnectionError) ||
              (self.event == MQTTSessionEventConnectionClosed),
              @"No MQTTSessionEventConnectionClosedByBroker or MQTTSessionEventConnectionError happened");
}

- (void)testPublish:(NSData *)data onTopic:(NSString *)topic retain:(BOOL)retain atLevel:(UInt8)qos {
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

- (void)testPublishCore:(NSData *)data onTopic:(NSString *)topic retain:(BOOL)retain atLevel:(UInt8)qos {
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
    
    XCTAssertFalse(self.timedout);
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
    XCTestExpectation *expectation = [self expectationWithDescription:@""];
    [self.session closeWithReturnCode:MQTTSuccess
                sessionExpiryInterval:nil
                         reasonString:nil
                         userProperty:nil
                    disconnectHandler:^(NSError *error) {
                        [expectation fulfill];
                    }];
    [self waitForExpectationsWithTimeout:[parameters[@"timeout"] intValue] handler:nil];
    self.session.delegate = nil;
    self.session = nil;
}

- (void)messageDelivered:(MQTTSession *)session msgID:(UInt16)msgID {
    DDLogInfo(@"messageDelivered %d", msgID);
    
    if (self.inflight) {
        [self.inflight removeObject:@(msgID)];
    }
    [super messageDelivered:session msgID:msgID];
}

- (void)newMessage:(MQTTSession *)session data:(NSData *)data onTopic:(NSString *)topic
               qos:(MQTTQosLevel)qos retained:(BOOL)retained mid:(unsigned int)mid {
    DDLogInfo(@"newMessage %d", mid);
    
    if (self.inflight) {
        [self.inflight removeObject:@(mid)];
    }
    [super newMessage:session data:data onTopic:topic
                  qos:qos retained:retained mid:mid];
}


@end
