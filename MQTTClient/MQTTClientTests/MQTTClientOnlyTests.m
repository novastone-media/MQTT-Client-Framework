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

@interface MQTTClientOnlyTests : XCTestCase <MQTTSessionDelegate>
@property (strong, nonatomic) MQTTSession *session;
@property (nonatomic) NSInteger event;
@property (strong, nonatomic) NSError *error;
@property (nonatomic) BOOL timeout;
@property (nonatomic) int type;
@end

@implementation MQTTClientOnlyTests

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    [self.session close];
    self.session.delegate = nil;
    self.session = nil;

    [super tearDown];
}

- (void)test_connect_host_not_found
{
    self.session = [[MQTTSession alloc] init];
    self.session.persistence.persistent = PERSISTENT;
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


- (void)test_connect_1889
{
    self.session = [[MQTTSession alloc] init];
    self.session.persistence.persistent = PERSISTENT;
    self.session.delegate = self;
    self.event = -1;
    [self.session connectToHost:@"localhost" port:1889 usingSSL:NO];
    while (self.event == -1) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    XCTAssertNotEqual(self.event, (NSInteger)MQTTSessionEventConnected, @"MQTTSessionEventConnected %@", self.error);
    XCTAssertNotEqual(self.event, (NSInteger)MQTTSessionEventConnectionRefused, @"MQTTSessionEventConnectionRefused %@", self.error);
    XCTAssertNotEqual(self.event, (NSInteger)MQTTSessionEventProtocolError, @"MQTTSessionEventProtocolErrorr %@", self.error);
}

- (void)received:(int)type qos:(int)qos retained:(BOOL)retained duped:(BOOL)duped mid:(UInt16)mid data:(NSData *)data
{
    //NSLog(@"received:%d qos:%d retained:%d duped:%d mid:%d data:%@", type, qos, retained, duped, mid, data);

    self.type = type;
}

- (void)newMessage:(MQTTSession *)session data:(NSData *)data onTopic:(NSString *)topic qos:(MQTTQosLevel)qos retained:(BOOL)retained mid:(unsigned int)mid
{
    //NSLog(@"newMessage:%@ onTopic:%@ qos:%d retained:%d mid:%d", data, topic, qos, retained, mid);
}

- (void)handleEvent:(MQTTSession *)session event:(MQTTSessionEvent)eventCode error:(NSError *)error
{
    //NSLog(@"handleEvent:%ld error:%@", (long)eventCode, error);
    self.event = eventCode;
    self.error = error;
}

- (void)ackTimeout:(NSNumber *)timeout
{
    //NSLog(@"ackTimeout: %f", [timeout doubleValue]);
    self.timeout = TRUE;
}




@end
