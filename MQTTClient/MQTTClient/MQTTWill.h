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

- (_Nonnull instancetype)initWithTopic:(NSString * _Nonnull)topic
                                  data:(NSData * _Nonnull)data
                            retainFlag:(BOOL)retainFlag
                                   qos:(MQTTQosLevel)qos
NS_DESIGNATED_INITIALIZER;

@end
