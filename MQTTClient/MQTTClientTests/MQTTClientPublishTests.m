//
//  MQTTClientPublishTests.m
//  MQTTClient
//
//  Created by Christoph Krey on 05.02.14.
//  Copyright (c) 2014 Christoph Krey. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MQTTClient.h"
#import "MQTTClientTests.h"

@interface MQTTClientPublishTests : XCTestCase <MQTTSessionDelegate>
@property (strong, nonatomic) MQTTSession *session;
@property (nonatomic) NSInteger event;
@property (nonatomic) UInt16 mid;
@property (nonatomic) UInt16 sentMid;
@property (nonatomic) NSInteger qos;
@property (nonatomic) BOOL timeout;
@property (nonatomic) NSTimeInterval timeoutValue;
@property (nonatomic) NSInteger type;

@end

@implementation MQTTClientPublishTests

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testPublish_r0_q0
{
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        [self connect:parameters];
        [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
                  onTopic:[NSString stringWithFormat:@"%@/%s", TOPIC, __FUNCTION__]
                   retain:NO
                  atLevel:0];
        [self shutdown:parameters];
    }
}

- (void)testPublish_r0_q1
{
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        [self connect:parameters];
        [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
                  onTopic:[NSString stringWithFormat:@"%@/%s", TOPIC, __FUNCTION__]
                   retain:NO
                  atLevel:1];
        [self shutdown:parameters];
    }
}

- (void)testPublish_r0_q2
{
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        [self connect:parameters];
        [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
                  onTopic:[NSString stringWithFormat:@"%@/%s", TOPIC, __FUNCTION__]
                   retain:NO
                  atLevel:2];
        [self shutdown:parameters];
    }
}

- (void)testPublish_r1_q2
{
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        [self connect:parameters];
        [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
                  onTopic:[NSString stringWithFormat:@"%@/%s", TOPIC, __FUNCTION__]
                   retain:YES
                  atLevel:2];
        [self shutdown:parameters];
    }
}

- (void)testPublishNoUTF8_MQTT_3_3_2_1
{
    NSLog(@"Can't test[MQTT-3.3.2-1]");
}

- (void)testPublishWithPlus_MQTT_3_3_2_2
{
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        [self connect:parameters];
        [self testPublishCloseExpected:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
                               onTopic:[NSString stringWithFormat:@"%@/+%s", TOPIC, __FUNCTION__]
                                retain:YES
                               atLevel:2];
        [self shutdown:parameters];
    }
}

- (void)testPublishWithHash_MQTT_3_3_2_2
{
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        [self connect:parameters];
        [self testPublishCloseExpected:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
                               onTopic:[NSString stringWithFormat:@"%@/#%s", TOPIC, __FUNCTION__]
                                retain:YES
                               atLevel:2];
        [self shutdown:parameters];
    }
}

- (void)testPublishEmptyTopic_MQTT_4_7_3_1
{
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        [self connect:parameters];
        [self testPublishCloseExpected:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
                               onTopic:@""
                                retain:YES
                               atLevel:2];
        [self shutdown:parameters];
    }
}

- (void)testPublish_q1
{
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        [self connect:parameters];
        [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
                  onTopic:[NSString stringWithFormat:@"%@/%s", TOPIC, __FUNCTION__]
                   retain:NO
                  atLevel:MQTTQosLevelAtLeastOnce];
        [self shutdown:parameters];
    }
}

- (void)testPublish_q1_x2
{
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
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
}

- (void)testPublish_q2
{
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        [self connect:parameters];
        [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
                  onTopic:[NSString stringWithFormat:@"%@/1%s", TOPIC, __FUNCTION__]
                   retain:NO
                  atLevel:MQTTQosLevelExactlyOnce];
        [self shutdown:parameters];
    }
}

- (void)testPublish_q2_x2
{
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
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
}



/*
 * helpers
 */

- (void)testPublishCloseExpected:(NSData *)data onTopic:(NSString *)topic retain:(BOOL)retain atLevel:(UInt8)qos
{
    [self testPublishCore:data onTopic:topic retain:retain atLevel:qos];
    XCTAssertEqual(self.event, MQTTSessionEventConnectionClosedByBroker, @"No MQTTSessionEventConnectionClosedByBroker happened");
}

- (void)testPublish:(NSData *)data onTopic:(NSString *)topic retain:(BOOL)retain atLevel:(UInt8)qos
{
    [self testPublishCore:data onTopic:topic retain:retain atLevel:qos];
    switch (qos % 4) {
        case 0:
            XCTAssert(self.event == -1, @"Event %ld happened", (long)self.event);
            XCTAssert(self.timeout, @"Responses during %f seconds timeout", self.timeoutValue);
            break;
        case 1:
            XCTAssert(self.event == -1, @"Event %ld happened", (long)self.event);
            XCTAssertFalse(self.timeout, @"Timeout after %f seconds", self.timeoutValue);
            XCTAssert(self.mid == self.sentMid, @"sentMid(%ld) != mid(%ld)", (long)self.sentMid, (long)self.mid);
            break;
        case 2:
            XCTAssert(self.event == -1, @"Event %ld happened", (long)self.event);
            XCTAssertFalse(self.timeout, @"Timeout after %f seconds", self.timeoutValue);
            XCTAssert(self.mid == self.sentMid, @"sentMid(%ld) != mid(%ld)", (long)self.sentMid, (long)self.mid);
            break;
        case 3:
        default:
            XCTAssert(self.event == (long)MQTTSessionEventConnectionClosed, @"no close received");
            break;
    }
}

- (void)testPublishCore:(NSData *)data onTopic:(NSString *)topic retain:(BOOL)retain atLevel:(UInt8)qos
{
    self.mid = 0;
    self.sentMid = [self.session publishData:data onTopic:topic retain:retain qos:qos];
    [self performSelector:@selector(ackTimeout:)
               withObject:nil
               afterDelay:self.timeoutValue];

    while (self.mid == 0 && !self.timeout && self.event == -1) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
}

- (void)ackTimeout:(NSTimeInterval)timeout
{
    self.timeout = TRUE;
}

- (void)newMessage:(MQTTSession *)session data:(NSData *)data onTopic:(NSString *)topic qos:(MQTTQosLevel)qos retained:(BOOL)retained mid:(unsigned int)mid
{
    //NSLog(@"newMessage:%@ onTopic:%@ qos:%d retained:%d mid:%d", data, topic, qos, retained, mid);
    self.mid = mid;
}

- (void)handleEvent:(MQTTSession *)session event:(MQTTSessionEvent)eventCode error:(NSError *)error
{
    //NSLog(@"handleEvent:%ld error:%@", (long)eventCode, error);
    self.event = eventCode;
}

- (void)messageDelivered:(MQTTSession *)session msgID:(UInt16)msgID
{
    //NSLog(@"messageDelivered:%ld", (long)msgID);
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
                                           protocolLevel:4
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
    self.qos = -1;
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
