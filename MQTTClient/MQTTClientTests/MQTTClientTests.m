//
//  MQTTClientTests.m
//  MQTTClientTests
//
//  Created by Christoph Krey on 13.01.14.
//  Copyright (c) 2014 Christoph Krey. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MQTTClient.h"
#import "MQTTClientTests.h"

@interface MQTTClientTests : XCTestCase <MQTTSessionDelegate>
@property (strong, nonatomic) MQTTSession *session;
@property (nonatomic) MQTTSessionEvent event;
@property (strong, nonatomic) NSError *error;
@property (nonatomic) BOOL timeout;
@property (nonatomic) int type;
@property (nonatomic) BOOL ungraceful;
@property (strong, nonatomic) NSDictionary *parameters;
@end

@implementation MQTTClientTests

- (void)setUp
{
    [super setUp];

    self.parameters = PARAMETERS;
}

- (void)tearDown
{
    if (!self.ungraceful) {
        self.event = -1;
        
        self.timeout = FALSE;
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
        
        self.session.delegate = nil;
        self.session = nil;
    }
    
    [super tearDown];
}

- (void)test_init
{
    self.session = [[MQTTSession alloc] init];
    [self connect:self.session];
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
}

- (void)test_init_short_clientId
{
    self.session = [[MQTTSession alloc] initWithClientId:@""
                                                userName:nil
                                                password:nil
                                               keepAlive:60
                                            cleanSession:YES
                                                    will:NO
                                               willTopic:nil
                                                 willMsg:nil
                                                 willQoS:0
                                          willRetainFlag:NO
                                           protocolLevel:[self.parameters[@"protocollevel"] intValue]
                                                 runLoop:[NSRunLoop currentRunLoop]
                                                 forMode:NSRunLoopCommonModes];
    [self connect:self.session];
    XCTAssert(!self.timeout, @"timeout");
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
}

- (void)test_init_long_clientId
{
    self.session = [[MQTTSession alloc] initWithClientId:@"123456789.123456789.1234"
                                                userName:nil
                                                password:nil
                                               keepAlive:60
                                            cleanSession:YES
                                                    will:NO
                                               willTopic:nil
                                                 willMsg:nil
                                                 willQoS:0
                                          willRetainFlag:NO
                                           protocolLevel:[self.parameters[@"protocollevel"] intValue]
                                                 runLoop:[NSRunLoop currentRunLoop]
                                                 forMode:NSRunLoopCommonModes];
    [self connect:self.session];
    XCTAssert(!self.timeout, @"timeout");
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
}

- (void)test_init_no_clientId
{
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
                                           protocolLevel:[self.parameters[@"protocollevel"] intValue]
                                                 runLoop:[NSRunLoop currentRunLoop]
                                                 forMode:NSRunLoopCommonModes];
    [self connect:self.session];
    XCTAssert(!self.timeout, @"timeout");
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
}

- (void)test_connect_1883
{
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
                                           protocolLevel:[self.parameters[@"protocollevel"] intValue]
                                                 runLoop:[NSRunLoop currentRunLoop]
                                                 forMode:NSRunLoopCommonModes];
    [self connect:self.session];
    XCTAssert(!self.timeout, @"timeout");
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
}

- (void)test_connect_user_no_pwd
{
    self.session = [[MQTTSession alloc] initWithClientId:nil
                                                userName:@"user"
                                                password:nil
                                               keepAlive:60
                                            cleanSession:YES
                                                    will:NO
                                               willTopic:nil
                                                 willMsg:nil
                                                 willQoS:0
                                          willRetainFlag:NO
                                           protocolLevel:[self.parameters[@"protocollevel"] intValue]
                                                 runLoop:[NSRunLoop currentRunLoop]
                                                 forMode:NSRunLoopCommonModes];
    [self connect:self.session];
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
}

- (void)test_connect_will
{
    self.session = [[MQTTSession alloc] initWithClientId:nil
                                                userName:nil
                                                password:nil
                                               keepAlive:10
                                            cleanSession:YES
                                                    will:YES
                                               willTopic:@"MQTTClient/will-qos0"
                                                 willMsg:[@"will-qos0" dataUsingEncoding:NSUTF8StringEncoding]
                                                 willQoS:0
                                          willRetainFlag:NO
                                           protocolLevel:[self.parameters[@"protocollevel"] intValue]
                                                 runLoop:[NSRunLoop currentRunLoop]
                                                 forMode:NSRunLoopCommonModes];
    [self connect:self.session];
    XCTAssert(!self.timeout, @"timeout");
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);

    self.ungraceful = TRUE;
}

