//
// MQTTMessage.m
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

#import "MQTTMessage.h"
#import "MQTTProperties.h"

#import "MQTTLog.h"

@implementation MQTTMessage

+ (MQTTMessage *)connectMessageWithClientId:(NSString *)clientId
                                   userName:(NSString *)userName
                                   password:(NSString *)password
                                  keepAlive:(NSInteger)keepAlive
                               cleanSession:(BOOL)cleanSessionFlag
                                       will:(BOOL)will
                                  willTopic:(NSString *)willTopic
                                    willMsg:(NSData *)willMsg
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
                               userProperty:(NSDictionary<NSString *,NSString *> *)userProperty
                          maximumPacketSize:(NSNumber *)maximumPacketSize {
    /*
     * setup flags w/o basic plausibility checks
     *
     */
    UInt8 flags = 0x00;

    if (cleanSessionFlag) {
        flags |= 0x02;
    }

    if (userName) {
        flags |= 0x80;
    }
    if (password) {
        flags |= 0x40;
    }

    if (will) {
        flags |= 0x04;
    }

    flags |= ((willQoS & 0x03) << 3);

    if (willRetainFlag) {
        flags |= 0x20;
    }

    NSMutableData* data = [NSMutableData data];

    switch (protocolLevel) {
        case MQTTProtocolVersion50:
            [data appendMQTTString:@"MQTT"];
            [data appendByte:MQTTProtocolVersion50];
            break;

        case MQTTProtocolVersion311:
            [data appendMQTTString:@"MQTT"];
            [data appendByte:MQTTProtocolVersion311];
            break;

        case MQTTProtocolVersion31:
            [data appendMQTTString:@"MQIsdp"];
            [data appendByte:MQTTProtocolVersion31];
            break;

        case MQTTProtocolVersion0:
            [data appendMQTTString:@""];
            [data appendByte:protocolLevel];
            break;

        default:
            [data appendMQTTString:@"MQTT"];
            [data appendByte:protocolLevel];
            break;
    }
    [data appendByte:flags];
    [data appendUInt16BigEndian:keepAlive];

    if (protocolLevel == MQTTProtocolVersion50) {
        NSMutableData *properties = [[NSMutableData alloc] init];
        if (sessionExpiryInterval) {
            [properties appendByte:MQTTSessionExpiryInterval];
            [properties appendUInt32BigEndian:sessionExpiryInterval.unsignedIntValue];
        }
        if (authMethod) {
            [properties appendByte:MQTTAuthMethod];
            [properties appendMQTTString:authMethod];
        }
        if (authData) {
            [properties appendByte:MQTTAuthData];
            [properties appendBinaryData:authData];
        }
        if (requestProblemInformation) {
            [properties appendByte:MQTTRequestProblemInformation];
            [properties appendByte:requestProblemInformation.unsignedIntValue];
        }
        if (willDelayInterval) {
            [properties appendByte:MQTTWillDelayInterval];
            [properties appendUInt32BigEndian:willDelayInterval.unsignedIntValue];
        }
        if (requestResponseInformation) {
            [properties appendByte:MQTTRequestResponseInformation];
            [properties appendByte:requestResponseInformation.unsignedIntValue];
        }
        if (receiveMaximum) {
            [properties appendByte:MQTTReceiveMaximum];
            [properties appendUInt16BigEndian:receiveMaximum.unsignedIntValue];
        }
        if (topicAliasMaximum) {
            [properties appendByte:MQTTTopicAliasMaximum];
            [properties appendUInt16BigEndian:topicAliasMaximum.unsignedIntValue];
        }
        if (userProperty) {
            for (NSString *key in userProperty.allKeys) {
                [properties appendByte:MQTTUserProperty];
                [properties appendMQTTString:key];
                [properties appendMQTTString:userProperty[key]];
            }
        }
        if (maximumPacketSize) {
            [properties appendByte:MQTTMaximumPacketSize];
            [properties appendUInt32BigEndian:maximumPacketSize.unsignedIntValue];
        }
        [data appendVariableLength:properties.length];
        [data appendData:properties];
    }

    [data appendMQTTString:clientId];
    if (willTopic) {
        [data appendMQTTString:willTopic];
    }
    if (willMsg) {
        [data appendUInt16BigEndian:willMsg.length];
        [data appendData:willMsg];
    }
    if (userName) {
        [data appendMQTTString:userName];
    }
    if (password) {
        [data appendMQTTString:password];
    }

    MQTTMessage *msg = [[MQTTMessage alloc] initWithType:MQTTConnect
                                                    data:data];
    return msg;
}

