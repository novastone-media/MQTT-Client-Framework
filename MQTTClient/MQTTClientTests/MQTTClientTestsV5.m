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
    XCTestExpectation *connectExpectation = [self expectationWithDescription:@""];
    [self.session connectWithConnectHandler:^(NSError *error) {
        [connectExpectation fulfill];
    }];
    NSTimeInterval timeout = [parameters[@"timeout"] doubleValue];
    [self waitForExpectationsWithTimeout:timeout handler:nil];
}

- (void)shutdown:(NSDictionary *)parameters
      returnCode:(MQTTReturnCode)returnCode
sessionExpiryInterval:(NSNumber *)sessionExpiryInterval
    reasonString:(NSString *)reasonString
    userProperty:(NSDictionary <NSString *, NSString *> *)userProperty {
    if (!self.ungraceful) {
        self.event = -1;
        
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        XCTestExpectation *expectation = [self expectationWithDescription:@""];
        [self.session closeWithReturnCode:returnCode
                    sessionExpiryInterval:sessionExpiryInterval
                             reasonString:reasonString
                             userProperty:userProperty
                        disconnectHandler:^(NSError *error) {
                            XCTAssertNil(error);
                            [expectation fulfill];
                        }];
        int timeout = [parameters[@"timeout"] intValue];
        [self waitForExpectationsWithTimeout:timeout handler:nil];
        
        [NSObject cancelPreviousPerformRequestsWithTarget:self];        
        self.session.delegate = nil;
        self.session = nil;
    }
}

@end