- (void)test_connect_other_protocollevel
{
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
                                           protocolLevel:([self.parameters[@"protocollevel"] intValue] == 4) ? 3 : 4
                                                 runLoop:[NSRunLoop currentRunLoop]
                                                 forMode:NSRunLoopCommonModes];
    [self connect:self.session];
    XCTAssert(!self.timeout, @"timeout");
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"No MQTTSessionEventConnected %@", self.error);
    XCTAssertNotEqual(self.event, MQTTSessionEventConnectionClosed, @"MQTTSessionEventConnectionClosed %@", self.error);
    XCTAssertNotEqual(self.event, MQTTSessionEventConnectionError, @"MQTTSessionEventConnectionError %@", self.error);
    XCTAssertNotEqual(self.event, MQTTSessionEventConnectionRefused, @"MQTTSessionEventConnectionRefused %@", self.error);
    XCTAssertNotEqual(self.event, MQTTSessionEventProtocolError, @"MQTTSessionEventProtocolError %@", self.error);
}


- (void)test_connect_wrong_user_passwd
{
    self.session = [[MQTTSession alloc] initWithClientId:nil
                                                userName:@"username"
                                                password:@"password"
                                               keepAlive:60
                                            cleanSession:YES
                                                    will:NO
                                               willTopic:nil
                                                 willMsg:nil
                                                 willQoS:0
                                          willRetainFlag:NO
                                           protocolLevel:[self.parameters[@"protocollevel"] intValue]
                                                 runLoop:[NSRunLoop currentRunLoop]
                                                 forMode:NSRunLoopCommonModes];
    [self connect:self.session];
    XCTAssert(!self.timeout, @"timeout");
    XCTAssertNotEqual(self.event, MQTTSessionEventConnected, @"MQTTSessionEventConnected %@", self.error);
    XCTAssertNotEqual(self.event, MQTTSessionEventConnectionError, @"MQTTSessionEventConnectionError %@", self.error);
    XCTAssertNotEqual(self.event, MQTTSessionEventProtocolError, @"MQTTSessionEventProtocolErrorr %@", self.error);
}

- (void)test_ping
{
    self.session = [[MQTTSession alloc] initWithClientId:nil
                                                userName:nil
                                                password:nil
                                               keepAlive:5
                                            cleanSession:YES
                                                    will:NO
                                               willTopic:nil
                                                 willMsg:nil
                                                 willQoS:0
                                          willRetainFlag:NO
                                           protocolLevel:[self.parameters[@"protocollevel"] intValue]
                                                 runLoop:[NSRunLoop currentRunLoop]
                                                 forMode:NSRunLoopCommonModes];
    [self connect:self.session];
    XCTAssert(!self.timeout, @"timeout");
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"No MQTTSessionEventConnected %@", self.error);

    self.event = -1;
    self.type = 0xff;
    [self performSelector:@selector(ackTimeout:)
               withObject:self.parameters[@"timeout"]
               afterDelay:[self.parameters[@"timeout"] intValue]];
     
    while (!self.timeout && self.event == -1 && self.type == 0xff) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    XCTAssertEqual(self.type, MQTTPingresp, @"No PingResp received %u", self.type);
    XCTAssertNotEqual(self.event, MQTTSessionEventConnectionClosed, @"MQTTSessionEventConnectionClosed %@", self.error);
    XCTAssertNotEqual(self.event, MQTTSessionEventProtocolError, @"MQTTSessionEventProtocolError %@", self.error);
    XCTAssert(!self.timeout, @"Timeout 200%% keepalive");
}

- (void)test_disconnect_wrong_flags_MQTT_3_14_1_1
{
    NSLog(@"can't test [MQTT-3.14.1-1]");
}

- (void)received:(MQTTSession *)session type:(int)type qos:(int)qos retained:(BOOL)retained duped:(BOOL)duped mid:(UInt16)mid data:(NSData *)data
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

- (void)ackTimeout:(NSNumber *)timeout
{
    NSLog(@"ackTimeout: %f", [timeout doubleValue]);
    self.timeout = TRUE;
}

- (void)connect:(MQTTSession *)session
{
    session.delegate = self;
    self.event = -1;
    self.timeout = FALSE;
    
    NSLog(@"connecting to:%@ port:%d tls:%d",
          self.parameters[@"host"],
          [self.parameters[@"port"] intValue],
          [self.parameters[@"tls"] boolValue]);

    [session connectToHost:self.parameters[@"host"]
                      port:[self.parameters[@"port"] intValue]
                  usingSSL:[self.parameters[@"tls"] boolValue]];
    
    [self performSelector:@selector(ackTimeout:)
               withObject:self.parameters[@"timeout"]
               afterDelay:[self.parameters[@"timeout"] intValue]];
     

    while (!self.timeout && self.event == -1) {
        NSLog(@"waiting for connection");
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
}

@end
