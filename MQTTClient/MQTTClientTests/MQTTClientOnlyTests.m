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

@interface MQTTClientOnlyTests : MQTTTestHelpers
@end

@implementation MQTTClientOnlyTests

- (void)tearDown {
    [self.session closeWithReturnCode:MQTTSuccess
                sessionExpiryInterval:nil
                         reasonString:nil
                         userProperty:nil
                    disconnectHandler:nil];
    self.session.delegate = nil;
    self.session = nil;
    
    [super tearDown];
}

- (void)testConnectToWrongHostResultsInError {
    XCTestExpectation *expectation = [self expectationWithDescription:@""];
    
    NSMutableDictionary *parameters = [MQTTTestHelpers.broker mutableCopy];
    
    parameters[@"host"] = @"abc";
    self.session = [MQTTTestHelpers session:parameters];
    [self.session connectWithConnectHandler:^(NSError *error) {
        XCTAssertNotNil(error);
        XCTAssertEqual(self.session.status, MQTTSessionStatusClosed);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:10 handler:nil];
    
}

- (void)testConnectToWrongPort1884ResultsInError {
    XCTestExpectation *expectation = [self expectationWithDescription:@""];
    
    NSMutableDictionary *parameters = [MQTTTestHelpers.broker mutableCopy];
    
    parameters[@"port"] = @1884;
    self.session = [MQTTTestHelpers session:parameters];
    [self.session connectWithConnectHandler:^(NSError *error) {
        XCTAssertNotNil(error);
        XCTAssertEqual(self.session.status, MQTTSessionStatusClosed);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:10 handler:nil];
    
}

@end
