//
// MQTTMessage.h
// MQTTClient.framework
//
// Copyright © 2013-2017, Christoph Krey. All rights reserved.
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
@class MQTTProperties;

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
    MQTTProtocolVersion0 = 0,
    MQTTProtocolVersion31 = 3,
    MQTTProtocolVersion311 = 4,
    MQTTProtocolVersion50 = 5
};

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
    MQTTDisconnect = 14,
    MQTTAuth = 15
};

@interface MQTTMessage : NSObject

@property (nonatomic) MQTTCommandType type;
@property (nonatomic) MQTTQosLevel qos;
@property (nonatomic) BOOL retainFlag;
@property (nonatomic) BOOL dupFlag;
@property (nonatomic) UInt16 mid;
@property (strong, nonatomic) NSData *data;
@property (strong, nonatomic) NSNumber *returnCode;
@property (strong, nonatomic) NSNumber *connectAcknowledgeFlags;
@property (strong, nonatomic) MQTTProperties *properties;

/**
 Enumeration of MQTT return codes
 */

typedef NS_ENUM(NSUInteger, MQTTReturnCode) {
    MQTTAccepted = 0,
    MQTTRefusedUnacceptableProtocolVersion = 1,
    MQTTRefusedIdentiferRejected = 2,
    MQTTRefusedServerUnavailable = 3,
    MQTTRefusedBadUserNameOrPassword = 4,
    MQTTRefusedNotAuthorized = 5,

    MQTTSuccess = 0,
    MQTTDisconnectWithWillMessage = 4,
    MQTTNoSubscriptionExisted = 17,
    MQTTContinueAuthentication = 24,
    MQTTReAuthenticate = 25,
    MQTTUnspecifiedError = 128,
    MQTTMalformedPacket = 129,
    MQTTProtocolError = 130,
    MQTTImplementationSpecificError = 131,
    MQTTUnsupportedProtocolVersion = 132,
    MQTTClientIdentifierNotValid = 133,
    MQTTBadUserNameOrPassword = 134,
    MQTTNotAuthorized = 135,
    MQTTServerUnavailable = 136,
    MQTTServerBusy = 137,
    MQTTBanned = 138,
    MQTTServerShuttingDown = 139,
    MQTTBadAuthenticationMethod = 140,
    MQTTKeepAliveTimeout = 141,
    MQTTSessionTakenOver = 142,
    MQTTTopicFilterInvalid = 143,
    MQTTTopicNameInvalid = 144,
    MQTTPacketIdentifierInUse = 145,
    MQTTPacketIdentifierNotFound = 146,
    MQTTReceiveMaximumExceeded = 147,
    MQTTPacketTooLarge = 149,
    MQTTMessageRateTooHigh = 150,
    MQTTQuotaExceeded = 151,
    MQTTAdministrativeAction = 152,
    MQTTPayloadFormatInvalid = 153,
    MQTTRetainNotSupported = 154,
    MQTTQoSNotSupported = 155,
    MQTTUseAnotherServer = 156,
    MQTTServerMoved = 157,
    MQTTSharedSubscriptionNotSupported = 158,
    MQTTConnectionRateExceeded = 159,
    MQTTSubscriptionIdentifiersNotSupported = 161,
    MQTTWildcardSubscriptionNotSupported = 162
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
                              protocolLevel:(MQTTProtocolVersion)protocolLevel
                      sessionExpiryInterval:(NSNumber *)sessionExpiryInterval
                                 authMethod:(NSString *)authMethod
                                   authData:(NSData *)authData
                  requestProblemInformation:(NSNumber *)requestProblemInformation
                          willDelayInterval:(NSNumber *)willDelayInterval
                 requestResponseInformation:(NSNumber *)requestResponseInformation
                             receiveMaximum:(NSNumber *)receiveMaximum
                          topicAliasMaximum:(NSNumber *)topicAliasMaximum
                               userProperty:(NSDictionary <NSString *, NSString *> *)userProperty
                          maximumPacketSize:(NSNumber *)maximumPacketSize
;

+ (MQTTMessage *)pingreqMessage;

+ (MQTTMessage *)disconnectMessage:(MQTTProtocolVersion)protocolLevel
                        returnCode:(MQTTReturnCode)returnCode
             sessionExpiryInterval:(NSNumber *)sessionExpiryInterval
                      reasonString:(NSString *)reasonString
                      userProperty:(NSDictionary <NSString *, NSString *> *)userProperty;

+ (MQTTMessage *)subscribeMessageWithMessageId:(UInt16)msgId
                                        topics:(NSDictionary *)topics
                                 protocolLevel:(MQTTProtocolVersion)protocolLevel
                        subscriptionIdentifier:(NSNumber *)subscriptionIdentifier;

+ (MQTTMessage *)unsubscribeMessageWithMessageId:(UInt16)msgId
                                          topics:(NSArray *)topics
                                   protocolLevel:(MQTTProtocolVersion)protocolLevel;

+ (MQTTMessage *)publishMessageWithData:(NSData*)payload
                                onTopic:(NSString*)topic
                                    qos:(MQTTQosLevel)qosLevel
                                  msgId:(UInt16)msgId
                             retainFlag:(BOOL)retain
                                dupFlag:(BOOL)dup
                          protocolLevel:(MQTTProtocolVersion)protocolLevel
                 payloadFormatIndicator:(NSNumber *)payloadFormatIndicator
              publicationExpiryInterval:(NSNumber *)publicationExpiryInterval
                             topicAlias:(NSNumber *)topicAlias
                          responseTopic:(NSString *)responseTopic
                        correlationData:(NSData *)correlationData
                           userProperty:(NSDictionary <NSString *, NSString *> *)userProperty
                            contentType:(NSString *)contentType;

+ (MQTTMessage *)pubackMessageWithMessageId:(UInt16)msgId
                              protocolLevel:(MQTTProtocolVersion)protocolLevel
                                 returnCode:(MQTTReturnCode)returnCode
                               reasonString:(NSString *)reasonString
                               userProperty:(NSDictionary <NSString *, NSString *> *)userProperty;

+ (MQTTMessage *)pubrecMessageWithMessageId:(UInt16)msgId
                              protocolLevel:(MQTTProtocolVersion)protocolLevel
                                 returnCode:(MQTTReturnCode)returnCode
                               reasonString:(NSString *)reasonString
                               userProperty:(NSDictionary <NSString *, NSString *> *)userProperty;

+ (MQTTMessage *)pubrelMessageWithMessageId:(UInt16)msgId
                              protocolLevel:(MQTTProtocolVersion)protocolLevel
                                 returnCode:(MQTTReturnCode)returnCode
                               reasonString:(NSString *)reasonString
                               userProperty:(NSDictionary <NSString *, NSString *> *)userProperty;

+ (MQTTMessage *)pubcompMessageWithMessageId:(UInt16)msgId
                               protocolLevel:(MQTTProtocolVersion)protocolLevel
                                  returnCode:(MQTTReturnCode)returnCode
                                reasonString:(NSString *)reasonString
                                userProperty:(NSDictionary <NSString *, NSString *> *)userProperty;

+ (MQTTMessage *)messageFromData:(NSData *)data protocolLevel:(MQTTProtocolVersion)protocolLevel;

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

@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSData *wireFormat;


@end

@interface NSMutableData (MQTT)
- (void)appendByte:(UInt8)byte;
- (void)appendUInt16BigEndian:(UInt16)val;
- (void)appendUInt32BigEndian:(UInt32)val;
- (void)appendVariableLength:(unsigned long)length;
- (void)appendMQTTString:(NSString *)string;
- (void)appendBinaryData:(NSData *)data;

@end
