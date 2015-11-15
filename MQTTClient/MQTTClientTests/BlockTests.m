//
//  BlockTests.m
//  MQTTClient
//
//  Created by Christoph Krey on 11.11.15.
//  Copyright © 2015 Christoph Krey. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MQTTClient.h"
#import "MQTTClientTests.h"

@interface BlockTests : XCTestCase <MQTTSessionDelegate>
@property (strong, nonatomic) MQTTSession *session;
@property (nonatomic) BOOL timedout;
@property (strong, nonatomic) NSTimer *timer;


@end

@implementation BlockTests

- (void)setUp {
    [super setUp];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1
                                                  target:self
                                                selector:@selector(ticker:)
                                                userInfo:@"block"
                                                 repeats:true];
    
}

- (void)tearDown {
    [self.timer invalidate];
    [super tearDown];
}


- (void)ticker:(NSTimer *)timer {
    NSLog(@"ticker %@", timer.userInfo);
}

- (void)timedout:(id)object {
    NSLog(@"timedout");
    self.timedout = TRUE;
}

- (void)messageDelivered:(MQTTSession *)session msgID:(UInt16)msgID {
    NSLog(@"messageDelivered %d", msgID);
}

#define N 100

- (void)testBlockPublishSuccess
{
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        self.session = [[MQTTSession alloc] initWithClientId:@"MQTTClientBlocks"
                                                    userName:parameters[@"user"]
                                                    password:parameters[@"pass"]
                                                   keepAlive:20
                                                cleanSession:YES
                                                        will:NO
                                                   willTopic:nil
                                                     willMsg:nil
                                                     willQoS:0
                                              willRetainFlag:NO
                                               protocolLevel:[parameters[@"protocollevel"] intValue]
                                                     runLoop:[NSRunLoop currentRunLoop]
                                                     forMode:NSRunLoopCommonModes
                                              securityPolicy:[self securityPolicy:parameters]
                                                certificates:[self clientCerts:parameters]];
        self.session.delegate = self;
        self.timedout = FALSE;
        [self performSelector:@selector(timedout:) withObject:nil afterDelay:60];

        __block BOOL connected = false;
        
        [self.session connectToHost:parameters[@"host"]
                               port:[parameters[@"port"] intValue]
                           usingSSL:[parameters[@"tls"] boolValue]
                     connectHandler:^(NSError *error) {
                         NSLog(@"connectHandler error:%@", error.localizedDescription);
                         XCTAssertEqual(error, nil, @"Connect error %@", error.localizedDescription);
                         if (!error) {
                             connected = true;
                         }
                     }];
        
        while (!connected && !self.timedout) {
            NSLog(@"waiting for connect");
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }

        int pubs = 0;
        __block int delivered = 0;
        for (int i = 0; i < N; i++) {
            __block NSString *payload = [NSString stringWithFormat:@"Payload Qos0 %d", i];
            [self.session publishData:[payload dataUsingEncoding:NSUTF8StringEncoding]
                              onTopic:payload
                               retain:FALSE
                                  qos:MQTTQosLevelAtMostOnce
                       publishHandler:^(NSError *error){
                           if (error) {
                               NSLog(@"error: %@ %@", error.localizedDescription, payload);
                           } else {
                               NSLog(@"delivered:%@", payload);
                               delivered++;
                           }
                       }];
            pubs++;
        }
        for (int i = 0; i < N; i++) {
            __block NSString *payload = [NSString stringWithFormat:@"Payload Qos1 %d", i];
            __block UInt16 mid = [self.session publishData:[payload dataUsingEncoding:NSUTF8StringEncoding]
                                                   onTopic:payload
                                                    retain:FALSE
                                                       qos:MQTTQosLevelAtLeastOnce
                                            publishHandler:^(NSError *error){
                                                if (error) {
                                                    NSLog(@"error: %@ %@", error.localizedDescription, payload);
                                                } else {
                                                    NSLog(@"%u delivered:%@", mid, payload);
                                                    delivered++;
                                                }
                                            }];
            pubs++;
        }
        for (int i = 0; i < N; i++) {
            __block NSString *payload = [NSString stringWithFormat:@"Payload Qos2 %d", i];
            __block UInt16 mid = [self.session publishData:[payload dataUsingEncoding:NSUTF8StringEncoding]
                                                   onTopic:payload
                                                    retain:FALSE
                                                       qos:MQTTQosLevelExactlyOnce
                                            publishHandler:^(NSError *error){
                                                if (error) {
                                                    NSLog(@"error: %@ %@", error.localizedDescription, payload);
                                                } else {
                                                    NSLog(@"%u delivered:%@", mid, payload);
                                                    delivered++;
                                                }
                                            }];
            pubs++;
        }

        while (delivered < pubs && !self.timedout) {
            NSLog(@"waiting for delivery %d/%d", delivered, pubs);
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }
        
        __block BOOL closed = false;
        [self.session closeWithDisconnectHandler:^(NSError *error){
            NSLog(@"Closed with error:%@", error ? error.localizedDescription : @"none");
            closed = true;
        }];
        
        while (!closed && !self.timedout) {
            NSLog(@"waiting for close");
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }
    }
}






