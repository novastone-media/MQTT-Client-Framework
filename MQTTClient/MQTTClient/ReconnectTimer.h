//
//  ReconnectTimer.h
//  MQTTClient
//
//  Created by Josip Cavar on 22/08/2017.
//  Copyright © 2017 Christoph Krey. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ReconnectTimer : NSObject

- (instancetype)initWithRetryInterval:(NSTimeInterval)retryInterval
                     maxRetryInterval:(NSTimeInterval)maxRetryInterval
                                queue:(dispatch_queue_t)queue
                       reconnectBlock:(void (^)(void))block;
- (void)schedule;
- (void)stop;
- (void)resetRetryInterval;

@end