+ (MQTTMessage *)pingreqMessage {
    return [[MQTTMessage alloc] initWithType:MQTTPingreq];
}

+ (MQTTMessage *)disconnectMessage:(MQTTProtocolVersion)protocolLevel
                        returnCode:(MQTTReturnCode)returnCode
             sessionExpiryInterval:(NSNumber *)sessionExpiryInterval
                      reasonString:(NSString *)reasonString
                      userProperty:(NSDictionary<NSString *,NSString *> *)userProperty {
    NSMutableData* data = [NSMutableData data];
    if (protocolLevel == MQTTProtocolVersion50) {
        NSMutableData *properties = [[NSMutableData alloc] init];
        if (sessionExpiryInterval) {
            [properties appendByte:MQTTSessionExpiryInterval];
            [properties appendUInt32BigEndian:sessionExpiryInterval.unsignedIntValue];
        }
        if (reasonString) {
            [properties appendByte:MQTTReasonString];
            [properties appendMQTTString:reasonString];
        }
        if (userProperty) {
            for (NSString *key in userProperty.allKeys) {
                [properties appendByte:MQTTUserProperty];
                [properties appendMQTTString:key];
                [properties appendMQTTString:userProperty[key]];
            }
        }
        if (returnCode != MQTTSuccess || properties.length > 0) {
            [data appendByte:returnCode];
        }
        if (properties.length > 0) {
            [data appendVariableLength:properties.length];
            [data appendData:properties];
        }
    }
    MQTTMessage *msg = [[MQTTMessage alloc] initWithType:MQTTDisconnect
                                                    data:data];
    return msg;
}

+ (MQTTMessage *)subscribeMessageWithMessageId:(UInt16)msgId
                                        topics:(NSDictionary *)topics
                                 protocolLevel:(MQTTProtocolVersion)protocolLevel
                        subscriptionIdentifier:(NSNumber *)subscriptionIdentifier {
    NSMutableData* data = [NSMutableData data];
    [data appendUInt16BigEndian:msgId];
    if (protocolLevel == MQTTProtocolVersion50) {
        NSMutableData *properties = [[NSMutableData alloc] init];
        if (subscriptionIdentifier) {
            [properties appendByte:MQTTSubscriptionIdentifier];
            [properties appendVariableLength:subscriptionIdentifier.unsignedLongValue];
        }
        [data appendVariableLength:properties.length];
        [data appendData:properties];
    }

    for (NSString *topic in topics.allKeys) {
        [data appendMQTTString:topic];
        [data appendByte:[topics[topic] intValue]];
    }
    MQTTMessage* msg = [[MQTTMessage alloc] initWithType:MQTTSubscribe
                                                     qos:1
                                                    data:data];
    msg.mid = msgId;
    return msg;
}

+ (MQTTMessage *)unsubscribeMessageWithMessageId:(UInt16)msgId
                                          topics:(NSArray *)topics
                                   protocolLevel:(MQTTProtocolVersion)protocolLevel {
    NSMutableData* data = [NSMutableData data];
    [data appendUInt16BigEndian:msgId];
    for (NSString *topic in topics) {
        [data appendMQTTString:topic];
    }
    MQTTMessage* msg = [[MQTTMessage alloc] initWithType:MQTTUnsubscribe
                                                     qos:1
                                                    data:data];
    msg.mid = msgId;
    return msg;
}

