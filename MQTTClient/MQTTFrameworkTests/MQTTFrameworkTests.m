//
//  MQTTFrameworkTests.m
//  MQTTFrameworkTests
//
//  Created by Christoph Krey on 21.01.16.
//  Copyright © 2016 Christoph Krey. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MQTTFramework.h"

@interface MQTTFrameworkTests : XCTestCase
@property (strong, nonatomic) MQTTSession *session;
@end

@implementation MQTTFrameworkTests

- (void)setUp {
    [super setUp];
    self.session = [[MQTTSession alloc] init];
    [self.session connectAndWaitTimeout:30];
}

- (void)tearDown {
    [self.session closeAndWait:30];
    [super tearDown];
}

- (void)testFramework {
    [self.session subscribeAndWaitToTopic:@"$SYS"
                                  atLevel:MQTTQosLevelAtMostOnce
                                  timeout:30];
}

@end
