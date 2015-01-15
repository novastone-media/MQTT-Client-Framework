//
//  MQTTClientQoSTests.m
//  MQTTClient
//
//  Created by Christoph Krey on 20.12.14.
//  Copyright (c) 2014 Christoph Krey. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MQTTClient.h"
#import "MQTTClientTests.h"

@interface MQTTClientQoSTests : XCTestCase <MQTTSessionDelegate>
@property (strong, nonatomic) MQTTSession *session;
@property (nonatomic) NSInteger event;
@property (nonatomic) NSInteger mid;
@property (nonatomic) UInt16 sentMid;
@property (nonatomic) MQTTQosLevel qos;
@property (nonatomic) BOOL timeout;
@property (nonatomic) NSInteger type;
@property (strong, nonatomic) NSDictionary *parameters;


@end

@implementation MQTTClientQoSTests

- (void)setUp {
    [super setUp];
    
    self.parameters = PARAMETERS;

    self.session = [[MQTTSession alloc] initWithClientId:@"MQTTClientQoSTests"
                                                userName:nil
                                                password:nil
                                               keepAlive:60
                                            cleanSession:NO
                                                    will:NO
                                               willTopic:nil
                                                 willMsg:nil
                                                 willQoS:0
                                          willRetainFlag:NO
                                           protocolLevel:[self.parameters[@"protocollevel"] intValue]
                                                 runLoop:[NSRunLoop currentRunLoop]
                                                 forMode:NSRunLoopCommonModes];
    self.session.delegate = self;
    [self connect];
}

- (void)tearDown {
    [self disconnect];
    self.session.delegate = nil;
    self.session = nil;
    
    [super tearDown];
}


/*
 * Publish
 */

- (void)testPublish_q1
{
    [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
              onTopic:[NSString stringWithFormat:@"%@/%s", TOPIC, __FUNCTION__]
               retain:NO
              atLevel:MQTTQosLevelAtLeastOnce];
}

- (void)testPublish_q1_x2
{
    [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
              onTopic:[NSString stringWithFormat:@"%@/1%s", TOPIC, __FUNCTION__]
               retain:NO
              atLevel:MQTTQosLevelAtLeastOnce];
    
    [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
              onTopic:[NSString stringWithFormat:@"%@/2%s", TOPIC, __FUNCTION__]
               retain:NO
              atLevel:MQTTQosLevelAtLeastOnce];
    [self disconnect];
    [self connect];
    [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
              onTopic:[NSString stringWithFormat:@"%@/3%s", TOPIC, __FUNCTION__]
               retain:NO
              atLevel:MQTTQosLevelAtLeastOnce];
    [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
              onTopic:[NSString stringWithFormat:@"%@/4%s", TOPIC, __FUNCTION__]
               retain:NO
              atLevel:MQTTQosLevelAtLeastOnce];
}

- (void)testPublish_q2
{
    [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
              onTopic:[NSString stringWithFormat:@"%@/1%s", TOPIC, __FUNCTION__]
               retain:NO
              atLevel:MQTTQosLevelExactlyOnce];
}

- (void)testPublish_q2_x2
{
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
    [self disconnect];
    [self connect];
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

/*
 * helpers
 */

- (void)testPublish:(NSData *)data onTopic:(NSString *)topic retain:(BOOL)retain atLevel:(UInt8)qos
{
    self.type = -1;
    self.timeout = FALSE;
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    self.type = -1;
    self.mid = -1;
    self.qos = -1;
    self.event = -1;
    
    self.sentMid = [self.session publishData:data onTopic:topic retain:retain qos:qos];
    [self performSelector:@selector(ackTimeout:)
               withObject:self.parameters[@"timeout"]
               afterDelay:[self.parameters[@"timeout"] intValue]];
    
    while (self.mid == -1 && !self.timeout && self.event == -1) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    switch (qos % 4) {
        case 0:
            XCTAssert(self.event == -1, @"Event %ld happened", (long)self.event);
            XCTAssert(self.timeout, @"Responses during %d seconds timeout", [self.parameters[@"timeout"] intValue]);
            break;
        case 1:
            XCTAssert(self.event == -1, @"Event %ld happened", (long)self.event);
            XCTAssertFalse(self.timeout, @"Timeout after %d seconds", [self.parameters[@"timeout"] intValue]);
            XCTAssert(self.mid == self.sentMid, @"sentMid(%ld) != mid(%ld)", (long)self.sentMid, (long)self.mid);
            break;
        case 2:
            XCTAssert(self.event == -1, @"Event %ld happened", (long)self.event);
            XCTAssertFalse(self.timeout, @"Timeout after %d seconds", [self.parameters[@"timeout"] intValue]);
            XCTAssert(self.mid == self.sentMid, @"sentMid(%ld) != mid(%ld)", (long)self.sentMid, (long)self.mid);
            break;
        case 3:
        default:
            XCTAssert(self.event == (long)MQTTSessionEventConnectionClosed, @"no close received");
            break;
    }
}

- (void)ackTimeout:(NSTimeInterval)timeout
{
    self.timeout = TRUE;
}

- (void)handleEvent:(MQTTSession *)session event:(MQTTSessionEvent)eventCode error:(NSError *)error
{
    NSLog(@"handleEvent:%ld error:%@", (long)eventCode, error);
    self.event = eventCode;
}

- (void)messageDelivered:(MQTTSession *)session msgID:(UInt16)msgID
{
    NSLog(@"messageDelivered:%ld", (long)msgID);
    self.mid = msgID;
}

- (void)received:(int)type qos:(MQTTQosLevel)qos retained:(BOOL)retained duped:(BOOL)duped mid:(UInt16)mid data:(NSData *)data
{
    NSLog(@"received:%d qos:%d retained:%d duped:%d mid:%d data:%@", type, qos, retained, duped, mid, data);
    self.type = type;
}

- (void)newMessage:(MQTTSession *)session data:(NSData *)data onTopic:(NSString *)topic qos:(MQTTQosLevel)qos retained:(BOOL)retained mid:(unsigned int)mid {
    //
}

- (void) connect {
    self.event = -1;
    
    self.timeout = FALSE;
    [self performSelector:@selector(ackTimeout:)
               withObject:self.parameters[@"timeout"]
               afterDelay:[self.parameters[@"timeout"] intValue]];
    
    [self.session connectToHost:self.parameters[@"host"]
                           port:[self.parameters[@"port"] intValue]
                       usingSSL:[self.parameters[@"tls"] boolValue]];
    
    while (self.event == -1 && !self.timeout) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    
    XCTAssert(!self.timeout, @"timeout");
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    self.type = -1;
    self.timeout = FALSE;
    self.type = -1;
    self.mid = -1;
    self.qos = -1;
    self.event = -1;

}

- (void)disconnect {
    self.event = -1;
    self.timeout = FALSE;
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    [self performSelector:@selector(ackTimeout:)
               withObject:self.parameters[@"timeout"]
               afterDelay:[self.parameters[@"timeout"] intValue]];
    
    [self.session close];
    
    while (self.event == -1 && !self.timeout) {
        NSLog(@"waiting for disconnect");
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    
    XCTAssert(!self.timeout, @"timeout");
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}
@end