- (void)testBlockSubscribeSuccess
{
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        self.session = [[MQTTSession alloc] initWithClientId:@"MQTTClientBlocks"
                                                    userName:parameters[@"user"]
                                                    password:parameters[@"pass"]
                                                   keepAlive:60
                                                cleanSession:YES
                                                        will:NO
                                                   willTopic:nil
                                                     willMsg:nil
                                                     willQoS:0
                                              willRetainFlag:NO
                                               protocolLevel:[parameters[@"protocollevel"] intValue]
                                                     runLoop:[NSRunLoop currentRunLoop]
                                                     forMode:NSRunLoopCommonModes
                                              securityPolicy:[self securityPolicy:parameters]
                                                certificates:[self clientCerts:parameters]];
        self.session.delegate = self;
        
        __block int subs = 0;
        __block BOOL closed = false;
        
        [self.session connectToHost:parameters[@"host"]
                               port:[parameters[@"port"] intValue]
                           usingSSL:[parameters[@"tls"] boolValue]
                     connectHandler:^(NSError *error) {
                         NSLog(@"connectHandler error:%@", error.localizedDescription);
                         XCTAssertEqual(error, nil, @"Connect error %@", error.localizedDescription);
                         if (!error) {
                         __block UInt16 mid1 = [self.session subscribeToTopic:@"$SYS/#"
                                                                      atLevel:2
                                                             subscribeHandler:^(NSError *error, NSArray *grantedQos) {
                                                                 if (!error) {
                                                                     NSLog(@"%u Granted qoss:%@", mid1, grantedQos);
                                                                     subs++;
                                                                 } else {
                                                                     NSLog(@"%u Subscribe with error:%@", mid1, error.localizedDescription);
                                                                 }
                                                             }];
                         __block UInt16 mid2 = [self.session subscribeToTopic:@"#"
                                                                      atLevel:2
                                                             subscribeHandler:^(NSError *error, NSArray *grantedQos) {
                                                                 if (!error) {
                                                                     NSLog(@"%u Granted qoss:%@", mid2, grantedQos);
                                                                     subs++;
                                                                 } else {
                                                                     NSLog(@"%u Subscribe with error:%@", mid2, error.localizedDescription);
                                                                 }
                                                             }];
                         __block UInt16 mid3 = [self.session subscribeToTopic:@"abc"
                                                                      atLevel:2
                                                             subscribeHandler:^(NSError *error, NSArray *grantedQos) {
                                                                 if (!error) {
                                                                     NSLog(@"%u Granted qoss:%@", mid3, grantedQos);
                                                                     subs++;
                                                                 } else {
                                                                     NSLog(@"%u Subscribe with error:%@", mid3, error.localizedDescription);
                                                                 }
                                                             }];
                         }
                     }];
        
        while (subs < 3) {
            NSLog(@"waiting for 3 subs");
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }
        
        [self.session closeWithDisconnectHandler:^(NSError *error){
            NSLog(@"Closed with error:%@", error ? error.localizedDescription : @"none");
            closed = true;
        }];
        
        while (!closed) {
            NSLog(@"waiting for close");
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }
    }
}






