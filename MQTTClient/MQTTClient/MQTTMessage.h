//
// MQTTMessage.h
// MQTTClient.framework
//
// Copyright © 2013-2016, Christoph Krey
//
// based on
//
// Copyright (c) 2011, 2013, 2lemetry LLC
//
// All rights reserved. This program and the accompanying materials
// are made available under the terms of the Eclipse Public License v1.0
// which accompanies this distribution, and is available at
// http://www.eclipse.org/legal/epl-v10.html
//
// Contributors:
//    Kyle Roche - initial API and implementation and/or initial documentation
//

#import <Foundation/Foundation.h>

@interface MQTTMessage : NSObject
typedef NS_ENUM(UInt8, MQTTCommandType) {
    MQTT_None = 0,
    MQTTConnect = 1,
    MQTTConnack = 2,
    MQTTPublish = 3,
    MQTTPuback = 4,
    MQTTPubrec = 5,
    MQTTPubrel = 6,
    MQTTPubcomp = 7,
    MQTTSubscribe = 8,
    MQTTSuback = 9,
    MQTTUnsubscribe = 10,
    MQTTUnsuback = 11,
    MQTTPingreq = 12,
    MQTTPingresp = 13,
    MQTTDisconnect = 14
};

/**
 Enumeration of MQTT Quality of Service levels
 */
typedef NS_ENUM(UInt8, MQTTQosLevel) {
    MQTTQosLevelAtMostOnce = 0,
    MQTTQosLevelAtLeastOnce = 1,
    MQTTQosLevelExactlyOnce = 2
};

/**
 Enumeration of MQTT protocol version
 */
typedef NS_ENUM(UInt8, MQTTProtocolVersion) {
    MQTTProtocolVersion31 = 3,
    MQTTProtocolVersion311 = 4
};

@property (nonatomic) MQTTCommandType type;
@property (nonatomic) MQTTQosLevel qos;
@property (nonatomic) BOOL retainFlag;
@property (nonatomic) BOOL dupFlag;
@property (nonatomic) UInt16 mid;
@property (strong, nonatomic) NSData * data;

/**
 Enumeration of MQTT Connect return codes
 */

typedef NS_ENUM(NSUInteger, MQTTConnectReturnCode) {
    MQTTConnectAccepted = 0,
    MQTTConnectRefusedUnacceptableProtocolVersion,
    MQTTConnectRefusedIdentiferRejected,
    MQTTConnectRefusedServerUnavailable,
    MQTTConnectRefusedBadUserNameOrPassword,
    MQTTConnectRefusedNotAuthorized
};

// factory methods
+ (MQTTMessage *)connectMessageWithClientId:(NSString*)clientId
                                   userName:(NSString*)userName
                                   password:(NSString*)password
                                  keepAlive:(NSInteger)keeplive
                               cleanSession:(BOOL)cleanSessionFlag
                                       will:(BOOL)will
                                  willTopic:(NSString*)willTopic
                                    willMsg:(NSData*)willData
                                    willQoS:(MQTTQosLevel)willQoS
                                 willRetain:(BOOL)willRetainFlag
                              protocolLevel:(UInt8)protocolLevel;

+ (MQTTMessage *)pingreqMessage;
+ (MQTTMessage *)disconnectMessage;
+ (MQTTMessage *)subscribeMessageWithMessageId:(UInt16)msgId
                                        topics:(NSDictionary *)topics;
+ (MQTTMessage *)unsubscribeMessageWithMessageId:(UInt16)msgId
                                          topics:(NSArray *)topics;
+ (MQTTMessage *)publishMessageWithData:(NSData*)payload
                                onTopic:(NSString*)topic
                                    qos:(MQTTQosLevel)qosLevel
                                  msgId:(UInt16)msgId
                             retainFlag:(BOOL)retain
                                dupFlag:(BOOL)dup;
+ (MQTTMessage *)pubackMessageWithMessageId:(UInt16)msgId;
+ (MQTTMessage *)pubrecMessageWithMessageId:(UInt16)msgId;
+ (MQTTMessage *)pubrelMessageWithMessageId:(UInt16)msgId;
+ (MQTTMessage *)pubcompMessageWithMessageId:(UInt16)msgId;
+ (MQTTMessage *)messageFromData:(NSData *)data;

// instance methods
- (instancetype)initWithType:(MQTTCommandType)type;
- (instancetype)initWithType:(MQTTCommandType)type
                        data:(NSData *)data;
- (instancetype)initWithType:(MQTTCommandType)type
                         qos:(MQTTQosLevel)qos
                        data:(NSData *)data;
- (instancetype)initWithType:(MQTTCommandType)type
                         qos:(MQTTQosLevel)qos
                  retainFlag:(BOOL)retainFlag
                     dupFlag:(BOOL)dupFlag
                        data:(NSData *)data;

- (NSData *)wireFormat;


@end

@interface NSMutableData (MQTT)
- (void)appendByte:(UInt8)byte;
- (void)appendUInt16BigEndian:(UInt16)val;
- (void)appendMQTTString:(NSString*)s;

@end
