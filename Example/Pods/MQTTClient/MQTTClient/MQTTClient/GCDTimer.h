//
//  Timer.h
//  MQTTClient
//
//  Created by Josip Cavar on 06/11/2017.
//  Copyright © 2017 Christoph Krey. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GCDTimer: NSObject

+ (GCDTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)interval
                                     repeats:(BOOL)repeats
                                       queue:(dispatch_queue_t)queue
                                       block:(void (^)(void))block;
- (void)invalidate;

@end
