//
//  MQTTTestBlocks.m
//  MQTTClient
//
//  Created by Christoph Krey on 11.11.15.
//  Copyright © 2015-2016 Christoph Krey. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "MQTTLog.h"
#import "MQTTClient.h"
#import "MQTTTestHelpers.h"

@interface MQTTTestBlocks : MQTTTestHelpers
@end

@implementation MQTTTestBlocks

- (void)testBlockPublishSuccess {
    for (NSString *broker in self.brokers.allKeys) {
        DDLogVerbose(@"testing broker %@", broker);
        NSDictionary *parameters = self.brokers[broker];
        self.session = [MQTTTestHelpers session:parameters];
        self.session.delegate = self;
        self.timedout = FALSE;
        [self performSelector:@selector(timedout:) withObject:nil afterDelay:60];
        
        __block BOOL connected = false;
        
        [self.session connectWithConnectHandler:^(NSError *error) {
            DDLogVerbose(@"connectHandler error:%@", error.localizedDescription);
            XCTAssertEqual(error, nil, @"Connect error %@", error.localizedDescription);
            if (!error) {
                connected = true;
            }
        }];
        
        while (!connected && !self.timedout) {
            DDLogVerbose(@"waiting for connect");
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }
        
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
        
        __block BOOL closed = false;
        [self.session closeWithDisconnectHandler:^(NSError *error){
            DDLogVerbose(@"Closed with error:%@", error ? error.localizedDescription : @"none");
            closed = true;
        }];
        
        while (!closed && !self.timedout) {
            DDLogVerbose(@"waiting for close");
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }
    }
}

- (void)testBlockSubscribeSuccess {
    for (NSString *broker in self.brokers.allKeys) {
        DDLogVerbose(@"testing broker %@", broker);
        NSDictionary *parameters = self.brokers[broker];
        
        self.session = [MQTTTestHelpers session:parameters];
        self.session.delegate = self;
        
        __block int subs = 0;
        __block BOOL closed = false;
        
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
        
        [self.session closeWithDisconnectHandler:^(NSError *error){
            DDLogVerbose(@"Closed with error:%@", error ? error.localizedDescription : @"none");
            closed = true;
        }];
        
        while (!closed) {
            DDLogVerbose(@"waiting for close");
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }
    }
}

- (void)testBlockQueued {
    for (NSString *broker in self.brokers.allKeys) {
        DDLogVerbose(@"testing broker %@", broker);
        NSDictionary *parameters = self.brokers[broker];
        
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
}

- (void)testBlockSubscribeFail {
    for (NSString *broker in self.brokers.allKeys) {
        DDLogVerbose(@"testing broker %@", broker);
        NSDictionary *parameters = self.brokers[broker];
        
        self.session = [MQTTTestHelpers session:parameters];
        self.session.delegate = self;
        
        __block BOOL closed = false;
        
        [self.session connectWithConnectHandler:^(NSError *error) {
                         DDLogVerbose(@"connectHandler error:%@", error.localizedDescription);
                         XCTAssertEqual(error, nil, @"Connect error %@", error.localizedDescription);
                         if (!error) {
                             __block UInt16 mid = [self.session subscribeToTopic:@"$SYS/#/ABC"
                                                                         atLevel:2
                                                                subscribeHandler:^(NSError *error, NSArray *grantedQos) {
                                                                    if (!error) {
                                                                        DDLogVerbose(@"%d Granted qoss:%@", mid, grantedQos);
                                                                    } else {
                                                                        DDLogVerbose(@"%d Subscribe with error:%@", mid, error.localizedDescription);
                                                                    }
                                                                    
                                                                    [self.session closeWithDisconnectHandler:^(NSError *error){
                                                                        DDLogVerbose(@"Closed with error:%@", error ? error.localizedDescription : @"none");
                                                                        closed = true;
                                                                    }];
                                                                }];
                         }
                     }];
        
        while (!closed) {
            DDLogVerbose(@"waiting for close");
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }
    }
}

- (void)testBlockConnect {
    for (NSString *broker in self.brokers.allKeys) {
        DDLogVerbose(@"testing broker %@", broker);
        NSDictionary *parameters = self.brokers[broker];
        
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
}

- (void)testBlockConnectUnknownHost {
    for (NSString *broker in self.brokers.allKeys) {
        DDLogVerbose(@"testing broker %@", broker);
        NSMutableDictionary *parameters = self.brokers[broker];
        
        [parameters setObject:@"abc" forKey:@"host"];
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
}

- (void)testBlockConnectRefused {
    for (NSString *broker in self.brokers.allKeys) {
        DDLogVerbose(@"testing broker %@", broker);
        NSMutableDictionary *parameters = self.brokers[broker];
        
        [parameters setObject:@1998 forKey:@"port"];
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
}

@end