+ (MQTTMessage *)publishMessageWithData:(NSData *)payload
                                onTopic:(NSString *)topic
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
                           userProperty:(NSDictionary<NSString *,NSString *> *)userProperty
                            contentType:(NSString *)contentType {
    NSMutableData *data = [[NSMutableData alloc] init];
    [data appendMQTTString:topic];
    if (msgId) [data appendUInt16BigEndian:msgId];
    if (protocolLevel == MQTTProtocolVersion50) {
        NSMutableData *properties = [[NSMutableData alloc] init];
        if (payloadFormatIndicator) {
            [properties appendByte:MQTTPayloadFormatIndicator];
            [properties appendByte:payloadFormatIndicator.unsignedIntValue];
        }
        if (publicationExpiryInterval) {
            [properties appendByte:MQTTPublicationExpiryInterval];
            [properties appendUInt32BigEndian:publicationExpiryInterval.unsignedIntValue];
        }
        if (topicAlias) {
            [properties appendByte:MQTTTopicAlias];
            [properties appendUInt16BigEndian:topicAlias.unsignedIntValue];
        }
        if (responseTopic) {
            [properties appendByte:MQTTResponseTopic];
            [properties appendMQTTString:responseTopic];
        }
        if (correlationData) {
            [properties appendByte:MQTTCorrelationData];
            [properties appendBinaryData:correlationData];
        }
        if (userProperty) {
            for (NSString *key in userProperty.allKeys) {
                [properties appendByte:MQTTUserProperty];
                [properties appendMQTTString:key];
                [properties appendMQTTString:userProperty[key]];
            }
        }
        if (contentType) {
            [properties appendByte:MQTTContentType];
            [properties appendMQTTString:contentType];
        }
        [data appendVariableLength:properties.length];
        [data appendData:properties];
    }
    [data appendData:payload];
    MQTTMessage *msg = [[MQTTMessage alloc] initWithType:MQTTPublish
                                                     qos:qosLevel
                                              retainFlag:retain
                                                 dupFlag:dup
                                                    data:data];
    msg.mid = msgId;
    return msg;
}

+ (MQTTMessage *)pubackMessageWithMessageId:(UInt16)msgId
                              protocolLevel:(MQTTProtocolVersion)protocolLevel
                                 returnCode:(MQTTReturnCode)returnCode
                               reasonString:(NSString *)reasonString
                               userProperty:(NSDictionary<NSString *,NSString *> *)userProperty {
    NSMutableData* data = [NSMutableData data];
    [data appendUInt16BigEndian:msgId];
    if (protocolLevel == MQTTProtocolVersion50) {
        NSMutableData *properties = [[NSMutableData alloc] init];
        if (reasonString) {
            [properties appendByte:MQTTReasonString];
            [properties appendMQTTString:reasonString];
        }
        if (userProperty) {
            for (NSString *key in userProperty.allKeys) {
                [properties appendByte:MQTTUserProperty];
                [properties appendMQTTString:key];
                [properties appendMQTTString:userProperty[key]];
            }
        }
        [data appendByte:returnCode];
        [data appendVariableLength:properties.length];
        [data appendData:properties];
    }
    MQTTMessage *msg = [[MQTTMessage alloc] initWithType:MQTTPuback
                                                    data:data];
    msg.mid = msgId;
    return msg;
}

+ (MQTTMessage *)pubrecMessageWithMessageId:(UInt16)msgId
                              protocolLevel:(MQTTProtocolVersion)protocolLevel
                                 returnCode:(MQTTReturnCode)returnCode
                               reasonString:(NSString *)reasonString
                               userProperty:(NSDictionary<NSString *,NSString *> *)userProperty {
    NSMutableData* data = [NSMutableData data];
    [data appendUInt16BigEndian:msgId];
    if (protocolLevel == MQTTProtocolVersion50) {
        NSMutableData *properties = [[NSMutableData alloc] init];
        if (reasonString) {
            [properties appendByte:MQTTReasonString];
            [properties appendMQTTString:reasonString];
        }
        if (userProperty) {
            for (NSString *key in userProperty.allKeys) {
                [properties appendByte:MQTTUserProperty];
                [properties appendMQTTString:key];
                [properties appendMQTTString:userProperty[key]];
            }
        }
        [data appendByte:returnCode];
        [data appendVariableLength:properties.length];
        [data appendData:properties];
    }
    MQTTMessage *msg = [[MQTTMessage alloc] initWithType:MQTTPubrec
                                                    data:data];
    msg.mid = msgId;
    return msg;
}

