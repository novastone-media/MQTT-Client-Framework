//
//  MQTTSessionManagerTests.m
//  MQTTClient
//
//  Created by Christoph Krey on 21.08.15.
//  Copyright (c) 2015 Christoph Krey. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MQTTSessionManager.h"
#import "MQTTClientTests.h"

@interface MQTTSessionManagerTests : XCTestCase <MQTTSessionManagerDelegate>
@property (nonatomic) int received;
@property (nonatomic) int sent;
@property (nonatomic) BOOL timeout;
@property (nonatomic) int step;
@end

@implementation MQTTSessionManagerTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testMQTTSessionManagerClean {
    [self testMQTTSessionManager:true];
}

- (void)testMQTTSessionManagerNoClean {
    [self testMQTTSessionManager:false];
}

- (void)testMQTTSessionManager:(BOOL)clean {
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        
        
        self.step = -1;
        NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:[parameters[@"timeout"] intValue]
                                                          target:self
                                                        selector:@selector(timeout:)
                                                        userInfo:nil
                                                         repeats:true];
        
        self.received = 0;
        MQTTSessionManager *manager = [[MQTTSessionManager alloc] init];
        manager.delegate = self;
        manager.subscriptions = [@{@"#": @(0)} mutableCopy];
        [manager connectTo:parameters[@"host"]
                      port:[parameters[@"port"] intValue]
                       tls:[parameters[@"tls"] boolValue]
                 keepalive:60
                     clean:clean
                      auth:NO
                      user:nil
                      pass:nil
                      will:NO
                 willTopic:nil
                   willMsg:nil
                   willQos:MQTTQosLevelAtMostOnce
            willRetainFlag:FALSE
              withClientId:@"MQTTSessionManager"
            securityPolicy:[self securityPolicy:parameters]
              certificates:[self clientCerts:parameters]];
        while (self.step == -1 && manager.state != MQTTSessionManagerStateConnected) {
            NSLog(@"waiting for connect %d", manager.state);
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }
        XCTAssertEqual(manager.state, MQTTSessionManagerStateConnected);
        
        while (self.step <= 0) {
            NSLog(@"received %d on #", self.received);
            [manager sendData:[@"data" dataUsingEncoding:NSUTF8StringEncoding] topic:@"MQTTSessionManager" qos:MQTTQosLevelAtMostOnce retain:FALSE];
            self.sent++;
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }
        XCTAssertEqual(self.received, self.sent);
        
        manager.subscriptions = [@{@"#": @(0),@"$SYS/#": @(0)} mutableCopy];
        while (self.step == 1) {
            NSLog(@"received %d on # or $SYS/#", self.received);
            [manager sendData:[@"data" dataUsingEncoding:NSUTF8StringEncoding] topic:@"MQTTSessionManager" qos:MQTTQosLevelAtMostOnce retain:FALSE];
            self.sent++;
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }
        XCTAssertEqual(self.received, self.sent);
        
        manager.subscriptions = [@{@"$SYS/#": @(0)} mutableCopy];
        while (self.step <= 2) {
            NSLog(@"received %d on $SYS/#", self.received);
            [manager sendData:[@"data" dataUsingEncoding:NSUTF8StringEncoding] topic:@"MQTTSessionManager" qos:MQTTQosLevelAtMostOnce retain:FALSE];
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }
        XCTAssertEqual(self.received, self.sent);
        
        manager.subscriptions = [@{} mutableCopy];
        while (self.step <= 3) {
            NSLog(@"received %d on nothing", self.received);
            [manager sendData:[@"data" dataUsingEncoding:NSUTF8StringEncoding] topic:@"MQTTSessionManager" qos:MQTTQosLevelAtMostOnce retain:FALSE];
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }
        XCTAssertEqual(self.received, self.sent);
        
        [manager disconnect];
        while (self.step <= 4) {
            NSLog(@"received %d after disconnect", self.received);
            [manager sendData:[@"data" dataUsingEncoding:NSUTF8StringEncoding] topic:@"MQTTSessionManager" qos:MQTTQosLevelAtMostOnce retain:FALSE];
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }
        XCTAssertEqual(self.received, self.sent);
        [timer invalidate];
    }
}

- (void)handleMessage:(NSData *)data onTopic:(NSString *)topic retained:(BOOL)retained {
    NSLog(@"handleMessage t:%@", topic);
    if ([topic isEqualToString:@"MQTTSessionManager"]) {
        self.received++;
    }
}

- (void)messageDelivered:(UInt16)msgID {
    NSLog(@"messageDelivered %d", msgID);
}

- (void)timeout:(NSTimer *)timer {
    NSLog(@"timeout s:%d", self.step);
    self.step++;
}

