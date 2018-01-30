//
//  MQTTSessionTests.m
//  MQTTClient
//
//  Created by Josip Cavar on 30/10/2017.
//  Copyright © 2017 Christoph Krey. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MQTTSession.h"
#import "MQTTSSLSecurityPolicyTransport.h"
#import "MQTTTestHelpers.h"

@interface MQTTSessionTests : XCTestCase

@end

@implementation MQTTSessionTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testConnectToTLSServer {
    XCTestExpectation *expectation = [self expectationWithDescription:@""];
    NSDictionary *parameters = MQTTTestHelpers.allBrokers[@"mosquittoTLS"];
    
    __block MQTTSession *session = [MQTTTestHelpers session:parameters];
    [session connectWithConnectHandler:^(NSError *error) {
        XCTAssertNil(error);
        XCTAssertEqual(session.status, MQTTSessionStatusConnected);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:40 handler:nil];
}

- (void)testErrorWhenConnectsToTLSServerWithoutCertificate {
    XCTestExpectation *expectation = [self expectationWithDescription:@""];
    NSDictionary *parameters = MQTTTestHelpers.allBrokers[@"mosquittoTLS"];
    
    __block MQTTSession *session = [MQTTTestHelpers session:parameters];
    ((MQTTSSLSecurityPolicyTransport *)session.transport).securityPolicy.pinnedCertificates = @[];
    [session connectWithConnectHandler:^(NSError *error) {
        XCTAssertNotNil(error);
        XCTAssertEqual(session.status, MQTTSessionStatusClosed);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:40 handler:nil];
}

- (void)testConnectDisconnectMultipleTimes {
    // Test for https://github.com/novastone-media/MQTT-Client-Framework/issues/325
    // Connection is performed on background queue
    // We set session = nil on main queue which releases session and makes it dealloc
    for (int i = 0; i < 20; i++) {
        XCTestExpectation *expectation = [self expectationWithDescription:@""];
        NSDictionary *parameters = MQTTTestHelpers.brokers[@"mosquitto"];
        dispatch_queue_t background = dispatch_queue_create("background", NULL);
        
        __block MQTTSession *session = [MQTTTestHelpers session:parameters];
        session.queue = background;
        [session connectWithConnectHandler:^(NSError *error) {
            XCTAssertNil(error);
            XCTAssertEqual(session.status, MQTTSessionStatusConnected);
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                session = nil;
                [expectation fulfill];
            }];
        }];
        [self waitForExpectationsWithTimeout:40 handler:nil];
    }
}

- (void)testMQTTSessionDestroyedWhenDeallocated {
    __weak MQTTSession *weakSession = nil;
    @autoreleasepool {
        MQTTSession *session = [[MQTTSession alloc] init];
        weakSession = session;
        session.transport = [[MQTTSSLSecurityPolicyTransport alloc] init];
        [session connect];
    }
    XCTAssertNil(weakSession);
}

@end
