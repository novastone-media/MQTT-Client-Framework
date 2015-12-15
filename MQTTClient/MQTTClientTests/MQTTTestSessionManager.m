//
//  MQTTMQTTTestSessionManager.m
//  MQTTClient
//
//  Created by Christoph Krey on 21.08.15.
//  Copyright (c) 2015 Christoph Krey. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <CocoaLumberjack/Cocoalumberjack.h>

#import "MQTTSessionManager.h"
#import "MQTTCFSocketTransport.h"
#import "MQTTTestHelpers.h"

@interface MQTTTestSessionManager : XCTestCase <MQTTSessionManagerDelegate>
@property (nonatomic) int received;
@property (nonatomic) int sent;
@property (nonatomic) BOOL timeout;
@property (nonatomic) int step;
@end

@implementation MQTTTestSessionManager

- (void)setUp {
    [super setUp];
    
    if (![[DDLog allLoggers] containsObject:[DDTTYLogger sharedInstance]])
        [DDLog addLogger:[DDTTYLogger sharedInstance] withLevel:DDLogLevelAll];
    if (![[DDLog allLoggers] containsObject:[DDASLLogger sharedInstance]])
        [DDLog addLogger:[DDASLLogger sharedInstance] withLevel:DDLogLevelWarning];
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

        [manager addObserver:self
                  forKeyPath:@"effectiveSubscriptions"
                     options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                     context:nil];
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
            securityPolicy:[MQTTTestHelpers securityPolicy:parameters]
              certificates:[MQTTTestHelpers clientCerts:parameters]];
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
        [manager removeObserver:self forKeyPath:@"effectiveSubscriptions"];
        [timer invalidate];
    }
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
        [manager addObserver:self
                  forKeyPath:@"effectiveSubscriptions"
                     options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                     context:nil];
        
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
            securityPolicy:[MQTTTestHelpers securityPolicy:parameters]
              certificates:[MQTTTestHelpers clientCerts:parameters]];
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
        
        manager.subscriptions = [@{@"#": @(0),@"a": @(1),@"b": @(2),@"$SYS/#": @(0)} mutableCopy];
        
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
        [manager removeObserver:self forKeyPath:@"effectiveSubscriptions"];
        
        [timer invalidate];
    }
}

- (void)testSessionManagerShort {
    
    MQTTSessionManager *manager = [[MQTTSessionManager alloc] init];
    manager.delegate = self;
    [manager addObserver:self
              forKeyPath:@"effectiveSubscriptions"
                 options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                 context:nil];
    
    // allow 5 sec for connect
    self.timeout = false;
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:5
                                                      target:self
                                                    selector:@selector(timeout:)
                                                    userInfo:nil
                                                     repeats:false];
    
    
    manager.subscriptions = @{@"#": [NSNumber numberWithInt:MQTTQosLevelExactlyOnce]};
    [manager connectTo:@"localhost"
                  port:1883
                   tls:false
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
        securityPolicy:nil
          certificates:nil];
    
    while (!self.timeout && manager.state != MQTTSessionManagerStateConnected) {
        NSLog(@"waiting for connect %d", manager.state);
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.1]];
    }
    if (timer.valid) [timer invalidate];
    
    // allow 5 sec for sending and receiving
    self.timeout = false;
    timer = [NSTimer scheduledTimerWithTimeInterval:5
                                             target:self
                                           selector:@selector(timeout:)
                                           userInfo:nil
                                            repeats:false];
    
    
    while (!self.timeout) {
        [manager sendData:[@"data" dataUsingEncoding:NSUTF8StringEncoding] topic:@"MQTTSessionManager" qos:MQTTQosLevelExactlyOnce retain:FALSE];
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    if (timer.valid) [timer invalidate];
    
    // allow 3 sec for disconnect
    self.timeout = false;
    timer = [NSTimer scheduledTimerWithTimeInterval:3
                                             target:self
                                           selector:@selector(timeout:)
                                           userInfo:nil
                                            repeats:false];
    
    [manager disconnect];
    while (!self.timeout && manager.state != MQTTSessionStatusClosed) {
        NSLog(@"waiting for disconnect %d", manager.state);
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.1]];
    }
    if (timer.valid) [timer invalidate];
    [manager removeObserver:self forKeyPath:@"effectiveSubscriptions"];
}

#pragma mark - helpers


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

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"effectiveSubscriptions"]) {
        MQTTSessionManager *manager = (MQTTSessionManager *)object;
        NSLog(@"effectiveSubscriptions changed: %@", manager.effectiveSubscriptions);
    }
}

@end
