//
//  ForegroundReconnection.h
//  MQTTClient
//
//  Created by Josip Cavar on 22/08/2017.
//  Copyright © 2017 Christoph Krey. All rights reserved.
//

#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE == 1

@class MQTTSessionManager;

@interface ForegroundReconnection : NSObject

@property (weak, nonatomic) MQTTSessionManager *sessionManager;

- (instancetype)initWithMQTTSessionManager:(MQTTSessionManager *)manager;

@end

#endif
