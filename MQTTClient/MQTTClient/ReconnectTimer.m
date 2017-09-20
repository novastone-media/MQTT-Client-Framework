//
//  ReconnectTimer.m
//  MQTTClient
//
//  Created by Josip Cavar on 22/08/2017.
//  Copyright © 2017 Christoph Krey. All rights reserved.
//

#import "ReconnectTimer.h"

@interface ReconnectTimer()

@property (strong, nonatomic) NSTimer *timer;
@property (assign, nonatomic) NSTimeInterval retryInterval;
@property (assign, nonatomic) NSTimeInterval currentRetryInterval;
@property (assign, nonatomic) NSTimeInterval maxRetryInterval;
@property (copy, nonatomic) void (^reconnectBlock)(void);

@end

@implementation ReconnectTimer

- (instancetype)initWithRetryInterval:(NSTimeInterval)retryInterval
                     maxRetryInterval:(NSTimeInterval)maxRetryInterval
                       reconnectBlock:(void (^)(void))block {
    self = [super init];
    if (self) {
        self.retryInterval = retryInterval;
        self.currentRetryInterval = retryInterval;
        self.maxRetryInterval = maxRetryInterval;
        self.reconnectBlock = block;
    }
    return self;
}

- (void)schedule {
    self.timer = [NSTimer scheduledTimerWithTimeInterval:self.currentRetryInterval
                                                  target:self
                                                selector:@selector(reconnect)
                                                userInfo:nil
                                                 repeats:NO];
}

- (void)stop {
    [self.timer invalidate];
    self.timer = nil;
}

- (void)resetRetryInterval {
    self.currentRetryInterval = self.retryInterval;
}

- (void)reconnect {
    [self stop];
    if (self.currentRetryInterval < self.maxRetryInterval) {
        self.currentRetryInterval *= 2;
    }
    self.reconnectBlock();
}

@end
