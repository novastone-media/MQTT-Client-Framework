//
//  MQTTClientTests.m
//  MQTTClientTests
//
//  Created by Christoph Krey on 13.01.14.
//  Copyright © 2014-2017 Christoph Krey. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "MQTTLog.h"
#import "MQTTTestHelpers.h"
#import "MQTTSessionSynchron.h"
#import "MQTTCFSocketTransport.h"

@interface MQTTClientTestsV5 : MQTTTestHelpers
@property (nonatomic) BOOL ungraceful;
@property (strong, nonatomic) NSTimer *processingSimulationTimer;
@property (nonatomic) int sent;
@property (nonatomic) int received;
@property (nonatomic) int processed;

@end

@implementation MQTTClientTestsV5

- (void)test_complete_v5 {
    NSDictionary *parameters = MQTTTestHelpers.broker;
    if ([parameters[@"protocollevel"] integerValue] == MQTTProtocolVersion50) {
        self.session = [MQTTTestHelpers session:parameters];
        self.session.sessionExpiryInterval = @60U;
        self.session.authMethod = @"method";
        self.session.authData = [@"data" dataUsingEncoding:NSUTF8StringEncoding];
        self.session.requestProblemInformation = @1U;
        self.session.willDelayInterval = @30U;
        self.session.requestResponseInformation = @1U;
        self.session.receiveMaximum = @5U;
        self.session.topicAliasMaximum = @10U;
        self.session.userProperty = @{@"u1":@"v1", @"u2": @"v2"};
        self.session.maximumPacketSize = @8192U;
        [self connect:parameters];
        XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
        [self shutdown:parameters
            returnCode:MQTTSuccess
 sessionExpiryInterval:nil
          reasonString:nil
          userProperty:nil];
    }
}

- (void)test_v5_sessionExpiryInterval_5 {
    NSDictionary *parameters = MQTTTestHelpers.broker;
    if ([parameters[@"protocollevel"] integerValue] == MQTTProtocolVersion50) {
        self.session = [MQTTTestHelpers session:parameters];
        self.session.sessionExpiryInterval = @5U;
        [self connect:parameters];
        XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
        [self shutdown:parameters
            returnCode:MQTTSuccess
 sessionExpiryInterval:nil
          reasonString:nil
          userProperty:nil];
    }
}

- (void)test_v5_sessionExpiryInterval_0 {
    NSDictionary *parameters = MQTTTestHelpers.broker;
    if ([parameters[@"protocollevel"] integerValue] == MQTTProtocolVersion50) {
        self.session = [MQTTTestHelpers session:parameters];
        self.session.sessionExpiryInterval = @0U;
        [self connect:parameters];
        XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
        [self shutdown:parameters
            returnCode:MQTTSuccess
 sessionExpiryInterval:nil
          reasonString:nil
          userProperty:nil];
    }
}

- (void)test_v5_sessionExpiryInterval_none {
    NSDictionary *parameters = MQTTTestHelpers.broker;
    if ([parameters[@"protocollevel"] integerValue] == MQTTProtocolVersion50) {
        self.session = [MQTTTestHelpers session:parameters];
        [self connect:parameters];
        XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
        [self shutdown:parameters
            returnCode:MQTTSuccess
 sessionExpiryInterval:nil
          reasonString:nil
          userProperty:nil];
    }
}

