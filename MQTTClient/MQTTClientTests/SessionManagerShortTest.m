//
//  SessionManagerShortTest.m
//  MQTTClient
//
//  Created by Christoph Krey on 02.12.15.
//  Copyright © 2015 Christoph Krey. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MQTTSessionManager.h"
#import "MQTTClientTests.h"

@interface SessionManagerShortTest : XCTestCase <MQTTSessionManagerDelegate>
@property (nonatomic) BOOL timeout;

@end

@implementation SessionManagerShortTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
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

- (void)handleMessage:(NSData *)data onTopic:(NSString *)topic retained:(BOOL)retained {
    NSLog(@"handleMessage t:%@", topic);
}

- (void)messageDelivered:(UInt16)msgID {
    NSLog(@"messageDelivered %d", msgID);
}

- (void)timeout:(NSTimer *)timer {
    NSLog(@"timeout");
    self.timeout = TRUE;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"effectiveSubscriptions"]) {
        MQTTSessionManager *manager = (MQTTSessionManager *)object;
        NSLog(@"effectiveSubscriptions changed: %@", manager.effectiveSubscriptions);
    }
}




@end
