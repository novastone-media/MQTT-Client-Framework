//
//  MQTTTestBlocks.m
//  MQTTClient
//
//  Created by Christoph Krey on 11.11.15.
//  Copyright © 2015-2017 Christoph Krey. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "MQTTLog.h"
#import "MQTTTestHelpers.h"
#import "MQTTStrict.h"

@interface MQTTTestBlocks : MQTTTestHelpers
@end

@implementation MQTTTestBlocks

- (void)setUp {
    [super setUp];
    MQTTStrict.strict = NO;
}

- (void)testBlockPublishSuccess {
    NSDictionary *parameters = MQTTTestHelpers.broker;
    self.session = [MQTTTestHelpers session:parameters];
    self.session.delegate = self;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@""];
    [self.session connectWithConnectHandler:^(NSError *error) {
        DDLogVerbose(@"connectHandler error:%@", error.localizedDescription);
        XCTAssertEqual(error, nil, @"Connect error %@", error.localizedDescription);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:60 handler:nil];
    
    int pubs = 0;
    __block int delivered = 0;
    for (int i = 0; i < BULK; i++) {
        __block NSString *payload = [NSString stringWithFormat:@"Payload Qos0 %d", i];
        [self.session publishData:[payload dataUsingEncoding:NSUTF8StringEncoding]
                          onTopic:payload
                           retain:FALSE
                              qos:MQTTQosLevelAtMostOnce
                   publishHandler:^(NSError *error){
                       if (error) {
                           DDLogVerbose(@"error: %@ %@", error.localizedDescription, payload);
                       } else {
                           DDLogVerbose(@"delivered:%@", payload);
                           delivered++;
                       }
                   }];
        pubs++;
    }
    for (int i = 0; i < BULK; i++) {
        __block NSString *payload = [NSString stringWithFormat:@"Payload Qos1 %d", i];
        __block UInt16 mid = [self.session publishData:[payload dataUsingEncoding:NSUTF8StringEncoding]
                                               onTopic:payload
                                                retain:FALSE
                                                   qos:MQTTQosLevelAtLeastOnce
                                        publishHandler:^(NSError *error){
                                            if (error) {
                                                DDLogVerbose(@"error: %@ %@", error.localizedDescription, payload);
                                            } else {
                                                DDLogVerbose(@"%u delivered:%@", mid, payload);
                                                delivered++;
                                            }
                                        }];
        pubs++;
    }
    for (int i = 0; i < BULK; i++) {
        __block NSString *payload = [NSString stringWithFormat:@"Payload Qos2 %d", i];
        __block UInt16 mid = [self.session publishData:[payload dataUsingEncoding:NSUTF8StringEncoding]
                                               onTopic:payload
                                                retain:FALSE
                                                   qos:MQTTQosLevelExactlyOnce
                                        publishHandler:^(NSError *error){
                                            if (error) {
                                                DDLogVerbose(@"error: %@ %@", error.localizedDescription, payload);
                                            } else {
                                                DDLogVerbose(@"%u delivered:%@", mid, payload);
                                                delivered++;
                                            }
                                        }];
        pubs++;
    }
    
    while (delivered < pubs && !self.timedout) {
        DDLogVerbose(@"waiting for delivery %d/%d", delivered, pubs);
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    
    XCTestExpectation *closeExpectation = [self expectationWithDescription:@""];
    [self.session closeWithDisconnectHandler:^(NSError *error) {
        [closeExpectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)testBlockSubscribeSuccess {
    NSDictionary *parameters = MQTTTestHelpers.broker;
    
    self.session = [MQTTTestHelpers session:parameters];
    self.session.delegate = self;
    
    __block int subs = 0;
    
    [self.session connectWithConnectHandler:^(NSError *error) {
        DDLogVerbose(@"connectHandler error:%@", error.localizedDescription);
        XCTAssertEqual(error, nil, @"Connect error %@", error.localizedDescription);
        if (!error) {
            __block UInt16 mid1 = [self.session subscribeToTopic:@"$SYS/#"
                                                         atLevel:2
                                                subscribeHandler:^(NSError *error, NSArray *grantedQos) {
                                                    subs++;
                                                    if (!error) {
                                                        DDLogVerbose(@"%u Granted qoss:%@", mid1, grantedQos);
                                                    } else {
                                                        DDLogVerbose(@"%u Subscribe with error:%@", mid1, error.localizedDescription);
                                                    }
                                                }];
            __block UInt16 mid2 = [self.session subscribeToTopic:TOPIC
                                                         atLevel:2
                                                subscribeHandler:^(NSError *error, NSArray *grantedQos) {
                                                    subs++;
                                                    if (!error) {
                                                        DDLogVerbose(@"%u Granted qoss:%@", mid2, grantedQos);
                                                    } else {
                                                        DDLogVerbose(@"%u Subscribe with error:%@", mid2, error.localizedDescription);
                                                    }
                                                }];
            __block UInt16 mid3 = [self.session subscribeToTopic:@"abc"
                                                         atLevel:2
                                                subscribeHandler:^(NSError *error, NSArray *grantedQos) {
                                                    subs++;
                                                    if (!error) {
                                                        DDLogVerbose(@"%u Granted qoss:%@", mid3, grantedQos);
                                                    } else {
                                                        DDLogVerbose(@"%u Subscribe with error:%@", mid3, error.localizedDescription);
                                                    }
                                                }];
        }
    }];
    
    while (subs < 3) {
        DDLogVerbose(@"waiting for 3 subs");
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    
    XCTestExpectation *expectation = [self expectationWithDescription:@""];
    [self.session closeWithDisconnectHandler:^(NSError *error) {
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)testBlockQueued {
    NSDictionary *parameters = MQTTTestHelpers.broker;
    
    self.session = [MQTTTestHelpers session:parameters];
    self.session.delegate = self;
    self.session.cleanSessionFlag = FALSE;
    self.session.clientId = @"subscriber";
    
    [self.session connectWithConnectHandler:^(NSError *error) {
        DDLogVerbose(@"connectHandler error:%@", error.localizedDescription);
        XCTAssertEqual(error, nil, @"Connect error %@", error.localizedDescription);
        if (!error) {
            __block UInt16 mid1 = [self.session subscribeToTopic:@"subscriber"
                                                         atLevel:1
                                                subscribeHandler:^(NSError *error, NSArray *grantedQos) {
                                                    if (!error) {
                                                        DDLogVerbose(@"%u Granted qoss:%@", mid1, grantedQos);
                                                    } else {
                                                        DDLogVerbose(@"%u Subscribe with error:%@", mid1, error.localizedDescription);
                                                    }
                                                    
                                                }];
        }
    }];
    
    DDLogVerbose(@"waiting for sub");
    
    [[NSRunLoop currentRunLoop] runUntilDate:[[NSDate date] dateByAddingTimeInterval:5.0]];
    
    DDLogVerbose(@"aborting");
}

- (void)testBlockSubscribeFail {
    NSDictionary *parameters = MQTTTestHelpers.broker;
    
    self.session = [MQTTTestHelpers session:parameters];
    self.session.delegate = self;
    
    XCTestExpectation *expectation1 = [self expectationWithDescription:@""];
    [self.session connectWithConnectHandler:^(NSError *error) {
        XCTAssertNil(error);
        [expectation1 fulfill];
    }];
    [self waitForExpectationsWithTimeout:10 handler:nil];
    
    XCTestExpectation *expectation2 = [self expectationWithDescription:@""];
    [self.session subscribeToTopic:@"$SYS/#/ABC"
                           atLevel:2
                  subscribeHandler:^(NSError *error, NSArray *grantedQos) {
                      [expectation2 fulfill];
                      XCTAssertNotNil(error);
                  }];
    [self waitForExpectationsWithTimeout:10 handler:nil];
    
    XCTestExpectation *expectation3 = [self expectationWithDescription:@""];
    [self.session closeWithDisconnectHandler:^(NSError *error){
        XCTAssertNil(error);
        [expectation3 fulfill];
    }];
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)testBlockConnect {
    NSDictionary *parameters = MQTTTestHelpers.broker;
    
    self.session = [MQTTTestHelpers session:parameters];
    self.session.delegate = self;
    
    __block BOOL closed = false;
    
    [self.session connectWithConnectHandler:^(NSError *error){
        DDLogVerbose(@"connectHandler error:%@", error.localizedDescription);
        XCTAssertEqual(error, nil, @"Connect error %@", error.localizedDescription);
        if (!error) {
            [self.session closeWithDisconnectHandler:^(NSError *error){
                DDLogVerbose(@"Closed with error:%@", error ? error.localizedDescription : @"none");
                closed = true;
            }];
        }
    }];
    
    while (!closed) {
        DDLogVerbose(@"waiting for connect and close");
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
}

- (void)testBlockConnectUnknownHost {
    NSMutableDictionary *parameters = [MQTTTestHelpers.broker mutableCopy];
    
    parameters[@"host"] = @"abc";
    self.session = [MQTTTestHelpers session:parameters];
    self.session.delegate = self;
    
    __block BOOL closed = false;
    
    [self.session connectWithConnectHandler:^(NSError *error){
        XCTAssertNotEqual(error, nil, @"No error detected");
        [self.session closeWithDisconnectHandler:^(NSError *error){
            DDLogVerbose(@"Closed with error:%@", error ? error.localizedDescription : @"none");
            closed = true;
        }];
    }];
    
    while (!closed) {
        DDLogVerbose(@"waiting for connect and close");
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
}

- (void)testBlockConnectRefused {
    NSMutableDictionary *parameters = [MQTTTestHelpers.broker mutableCopy];
    parameters[@"port"] = @1998;
    self.session = [MQTTTestHelpers session:parameters];
    self.session.delegate = self;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@""];
    [self.session connectWithConnectHandler:^(NSError *error) {
        XCTAssertNotNil(error);
        [self.session closeWithDisconnectHandler:^(NSError *error){
            DDLogVerbose(@"Closed with error:%@", error ? error.localizedDescription : @"none");
            [expectation fulfill];
        }];
    }];
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

@end