- (void)test_v5_willDelayInterval_5 {
    NSDictionary *parameters = MQTTTestHelpers.broker;
    if ([parameters[@"protocollevel"] integerValue] == MQTTProtocolVersion50) {
        self.session = [MQTTTestHelpers session:parameters];
        self.session.sessionExpiryInterval = @10U;
        self.session.willDelayInterval = @5U;
        self.session.willFlag = true;
        self.session.willTopic = TOPIC;
        self.session.willMsg = [@"will" dataUsingEncoding:NSUTF8StringEncoding];
        self.session.willRetainFlag = false;
        self.session.willQoS = MQTTQosLevelAtMostOnce;
        [self connect:parameters];
        XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
        [self shutdown:parameters
            returnCode:MQTTDisconnectWithWillMessage
 sessionExpiryInterval:nil
          reasonString:nil
          userProperty:nil];
    }
}
- (void)test_v5_willDelayInterval_0 {
    NSDictionary *parameters = MQTTTestHelpers.broker;
    if ([parameters[@"protocollevel"] integerValue] == MQTTProtocolVersion50) {
        self.session = [MQTTTestHelpers session:parameters];
        self.session.sessionExpiryInterval = @5U;
        self.session.willDelayInterval = @0U;
        self.session.willFlag = true;
        self.session.willTopic = TOPIC;
        self.session.willMsg = [@"will" dataUsingEncoding:NSUTF8StringEncoding];
        self.session.willRetainFlag = false;
        self.session.willQoS = MQTTQosLevelAtMostOnce;
        [self connect:parameters];
        XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
        [self shutdown:parameters
            returnCode:MQTTDisconnectWithWillMessage
 sessionExpiryInterval:nil
          reasonString:nil
          userProperty:nil];
    }
}

- (void)test_v5_willDelayInterval_None {
    NSDictionary *parameters = MQTTTestHelpers.broker;
    if ([parameters[@"protocollevel"] integerValue] == MQTTProtocolVersion50) {
        self.session = [MQTTTestHelpers session:parameters];
        self.session.sessionExpiryInterval = @0U;
        self.session.willFlag = true;
        self.session.willTopic = TOPIC;
        self.session.willMsg = [@"will" dataUsingEncoding:NSUTF8StringEncoding];
        self.session.willRetainFlag = false;
        self.session.willQoS = MQTTQosLevelAtMostOnce;
        [self connect:parameters];
        XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
        [self shutdown:parameters
            returnCode:MQTTDisconnectWithWillMessage
 sessionExpiryInterval:nil
          reasonString:nil
          userProperty:nil];
    }
}


#pragma mark helpers

- (void)no_cleansession:(MQTTQosLevel)qos {
    
    NSDictionary *parameters = MQTTTestHelpers.broker;
    
    DDLogVerbose(@"Cleaning topic");
    
    MQTTSession *sendingSession = [MQTTTestHelpers session:parameters];
    sendingSession.clientId = @"MQTTClient-pub";
    if (![sendingSession connectAndWaitTimeout:[parameters[@"timeout"] unsignedIntValue]]) {
        XCTFail(@"no connection for pub to broker");
    }
    [sendingSession publishAndWaitData:[[NSData alloc] init] onTopic:TOPIC retain:true qos:qos];
    
    DDLogVerbose(@"Clearing old subs");
    self.session = [MQTTTestHelpers session:parameters];
    self.session.clientId = @"MQTTClient-sub";
    [self connect:parameters];
    [self shutdown:parameters
        returnCode:MQTTSuccess
sessionExpiryInterval:nil
      reasonString:nil
      userProperty:nil];
    
    DDLogVerbose(@"Subscribing to topic");
    self.session = [MQTTTestHelpers session:parameters];
    self.session.clientId = @"MQTTClient-sub";
    self.session.cleanSessionFlag = FALSE;
    
    [self connect:parameters];
    [self.session subscribeAndWaitToTopic:TOPIC atLevel:qos];
    [self shutdown:parameters
        returnCode:MQTTSuccess
sessionExpiryInterval:nil
      reasonString:nil
      userProperty:nil];
    
    for (int i = 1; i < BULK; i++) {
        DDLogVerbose(@"publishing to topic %d", i);
        NSString *payload = [NSString stringWithFormat:@"payload %d", i];
        [sendingSession publishAndWaitData:[payload dataUsingEncoding:NSUTF8StringEncoding] onTopic:TOPIC retain:false qos:qos];
    }
    [sendingSession closeAndWait];
    
    DDLogVerbose(@"receiving from topic");
    self.session = [MQTTTestHelpers session:parameters];
    self.session.clientId = @"MQTTClient-sub";
    self.session.cleanSessionFlag = FALSE;
    
    [self connect:parameters];
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"No MQTTSessionEventConnected %@", self.error);
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    self.timedout = FALSE;
    [self performSelector:@selector(timedout:)
               withObject:nil
               afterDelay:[parameters[@"timeout"] intValue]];
    
    while (!self.timedout) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    
    [self shutdown:parameters
        returnCode:MQTTSuccess
sessionExpiryInterval:nil
      reasonString:nil
      userProperty:nil];
}

