//
//  MQTTCFSocketTransportTests.m
//  MQTTClientTests
//
//  Created by Rob Nadin on 12/02/2020.
//  Copyright © 2020 Christoph Krey. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "MQTTCFSocketTransport.h"
#import "MQTTTestHelpers.h"

@interface MQTTCFSocketTransportTests : MQTTTestHelpers
@property (strong, nonatomic) MQTTCFSocketTransport *transport;
@end

@implementation MQTTCFSocketTransportTests

- (void)setUp {
    [super setUp];
    self.transport = [MQTTCFSocketTransport new];
}

- (void)tearDown {
    [self.session closeWithReturnCode:MQTTSuccess
                sessionExpiryInterval:nil
                         reasonString:nil
                         userProperty:nil
                    disconnectHandler:nil];
    self.session.delegate = nil;
    self.session = nil;
    self.transport = nil;
    
    [super tearDown];
}

- (void)testAllowsCellularAccessDefaultIsTrue {
    XCTAssertTrue(self.transport.allowsCellularAccess);
}

- (void)testConnectSessionDoesNotError {
    NSDictionary *parameters = MQTTTestHelpers.broker;
    self.transport.allowsCellularAccess = NO;
    self.transport.host = parameters[@"host"];
    self.transport.port = [parameters[@"port"] intValue];
    self.transport.tls = [parameters[@"tls"] boolValue];
    
    self.session = [[MQTTSession alloc] init];
    self.session.transport = self.transport;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@""];
    [self.session connectWithConnectHandler:^(NSError *error) {
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:[parameters[@"timeout"] intValue] handler:nil];
}

@end