- (void)testBlockSubscribeFail
{
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        self.session = [[MQTTSession alloc] initWithClientId:@"MQTTClientBlocks"
                                                    userName:parameters[@"user"]
                                                    password:parameters[@"pass"]
                                                   keepAlive:60
                                                cleanSession:YES
                                                        will:NO
                                                   willTopic:nil
                                                     willMsg:nil
                                                     willQoS:0
                                              willRetainFlag:NO
                                               protocolLevel:[parameters[@"protocollevel"] intValue]
                                                     runLoop:[NSRunLoop currentRunLoop]
                                                     forMode:NSRunLoopCommonModes
                                              securityPolicy:[self securityPolicy:parameters]
                                                certificates:[self clientCerts:parameters]];
        self.session.delegate = self;
        
        __block BOOL closed = false;
        
        [self.session connectToHost:parameters[@"host"]
                               port:[parameters[@"port"] intValue]
                           usingSSL:[parameters[@"tls"] boolValue]
                     connectHandler:^(NSError *error) {
                         NSLog(@"connectHandler error:%@", error.localizedDescription);
                         XCTAssertEqual(error, nil, @"Connect error %@", error.localizedDescription);
                         if (!error) {
                         __block UInt16 mid = [self.session subscribeToTopic:@"$SYS/#/ABC"
                                                                     atLevel:2
                                                            subscribeHandler:^(NSError *error, NSArray *grantedQos) {
                                                                if (!error) {
                                                                    NSLog(@"%d Granted qoss:%@", mid, grantedQos);
                                                                } else {
                                                                    NSLog(@"%d Subscribe with error:%@", mid, error.localizedDescription);
                                                                }
                                                                [self.session closeWithDisconnectHandler:^(NSError *error){
                                                                    NSLog(@"Closed with error:%@", error ? error.localizedDescription : @"none");
                                                                    closed = true;
                                                                }];
                                                            }];
                         }
                     }];
        
        while (!closed) {
            NSLog(@"waiting for close");
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }
    }
}





- (void)testBlockConnect
{
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        self.session = [[MQTTSession alloc] initWithClientId:@"MQTTClientBlocks"
                                                    userName:parameters[@"user"]
                                                    password:parameters[@"pass"]
                                                   keepAlive:60
                                                cleanSession:YES
                                                        will:NO
                                                   willTopic:nil
                                                     willMsg:nil
                                                     willQoS:0
                                              willRetainFlag:NO
                                               protocolLevel:[parameters[@"protocollevel"] intValue]
                                                     runLoop:[NSRunLoop currentRunLoop]
                                                     forMode:NSRunLoopCommonModes
                                              securityPolicy:[self securityPolicy:parameters]
                                                certificates:[self clientCerts:parameters]];
        self.session.delegate = self;
        
        __block BOOL closed = false;
        
        [self.session connectToHost:parameters[@"host"]
                               port:[parameters[@"port"] intValue]
                           usingSSL:[parameters[@"tls"] boolValue]
                     connectHandler:^(NSError *error){
                         NSLog(@"connectHandler error:%@", error.localizedDescription);
                         XCTAssertEqual(error, nil, @"Connect error %@", error.localizedDescription);
                         if (!error) {
                         [self.session closeWithDisconnectHandler:^(NSError *error){
                             NSLog(@"Closed with error:%@", error ? error.localizedDescription : @"none");
                             closed = true;
                         }];
                         }
                     }];
        
        while (!closed) {
            NSLog(@"waiting for connect and close");
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }
    }
}

