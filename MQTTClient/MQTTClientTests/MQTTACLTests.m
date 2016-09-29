//
//  MQTTACLTests.m
//  MQTTClient
//
//  Created by Christoph Krey on 03.02.15.
//  Copyright © 2015-2016 Christoph Krey. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "MQTTLog.h"
#import "MQTTClient.h"
#import "MQTTTestHelpers.h"

@interface MQTTACLTests : MQTTTestHelpers
@end

@implementation MQTTACLTests

- (void)setUp {
    [super setUp];
    
#ifdef LUMBERJACK
    if (![[DDLog allLoggers] containsObject:[DDTTYLogger sharedInstance]])
    [DDLog addLogger:[DDTTYLogger sharedInstance] withLevel:DDLogLevelAll];
    if (![[DDLog allLoggers] containsObject:[DDASLLogger sharedInstance]])
    [DDLog addLogger:[DDASLLogger sharedInstance] withLevel:DDLogLevelWarning];
#endif

}

- (void)tearDown {
    [super tearDown];
}

/*
 * [MQTT-3.1.2-19]
 * If the User Name Flag is set to 1, a user name MUST be present in the payload.
 * [MQTT-3.1.2-21]
 * If the Password Flag is set to 1, a password MUST be present in the payload.
 */
- (void)test_connect_user_pwd_MQTT_3_1_2_19_MQTT_3_1_2_21 {
    for (NSString *broker in self.brokers.allKeys) {
        DDLogVerbose(@"testing broker %@", broker);
        NSDictionary *parameters = self.brokers[broker];
        self.session = [MQTTTestHelpers session:parameters];
        [self connect:self.session parameters:parameters];
        XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
        [self shutdown:parameters];
    }
}

/*
 * [MQTT-3.1.2-19]
 * If the User Name Flag is set to 1, a user name MUST be present in the payload.
 * [MQTT-3.1.2-20]
 * If the Password Flag is set to 0, a password MUST NOT be present in the payload.
 */
- (void)test_connect_user_no_pwd_MQTT_3_1_2_19_MQTT_3_1_2_20 {
    for (NSString *broker in self.brokers.allKeys) {
        DDLogVerbose(@"testing broker %@", broker);
        NSDictionary *parameters = self.brokers[broker];
        self.session = [MQTTTestHelpers session:parameters];
        self.session.userName = @"user w/o password";
        self.session.password = nil;

        [self connect:self.session parameters:parameters];
        XCTAssertEqual(self.event, MQTTSessionEventConnectionClosedByBroker, @"Not Connected %ld %@", (long)self.event, self.error);
        [self shutdown:parameters];
    }
}

/*
 * [MQTT-3.1.2-18]
 * If the User Name Flag is set to 0, a user name MUST NOT be present in the payload.
 * [MQTT-3.1.2-20]
 * If the Password Flag is set to 0, a password MUST NOT be present in the payload.
 */
- (void)test_connect_no_user_no_pwd_MQTT_3_1_2_18_MQTT_3_1_2_20 {
    for (NSString *broker in self.brokers.allKeys) {
        DDLogVerbose(@"testing broker %@", broker);
        NSDictionary *parameters = self.brokers[broker];
        self.session = [MQTTTestHelpers session:parameters];
        self.session.userName = nil;
        self.session.password = nil;

        [self connect:self.session parameters:parameters];
        XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
        [self shutdown:parameters];
    }
}

/*
 * [MQTT-3.1.2-22]
 * If the User Name Flag is set to 0, the Password Flag MUST be set to 0.
 */

- (void)test_connect_no_user_but_pwd_MQTT_3_1_2_22 {
    for (NSString *broker in self.brokers.allKeys) {
        DDLogVerbose(@"testing broker %@", broker);
        NSDictionary *parameters = self.brokers[broker];
        self.session = [MQTTTestHelpers session:parameters];
        self.session.userName = nil;
        self.session.password = @"password w/o user";

        [self connect:self.session parameters:parameters];
        XCTAssertEqual(self.event, MQTTSessionEventConnectionClosedByBroker, @"Not Rejected %ld %@", (long)self.event, self.error);
        [self shutdown:parameters];
    }
}
 
- (void)connect:(MQTTSession *)session parameters:(NSDictionary *)parameters{
    session.delegate = self;
    self.event = -1;
    self.timedout = FALSE;

    [self.session connect];

    [self performSelector:@selector(timedout:)
               withObject:nil
               afterDelay:[parameters[@"timeout"] intValue]];


    while (!self.timedout && self.event == -1) {
        DDLogVerbose(@"waiting for connection");
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
}

- (void)shutdown:(NSDictionary *)parameters {
    self.event = -1;

    self.timedout = FALSE;
    [self performSelector:@selector(timedout:)
               withObject:nil
               afterDelay:[parameters[@"timeout"] intValue]];

    [self.session close];

    while (self.event == -1 && !self.timedout) {
        DDLogVerbose(@"waiting for disconnect");
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }

    XCTAssert(!self.timedout, @"timeout");
    [NSObject cancelPreviousPerformRequestsWithTarget:self];

    self.session.delegate = nil;
    self.session = nil;
}

@end
