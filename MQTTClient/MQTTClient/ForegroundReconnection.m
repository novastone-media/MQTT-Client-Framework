//
//  ForegroundReconnection.m
//  MQTTClient
//
//  Created by Josip Cavar on 22/08/2017.
//  Copyright © 2017 Christoph Krey. All rights reserved.
//

#import "ForegroundReconnection.h"

#if TARGET_OS_IPHONE == 1 && TARGET_OS_WATCH == 0
#import "MQTTSessionManager.h"
#import <UIKit/UIKit.h>
@interface ForegroundReconnection ()

@property (nonatomic) UIBackgroundTaskIdentifier backgroundTask;

@end

@implementation ForegroundReconnection

- (instancetype)initWithMQTTSessionManager:(MQTTSessionManager *)manager {
    self = [super init];
    self.sessionManager = manager;
    self.backgroundTask = UIBackgroundTaskInvalid;
    
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    
    [defaultCenter addObserver:self
                      selector:@selector(appWillResignActive)
                          name:UIApplicationWillResignActiveNotification
                        object:nil];
    
    [defaultCenter addObserver:self
                      selector:@selector(appDidEnterBackground)
                          name:UIApplicationDidEnterBackgroundNotification
                        object:nil];
    
    [defaultCenter addObserver:self
                      selector:@selector(appDidBecomeActive)
                          name:UIApplicationDidBecomeActiveNotification
                        object:nil];
    return self;
}

- (void)dealloc {
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [defaultCenter removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [defaultCenter removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)appWillResignActive {
    [self.sessionManager disconnect];
}

- (void)appDidEnterBackground {
    __weak ForegroundReconnection *weakSelf = self;
    self.backgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        __strong ForegroundReconnection *strongSelf = weakSelf;
        if (strongSelf.backgroundTask) {
            [[UIApplication sharedApplication] endBackgroundTask:strongSelf.backgroundTask];
            strongSelf.backgroundTask = UIBackgroundTaskInvalid;
        }
    }];
}

- (void)appDidBecomeActive {
    [self.sessionManager connectToLast];
}

- (void)endBackgroundTask {
    if (self.backgroundTask) {
        [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTask];
        self.backgroundTask = UIBackgroundTaskInvalid;
    }
}

@end

#endif
