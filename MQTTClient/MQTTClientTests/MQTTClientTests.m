//
//  MQTTClientTests.m
//  MQTTClientTests
//
//  Created by Christoph Krey on 13.01.14.
//  Copyright (c) 2014 Christoph Krey. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MQTTClient.h"

@interface MQTTClientTests : XCTestCase <MQTTSessionDelegate>
@property (strong, nonatomic) MQTTSession *session;
@property (nonatomic) MQTTSessionEvent event;
@end

@implementation MQTTClientTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)test_connect_1883
{
    self.session = [[MQTTSession alloc] initWithClientId:@"__FUNCTION__" userName:nil password:nil keepAlive:60 cleanSession:YES will:NO willTopic:nil willMsg:nil willQoS:0 willRetainFlag:NO protocolLevel:3 runLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    self.session.delegate = self;
    self.event = -1;
    [self.session connectToHost:@"test.mosquitto.org" port:1883 usingSSL:NO];
    while (self.event == -1) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    [self.session subscribeToTopic:@"mqttitude/#" atLevel:0];
    [self.session unsubscribeTopic:@"mqttitdue/#"];
    [self.session close];
    self.session.delegate = nil;
    self.session = nil;
}

/*
- (void)test_connect_1884
{
    self.session = [[MQTTSession alloc] initWithClientId:@"__FUNCTION__" userName:nil password:nil keepAlive:60 cleanSession:YES will:NO willTopic:nil willMsg:nil willQoS:0 willRetainFlag:NO protocolLevel:3 runLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    self.session.delegate = self;
    self.event = -1;
    [self.session connectToHost:@"test.mosquitto.org" port:1884 usingSSL:NO];
    while (self.event == -1) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    [self.session unsubscribeTopic:@"mqttitdue/#"];
    [self.session close];
    self.session.delegate = nil;
    self.session = nil;
}
*/

- (void)newMessage:(MQTTSession *)session data:(NSData *)data onTopic:(NSString *)topic qos:(int)qos retained:(BOOL)retained mid:(unsigned int)mid
{
    NSLog(@"newMessage:%@ onTopic:%@ qos:%d retained:%d mid:%d", data, topic, qos, retained, mid);
}

- (void)handleEvent:(MQTTSession *)session event:(MQTTSessionEvent)eventCode error:(NSError *)error
{
    NSLog(@"handleEvent:%d error:%@", eventCode, error);
    XCTAssertNotEqual(eventCode, MQTTSessionEventConnectionError, @"MQTTSessionEventConnectionError %@", error);
    XCTAssertNotEqual(eventCode, MQTTSessionEventConnectionRefused, @"MQTTSessionEventConnectionRefused %@", error);
    XCTAssertNotEqual(eventCode, MQTTSessionEventProtocolError, @"MQTTSessionEventProtocolError %@", error);
    self.event = eventCode;
}


@end
