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
#import "MQTTLog.h"

@interface MQTTSessionTests : XCTestCase

@end

@implementation MQTTSessionTests

- (void)testConnectToTLSServer {
    XCTestExpectation *expectation = [self expectationWithDescription:@""];
    NSDictionary *parameters = MQTTTestHelpers.allBrokers[@"localTLS"];
    
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
    NSDictionary *parameters = MQTTTestHelpers.allBrokers[@"localTLS"];
    
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
    for (int i = 0; i < 100; i++) {
        XCTestExpectation *expectation = [self expectationWithDescription:@""];
        NSDictionary *parameters = MQTTTestHelpers.broker;
        dispatch_queue_t background = dispatch_queue_create("background", NULL);
        
        __block MQTTSession *session = [MQTTTestHelpers session:parameters];
        session.cleanSessionFlag = YES;
        session.queue = background;
        NSLog(@"[XY] connect");
        [session connectWithConnectHandler:^(NSError *error) {
            NSLog(@"[XY] connected");
            XCTAssertNil(error);
            XCTAssertEqual(session.status, MQTTSessionStatusConnected);
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                NSLog(@"[XY] destory session");
                session = nil;
                [expectation fulfill];
            }];
        }];
        NSLog(@"[XY] wait for expecation");
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