- (void)testMQTTSessionManagerPersistent {
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        
        self.step = -1;
        NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:[parameters[@"timeout"] intValue]
                                                          target:self
                                                        selector:@selector(timeout:)
                                                        userInfo:nil
                                                         repeats:true];
        
        self.received = 0;
        MQTTSessionManager *manager = [[MQTTSessionManager alloc] initWithPersistence:true
                                                                        maxWindowSize:2
                                                                          maxMessages:1024
                                                                              maxSize:64*1024*1024];
        manager.delegate = self;
        manager.subscriptions = [@{@"#": @(0)} mutableCopy];
        [manager connectTo:parameters[@"host"]
                      port:[parameters[@"port"] intValue]
                       tls:[parameters[@"tls"] boolValue]
                 keepalive:60
                     clean:TRUE
                      auth:NO
                      user:nil
                      pass:nil
                      will:NO
                 willTopic:nil
                   willMsg:nil
                   willQos:MQTTQosLevelAtMostOnce
            willRetainFlag:FALSE
              withClientId:@"MQTTSessionManager"
            securityPolicy:[self securityPolicy:parameters]
              certificates:[self clientCerts:parameters]];
        while (self.step == -1 && manager.state != MQTTSessionManagerStateConnected) {
            NSLog(@"waiting for connect %d", manager.state);
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }
        XCTAssertEqual(manager.state, MQTTSessionManagerStateConnected);
        
        while (self.step <= 0) {
            NSLog(@"received %d on #", self.received);
            [manager sendData:[@"data" dataUsingEncoding:NSUTF8StringEncoding] topic:@"MQTTSessionManager" qos:MQTTQosLevelExactlyOnce retain:FALSE];
            self.sent++;
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.1]];
        }
        XCTAssertEqual(self.received, self.sent);
        
        manager.subscriptions = [@{@"#": @(0),@"$SYS/#": @(0)} mutableCopy];
        while (self.step == 1) {
            NSLog(@"received %d on # or $SYS/#", self.received);
            [manager sendData:[@"data" dataUsingEncoding:NSUTF8StringEncoding] topic:@"MQTTSessionManager" qos:MQTTQosLevelExactlyOnce retain:FALSE];
            self.sent++;
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.1]];
        }
        XCTAssertEqual(self.received, self.sent);
        
        manager.subscriptions = [@{@"$SYS/#": @(0)} mutableCopy];
        while (self.step <= 2) {
            NSLog(@"received %d on $SYS/#", self.received);
            [manager sendData:[@"data" dataUsingEncoding:NSUTF8StringEncoding] topic:@"MQTTSessionManager" qos:MQTTQosLevelExactlyOnce retain:FALSE];
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.1]];
        }
        XCTAssertEqual(self.received, self.sent);
        
        manager.subscriptions = [@{} mutableCopy];
        while (self.step <= 3) {
            NSLog(@"received %d on nothing", self.received);
            [manager sendData:[@"data" dataUsingEncoding:NSUTF8StringEncoding] topic:@"MQTTSessionManager" qos:MQTTQosLevelExactlyOnce retain:FALSE];
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.1]];
        }
        XCTAssertEqual(self.received, self.sent);
        
        [manager disconnect];
        while (self.step <= 4) {
            NSLog(@"received %d after disconnect", self.received);
            [manager sendData:[@"data" dataUsingEncoding:NSUTF8StringEncoding] topic:@"MQTTSessionManager" qos:MQTTQosLevelExactlyOnce retain:FALSE];
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.1]];
        }
        XCTAssertEqual(self.received, self.sent);
        [timer invalidate];
    }
}

- (NSArray *)clientCerts:(NSDictionary *)parameters {
    NSArray *clientCerts = nil;
    if (parameters[@"clientp12"] && parameters[@"clientp12pass"]) {
        
        NSString *path = [[NSBundle bundleForClass:[MQTTSessionManagerTests class]] pathForResource:parameters[@"clientp12"]
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
        
        NSString *path = [[NSBundle bundleForClass:[MQTTSessionManagerTests class]] pathForResource:parameters[@"serverCER"]
                                                                                     ofType:@"cer"];
        if (path) {
            NSData *certificateData = [NSData dataWithContentsOfFile:path];
            if (certificateData) {
                securityPolicy = [MQTTSSLSecurityPolicy policyWithPinningMode:MQTTSSLPinningModeCertificate];
                securityPolicy.pinnedCertificates = [[NSArray alloc] initWithObjects:certificateData, nil];
                securityPolicy.validatesCertificateChain = TRUE;
                securityPolicy.allowInvalidCertificates = FALSE;
                securityPolicy.validatesDomainName = TRUE;
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
