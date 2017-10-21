//
//  MQTTWill.m
//  MQTTClientTests
//
//  Created by Christoph Krey on 01.10.17.
//  Copyright © 2017 Christoph Krey. All rights reserved.
//

#import "MQTTWill.h"

@implementation MQTTWill
- (instancetype)init {
    return [self initWithTopic:@"will"
                          data:[[NSData alloc] init]
                    retainFlag:false
                           qos:MQTTQosLevelAtMostOnce
            willDelayInterval:nil
        payloadFormatIndicator:nil
         messageExpiryInterval:nil
                   contentType:nil
                 responseTopic:nil
               correlationData:nil
                userProperties:nil];
}

- (instancetype)initWithTopic:(NSString * _Nonnull)topic
                         data:(NSData * _Nonnull)data
                   retainFlag:(BOOL)retainFlag
                          qos:(MQTTQosLevel)qos
            willDelayInterval:(NSNumber * _Nullable)willDelayInterval
       payloadFormatIndicator:(NSNumber * _Nullable)payloadFormatIndicator messageExpiryInterval:(NSNumber * _Nullable)messageExpiryInterval
                  contentType:(NSString * _Nullable)contentType
                responseTopic:(NSString * _Nullable)responseTopic
              correlationData:(NSData * _Nullable)correlationData
               userProperties:(NSArray<NSDictionary<NSString *,NSString *> *> * _Nullable)userProperties {

    self = [super init];
    self.topic = topic;
    self.data = data;
    self.retainFlag = retainFlag;
    self.qos = qos;
    self.willDelayInterval = willDelayInterval;
    self.payloadFormatIndicator = payloadFormatIndicator;
    self.messageExpiryInterval = messageExpiryInterval;
    self.contentType = contentType;
    self.responseTopic = responseTopic;
    self.correlationData = correlationData;
    self.userProperties = userProperties;

    return self;
}

@end
