//
//  Timer.m
//  MQTTClient
//
//  Created by Josip Cavar on 06/11/2017.
//  Copyright © 2017 Christoph Krey. All rights reserved.
//

#import "GCDTimer.h"

@interface GCDTimer ()

@property (strong, nonatomic) dispatch_source_t timer;

@end

@implementation GCDTimer

+ (GCDTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)interval
                                     repeats:(BOOL)repeats
                                       queue:(dispatch_queue_t)queue
                                       block:(void (^)(void))block {
    GCDTimer *timer = [[GCDTimer alloc] initWithInterval:interval
                                                 repeats:repeats
                                                   queue:queue
                                                   block:block];
    return timer;
}

- (instancetype)initWithInterval:(NSTimeInterval)interval
                         repeats:(BOOL)repeats
                           queue:(dispatch_queue_t)queue
                           block:(void (^)(void))block {
    self = [super init];
    if (self) {
        self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
        dispatch_source_set_timer(self.timer, dispatch_time(DISPATCH_TIME_NOW, interval * NSEC_PER_SEC), interval * NSEC_PER_SEC, 0);
        dispatch_source_set_event_handler(self.timer, ^{
            if (!repeats) {
                dispatch_source_cancel(self.timer);
            }
            block();
        });
        dispatch_resume(self.timer);
    }
    return self;
}

- (void)dealloc {
    [self invalidate];
}

- (void)invalidate {
    if (self.timer) {
        dispatch_source_cancel(self.timer);
    }
}

@end
