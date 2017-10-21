//
//  MQTTWill.h
//  MQTTClientTests
//
//  Created by Christoph Krey on 01.10.17.
//  Copyright © 2017 Christoph Krey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MQTTMessage.h"

@interface MQTTWill : NSObject
@property (strong, nonatomic, nonnull) NSString *topic;
@property (strong, nonatomic, nonnull) NSData *data;
@property BOOL retainFlag;
@property MQTTQosLevel qos;
@property (strong, nonatomic, nullable) NSNumber * willDelayInterval;
@property (strong, nonatomic, nullable) NSNumber * payloadFormatIndicator;
@property (strong, nonatomic, nullable) NSNumber * messageExpiryInterval;
@property (strong, nonatomic, nullable) NSString * contentType;
@property (strong, nonatomic, nullable) NSString * responseTopic;
@property (strong, nonatomic, nullable) NSData * correlationData;
@property (strong, nonatomic, nullable) NSArray <NSDictionary <NSString *, NSString *> *> *userProperties;

- (_Nonnull instancetype)initWithTopic:(NSString * _Nonnull)topic
                                  data:(NSData * _Nonnull)data
                            retainFlag:(BOOL)retainFlag
                                   qos:(MQTTQosLevel)qos
                     willDelayInterval:(NSNumber * _Nullable)willDelayInterval
                payloadFormatIndicator:(NSNumber * _Nullable)payloadFormatIndicator
                 messageExpiryInterval:(NSNumber * _Nullable)messageExpiryInterval
                           contentType:(NSString * _Nullable)contentType
                         responseTopic:(NSString * _Nullable)responseTopic
                       correlationData:(NSData * _Nullable)correlationData
                        userProperties:(NSArray <NSDictionary <NSString *, NSString *> *> * _Nullable)userProperties
NS_DESIGNATED_INITIALIZER;

@end
