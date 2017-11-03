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

@interface MQTTSessionTests : XCTestCase

@end

@implementation MQTTSessionTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
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