+ (MQTTMessage *)pubrelMessageWithMessageId:(UInt16)msgId
                              protocolLevel:(MQTTProtocolVersion)protocolLevel
                                 returnCode:(MQTTReturnCode)returnCode
                               reasonString:(NSString *)reasonString
                               userProperty:(NSDictionary<NSString *,NSString *> *)userProperty {
    NSMutableData* data = [NSMutableData data];
    [data appendUInt16BigEndian:msgId];
    if (protocolLevel == MQTTProtocolVersion50) {
        NSMutableData *properties = [[NSMutableData alloc] init];
        if (reasonString) {
            [properties appendByte:MQTTReasonString];
            [properties appendMQTTString:reasonString];
        }
        if (userProperty) {
            for (NSString *key in userProperty.allKeys) {
                [properties appendByte:MQTTUserProperty];
                [properties appendMQTTString:key];
                [properties appendMQTTString:userProperty[key]];
            }
        }
        [data appendByte:returnCode];
        [data appendVariableLength:properties.length];
        [data appendData:properties];
    }
    MQTTMessage *msg = [[MQTTMessage alloc] initWithType:MQTTPubrel
                                                     qos:1
                                                    data:data];
    msg.mid = msgId;
    return msg;
}

+ (MQTTMessage *)pubcompMessageWithMessageId:(UInt16)msgId
                               protocolLevel:(MQTTProtocolVersion)protocolLevel
                                  returnCode:(MQTTReturnCode)returnCode
                                reasonString:(NSString *)reasonString
                                userProperty:(NSDictionary<NSString *,NSString *> *)userProperty {
    NSMutableData* data = [NSMutableData data];
    [data appendUInt16BigEndian:msgId];
    if (protocolLevel == MQTTProtocolVersion50) {
        NSMutableData *properties = [[NSMutableData alloc] init];
        if (reasonString) {
            [properties appendByte:MQTTReasonString];
            [properties appendMQTTString:reasonString];
        }
        if (userProperty) {
            for (NSString *key in userProperty.allKeys) {
                [properties appendByte:MQTTUserProperty];
                [properties appendMQTTString:key];
                [properties appendMQTTString:userProperty[key]];
            }
        }
        [data appendByte:returnCode];
        [data appendVariableLength:properties.length];
        [data appendData:properties];
    }
    MQTTMessage *msg = [[MQTTMessage alloc] initWithType:MQTTPubcomp
                                                    data:data];
    msg.mid = msgId;
    return msg;
}

- (instancetype)init {
    self = [super init];
    self.type = 0;
    self.qos = MQTTQosLevelAtMostOnce;
    self.retainFlag = false;
    self.mid = 0;
    self.data = nil;
    return self;
}

- (instancetype)initWithType:(MQTTCommandType)type {
    self = [self init];
    self.type = type;
    return self;
}

- (instancetype)initWithType:(MQTTCommandType)type
                        data:(NSData *)data {
    self = [self init];
    self.type = type;
    self.data = data;
    return self;
}

- (instancetype)initWithType:(MQTTCommandType)type
                         qos:(MQTTQosLevel)qos
                        data:(NSData *)data {
    self = [self init];
    self.type = type;
    self.qos = qos;
    self.data = data;
    return self;
}

- (instancetype)initWithType:(MQTTCommandType)type
                         qos:(MQTTQosLevel)qos
                  retainFlag:(BOOL)retainFlag
                     dupFlag:(BOOL)dupFlag
                        data:(NSData *)data {
    self = [self init];
    self.type = type;
    self.qos = qos;
    self.retainFlag = retainFlag;
    self.dupFlag = dupFlag;
    self.data = data;
    return self;
}

- (NSData *)wireFormat {
    NSMutableData *buffer = [[NSMutableData alloc] init];

    // encode fixed header
    UInt8 header;
    header = (self.type & 0x0f) << 4;
    if (self.dupFlag) {
        header |= 0x08;
    }
    header |= (self.qos & 0x03) << 1;
    if (self.retainFlag) {
        header |= 0x01;
    }
    [buffer appendBytes:&header length:1];
    [buffer appendVariableLength:self.data.length];

    // encode message data
    if (self.data != nil) {
        [buffer appendData:self.data];
    }

    DDLogVerbose(@"[MQTTMessage] wireFormat(%lu)=%@...",
                 (unsigned long)buffer.length,
                 [buffer subdataWithRange:NSMakeRange(0, MIN(256, buffer.length))]);

    return buffer;
}