- (void)testBlockConnectUnknownHost
{
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        self.session = [[MQTTSession alloc] initWithClientId:@"MQTTClientBlocks"
                                                    userName:parameters[@"user"]
                                                    password:parameters[@"pass"]
                                                   keepAlive:60
                                                cleanSession:YES
                                                        will:NO
                                                   willTopic:nil
                                                     willMsg:nil
                                                     willQoS:0
                                              willRetainFlag:NO
                                               protocolLevel:[parameters[@"protocollevel"] intValue]
                                                     runLoop:[NSRunLoop currentRunLoop]
                                                     forMode:NSRunLoopCommonModes
                                              securityPolicy:[self securityPolicy:parameters]
                                                certificates:[self clientCerts:parameters]];
        self.session.delegate = self;
        
        __block BOOL closed = false;
        
        [self.session connectToHost:parameters[@"host"]
                               port:1888
                           usingSSL:[parameters[@"tls"] boolValue]
                     connectHandler:^(NSError *error){
                         XCTAssertNotEqual(error, nil, @"No error detected");
                         [self.session closeWithDisconnectHandler:^(NSError *error){
                             NSLog(@"Closed with error:%@", error ? error.localizedDescription : @"none");
                             closed = true;
                         }];
                     }];
        
        while (!closed) {
            NSLog(@"waiting for connect and close");
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }
    }
}

- (void)testBlockConnectRefused
{
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        self.session = [[MQTTSession alloc] initWithClientId:@"MQTTClientBlocks"
                                                    userName:parameters[@"user"]
                                                    password:parameters[@"pass"]
                                                   keepAlive:60
                                                cleanSession:YES
                                                        will:NO
                                                   willTopic:nil
                                                     willMsg:nil
                                                     willQoS:0
                                              willRetainFlag:NO
                                               protocolLevel:[parameters[@"protocollevel"] intValue]
                                                     runLoop:[NSRunLoop currentRunLoop]
                                                     forMode:NSRunLoopCommonModes
                                              securityPolicy:[self securityPolicy:parameters]
                                                certificates:[self clientCerts:parameters]];
        self.session.delegate = self;
        
        __block BOOL closed = false;
        
        [self.session connectToHost:@"unknown-Host"
                               port:[parameters[@"port"] intValue]
                           usingSSL:[parameters[@"tls"] boolValue]
                     connectHandler:^(NSError *error){
                         XCTAssertNotEqual(error, nil, @"No error detected");
                         [self.session closeWithDisconnectHandler:^(NSError *error){
                             NSLog(@"Closed with error:%@", error ? error.localizedDescription : @"none");
                             closed = true;
                         }];
                     }];
        
        while (!closed) {
            NSLog(@"waiting for connect and close");
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }
    }
}

#pragma mark helpers

- (NSArray *)clientCerts:(NSDictionary *)parameters {
    NSArray *clientCerts = nil;
    if (parameters[@"clientp12"] && parameters[@"clientp12pass"]) {
        
        NSString *path = [[NSBundle bundleForClass:[BlockTests class]] pathForResource:parameters[@"clientp12"]
                                                                                ofType:@"p12"];
        
        clientCerts = [MQTTSession clientCertsFromP12:path passphrase:parameters[@"clientp12pass"]];
        if (!clientCerts) {
            XCTFail(@"invalid p12 file");
        }
    }
    return clientCerts;
}

- (MQTTSSLSecurityPolicy *)securityPolicy:(NSDictionary *)parameters {
    MQTTSSLSecurityPolicy *securityPolicy = nil;
    
    if (parameters[@"serverCER"]) {
        
        NSString *path = [[NSBundle bundleForClass:[BlockTests class]] pathForResource:parameters[@"serverCER"]
                                                                                ofType:@"cer"];
        if (path) {
            NSData *certificateData = [NSData dataWithContentsOfFile:path];
            if (certificateData) {
                securityPolicy = [MQTTSSLSecurityPolicy policyWithPinningMode:MQTTSSLPinningModeCertificate];
                securityPolicy.pinnedCertificates = [[NSArray alloc] initWithObjects:certificateData, nil];
                securityPolicy.validatesCertificateChain = FALSE;
                securityPolicy.allowInvalidCertificates = TRUE;
                securityPolicy.validatesDomainName = FALSE;
            } else {
                XCTFail(@"error reading cer file");
            }
        } else {
            XCTFail(@"cer file not found");
        }
    }
    return securityPolicy;
}

@end
