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
                           qos:MQTTQosLevelAtMostOnce];
}

- (instancetype)initWithTopic:(NSString * _Nonnull)topic
                         data:(NSData * _Nonnull)data
                   retainFlag:(BOOL)retainFlag
                          qos:(MQTTQosLevel)qos {
    self = [super init];
    self.topic = topic;
    self.data = data;
    self.retainFlag = retainFlag;
    self.qos = qos;
    return self;
}

@end