- (void)cleansession:(MQTTQosLevel)qos {
    
    NSDictionary *parameters = MQTTTestHelpers.broker;
    
    DDLogVerbose(@"Cleaning topic");
    MQTTSession *sendingSession = [MQTTTestHelpers session:parameters];
    sendingSession.clientId = @"MQTTClient-pub";
    
    if (![sendingSession connectAndWaitTimeout:[parameters[@"timeout"] unsignedIntValue]]) {
        XCTFail(@"no connection for pub to broker");
    }
    [sendingSession publishAndWaitData:[[NSData alloc] init] onTopic:TOPIC retain:true qos:qos];
    
    DDLogVerbose(@"Clearing old subs");
    self.session = [MQTTTestHelpers session:parameters];
    self.session.clientId = @"MQTTClient-sub";
    [self connect:parameters];
    [self shutdown:parameters
        returnCode:MQTTSuccess
sessionExpiryInterval:nil
      reasonString:nil
      userProperty:nil];
    
    DDLogVerbose(@"Subscribing to topic");
    self.session = [MQTTTestHelpers session:parameters];
    self.session.clientId = @"MQTTClient-sub";
    [self connect:parameters];
    [self.session subscribeAndWaitToTopic:TOPIC atLevel:qos];
    
    for (int i = 1; i < BULK; i++) {
        DDLogVerbose(@"publishing to topic %d", i);
        NSString *payload = [NSString stringWithFormat:@"payload %d", i];
        [sendingSession publishAndWaitData:[payload dataUsingEncoding:NSUTF8StringEncoding] onTopic:TOPIC retain:false qos:qos];
    }
    [sendingSession closeAndWait];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    self.timedout = FALSE;
    [self performSelector:@selector(timedout:)
               withObject:nil
               afterDelay:[parameters[@"timeout"] intValue]];
    
    while (!self.timedout) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    
    [self shutdown:parameters
        returnCode:MQTTSuccess
sessionExpiryInterval:nil
      reasonString:nil
      userProperty:nil];
}

- (BOOL)newMessageWithFeedback:(MQTTSession *)session data:(NSData *)data onTopic:(NSString *)topic qos:(MQTTQosLevel)qos retained:(BOOL)retained mid:(unsigned int)mid {
    DDLogVerbose(@"newMessageWithFeedback(%lu):%@ onTopic:%@ qos:%d retained:%d mid:%d", (unsigned long)self.processed, data, topic, qos, retained, mid);
    if (self.processed > self.received - 10) {
        if (!retained && [topic isEqualToString:TOPIC]) {
            self.received++;
        }
        return true;
    } else {
        return false;
    }
}

- (void)connect:(NSDictionary *)parameters{
    self.session.delegate = self;
    self.event = -1;
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    self.timedout = FALSE;
    [self performSelector:@selector(timedout:)
               withObject:nil
               afterDelay:[parameters[@"timeout"] intValue]];
    
    [self.session connect];
    
    while (!self.timedout && self.event == -1) {
        DDLogVerbose(@"waiting for connection");
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
}

- (void)shutdown:(NSDictionary *)parameters
      returnCode:(MQTTReturnCode)returnCode
sessionExpiryInterval:(NSNumber *)sessionExpiryInterval
    reasonString:(NSString *)reasonString
    userProperty:(NSDictionary <NSString *, NSString *> *)userProperty {
    if (!self.ungraceful) {
        self.event = -1;
        
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        self.timedout = FALSE;
        [self performSelector:@selector(timedout:)
                   withObject:nil
                   afterDelay:[parameters[@"timeout"] intValue]];
        
        [self.session closeWithReturnCode:returnCode
                    sessionExpiryInterval:sessionExpiryInterval
                             reasonString:reasonString
                             userProperty:userProperty
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
}

@end
