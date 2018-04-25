//
//  ReconnectTimerTests.m
//  MQTTClient
//
//  Created by Josip Cavar on 22/08/2017.
//  Copyright © 2017 Christoph Krey. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ReconnectTimer.h"

@interface ReconnectTimerTests : XCTestCase

@end

@implementation ReconnectTimerTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testReconnectBlockCalledAfterRetryInterval {
    XCTestExpectation *expectation = [self expectationWithDescription:@""];
    
    NSDate *startDate = [NSDate date];
    ReconnectTimer *timer = [[ReconnectTimer alloc] initWithRetryInterval:1
                                                         maxRetryInterval:5
                                                                    queue:dispatch_get_main_queue()
                                                           reconnectBlock:^{
                                                               NSTimeInterval difference = [[NSDate date] timeIntervalSinceDate:startDate];
                                                               XCTAssertEqualWithAccuracy(difference, 1, 0.1, "Reconnect block should be called after 1 second");
                                                               [expectation fulfill];
                                                           }];
    [timer schedule];
    
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testReconnectRetryIntervalIncreased {
    XCTestExpectation *expectation = [self expectationWithDescription:@""];
    
    __block NSDate *startDate = [NSDate date];
    __block BOOL isFirst = YES;
    ReconnectTimer *timer = [[ReconnectTimer alloc] initWithRetryInterval:1
                                                         maxRetryInterval:2
                                                                    queue:dispatch_get_main_queue()
                                                           reconnectBlock:^{
                                                               NSTimeInterval difference = [[NSDate date] timeIntervalSinceDate:startDate];
                                                               if (isFirst) {
                                                                   isFirst = NO;
                                                               } else {
                                                                   XCTAssertEqualWithAccuracy(difference, 2, 0.1, "Reconnect block should be called after 2 second next time");
                                                                   [expectation fulfill];
                                                               }
                                                           }];
    [timer schedule];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        startDate = [NSDate date];
        [timer schedule];
    });
    
    [self waitForExpectationsWithTimeout:5 handler:nil];
}

@end
