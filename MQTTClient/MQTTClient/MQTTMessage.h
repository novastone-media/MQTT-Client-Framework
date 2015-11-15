//
// MQTTMessage.h
// MQTTClient.framework
//
// Copyright (c) 2013-2015, Christoph Krey
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
@property (nonatomic)    UInt8    type;
@property (nonatomic)    UInt8    qos;
@property (nonatomic)    BOOL     retainFlag;
@property (nonatomic)    BOOL     dupFlag;
@property (nonatomic)    UInt16   mid;

typedef NS_ENUM(UInt8, MQTTCommandType) {
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
    MQTTQosLevelAtLeastOnce,
    MQTTQosLevelExactlyOnce
};

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

// instance methods
+ (id)connectMessageWithClientId:(NSString*)clientId
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

+ (id)pingreqMessage;
+ (id)disconnectMessage;
+ (id)subscribeMessageWithMessageId:(UInt16)msgId
                             topics:(NSDictionary *)topics;
+ (id)unsubscribeMessageWithMessageId:(UInt16)msgId
                                topics:(NSArray *)topics;
+ (id)publishMessageWithData:(NSData*)payload
                     onTopic:(NSString*)topic
                         qos:(MQTTQosLevel)qosLevel
                       msgId:(UInt16)msgId
                  retainFlag:(BOOL)retain
                     dupFlag:(BOOL)dup;
+ (id)pubackMessageWithMessageId:(UInt16)msgId;
+ (id)pubrecMessageWithMessageId:(UInt16)msgId;
+ (id)pubrelMessageWithMessageId:(UInt16)msgId;
+ (id)pubcompMessageWithMessageId:(UInt16)msgId;

- (id)initWithType:(UInt8)aType;
- (id)initWithType:(UInt8)aType data:(NSData*)aData;
- (id)initWithType:(UInt8)aType
               qos:(MQTTQosLevel)aQos
              data:(NSData*)aData;
- (id)initWithType:(UInt8)aType
               qos:(MQTTQosLevel)aQos
        retainFlag:(BOOL)aRetainFlag
           dupFlag:(BOOL)aDupFlag
              data:(NSData*)aData;
@property (strong,nonatomic) NSData * data;

@end

@interface NSMutableData (MQTT)
- (void)appendByte:(UInt8)byte;
- (void)appendUInt16BigEndian:(UInt16)val;
- (void)appendMQTTString:(NSString*)s;

@end
