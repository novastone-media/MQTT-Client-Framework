//
//  MQTTClientTests.m
//  MQTTClientTests
//
//  Created by Christoph Krey on 13.01.14.
//  Copyright © 2014-2016 Christoph Krey. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "MQTTLog.h"
#import "MQTTClient.h"
#import "MQTTTestHelpers.h"

@interface MQTTClientOnlyTests : MQTTTestHelpers
@end

@implementation MQTTClientOnlyTests

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
    [self.session close];
    self.session.delegate = nil;
    self.session = nil;

    [super tearDown];
}

- (void)test_connect_host_not_found {
    for (NSString *broker in self.brokers.allKeys) {
        DDLogVerbose(@"testing broker %@", broker);
        NSMutableDictionary *parameters = [self.brokers[broker] mutableCopy];
        
        [parameters setObject:@"abc" forKey:@"host"];
        self.session = [MQTTTestHelpers session:parameters];
        self.session.delegate = self;
        self.event = -1;
        [self.session connect];
        while (self.event == -1) {
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }
        XCTAssertNotEqual(self.event, (NSInteger)MQTTSessionEventConnected, @"MQTTSessionEventConnected %@", self.error);
        XCTAssertNotEqual(self.event, (NSInteger)MQTTSessionEventConnectionRefused, @"MQTTSessionEventConnectionRefused %@", self.error);
        XCTAssertNotEqual(self.event, (NSInteger)MQTTSessionEventProtocolError, @"MQTTSessionEventProtocolError %@", self.error);
    }
}


- (void)test_connect_1889 {
    for (NSString *broker in self.brokers.allKeys) {
        DDLogVerbose(@"testing broker %@", broker);
        NSMutableDictionary *parameters = [self.brokers[broker] mutableCopy];
        
        [parameters setObject:@1889 forKey:@"port"];

        self.session = [MQTTTestHelpers session:parameters];
        self.session.delegate = self;
        self.event = -1;
        [self.session connect];
        while (self.event == -1) {
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }
        XCTAssertNotEqual(self.event, (NSInteger)MQTTSessionEventConnected, @"MQTTSessionEventConnected %@", self.error);
        XCTAssertNotEqual(self.event, (NSInteger)MQTTSessionEventConnectionRefused, @"MQTTSessionEventConnectionRefused %@", self.error);
        XCTAssertNotEqual(self.event, (NSInteger)MQTTSessionEventProtocolError, @"MQTTSessionEventProtocolErrorr %@", self.error);
    }
}

@end
