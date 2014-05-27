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
@property (nonatomic) NSInteger mid;
@property (nonatomic) UInt16 sentMid;
@property (nonatomic) NSInteger qos;
@property (nonatomic) BOOL timeout;
@property (nonatomic) NSInteger type;

@end

@implementation MQTTClientPublishTests

- (void)setUp
{
    [super setUp];
    
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
                                           protocolLevel:PROTOCOLLEVEL
                                                 runLoop:[NSRunLoop currentRunLoop]
                                                 forMode:NSRunLoopCommonModes];
    self.session.delegate = self;
    self.event = -1;
    [self.session connectToHost:HOST port:1883 usingSSL:NO];
    while (self.event == -1) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }

    self.type = -1;
    /*
    [self.session subscribeToTopic:[NSString stringWithFormat:@"%@/#", TOPIC] atLevel:2];
    while (self.type == -1) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
     */
    self.timeout = FALSE;
    self.type = -1;
    self.mid = -1;
    self.qos = -1;
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
 * Publish
 */

- (void)testPublish_r0_q0
{
    [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
              onTopic:[NSString stringWithFormat:@"%@/%s", TOPIC, __FUNCTION__]
               retain:NO
              atLevel:0];
}

- (void)testPublish_r0_q1
{
    [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
              onTopic:[NSString stringWithFormat:@"%@/%s", TOPIC, __FUNCTION__]
               retain:NO
              atLevel:1];
}

- (void)testPublish_r0_q2
{
    [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
              onTopic:[NSString stringWithFormat:@"%@/%s", TOPIC, __FUNCTION__]
               retain:NO
              atLevel:2];
}

- (void)testPublish_r0_q3
{
    [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
              onTopic:[NSString stringWithFormat:@"%@/%s", TOPIC, __FUNCTION__]
               retain:NO
              atLevel:3];
}

- (void)testPublish_r0_q4
{
    [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
              onTopic:[NSString stringWithFormat:@"%@/%s", TOPIC, __FUNCTION__]
               retain:NO
              atLevel:4];
}

- (void)testPublish_r1_q2
{
    [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
              onTopic:[NSString stringWithFormat:@"%@/%s", TOPIC, __FUNCTION__]
               retain:YES
              atLevel:2];
}

- (void)testPublishNoUTF8_MQTT_3_3_2_1
{
    NSLog(@"Can't test[MQTT-3.3.2-1]");
}

- (void)testPublishWithPlus_MQTT_3_3_2_2
{
    [self testPublishCloseExpected:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
              onTopic:[NSString stringWithFormat:@"%@/+%s", TOPIC, __FUNCTION__]
               retain:YES
              atLevel:2];
}

- (void)testPublishWithHash_MQTT_3_3_2_2
{
    [self testPublishCloseExpected:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
              onTopic:[NSString stringWithFormat:@"%@/#%s", TOPIC, __FUNCTION__]
               retain:YES
              atLevel:2];
}

- (void)testPublishEmptyTopic_MQTT_4_7_3_1
{
    [self testPublishCloseExpected:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
                           onTopic:@""
                            retain:YES
                           atLevel:2];
}

/*
 * helpers
 */

- (void)testPublishCloseExpected:(NSData *)data onTopic:(NSString *)topic retain:(BOOL)retain atLevel:(UInt8)qos
{
    [self testPublishCore:data onTopic:topic retain:retain atLevel:qos];
    XCTAssert(self.event == (long)MQTTSessionEventConnectionClosed, @"No MQTTSessionEventConnectionClosed happened");
}

- (void)testPublish:(NSData *)data onTopic:(NSString *)topic retain:(BOOL)retain atLevel:(UInt8)qos
{
    [self testPublishCore:data onTopic:topic retain:retain atLevel:qos];
    switch (qos % 4) {
        case 0:
            XCTAssert(self.event == -1, @"Event %ld happened", (long)self.event);
            XCTAssert(self.timeout, @"Responses during %d seconds timeout", 10);
            break;
        case 1:
            XCTAssert(self.event == -1, @"Event %ld happened", (long)self.event);
            XCTAssertFalse(self.timeout, @"Timeout after %d seconds", 10);
            XCTAssert(self.mid == self.sentMid, @"sentMid(%ld) != mid(%ld)", (long)self.sentMid, (long)self.mid);
            break;
        case 2:
            XCTAssert(self.event == -1, @"Event %ld happened", (long)self.event);
            XCTAssertFalse(self.timeout, @"Timeout after %d seconds", 10);
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
    self.sentMid = [self.session publishData:data onTopic:topic retain:retain qos:qos];
    [self performSelector:@selector(ackTimeout:) withObject:@(10) afterDelay:10];
    while (self.mid == -1 && !self.timeout && self.event == -1) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
}

- (void)ackTimeout:(NSTimeInterval)timeout
{
    self.timeout = TRUE;
}

- (void)newMessage:(MQTTSession *)session data:(NSData *)data onTopic:(NSString *)topic qos:(int)qos retained:(BOOL)retained mid:(unsigned int)mid
{
    NSLog(@"newMessage:%@ onTopic:%@ qos:%d retained:%d mid:%d", data, topic, qos, retained, mid);
    self.mid = mid;
}

- (void)handleEvent:(MQTTSession *)session event:(MQTTSessionEvent)eventCode error:(NSError *)error
{
    NSLog(@"handleEvent:%d error:%@", eventCode, error);
    self.event = eventCode;
}

- (void)messageDelivered:(MQTTSession *)session msgID:(UInt16)msgID
{
    NSLog(@"messageDelivered:%ld", (long)msgID);
    self.mid = msgID;
}

- (void)received:(int)type qos:(int)qos retained:(BOOL)retained duped:(BOOL)duped mid:(UInt16)mid data:(NSData *)data
{
    NSLog(@"received:%d qos:%d retained:%d duped:%d mid:%d data:%@", type, qos, retained, duped, mid, data);
    self.type = type;
}

@end