+ (MQTTMessage *)messageFromData:(NSData *)data protocolLevel:(MQTTProtocolVersion)protocolLevel {
    MQTTMessage *message = nil;
    if (data.length >= 2) {
        UInt8 header;
        [data getBytes:&header length:sizeof(header)];
        UInt8 type = (header >> 4) & 0x0f;
        UInt8 dupFlag = (header >> 3) & 0x01;
        UInt8 qos = (header >> 1) & 0x03;
        UInt8 retainFlag = header & 0x01;
        UInt32 remainingLength = 0;
        UInt32 multiplier = 1;
        UInt8 offset = 1;
        UInt8 digit;
        do {
            if (data.length < offset) {
                DDLogWarn(@"[MQTTMessage] message data incomplete remaining length");
                offset = -1;
                break;
            }
            [data getBytes:&digit range:NSMakeRange(offset, 1)];
            offset++;
            remainingLength += (digit & 0x7f) * multiplier;
            multiplier *= 128;
            if (multiplier > 128*128*128) {
                DDLogWarn(@"[MQTTMessage] message data too long remaining length");
                multiplier = -1;
                break;
            }
        } while ((digit & 0x80) != 0);

        if (type >= MQTTConnect &&
            type <= MQTTDisconnect) {
            if (offset > 0 &&
                multiplier > 0 &&
                data.length == remainingLength + offset) {
                if ((type == MQTTPublish && (qos >= MQTTQosLevelAtMostOnce && qos <= MQTTQosLevelExactlyOnce)) ||
                    (type == MQTTConnect && qos == 0) ||
                    (type == MQTTConnack && qos == 0) ||
                    (type == MQTTPuback && qos == 0) ||
                    (type == MQTTPubrec && qos == 0) ||
                    (type == MQTTPubrel && qos == 1) ||
                    (type == MQTTPubcomp && qos == 0) ||
                    (type == MQTTSubscribe && qos == 1) ||
                    (type == MQTTSuback && qos == 0) ||
                    (type == MQTTUnsubscribe && qos == 1) ||
                    (type == MQTTUnsuback && qos == 0) ||
                    (type == MQTTPingreq && qos == 0) ||
                    (type == MQTTPingresp && qos == 0) ||
                    (type == MQTTDisconnect && qos == 0)) {
                    message = [[MQTTMessage alloc] init];
                    message.type = type;
                    message.dupFlag = dupFlag == 1;
                    message.retainFlag = retainFlag == 1;
                    message.qos = qos;
                    message.data = [data subdataWithRange:NSMakeRange(offset, remainingLength)];
                    if ((type == MQTTPublish &&
                         (qos == MQTTQosLevelAtLeastOnce ||
                          qos == MQTTQosLevelExactlyOnce)
                         ) ||
                        type == MQTTPuback ||
                        type == MQTTPubrec ||
                        type == MQTTPubrel ||
                        type == MQTTPubcomp ||
                        type == MQTTSubscribe ||
                        type == MQTTSuback ||
                        type == MQTTUnsubscribe ||
                        type == MQTTUnsuback) {
                        if (message.data.length >= 2) {
                            [message.data getBytes:&digit range:NSMakeRange(0, 1)];
                            message.mid = digit * 256;
                            [message.data getBytes:&digit range:NSMakeRange(1, 1)];
                            message.mid += digit;
                        } else {
                            DDLogWarn(@"[MQTTMessage] missing packet identifier");
                            message = nil;
                        }
                    }
                    if (type == MQTTPuback ||
                        type == MQTTPubrec ||
                        type == MQTTPubrel ||
                        type == MQTTPubcomp) {
                        if (protocolLevel != MQTTProtocolVersion50) {
                            if (message.data.length > 2) {
                                DDLogWarn(@"[MQTTMessage] unexpected payload after packet identifier");
                                message = nil;
                            }
                        } else {
                            if (message.data.length < 3) {
                                DDLogWarn(@"[MQTTMessage] no returncode");
                                message = nil;
                            } else {
                                const UInt8 *bytes = message.data.bytes;
                                message.returnCode = [NSNumber numberWithInt:bytes[2]];
                                if (message.data.length >= 3) {
                                    message.properties = [[MQTTProperties alloc] initFromData:
                                                          [message.data subdataWithRange:NSMakeRange(3, message.data.length - 3)]];
                                }
                            }

                        }
                    }
                    if (type == MQTTUnsuback ) {
                        if (message.data.length > 2) {
                            DDLogWarn(@"[MQTTMessage] unexpected payload after packet identifier");
                            message = nil;
                        }
                    }
                    if (type == MQTTPingreq ||
                        type == MQTTPingresp) {
                        if (message.data.length > 0) {
                            DDLogWarn(@"[MQTTMessage] unexpected payload");
                            message = nil;
                        }
                    }
                    if (type == MQTTDisconnect) {
                        if (protocolLevel == MQTTProtocolVersion50) {
                            if (message.data.length == 0) {
                                message.properties = nil;
                                message.returnCode = @(MQTTSuccess);
                            } else if (message.data.length == 1) {
                                message.properties = nil;
                                const UInt8 *bytes = message.data.bytes;
                                message.returnCode = [NSNumber numberWithUnsignedInt:bytes[0]];
                            } else if (message.data.length > 1) {
                                const UInt8 *bytes = message.data.bytes;
                                message.returnCode = [NSNumber numberWithUnsignedInt:bytes[0]];
                                message.properties = [[MQTTProperties alloc] initFromData:
                                                      [message.data subdataWithRange:NSMakeRange(1, message.data.length - 1)]];
                            }
                        } else {
                            if (message.data.length != 2) {
                                DDLogWarn(@"[MQTTMessage] unexpected payload");
                                message = nil;
                            }
                        }
                    }
                    if (type == MQTTConnect) {
                        if (message.data.length < 3) {
                            DDLogWarn(@"[MQTTMessage] missing connect variable header");
                            message = nil;
                        }
                    }
                    if (type == MQTTConnack) {
                        if (protocolLevel == MQTTProtocolVersion50) {
                            if (message.data.length < 3) {
                                DDLogWarn(@"[MQTTMessage] missing connack variable header");
                                message = nil;
                            }
                        } else {
                            if (message.data.length != 2) {
                                DDLogWarn(@"[MQTTMessage] missing connack variable header");
                                message = nil;
                            }
                        }
                        if (message) {
                            const UInt8 *bytes = message.data.bytes;
                            message.connectAcknowledgeFlags = [NSNumber numberWithUnsignedInt:bytes[0]];
                            message.returnCode = [NSNumber numberWithUnsignedInt:bytes[1]];
                            if (protocolLevel == MQTTProtocolVersion50) {
                                message.properties = [[MQTTProperties alloc] initFromData:
                                                      [message.data subdataWithRange:NSMakeRange(2, message.data.length - 2)]];
                            }
                        }
                    }
                    if (type == MQTTSubscribe) {
                        if (message.data.length < 3) {
                            DDLogWarn(@"[MQTTMessage] missing subscribe variable header");
                            message = nil;
                        }
                    }
                    if (type == MQTTSuback) {
                        if (message.data.length < 3) {
                            DDLogWarn(@"[MQTTMessage] missing suback variable header");
                            message = nil;
                        }
                    }
                    if (type == MQTTUnsubscribe) {
                        if (message.data.length < 3) {
                            DDLogWarn(@"[MQTTMessage] missing unsubscribe variable header");
                            message = nil;
                        }
                    }
                } else {
                    DDLogWarn(@"[MQTTMessage] illegal header flags");
                }
            } else {
                DDLogWarn(@"[MQTTMessage] remaining data wrong length");
            }
        } else {
            DDLogWarn(@"[MQTTMessage] illegal message type");
        }
    } else {
        DDLogWarn(@"[MQTTMessage] message data length < 2");
    }
    return message;
}

@end

@implementation NSMutableData (MQTT)

- (void)appendByte:(UInt8)byte {
    [self appendBytes:&byte length:1];
}

- (void)appendUInt16BigEndian:(UInt16)val {
    [self appendByte:val / 256];
    [self appendByte:val % 256];
}

- (void)appendUInt32BigEndian:(UInt32)val {
    [self appendByte:(val / (256 * 256 * 256))];
    [self appendByte:(val / (256 * 256)) & 0xff];
    [self appendByte:(val / 256) & 0xff];
    [self appendByte:val % 256];
}

- (void)appendVariableLength:(unsigned long)length {
    do {
        UInt8 digit = length % 128;
        length /= 128;
        if (length > 0) {
            digit |= 0x80;
        }
        [self appendBytes:&digit length:1];
    }
    while (length > 0);
}

- (void)appendMQTTString:(NSString *)string {
    if (string) {
        NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
        [self appendUInt16BigEndian:data.length];
        [self appendData:data];
    }
}

- (void)appendBinaryData:(NSData *)data {
    if (data) {
        [self appendUInt16BigEndian:data.length];
        [self appendData:data];
    }
}

@end

