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
@property (nonatomic) NSInteger event;
@property (strong, nonatomic) NSError *error;
@property (nonatomic) BOOL timeout;
@property (nonatomic) int type;
@property (nonatomic) BOOL ungraceful;
@end

#define HOST @"localhost"
#define PROTOCOLLEVEL 4

@implementation MQTTClientTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    if (!self.ungraceful) {
        [self.session close];
        self.session.delegate = nil;
        self.session = nil;
    }

    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)test_connect_1883
{
    self.session = [[MQTTSession alloc] initWithClientId:[NSString stringWithCString:__FUNCTION__ encoding:NSUTF8StringEncoding]
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
    [self performSelector:@selector(ackTimeout:) withObject:@(10) afterDelay:10];
    while (!self.timeout && self.event == -1) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    XCTAssertNotEqual(self.event, (NSInteger)MQTTSessionEventConnectionError, @"MQTTSessionEventConnectionError %@", self.error);
    XCTAssertNotEqual(self.event, (NSInteger)MQTTSessionEventConnectionRefused, @"MQTTSessionEventConnectionRefused %@", self.error);
    XCTAssertNotEqual(self.event, (NSInteger)MQTTSessionEventProtocolError, @"MQTTSessionEventProtocolError %@", self.error);
}

- (void)test_connect_zero_length_user_pwd
{
    self.session = [[MQTTSession alloc] initWithClientId:[NSString stringWithCString:__FUNCTION__ encoding:NSUTF8StringEncoding]
                                                userName:@""
                                                password:@""
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
    [self performSelector:@selector(ackTimeout:) withObject:@(10) afterDelay:10];
    while (!self.timeout && self.event == -1) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    XCTAssertNotEqual(self.event, (NSInteger)MQTTSessionEventConnected, @"MQTTSessionEventConnected %@", self.error);
    XCTAssertNotEqual(self.event, (NSInteger)MQTTSessionEventConnectionError, @"MQTTSessionEventConnectionError %@", self.error);
    XCTAssertEqual(self.event, (NSInteger)MQTTSessionEventConnectionRefused, @"MQTTSessionEventConnectionRefused %@", self.error);
    XCTAssertNotEqual(self.event, (NSInteger)MQTTSessionEventProtocolError, @"MQTTSessionEventProtocolError %@", self.error);
}

- (void)test_connect_user_no_pwd
{
    self.session = [[MQTTSession alloc] initWithClientId:[NSString stringWithCString:__FUNCTION__ encoding:NSUTF8StringEncoding]
                                                userName:@"user"
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
    [self performSelector:@selector(ackTimeout:) withObject:@(10) afterDelay:10];
    while (!self.timeout && self.event == -1) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    XCTAssertNotEqual(self.event, (NSInteger)MQTTSessionEventConnected, @"MQTTSessionEventConnected %@", self.error);
    XCTAssertNotEqual(self.event, (NSInteger)MQTTSessionEventConnectionError, @"MQTTSessionEventConnectionError %@", self.error);
    XCTAssertEqual(self.event, (NSInteger)MQTTSessionEventConnectionRefused, @"MQTTSessionEventConnectionRefused %@", self.error);
    XCTAssertNotEqual(self.event, (NSInteger)MQTTSessionEventProtocolError, @"MQTTSessionEventProtocolError %@", self.error);
}

- (void)test_connect_no_user_but_pwd
{
    self.session = [[MQTTSession alloc] initWithClientId:[NSString stringWithCString:__FUNCTION__ encoding:NSUTF8StringEncoding]
                                                userName:nil
                                                password:@"passwd"
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
    [self performSelector:@selector(ackTimeout:) withObject:@(10) afterDelay:10];
    while (!self.timeout && self.event == -1) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    XCTAssertNotEqual(self.event, (NSInteger)MQTTSessionEventConnected, @"MQTTSessionEventConnected %@", self.error);
    XCTAssertNotEqual(self.event, (NSInteger)MQTTSessionEventConnectionError, @"MQTTSessionEventConnectionError %@", self.error);
    XCTAssertNotEqual(self.event, (NSInteger)MQTTSessionEventConnectionRefused, @"MQTTSessionEventConnectionRefused %@", self.error);
    XCTAssertNotEqual(self.event, (NSInteger)MQTTSessionEventProtocolError, @"MQTTSessionEventProtocolError %@", self.error);
    XCTAssertEqual(self.event, (NSInteger)MQTTSessionEventConnectionClosed, @"MQTTSessionEventConnectionClosed %@", self.error);
    
}

- (void)test_connect_will_with_qos3
{
    self.session = [[MQTTSession alloc] initWithClientId:[NSString stringWithCString:__FUNCTION__ encoding:NSUTF8StringEncoding]
                                                userName:nil
                                                password:nil
                                               keepAlive:10
                                            cleanSession:YES
                                                    will:YES
                                               willTopic:@"will-qos3"
                                                 willMsg:[@"will-qos3" dataUsingEncoding:NSUTF8StringEncoding]
                                                 willQoS:3
                                          willRetainFlag:NO
                                           protocolLevel:PROTOCOLLEVEL
                                                 runLoop:[NSRunLoop currentRunLoop]
                                                 forMode:NSRunLoopCommonModes];
    self.session.delegate = self;
    self.event = -1;
    [self.session connectToHost:HOST port:1883 usingSSL:NO];
    [self performSelector:@selector(ackTimeout:) withObject:@(10) afterDelay:10];
    while (!self.timeout && self.event == -1) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    XCTAssertNotEqual(self.event, (NSInteger)MQTTSessionEventConnected, @"MQTTSessionEventConnected %@", self.error);
    XCTAssertNotEqual(self.event, (NSInteger)MQTTSessionEventConnectionError, @"MQTTSessionEventConnectionError %@", self.error);
    XCTAssertNotEqual(self.event, (NSInteger)MQTTSessionEventConnectionRefused, @"MQTTSessionEventConnectionRefused %@", self.error);
    XCTAssertNotEqual(self.event, (NSInteger)MQTTSessionEventProtocolError, @"MQTTSessionEventProtocolError %@", self.error);
    XCTAssertEqual(self.event, (NSInteger)MQTTSessionEventConnectionClosed, @"MQTTSessionEventConnectionClosed %@", self.error);
    self.ungraceful = TRUE;
    
}

- (void)test_connect_will
{
    self.session = [[MQTTSession alloc] initWithClientId:[NSString stringWithCString:__FUNCTION__ encoding:NSUTF8StringEncoding]
                                                userName:nil
                                                password:nil
                                               keepAlive:10
                                            cleanSession:YES
                                                    will:YES
                                               willTopic:@"will-qos0"
                                                 willMsg:[@"will-qos0" dataUsingEncoding:NSUTF8StringEncoding]
                                                 willQoS:0
                                          willRetainFlag:NO
                                           protocolLevel:PROTOCOLLEVEL
                                                 runLoop:[NSRunLoop currentRunLoop]
                                                 forMode:NSRunLoopCommonModes];
    self.session.delegate = self;
    self.event = -1;
    [self.session connectToHost:HOST port:1883 usingSSL:NO];
    [self performSelector:@selector(ackTimeout:) withObject:@(10) afterDelay:10];
    while (!self.timeout && self.event == -1) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    XCTAssertEqual(self.event, (NSInteger)MQTTSessionEventConnected, @"MQTTSessionEventConnected %@", self.error);
    self.ungraceful = TRUE;
    
}

- (void)test_connect_other_protocollevel
{
    self.session = [[MQTTSession alloc] initWithClientId:[NSString stringWithCString:__FUNCTION__ encoding:NSUTF8StringEncoding]
                                                userName:nil
                                                password:nil
                                               keepAlive:60
                                            cleanSession:YES
                                                    will:NO
                                               willTopic:nil
                                                 willMsg:nil
                                                 willQoS:0
                                          willRetainFlag:NO
                                           protocolLevel:(PROTOCOLLEVEL == 4) ? 3 : 4
                                                 runLoop:[NSRunLoop currentRunLoop]
                                                 forMode:NSRunLoopCommonModes];
    self.session.delegate = self;
    self.event = -1;
    [self.session connectToHost:HOST port:1883 usingSSL:NO];
    [self performSelector:@selector(ackTimeout:) withObject:@(10) afterDelay:10];
    
    while (!self.timeout && self.event == -1) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    XCTAssert(!self.timeout, @"timeout");
    XCTAssertEqual(self.event, (NSInteger)MQTTSessionEventConnected, @"No MQTTSessionEventConnected %@", self.error);
    XCTAssertNotEqual(self.event, (NSInteger)MQTTSessionEventConnectionClosed, @"MQTTSessionEventConnectionClosed %@", self.error);
    XCTAssertNotEqual(self.event, (NSInteger)MQTTSessionEventConnectionError, @"MQTTSessionEventConnectionError %@", self.error);
    XCTAssertNotEqual(self.event, (NSInteger)MQTTSessionEventConnectionRefused, @"MQTTSessionEventConnectionRefused %@", self.error);
    XCTAssertNotEqual(self.event, (NSInteger)MQTTSessionEventProtocolError, @"MQTTSessionEventProtocolError %@", self.error);
}

- (void)test_connect_host_not_found
{
    self.session = [[MQTTSession alloc] initWithClientId:[NSString stringWithCString:__FUNCTION__ encoding:NSUTF8StringEncoding]
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
    [self.session connectToHost:@"abc" port:1883 usingSSL:NO];
    while (self.event == -1) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    XCTAssertNotEqual(self.event, (NSInteger)MQTTSessionEventConnected, @"MQTTSessionEventConnected %@", self.error);
    XCTAssertNotEqual(self.event, (NSInteger)MQTTSessionEventConnectionRefused, @"MQTTSessionEventConnectionRefused %@", self.error);
    XCTAssertNotEqual(self.event, (NSInteger)MQTTSessionEventProtocolError, @"MQTTSessionEventProtocolError %@", self.error);
}


- (void)test_connect_1884
{
    self.session = [[MQTTSession alloc] initWithClientId:[NSString stringWithCString:__FUNCTION__ encoding:NSUTF8StringEncoding]
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
    [self.session connectToHost:HOST port:1884 usingSSL:NO];
    while (self.event == -1) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    XCTAssertNotEqual(self.event, (NSInteger)MQTTSessionEventConnected, @"MQTTSessionEventConnected %@", self.error);
    XCTAssertNotEqual(self.event, (NSInteger)MQTTSessionEventConnectionRefused, @"MQTTSessionEventConnectionRefused %@", self.error);
    XCTAssertNotEqual(self.event, (NSInteger)MQTTSessionEventProtocolError, @"MQTTSessionEventProtocolErrorr %@", self.error);
}

- (void)test_connect_wrong_user_passwd
{
    self.session = [[MQTTSession alloc] initWithClientId:[NSString stringWithCString:__FUNCTION__ encoding:NSUTF8StringEncoding]
                                                userName:@"username"
                                                password:@"password"
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
    XCTAssertNotEqual(self.event, (NSInteger)MQTTSessionEventConnected, @"MQTTSessionEventConnected %@", self.error);
    XCTAssertNotEqual(self.event, (NSInteger)MQTTSessionEventConnectionError, @"MQTTSessionEventConnectionError %@", self.error);
    XCTAssertNotEqual(self.event, (NSInteger)MQTTSessionEventProtocolError, @"MQTTSessionEventProtocolErrorr %@", self.error);
}

- (void)test_ping
{
    self.session = [[MQTTSession alloc] initWithClientId:[NSString stringWithCString:__FUNCTION__ encoding:NSUTF8StringEncoding]
                                                userName:nil
                                                password:nil
                                               keepAlive:5
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
    while (!self.timeout && self.event == -1) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    NSLog(@"self.event:%ld MQTTSessionEventConnected:%ld", (long)self.event, (long)MQTTSessionEventConnected);
    XCTAssertEqual(self.event, (NSInteger)MQTTSessionEventConnected, @"No MQTTSessionEventConnected %@", self.error);

    self.event = -1;
    self.type = 0xff;
    [self performSelector:@selector(ackTimeout:) withObject:@(10) afterDelay:10];
    while (!self.timeout && self.event == -1 && self.type == 0xff) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    XCTAssertEqual(self.type, MQTTPingresp, @"No PingResp received %u", self.type);
    XCTAssertNotEqual(self.event, (NSInteger)MQTTSessionEventConnectionClosed, @"MQTTSessionEventConnectionClosed %@", self.error);
    XCTAssertNotEqual(self.event, (NSInteger)MQTTSessionEventProtocolError, @"MQTTSessionEventProtocolError %@", self.error);
    XCTAssert(!self.timeout, @"Timeout 200%% keepalive");
}

- (void)test_disconnect_wrong_flags_MQTT_3_14_1_1
{
    NSLog(@"can't test [MQTT-3.14.1-1]");
}

- (void)received:(int)type qos:(int)qos retained:(BOOL)retained duped:(BOOL)duped mid:(UInt16)mid data:(NSData *)data
{
    NSLog(@"received:%d qos:%d retained:%d duped:%d mid:%d data:%@", type, qos, retained, duped, mid, data);

    self.type = type;
}

- (void)newMessage:(MQTTSession *)session data:(NSData *)data onTopic:(NSString *)topic qos:(int)qos retained:(BOOL)retained mid:(unsigned int)mid
{
    NSLog(@"newMessage:%@ onTopic:%@ qos:%d retained:%d mid:%d", data, topic, qos, retained, mid);
}

- (void)handleEvent:(MQTTSession *)session event:(MQTTSessionEvent)eventCode error:(NSError *)error
{
    NSLog(@"handleEvent:%d error:%@", eventCode, error);
    self.event = eventCode;
    self.error = error;
}

- (void)ackTimeout:(NSTimeInterval)timeout
{
    NSLog(@"ackTimeout: %f", timeout);
    self.timeout = TRUE;
}




@end
