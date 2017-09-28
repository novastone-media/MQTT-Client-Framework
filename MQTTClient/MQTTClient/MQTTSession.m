//
// MQTTSession.m
// MQTTClient.framework
//
// Copyright © 2013-2017, Christoph Krey. All rights reserved.
//


#import "MQTTSession.h"
#import "MQTTDecoder.h"
#import "MQTTStrict.h"
#import "MQTTProperties.h"
#import "MQTTMessage.h"
#import "MQTTCoreDataPersistence.h"

@class MQTTSSLSecurityPolicy;

#import "MQTTLog.h"

NSString * const MQTTSessionErrorDomain = @"MQTT";

@interface MQTTSession() <MQTTDecoderDelegate, MQTTTransportDelegate>

@property (nonatomic, readwrite) MQTTSessionStatus status;
@property (nonatomic, readwrite) BOOL sessionPresent;

@property (strong, nonatomic) NSTimer *keepAliveTimer;
@property (strong, nonatomic) NSNumber * _Nullable serverKeepAlive;
@property (strong, nonatomic) NSString * _Nullable assignedClientIdentifier;
@property (strong, nonatomic) NSString * _Nullable brokerAuthMethod;
@property (strong, nonatomic) NSData * _Nullable brokerAuthData;
@property (strong, nonatomic) NSString * _Nullable brokerResponseInformation;
@property (strong, nonatomic) NSString * _Nullable serverReference;
@property (strong, nonatomic) NSString * _Nullable brokerReasonString;
@property (strong, nonatomic) NSNumber * _Nullable brokerReceiveMaximum;
@property (strong, nonatomic) NSNumber * _Nullable brokerTopicAliasMaximum;
@property (strong, nonatomic) NSNumber * _Nullable maximumQoS;
@property (strong, nonatomic) NSNumber * _Nullable retainAvailable;
@property (strong, nonatomic) NSMutableArray <NSDictionary <NSString *, NSString *> *> * _Nullable brokerUserProperties;
@property (strong, nonatomic) NSNumber * _Nullable brokerMaximumPacketSize;
@property (strong, nonatomic) NSNumber * _Nullable wildcardSubscriptionAvailable;
@property (strong, nonatomic) NSNumber * _Nullable subscriptionIdentifiersAvailable;
@property (strong, nonatomic) NSNumber * _Nullable sharedSubscriptionAvailable;

@property (nonatomic) UInt16 effectiveKeepAlive;
@property (strong, nonatomic) NSTimer *checkDupTimer;

@property (strong, nonatomic) MQTTDecoder *decoder;

@property (copy, nonatomic) MQTTDisconnectHandler disconnectHandler;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, MQTTSubscribeHandler> *subscribeHandlers;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, MQTTSubscribeHandlerV5> *subscribeHandlersV5;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, MQTTUnsubscribeHandler> *unsubscribeHandlers;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, MQTTUnsubscribeHandlerV5> *unsubscribeHandlersV5;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, MQTTPublishHandler> *publishHandlers;

@property (nonatomic) UInt16 txMsgId;

@property (nonatomic) BOOL synchronPub;
@property (nonatomic) UInt16 synchronPubMid;
@property (nonatomic) BOOL synchronUnsub;
@property (nonatomic) UInt16 synchronUnsubMid;
@property (nonatomic) BOOL synchronSub;
@property (nonatomic) UInt16 synchronSubMid;
@property (nonatomic) BOOL synchronConnect;
@property (nonatomic) BOOL synchronDisconnect;

@property (strong, nonatomic) MQTTSSLSecurityPolicy *securityPolicy;

@end

#define DUPLOOP 1.0

@implementation MQTTSession
@synthesize certificates;

- (void)setCertificates:(NSArray *)newCertificates {
    certificates = newCertificates;
    if (self.transport) {
        if ([self.transport respondsToSelector:@selector(setCertificates:)]) {
            [self.transport performSelector:@selector(setCertificates:) withObject:certificates];
        }
    }
}

- (instancetype)init {
    DDLogVerbose(@"[MQTTSession] init");
    self = [super init];
    self.txMsgId = 1;
    self.persistence = [[MQTTCoreDataPersistence alloc] init];
    self.subscribeHandlers = [[NSMutableDictionary alloc] init];
    self.subscribeHandlersV5 = [[NSMutableDictionary alloc] init];
    self.unsubscribeHandlers = [[NSMutableDictionary alloc] init];
    self.unsubscribeHandlersV5 = [[NSMutableDictionary alloc] init];
    self.publishHandlers = [[NSMutableDictionary alloc] init];

    self.clientId = nil;
    self.userName = nil;
    self.password = nil;
    self.keepAliveInterval = 60;
    self.dupTimeout = 20.0;
    self.cleanSessionFlag = true;
    self.willFlag = false;
    self.willTopic = nil;
    self.willMsg = nil;
    self.willQoS = MQTTQosLevelAtMostOnce;
    self.willRetainFlag = false;
    self.protocolLevel = MQTTProtocolVersion311;
    self.runLoop = [NSRunLoop currentRunLoop];
    self.runLoopMode = NSRunLoopCommonModes;

    self.status = MQTTSessionStatusCreated;

    return self;
}

- (NSString *)host
{
    return _transport.host;
}

- (UInt32)port
{
    return _transport.port;
}

- (void)setClientId:(NSString *)clientId
{
    if (!clientId) {
        clientId = [NSString stringWithFormat:@"MQTTClient%.0f",fmod([NSDate date].timeIntervalSince1970, 1.0) * 1000000.0];
    }

    _clientId = clientId;
}

- (void)setRunLoop:(NSRunLoop *)runLoop
{
    if (!runLoop ) {
        runLoop = [NSRunLoop currentRunLoop];
    }
    _runLoop = runLoop;
}

- (void)setRunLoopMode:(NSString *)runLoopMode
{
    if (!runLoopMode) {
        runLoopMode = NSRunLoopCommonModes;
    }
    _runLoopMode = runLoopMode;
}

/*  ____   _   _  ____  ____    ____  ____   ___  ____   _____
 * / ___| | | | || __ )/ ___|  / ___||  _ \ |_ _|| __ ) | ____|
 * \___ \ | | | ||  _ \\___ \ | |    | |_) | | | |  _ \ |  _|
 *  ___) || |_| || |_) |___) || |___ |  _ <  | | | |_) || |___
 * |____/  \___/ |____/|____/  \____||_| \_\|___||____/ |_____|
 */

- (UInt16)subscribeToTopic:(NSString *)topic
                   atLevel:(MQTTQosLevel)qosLevel {
    return [self subscribeToTopic:topic atLevel:qosLevel subscribeHandler:nil];
}

- (UInt16)subscribeToTopic:(NSString *)topic
                   atLevel:(MQTTQosLevel)qosLevel
                   noLocal:(BOOL)noLocal
         retainAsPublished:(BOOL)retainAsPublished
            retainHandling:(MQTTRetainHandling)retainHandling
    subscriptionIdentifier:(UInt32)subscriptionIdentifier {
    return [self subscribeToTopic:topic
                          atLevel:qosLevel
                          noLocal:noLocal
                retainAsPublished:retainAsPublished
                   retainHandling:retainHandling
           subscriptionIdentifier:subscriptionIdentifier
                 subscribeHandler:nil];
}

- (UInt16)subscribeToTopic:(NSString *)topic
                   atLevel:(MQTTQosLevel)qosLevel
          subscribeHandler:(MQTTSubscribeHandler)subscribeHandler {
    return [self subscribeToTopics:topic ? @{topic: @(qosLevel)} : @{} subscribeHandler:subscribeHandler];
}

- (UInt16)subscribeToTopic:(NSString *)topic
                   atLevel:(MQTTQosLevel)qosLevel
                   noLocal:(BOOL)noLocal
         retainAsPublished:(BOOL)retainAsPublished
            retainHandling:(MQTTRetainHandling)retainHandling
    subscriptionIdentifier:(UInt32)subscriptionIdentifier
          subscribeHandler:(MQTTSubscribeHandlerV5 _Nullable)subscribeHandler {
    UInt8 subscriptionOptions = qosLevel | noLocal << 2 | retainAsPublished << 3 | retainHandling << 4;
    return [self subscribeToTopics:topic ? @{topic: @(subscriptionOptions)} : @{}
            subscriptionIdentifier:subscriptionIdentifier subscribeHandler:subscribeHandler];
}

- (UInt16)subscribeToTopics:(NSDictionary<NSString *, NSNumber *> *)topics {
    return [self subscribeToTopics:topics subscribeHandler:nil];
}

- (UInt16)subscribeToTopics:(NSDictionary<NSString *,NSNumber *> *)topics
     subscriptionIdentifier:(UInt32)subscriptionIdentifier {
    return [self subscribeToTopics:topics
            subscriptionIdentifier:subscriptionIdentifier
                  subscribeHandler:nil];
}

- (void)checkTopicFilters:(NSArray <NSString *> *)topicFilters {
    if (MQTTStrict.strict &&
        topicFilters.count == 0) {
        NSException* myException = [NSException
                                    exceptionWithName:@"topicFilter array in SUBSCRIBE or UNSUBSRIBE must not be empty"
                                    reason:[NSString stringWithFormat:@"%@", topicFilters]
                                    userInfo:nil];
        @throw myException;
    }

    for (NSString *topicFilter in topicFilters) {
        if (MQTTStrict.strict &&
            topicFilter.length < 1) {
            NSException* myException = [NSException
                                        exceptionWithName:@"topicFilter must be at least 1 characters long"
                                        reason:[NSString stringWithFormat:@"%@", topicFilter]
                                        userInfo:nil];
            @throw myException;
        }

        if (MQTTStrict.strict &&
            [topicFilter dataUsingEncoding:NSUTF8StringEncoding].length > 65535L) {
            NSException* myException = [NSException
                                        exceptionWithName:@"topicFilter may not be longer than 65535 bytes in UTF8 representation"
                                        reason:[NSString stringWithFormat:@"topicFilter length = %lu",
                                                (unsigned long)[topicFilter dataUsingEncoding:NSUTF8StringEncoding].length]
                                        userInfo:nil];
            @throw myException;
        }

        if (MQTTStrict.strict &&
            ![topicFilter dataUsingEncoding:NSUTF8StringEncoding]) {
            NSException* myException = [NSException
                                        exceptionWithName:@"topicFilter must not contain non-UTF8 characters"
                                        reason:[NSString stringWithFormat:@"topicFilter = %@", topicFilter]
                                        userInfo:nil];
            @throw myException;
        }

        if (MQTTStrict.strict) {
            NSArray <NSString *> *components = [topicFilter componentsSeparatedByString:@"/"];
            for (int level = 0; level < components.count; level++) {
                if ([components[level] rangeOfString:@"+"].location != NSNotFound &&
                    components[level].length > 1) {
                    NSException* myException = [NSException
                                                exceptionWithName:@"singlelevel wildcard must be alone on a level of a topic filter"
                                                reason:[NSString stringWithFormat:@"topicFilter = %@", topicFilter]
                                                userInfo:nil];
                    @throw myException;
                }
            }

            for (int level = 0; level < components.count - 1; level++) {
                if ([components[level] rangeOfString:@"#"].location != NSNotFound) {
                    NSException* myException = [NSException
                                                exceptionWithName:@"multilevel wildcard must be on the last level of a topic filter"
                                                reason:[NSString stringWithFormat:@"topicFilter = %@", topicFilter]
                                                userInfo:nil];
                    @throw myException;
                }
            }
            if ([components[components.count - 1] rangeOfString:@"#"].location != NSNotFound &&
                components[components.count - 1].length > 1) {
                NSException* myException = [NSException
                                            exceptionWithName:@"multilevel wildcard must be alone on a level of a topic filter"
                                            reason:[NSString stringWithFormat:@"topicFilter = %@", topicFilter]
                                            userInfo:nil];
                @throw myException;
            }
        }

        if (MQTTStrict.strict &&
            [topicFilter rangeOfString:@"#"].location != NSNotFound &&
            [topicFilter rangeOfString:@"#"].location != topicFilter.length &&
            (topicFilter.length == 1 || [[topicFilter substringWithRange:NSMakeRange(topicFilter.length - 2, 1)] isEqualToString:@"/"])
            ) {
            NSException* myException = [NSException
                                        exceptionWithName:@"multilevel wildcard must alone on the last level of a topic filter"
                                        reason:[NSString stringWithFormat:@"topicFilter = %@", topicFilter]
                                        userInfo:nil];
            @throw myException;
        }

    }
}

- (UInt16)subscribeToTopics:(NSDictionary<NSString *, NSNumber *> *)topics
           subscribeHandler:(MQTTSubscribeHandler)subscribeHandler {
    DDLogVerbose(@"[MQTTSession] subscribeToTopics:%@]", topics);

    [self checkTopicFilters:topics.allKeys];

    for (NSNumber *qos in topics.allValues) {
        if (MQTTStrict.strict &&
            qos.intValue != MQTTQosLevelAtMostOnce &&
            qos.intValue != MQTTQosLevelAtLeastOnce &&
            qos.intValue != MQTTQosLevelExactlyOnce) {
            NSException* myException = [NSException
                                        exceptionWithName:@"Illegal QoS level"
                                        reason:[NSString stringWithFormat:@"%d is not 0, 1, or 2", qos.intValue]
                                        userInfo:nil];
            @throw myException;
        }
    }

    UInt16 mid = [self nextMsgId];
    if (subscribeHandler) {
        (self.subscribeHandlers)[@(mid)] = [subscribeHandler copy];
    } else {
        [self.subscribeHandlers removeObjectForKey:@(mid)];
    }
    (void)[self encode:[MQTTMessage subscribeMessageWithMessageId:mid
                                                           topics:topics
                                                    protocolLevel:self.protocolLevel
                                           subscriptionIdentifier:nil]];

    return mid;
}

- (UInt16)subscribeToTopics:(NSDictionary<NSString *,NSNumber *> *)topics
     subscriptionIdentifier:(UInt32)subscriptionIdentifier
           subscribeHandler:(MQTTSubscribeHandlerV5)subscribeHandler {
    DDLogVerbose(@"[MQTTSession] subscribeToTopics:%@]", topics);

    [self checkTopicFilters:topics.allKeys];

    if (MQTTStrict.strict) {

        for (NSNumber *subscriptionOptions in topics.allValues) {
            MQTTQosLevel qos = [subscriptionOptions intValue] & 0x03;
            MQTTRetainHandling retainHandling = ([subscriptionOptions intValue] & 0x30) >> 4;
            int reserved = [subscriptionOptions intValue] & 0xffffffc0;

            if (reserved != 0) {
                NSException* myException = [NSException
                                            exceptionWithName:@"Reserved bits in subscriptionOptions used"
                                            reason:[NSString stringWithFormat:@"%d 0", reserved]
                                            userInfo:nil];
                @throw myException;
            }

            if (qos != MQTTQosLevelAtMostOnce &&
                qos != MQTTQosLevelAtLeastOnce &&
                qos != MQTTQosLevelExactlyOnce) {
                NSException* myException = [NSException
                                            exceptionWithName:@"Illegal QoS level"
                                            reason:[NSString stringWithFormat:@"%d is not 0, 1, or 2", qos]
                                            userInfo:nil];
                @throw myException;

            }
            if (retainHandling != MQTTSendRetained &&
                retainHandling != MQTTSendRetainedIfNotYetSubscribed &&
                retainHandling != MQTTDontSendRetained) {
                NSException* myException = [NSException
                                            exceptionWithName:@"Illegal retain handling"
                                            reason:[NSString stringWithFormat:@"%d is not 0, 1, or 2", retainHandling]
                                            userInfo:nil];
                @throw myException;
            }
        }
    }

    UInt16 mid = [self nextMsgId];
    if (subscribeHandler) {
        (self.subscribeHandlersV5)[@(mid)] = [subscribeHandler copy];
    } else {
        [self.subscribeHandlersV5 removeObjectForKey:@(mid)];
    }
    (void)[self encode:[MQTTMessage subscribeMessageWithMessageId:mid
                                                           topics:topics
                                                    protocolLevel:self.protocolLevel
                                           subscriptionIdentifier:subscriptionIdentifier ? @(subscriptionIdentifier) : nil]];

    return mid;
}

/*  _   _  _   _  ____   _   _  ____  ____    ____  ____   ___  ____   _____
 * | | | || \ | |/ ___| | | | || __ )/ ___|  / ___||  _ \ |_ _|| __ ) | ____|
 * | | | ||  \| |\___ \ | | | ||  _ \\___ \ | |    | |_) | | | |  _ \ |  _|
 * | |_| || |\  | ___) || |_| || |_) |___) || |___ |  _ <  | | | |_) || |___
 *  \___/ |_| \_||____/  \___/ |____/|____/  \____||_| \_\|___||____/ |_____|
 */
- (UInt16)unsubscribeTopic:(NSString*)topic {
    return [self unsubscribeTopic:topic unsubscribeHandler:nil];
}

- (UInt16)unsubscribeTopic:(NSString *)topic
        unsubscribeHandler:(MQTTUnsubscribeHandler)unsubscribeHandler {
    return [self unsubscribeTopics:topic ? @[topic] : @[] unsubscribeHandler:unsubscribeHandler];
}

- (UInt16)unsubscribeTopicV5:(NSString *)topic
          unsubscribeHandler:(MQTTUnsubscribeHandlerV5)unsubscribeHandler {
    return [self unsubscribeTopicsV5:topic ? @[topic] : @[] unsubscribeHandler:unsubscribeHandler];
}

- (UInt16)unsubscribeTopics:(NSArray<NSString *> *)topics {
    return [self unsubscribeTopics:topics unsubscribeHandler:nil];
}

- (UInt16)unsubscribeTopicsV5:(NSArray<NSString *> *)topics {
    return [self unsubscribeTopics:topics unsubscribeHandler:nil];
}

- (UInt16)unsubscribeTopics:(NSArray<NSString *> *)topics
         unsubscribeHandler:(MQTTUnsubscribeHandler)unsubscribeHandler {
    DDLogVerbose(@"[MQTTSession] unsubscribeTopics:%@", topics);

    [self checkTopicFilters:topics];

    UInt16 mid = [self nextMsgId];
    if (unsubscribeHandler) {
        (self.unsubscribeHandlers)[@(mid)] = [unsubscribeHandler copy];
    } else {
        [self.unsubscribeHandlers removeObjectForKey:@(mid)];
    }
    (void)[self encode:[MQTTMessage unsubscribeMessageWithMessageId:mid
                                                             topics:topics
                                                      protocolLevel:self.protocolLevel]];
    return mid;
}

- (UInt16)unsubscribeTopicsV5:(NSArray<NSString *> *)topics
           unsubscribeHandler:(MQTTUnsubscribeHandlerV5)unsubscribeHandler {
    DDLogVerbose(@"[MQTTSession] unsubscribeTopicsV5:%@", topics);

    [self checkTopicFilters:topics];

    UInt16 mid = [self nextMsgId];
    if (unsubscribeHandler) {
        (self.unsubscribeHandlersV5)[@(mid)] = [unsubscribeHandler copy];
    } else {
        [self.unsubscribeHandlersV5 removeObjectForKey:@(mid)];
    }
    (void)[self encode:[MQTTMessage unsubscribeMessageWithMessageId:mid
                                                             topics:topics
                                                      protocolLevel:self.protocolLevel]];
    return mid;
}


/*  ____   _   _  ____   _      ___  ____   _   _
 * |  _ \ | | | || __ ) | |    |_ _|/ ___| | | | |
 * | |_) || | | ||  _ \ | |     | | \___ \ | |_| |
 * |  __/ | |_| || |_) || |___  | |  ___) ||  _  |
 * |_|     \___/ |____/ |_____||___||____/ |_| |_|
 */
- (UInt16)publishData:(NSData*)data
              onTopic:(NSString*)topic
               retain:(BOOL)retainFlag
                  qos:(MQTTQosLevel)qos {
    return [self publishDataV5:data
                       onTopic:topic
                        retain:retainFlag
                           qos:qos
        payloadFormatIndicator:0
     publicationExpiryInterval:0
                    topicAlias:0
                 responseTopic:nil
               correlationData:nil
                userProperties:nil
                   contentType:nil];
}

- (UInt16)publishDataV5:(NSData *)data
                onTopic:(NSString *)topic
                 retain:(BOOL)retainFlag
                    qos:(MQTTQosLevel)qos
 payloadFormatIndicator:(NSNumber *)payloadFormatIndicator
publicationExpiryInterval:(NSNumber *)publicationExpiryInterval
             topicAlias:(NSNumber *)topicAlias
          responseTopic:(NSString *)responseTopic
        correlationData:(NSData *)correlationData
         userProperties:(NSArray<NSDictionary<NSString *,NSString *> *> *)userProperties
            contentType:(NSString *)contentType {
    return [self publishDataV5:data
                       onTopic:topic
                        retain:retainFlag
                           qos:qos
        payloadFormatIndicator:payloadFormatIndicator
     publicationExpiryInterval:publicationExpiryInterval
                    topicAlias:topicAlias
                 responseTopic:responseTopic
               correlationData:correlationData
                userProperties:userProperties
                   contentType:contentType
                publishHandler:nil];
}

- (UInt16)publishData:(NSData *)data
              onTopic:(NSString *)topic
               retain:(BOOL)retainFlag
                  qos:(MQTTQosLevel)qos
       publishHandler:(MQTTPublishHandler)publishHandler {
    return [self publishDataV5:data
                       onTopic:topic
                        retain:retainFlag
                           qos:qos
        payloadFormatIndicator:0
     publicationExpiryInterval:0
                    topicAlias:0
                 responseTopic:nil
               correlationData:nil
                userProperties:nil
                   contentType:nil
                publishHandler:nil];

}

- (UInt16)publishDataV5:(NSData *)data
                onTopic:(NSString *)topic
                 retain:(BOOL)retainFlag
                    qos:(MQTTQosLevel)qos
 payloadFormatIndicator:(NSNumber *)payloadFormatIndicator
publicationExpiryInterval:(NSNumber *)publicationExpiryInterval
             topicAlias:(NSNumber *)topicAlias
          responseTopic:(NSString *)responseTopic
        correlationData:(NSData *)correlationData
         userProperties:(NSArray<NSDictionary<NSString *,NSString *> *> *)userProperties
            contentType:(NSString *)contentType
         publishHandler:(MQTTPublishHandler)publishHandler {

    DDLogVerbose(@"[MQTTSession] publishData:%@... onTopic:%@ retain:%d qos:%ld "
                 "payloadFormatIndicator %@ "
                 "publicationExpiryInterval %@ "
                 "topicAlias %@ "
                 "responseTopic %@ "
                 "correlationData %@ "
                 "userProperties %@ "
                 "contentType %@ "
                 "publishHandler:%p",
                 [data subdataWithRange:NSMakeRange(0, MIN(256, data.length))],
                 [topic substringWithRange:NSMakeRange(0, MIN(256, topic.length))],
                 retainFlag,
                 (long)qos,
                 payloadFormatIndicator,
                 publicationExpiryInterval,
                 topicAlias,
                 responseTopic,
                 correlationData,
                 userProperties,
                 contentType,
                 publishHandler);

    if (MQTTStrict.strict &&
        !topic) {
        NSException* myException = [NSException
                                    exceptionWithName:@"topic must not be nil"
                                    reason:[NSString stringWithFormat:@"%@", topic]
                                    userInfo:nil];
        @throw myException;
    }

    if (MQTTStrict.strict &&
        topic &&
        topic.length < 1) {
        NSException* myException = [NSException
                                    exceptionWithName:@"topic must not at least 1 character long"
                                    reason:[NSString stringWithFormat:@"%@", topic]
                                    userInfo:nil];
        @throw myException;
    }

    if (MQTTStrict.strict &&
        topic &&
        [topic dataUsingEncoding:NSUTF8StringEncoding].length > 65535L) {
        NSException* myException = [NSException
                                    exceptionWithName:@"topic may not be longer than 65535 bytes in UTF8 representation"
                                    reason:[NSString stringWithFormat:@"topic length = %lu",
                                            (unsigned long)[topic dataUsingEncoding:NSUTF8StringEncoding].length]
                                    userInfo:nil];
        @throw myException;
    }

    if (MQTTStrict.strict &&
        topic &&
        ![topic dataUsingEncoding:NSUTF8StringEncoding]) {
        NSException* myException = [NSException
                                    exceptionWithName:@"topic must not contain non-UTF8 characters"
                                    reason:[NSString stringWithFormat:@"topic = %@", topic]
                                    userInfo:nil];
        @throw myException;
    }

    if (MQTTStrict.strict &&
        self.willTopic &&
        ([self.willTopic containsString:@"+"] ||
         [self.willTopic containsString:@"#"])
        ) {
        NSException* myException = [NSException
                                    exceptionWithName:@"willTopic must not contain wildcards"
                                    reason:[NSString stringWithFormat:@"willTopic = %@", self.willTopic]
                                    userInfo:nil];
        @throw myException;
    }

    if (MQTTStrict.strict &&
        qos != MQTTQosLevelAtMostOnce &&
        qos != MQTTQosLevelAtLeastOnce &&
        qos != MQTTQosLevelExactlyOnce) {
        NSException* myException = [NSException
                                    exceptionWithName:@"Illegal QoS level"
                                    reason:[NSString stringWithFormat:@"%d is not 0, 1, or 2", qos]
                                    userInfo:nil];
        @throw myException;
    }

    NSData *userPropertiesAsData = nil;
    if (userProperties && [NSJSONSerialization isValidJSONObject:userProperties]) {
        userPropertiesAsData = [NSJSONSerialization dataWithJSONObject:userProperties options:0 error:nil];
    }

    UInt16 msgId = 0;
    if (!qos) {
        MQTTMessage *msg = [MQTTMessage publishMessageWithData:data
                                                       onTopic:topic
                                                           qos:qos
                                                         msgId:msgId
                                                    retainFlag:retainFlag
                                                       dupFlag:FALSE
                                                 protocolLevel:self.protocolLevel
                                        payloadFormatIndicator:payloadFormatIndicator
                                     publicationExpiryInterval:publicationExpiryInterval
                                                    topicAlias:topicAlias
                                                 responseTopic:responseTopic
                                               correlationData:correlationData
                                                userProperties:userProperties
                                                   contentType:contentType];
        NSError *error = nil;
        if (![self encode:msg]) {
            error = [NSError errorWithDomain:MQTTSessionErrorDomain
                                        code:MQTTSessionErrorEncoderNotReady
                                    userInfo:@{NSLocalizedDescriptionKey : @"Encoder not ready"}];
        }
        if (publishHandler) {
            [self onPublish:publishHandler error:error];
        }
    } else {
        msgId = [self nextMsgId];
        MQTTMessage *msg = nil;

        id<MQTTFlow> flow;
        if (self.status == MQTTSessionStatusConnected) {
            NSArray *flows = [self.persistence allFlowsforClientId:self.clientId
                                                      incomingFlag:NO];

            BOOL unprocessedMessageNotExists = TRUE;
            NSUInteger windowSize = 0;
            for (id<MQTTFlow> flow in flows) {
                if ((flow.commandType).intValue != MQTT_None) {
                    windowSize++;
                } else {
                    unprocessedMessageNotExists = FALSE;
                }
            }
            if (unprocessedMessageNotExists && windowSize <= self.persistence.maxWindowSize) {
                msg = [MQTTMessage publishMessageWithData:data
                                                  onTopic:topic
                                                      qos:qos
                                                    msgId:msgId
                                               retainFlag:retainFlag
                                                  dupFlag:FALSE
                                            protocolLevel:self.protocolLevel
                                   payloadFormatIndicator:payloadFormatIndicator
                                publicationExpiryInterval:publicationExpiryInterval
                                               topicAlias:topicAlias
                                            responseTopic:responseTopic
                                          correlationData:correlationData
                                           userProperties:userProperties
                                              contentType:contentType];
                flow = [self.persistence storeMessageForClientId:self.clientId
                                                           topic:topic
                                                            data:data
                                                      retainFlag:retainFlag
                                                             qos:qos
                                                           msgId:msgId
                                                    incomingFlag:NO
                                                     commandType:MQTTPublish
                                                        deadline:[NSDate dateWithTimeIntervalSinceNow:self.dupTimeout]
                                          payloadFormatIndicator:payloadFormatIndicator
                                       publicationExpiryInterval:publicationExpiryInterval
                                                      topicAlias:topicAlias
                                                   responseTopic:responseTopic
                                                 correlationData:correlationData
                                                  userProperties:userPropertiesAsData
                                                     contentType:contentType];
            }
        }
        if (!msg) {
            flow = [self.persistence storeMessageForClientId:self.clientId
                                                       topic:topic
                                                        data:data
                                                  retainFlag:retainFlag
                                                         qos:qos
                                                       msgId:msgId
                                                incomingFlag:NO
                                                 commandType:MQTT_None
                                                    deadline:[NSDate date]
                                      payloadFormatIndicator:payloadFormatIndicator
                                   publicationExpiryInterval:publicationExpiryInterval
                                                  topicAlias:topicAlias
                                               responseTopic:responseTopic
                                             correlationData:correlationData
                                              userProperties:userPropertiesAsData
                                                 contentType:contentType];
        }
        if (!flow) {
            DDLogWarn(@"[MQTTSession] dropping outgoing message %d", msgId);
            NSError *error = [NSError errorWithDomain:MQTTSessionErrorDomain
                                                 code:MQTTSessionErrorDroppingOutgoingMessage
                                             userInfo:@{NSLocalizedDescriptionKey : @"Dropping outgoing Message"}];
            if (publishHandler) {
                [self onPublish:publishHandler error:error];
            }
            msgId = 0;
        } else {
            [self.persistence sync];
            if (publishHandler) {
                (self.publishHandlers)[@(msgId)] = [publishHandler copy];
            } else {
                [self.publishHandlers removeObjectForKey:@(msgId)];
            }

            if ((flow.commandType).intValue == MQTTPublish) {
                DDLogVerbose(@"[MQTTSession] PUBLISH %d", msgId);
                if (![self encode:msg]) {
                    DDLogInfo(@"[MQTTSession] queueing message %d after unsuccessfull attempt", msgId);
                    flow.commandType = [NSNumber numberWithUnsignedInt:MQTT_None];
                    flow.deadline = [NSDate date];
                    [self.persistence sync];
                }
            } else {
                DDLogInfo(@"[MQTTSession] queueing message %d", msgId);
            }
        }
    }
    [self tell];
    return msgId;
}


- (void)close {
    [self closeWithDisconnectHandler:nil];
}

- (void)closeWithDisconnectHandler:(MQTTDisconnectHandler)disconnectHandler {
    [self closeWithReturnCode:MQTTSuccess
        sessionExpiryInterval:nil
                 reasonString:nil
               userProperties:nil
            disconnectHandler:disconnectHandler];
}

- (void)closeWithReturnCode:(MQTTReturnCode)returnCode
      sessionExpiryInterval:(NSNumber *)sessionExpiryInterval
               reasonString:(NSString *)reasonString
             userProperties:(NSArray <NSDictionary<NSString *,NSString *> *>*)userProperties
          disconnectHandler:(MQTTDisconnectHandler)disconnectHandler {
    DDLogVerbose(@"[MQTTSession] closeWithDisconnectHandler:%p ", disconnectHandler);
    self.disconnectHandler = disconnectHandler;

    if (self.status == MQTTSessionStatusConnected) {
        [self disconnectWithReturnCode:returnCode
                 sessionExpiryInterval:sessionExpiryInterval
                          reasonString:reasonString
                        userProperties:userProperties];
    } else {
        [self closeInternal];
    }
}

- (void)disconnect {
    [self disconnectWithReturnCode:MQTTSuccess
             sessionExpiryInterval:nil
                      reasonString:nil
                    userProperties:nil];
}

- (void)disconnectWithReturnCode:(MQTTReturnCode)returnCode
           sessionExpiryInterval:(NSNumber *)sessionExpiryInterval
                    reasonString:(NSString *)reasonString
                  userProperties:(NSArray <NSDictionary<NSString *,NSString *> *> *)userProperties {
    DDLogVerbose(@"[MQTTSession] sending DISCONNECT");
    self.status = MQTTSessionStatusDisconnecting;

    (void)[self encode:[MQTTMessage disconnectMessage:self.protocolLevel
                                           returnCode:returnCode
                                sessionExpiryInterval:sessionExpiryInterval
                                         reasonString:reasonString
                                       userProperties:userProperties]];
}

- (void)closeInternal
{
    DDLogVerbose(@"[MQTTSession] closeInternal");

    if (self.checkDupTimer) {
        [self.checkDupTimer invalidate];
        self.checkDupTimer = nil;
    }

    if (self.keepAliveTimer) {
        [self.keepAliveTimer invalidate];
        self.keepAliveTimer = nil;
    }

    if (self.transport) {
        [self.transport close];
        self.transport.delegate = nil;
    }

    if(self.decoder){
        [self.decoder close];
        self.decoder.delegate = nil;
    }

    NSArray *flows = [self.persistence allFlowsforClientId:self.clientId
                                              incomingFlag:NO];
    for (id<MQTTFlow> flow in flows) {
        switch ((flow.commandType).intValue) {
            case MQTTPublish:
            case MQTTPubrel:
                flow.deadline = [flow.deadline dateByAddingTimeInterval:-self.dupTimeout];
                [self.persistence sync];
                break;
        }
    }

    self.status = MQTTSessionStatusClosed;
    if ([self.delegate respondsToSelector:@selector(handleEvent:event:error:)]) {
        [self.delegate handleEvent:self event:MQTTSessionEventConnectionClosed error:nil];
    }
    if ([self.delegate respondsToSelector:@selector(connectionClosed:)]) {
        [self.delegate connectionClosed:self];
    }

    NSError *error = [NSError errorWithDomain:MQTTSessionErrorDomain
                                         code:MQTTSessionErrorNoResponse
                                     userInfo:@{NSLocalizedDescriptionKey : @"No response"}];

    NSArray *allSubscribeHandlers = self.subscribeHandlers.allValues;
    [self.subscribeHandlers removeAllObjects];
    for (MQTTSubscribeHandler subscribeHandler in allSubscribeHandlers) {
        subscribeHandler(error, nil);
    }

    NSArray *allSubscribeHandlersV5 = self.subscribeHandlersV5.allValues;
    [self.subscribeHandlersV5 removeAllObjects];
    for (MQTTSubscribeHandlerV5 subscribeHandlerV5 in allSubscribeHandlersV5) {
        subscribeHandlerV5(error, nil, nil, nil);
    }

    NSArray *allUnsubscribeHandlers = self.unsubscribeHandlers.allValues;
    [self.unsubscribeHandlers removeAllObjects];
    for (MQTTUnsubscribeHandler unsubscribeHandler in allUnsubscribeHandlers) {
        unsubscribeHandler(error);
    }

    NSArray *allUnsubscribeHandlersV5 = self.unsubscribeHandlersV5.allValues;
    [self.unsubscribeHandlersV5 removeAllObjects];
    for (MQTTUnsubscribeHandlerV5 unsubscribeHandlerV5 in allUnsubscribeHandlersV5) {
        unsubscribeHandlerV5(error, nil, nil, nil);
    }

    MQTTDisconnectHandler disconnectHandler = self.disconnectHandler;
    if (disconnectHandler) {
        self.disconnectHandler = nil;
        disconnectHandler(nil);
    }

    [self tell];
    self.synchronPub = FALSE;
    self.synchronPubMid = 0;
    self.synchronSub = FALSE;
    self.synchronSubMid = 0;
    self.synchronUnsub = FALSE;
    self.synchronUnsubMid = 0;
}


- (void)keepAlive:(NSTimer *)timer {
    DDLogVerbose(@"[MQTTSession] keepAlive %@ @%.0f", self.clientId, [[NSDate date] timeIntervalSince1970]);
    (void)[self encode:[MQTTMessage pingreqMessage]];
}

- (void)checkDup:(NSTimer *)timer {
    DDLogVerbose(@"[MQTTSession] checkDup %@ @%.0f", self.clientId, [[NSDate date] timeIntervalSince1970]);
    [self checkTxFlows];
}

- (void)checkTxFlows {
    NSUInteger windowSize;
    MQTTMessage *message;
    if (self.status != MQTTSessionStatusConnected) {
        return;
    }

    NSArray *flows = [self.persistence allFlowsforClientId:self.clientId
                                              incomingFlag:NO];
    windowSize = 0;
    message = nil;

    for (id<MQTTFlow> flow in flows) {
        if ((flow.commandType).intValue != MQTT_None) {
            windowSize++;
        }
    }
    for (id<MQTTFlow> flow in flows) {
        DDLogVerbose(@"[MQTTSession] %@ flow %@ %@ %@", self.clientId, flow.deadline, flow.commandType, flow.messageId);
        if ([flow.deadline compare:[NSDate date]] == NSOrderedAscending) {
            NSArray <NSDictionary <NSString *, NSString *> *> *userProperties = nil;
            if (flow.userProperties) {
                userProperties = [NSJSONSerialization JSONObjectWithData:flow.userProperties options:0 error:nil];
            }

            switch ((flow.commandType).intValue) {
                case 0:
                    if (windowSize <= self.persistence.maxWindowSize) {
                        DDLogVerbose(@"[MQTTSession] PUBLISH queued message %@", flow.messageId);
                        message = [MQTTMessage publishMessageWithData:flow.data
                                                              onTopic:flow.topic
                                                                  qos:(flow.qosLevel).intValue
                                                                msgId:(flow.messageId).intValue
                                                           retainFlag:(flow.retainedFlag).boolValue
                                                              dupFlag:NO
                                                        protocolLevel:self.protocolLevel
                                               payloadFormatIndicator:flow.payloadFormatIndicator
                                            publicationExpiryInterval:flow.publicationExpiryInterval
                                                           topicAlias:flow.topicAlias
                                                        responseTopic:flow.responseTopic
                                                      correlationData:flow.correlationData
                                                       userProperties:userProperties
                                                          contentType:flow.contentType];
                        if ([self encode:message]) {
                            flow.commandType = @(MQTTPublish);
                            flow.deadline = [NSDate dateWithTimeIntervalSinceNow:self.dupTimeout];
                            [self.persistence sync];
                            windowSize++;
                        }
                    }
                    break;
                case MQTTPublish:
                    DDLogInfo(@"[MQTTSession] resend PUBLISH %@", flow.messageId);
                    message = [MQTTMessage publishMessageWithData:flow.data
                                                          onTopic:flow.topic
                                                              qos:(flow.qosLevel).intValue
                                                            msgId:(flow.messageId).intValue
                                                       retainFlag:(flow.retainedFlag).boolValue
                                                          dupFlag:YES
                                                    protocolLevel:self.protocolLevel
                                           payloadFormatIndicator:flow.payloadFormatIndicator
                                        publicationExpiryInterval:flow.publicationExpiryInterval
                                                       topicAlias:flow.topicAlias
                                                    responseTopic:flow.responseTopic
                                                  correlationData:flow.correlationData
                                                   userProperties:userProperties
                                                      contentType:flow.contentType];
                    if ([self encode:message]) {
                        flow.deadline = [NSDate dateWithTimeIntervalSinceNow:self.dupTimeout];
                        [self.persistence sync];
                    }
                    break;
                case MQTTPubrel:
                    DDLogInfo(@"[MQTTSession] resend PUBREL %@", flow.messageId);
                    message = [MQTTMessage pubrelMessageWithMessageId:(flow.messageId).intValue
                                                        protocolLevel:self.protocolLevel
                                                           returnCode:MQTTSuccess
                                                         reasonString:nil
                                                       userProperties:nil];
                    if ([self encode:message]) {
                        flow.deadline = [NSDate dateWithTimeIntervalSinceNow:self.dupTimeout];
                        [self.persistence sync];
                    }
                    break;
                default:
                    break;
            }
        }
    }
}

- (void)decoder:(MQTTDecoder*)sender handleEvent:(MQTTDecoderEvent)eventCode error:(NSError *)error {
    __unused NSArray *events = @[
                                 @"MQTTDecoderEventProtocolError",
                                 @"MQTTDecoderEventConnectionClosed",
                                 @"MQTTDecoderEventConnectionError"
                                 ];
    DDLogVerbose(@"[MQTTSession] decoder handleEvent: %@ (%d) %@",
                 events[eventCode % [events count]],
                 eventCode,
                 [error description]);

    switch (eventCode) {
        case MQTTDecoderEventConnectionClosed:
            [self error:MQTTSessionEventConnectionClosedByBroker error:error];
            break;
        case MQTTDecoderEventConnectionError:
            [self connectionError:error];
            break;
        case MQTTDecoderEventProtocolError:
            [self protocolError:error];
            break;
    }
    MQTTConnectHandler connectHandler = self.connectHandler;
    if (connectHandler) {
        self.connectHandler = nil;
        [self onConnect:connectHandler error:error];
    }
}

- (void)decoder:(MQTTDecoder*)sender didReceiveMessage:(NSData *)data {
    MQTTMessage *message = [MQTTMessage messageFromData:data
                                          protocolLevel:self.protocolLevel
                                    maximumPacketLength:self.maximumPacketSize];
    if (!message) {
        DDLogError(@"[MQTTSession] MQTT illegal message received");
        NSError * error = [NSError errorWithDomain:MQTTSessionErrorDomain
                                              code:MQTTSessionErrorIllegalMessageReceived
                                          userInfo:@{NSLocalizedDescriptionKey : @"MQTT illegal message received"}];
        [self protocolError:error];

        return;
    }

    @synchronized(sender) {
        if ([self.delegate respondsToSelector:@selector(received:type:qos:retained:duped:mid:data:)]) {
            [self.delegate received:self
                               type:message.type
                                qos:message.qos
                           retained:message.retainFlag
                              duped:message.dupFlag
                                mid:message.mid
                               data:message.data];
        }
        if ([self.delegate respondsToSelector:@selector(ignoreReceived:type:qos:retained:duped:mid:data:)]) {
            if ([self.delegate ignoreReceived:self
                                         type:message.type
                                          qos:message.qos
                                     retained:message.retainFlag
                                        duped:message.dupFlag
                                          mid:message.mid
                                         data:message.data]) {
                return;
            }
        }
        switch (self.status) {
            case MQTTSessionStatusConnecting:
                switch (message.type) {
                    case MQTTConnack:
                        if ((self.protocolLevel == MQTTProtocolVersion50 && message.data.length < 3) ||
                            (self.protocolLevel != MQTTProtocolVersion50 && message.data.length != 2)) {
                            NSError *error = [NSError errorWithDomain:MQTTSessionErrorDomain
                                                                 code:MQTTSessionErrorInvalidConnackReceived
                                                             userInfo:@{NSLocalizedDescriptionKey : @"MQTT protocol CONNACK expected"}];

                            [self protocolError:error];
                            MQTTConnectHandler connectHandler = self.connectHandler;
                            if (connectHandler) {
                                self.connectHandler = nil;
                                [self onConnect:connectHandler error:error];
                            }
                        } else {
                            if (message.returnCode && (message.returnCode).intValue == MQTTSuccess) {
                                self.status = MQTTSessionStatusConnected;
                                if (message.connectAcknowledgeFlags &&
                                    ((message.connectAcknowledgeFlags).unsignedIntValue & 0x01) == 0x01) {
                                    self.sessionPresent = true;
                                } else {
                                    self.sessionPresent = false;
                                }

                                self.checkDupTimer = [NSTimer timerWithTimeInterval:DUPLOOP
                                                                             target:self
                                                                           selector:@selector(checkDup:)
                                                                           userInfo:nil
                                                                            repeats:YES];
                                [self.runLoop addTimer:self.checkDupTimer forMode:self.runLoopMode];
                                [self checkDup:self.checkDupTimer];

                                if (message.properties) {
                                    self.assignedClientIdentifier = message.properties.assignedClientIdentifier;
                                    self.serverKeepAlive = message.properties.serverKeepAlive;
                                    self.brokerAuthMethod = message.properties.authMethod;
                                    self.brokerAuthData = message.properties.authData;
                                    self.brokerResponseInformation = message.properties.responseInformation;
                                    self.serverReference = message.properties.serverReference;
                                    self.brokerReasonString = message.properties.reasonString;
                                    self.brokerReceiveMaximum = message.properties.receiveMaximum;
                                    self.brokerTopicAliasMaximum = message.properties.topicAliasMaximum;
                                    self.maximumQoS = message.properties.maximumQoS;
                                    self.retainAvailable = message.properties.retainAvailable;
                                    self.brokerUserProperties = message.properties.userProperties;
                                    self.brokerMaximumPacketSize = message.properties.maximumPacketSize;
                                    self.wildcardSubscriptionAvailable = message.properties.wildcardSubscriptionAvailable;
                                    self.subscriptionIdentifiersAvailable = message.properties.subscriptionIdentifiersAvailable;
                                    self.sharedSubscriptionAvailable = message.properties.sharedSubscriptionAvailable;
                                }

                                if (self.serverKeepAlive) {
                                    self.effectiveKeepAlive = (self.serverKeepAlive).unsignedShortValue;
                                } else {
                                    self.effectiveKeepAlive = self.keepAliveInterval;
                                }

                                if (self.effectiveKeepAlive > 0) {
                                    self.keepAliveTimer = [NSTimer
                                                           timerWithTimeInterval:self.effectiveKeepAlive
                                                           target:self
                                                           selector:@selector(keepAlive:)
                                                           userInfo:nil
                                                           repeats:YES];
                                    [self.runLoop addTimer:self.keepAliveTimer forMode:self.runLoopMode];
                                }

                                if ([self.delegate respondsToSelector:@selector(handleEvent:event:error:)]) {
                                    [self.delegate handleEvent:self event:MQTTSessionEventConnected error:nil];
                                }
                                if ([self.delegate respondsToSelector:@selector(connected:)]) {
                                    [self.delegate connected:self];
                                }
                                if ([self.delegate respondsToSelector:@selector(connected:sessionPresent:)]) {
                                    [self.delegate connected:self sessionPresent:self.sessionPresent];
                                }

                                if(self.connectionHandler){
                                    self.connectionHandler(MQTTSessionEventConnected);
                                }
                                MQTTConnectHandler connectHandler = self.connectHandler;
                                if (connectHandler) {
                                    self.connectHandler = nil;
                                    [self onConnect:connectHandler error:nil];
                                }

                            } else {
                                NSString *errorDescription = @"unknown";
                                NSInteger errorCode = 0;
                                if (message.returnCode) {
                                    switch ((message.returnCode).intValue) {
                                        case 1:
                                            errorDescription = @"MQTT CONNACK: unacceptable protocol version";
                                            errorCode = MQTTSessionErrorConnackUnacceptableProtocolVersion;
                                            break;
                                        case 2:
                                            errorDescription = @"MQTT CONNACK: identifier rejected";
                                            errorCode = MQTTSessionErrorConnackIdentifierRejected;
                                            break;
                                        case 3:
                                            errorDescription = @"MQTT CONNACK: server unavailable";
                                            errorCode = MQTTSessionErrorConnackServeUnavailable;
                                            break;
                                        case 4:
                                            errorDescription = @"MQTT CONNACK: bad user name or password";
                                            errorCode = MQTTSessionErrorConnackBadUsernameOrPassword;
                                            break;
                                        case 5:
                                            errorDescription = @"MQTT CONNACK: not authorized";
                                            errorCode = MQTTSessionErrorConnackNotAuthorized;
                                            break;
                                        default:
                                            errorDescription = @"MQTT CONNACK: reserved for future use";
                                            errorCode = MQTTSessionErrorConnackReserved;
                                            break;
                                    }
                                }

                                NSError *error = [NSError errorWithDomain:MQTTSessionErrorDomain
                                                                     code:errorCode
                                                                 userInfo:@{NSLocalizedDescriptionKey : errorDescription}];
                                [self error:MQTTSessionEventConnectionRefused error:error];
                                if ([self.delegate respondsToSelector:@selector(connectionRefused:error:)]) {
                                    [self.delegate connectionRefused:self error:error];
                                }
                                MQTTConnectHandler connectHandler = self.connectHandler;
                                if (connectHandler) {
                                    self.connectHandler = nil;
                                    [self onConnect:connectHandler error:error];
                                }
                            }

                            self.synchronConnect = FALSE;
                        }
                        break;
                    case MQTTDisconnect: {
                        NSError *error = [NSError errorWithDomain:MQTTSessionErrorDomain
                                                             code:(message.returnCode).intValue
                                                         userInfo:@{NSLocalizedDescriptionKey : @"MQTT protocol DISCONNECT instead of CONNACK"}];

                        [self protocolError:error];
                        MQTTConnectHandler connectHandler = self.connectHandler;
                        if (connectHandler) {
                            self.connectHandler = nil;
                            [self onConnect:connectHandler error:error];
                        }
                        break;
                    }
                    default: {
                        NSError * error = [NSError errorWithDomain:MQTTSessionErrorDomain
                                                              code:MQTTSessionErrorNoConnackReceived
                                                          userInfo:@{NSLocalizedDescriptionKey : @"MQTT protocol no CONNACK"}];
                        [self protocolError:error];
                        MQTTConnectHandler connectHandler = self.connectHandler;
                        if (connectHandler) {
                            self.connectHandler = nil;
                            [self onConnect:connectHandler error:error];
                        }
                        break;
                    }
                }
                break;
            case MQTTSessionStatusConnected:
                switch (message.type) {
                    case MQTTPublish:
                        [self handlePublish:message];
                        break;
                    case MQTTPuback:
                        [self handlePuback:message];
                        break;
                    case MQTTPubrec:
                        [self handlePubrec:message];
                        break;
                    case MQTTPubrel:
                        [self handlePubrel:message];
                        break;
                    case MQTTPubcomp:
                        [self handlePubcomp:message];
                        break;
                    case MQTTSuback:
                        [self handleSuback:message];
                        break;
                    case MQTTUnsuback:
                        [self handleUnsuback:message];
                        break;
                    case MQTTDisconnect: {
                        NSError *error = [NSError errorWithDomain:MQTTSessionErrorDomain
                                                             code:(message.returnCode).intValue
                                                         userInfo:@{NSLocalizedDescriptionKey : @"MQTT protocol DISCONNECT received"}];

                        [self protocolError:error];
                    }

                    default:
                        break;
                }
                break;
            default:
                DDLogError(@"[MQTTSession] other state");
                break;
        }
    }
}

- (void)handlePublish:(MQTTMessage*)msg {
    NSData *data = msg.data;
    if (data.length < 2) {
        return;
    }
    UInt8 const *bytes = data.bytes;
    UInt16 topicLength = 256 * bytes[0] + bytes[1];
    if (data.length < 2 + topicLength) {
        return;
    }
    NSData *topicData = [data subdataWithRange:NSMakeRange(2, topicLength)];
    NSString *topic = [[NSString alloc] initWithData:topicData
                                            encoding:NSUTF8StringEncoding];
    if (!topic) {
        topic = [[NSString alloc] initWithData:topicData
                                      encoding:NSISOLatin1StringEncoding];
        DDLogError(@"non UTF8 topic %@", topic);
    }
    NSRange range = NSMakeRange(2 + topicLength, data.length - topicLength - 2);
    data = [data subdataWithRange:range];

    if (msg.qos == 0) {
        if (self.protocolLevel == MQTTProtocolVersion50) {
            int propertiesLength = [MQTTProperties getVariableLength:data];
            int variableLength = [MQTTProperties variableIntLength:propertiesLength];
            msg.properties = [[MQTTProperties alloc] initFromData:data];
            NSRange range = NSMakeRange(variableLength + propertiesLength, data.length - variableLength - propertiesLength);
            data = [data subdataWithRange:range];
        }
        if ([self.delegate respondsToSelector:@selector(newMessage:data:onTopic:qos:retained:mid:)]) {
            [self.delegate newMessage:self
                                 data:data
                              onTopic:topic
                                  qos:msg.qos
                             retained:msg.retainFlag
                                  mid:0];
        }
        if ([self.delegate respondsToSelector:@selector(newMessageV5:data:onTopic:qos:retained:mid:payloadFormatIndicator:publicationExpiryInterval:topicAlias:responseTopic:correlationData:userProperties:contentType:subscriptionIdentifiers:)]) {
            [self.delegate newMessageV5:self
                                   data:data
                                onTopic:topic
                                    qos:msg.qos
                               retained:msg.retainFlag
                                    mid:0
                 payloadFormatIndicator:msg.properties.payloadFormatIndicator
              publicationExpiryInterval:msg.properties.publicationExpiryInterval
                             topicAlias:msg.properties.topicAlias
                          responseTopic:msg.properties.responseTopic
                        correlationData:msg.properties.correlationData
                         userProperties:msg.properties.userProperties
                            contentType:msg.properties.contentType
                subscriptionIdentifiers:msg.properties.subscriptionIdentifiers];
        }

        if ([self.delegate respondsToSelector:@selector(newMessageWithFeedback:data:onTopic:qos:retained:mid:)]) {
            [self.delegate newMessageWithFeedback:self
                                             data:data
                                          onTopic:topic
                                              qos:msg.qos
                                         retained:msg.retainFlag
                                              mid:0];
        }
        if ([self.delegate respondsToSelector:@selector(newMessageWithFeedbackV5:data:onTopic:qos:retained:mid:payloadFormatIndicator:publicationExpiryInterval:topicAlias:responseTopic:correlationData:userProperties:contentType:subscriptionIdentifiers:)]) {
            [self.delegate newMessageWithFeedbackV5:self
                                               data:data
                                            onTopic:topic
                                                qos:msg.qos
                                           retained:msg.retainFlag
                                                mid:0
                             payloadFormatIndicator:msg.properties.payloadFormatIndicator
                          publicationExpiryInterval:msg.properties.publicationExpiryInterval
                                         topicAlias:msg.properties.topicAlias
                                      responseTopic:msg.properties.responseTopic
                                    correlationData:msg.properties.correlationData
                                     userProperties:msg.properties.userProperties
                                        contentType:msg.properties.contentType
                            subscriptionIdentifiers:msg.properties.subscriptionIdentifiers];
        }
        if (self.messageHandler) {
            self.messageHandler(data, topic);
        }
    } else {
        if (data.length >= 2) {
            bytes = data.bytes;
            UInt16 msgId = 256 * bytes[0] + bytes[1];
            msg.mid = msgId;
            data = [data subdataWithRange:NSMakeRange(2, data.length - 2)];
            if (msg.qos == 1) {
                if (self.protocolLevel == MQTTProtocolVersion50) {
                    int propertiesLength = [MQTTProperties getVariableLength:data];
                    int variableLength = [MQTTProperties variableIntLength:propertiesLength];
                    msg.properties = [[MQTTProperties alloc] initFromData:data];
                    NSRange range = NSMakeRange(variableLength + propertiesLength, data.length - variableLength - propertiesLength);
                    data = [data subdataWithRange:range];
                }

                BOOL processed = true;
                if ([self.delegate respondsToSelector:@selector(newMessage:data:onTopic:qos:retained:mid:)]) {
                    [self.delegate newMessage:self
                                         data:data
                                      onTopic:topic
                                          qos:msg.qos
                                     retained:msg.retainFlag
                                          mid:msgId];
                }
                if ([self.delegate respondsToSelector:@selector(newMessageV5:data:onTopic:qos:retained:mid:payloadFormatIndicator:publicationExpiryInterval:topicAlias:responseTopic:correlationData:userProperties:contentType:subscriptionIdentifiers:)]) {
                    [self.delegate newMessageV5:self
                                           data:data
                                        onTopic:topic
                                            qos:msg.qos
                                       retained:msg.retainFlag
                                            mid:0
                         payloadFormatIndicator:msg.properties.payloadFormatIndicator
                      publicationExpiryInterval:msg.properties.publicationExpiryInterval
                                     topicAlias:msg.properties.topicAlias
                                  responseTopic:msg.properties.responseTopic
                                correlationData:msg.properties.correlationData
                                 userProperties:msg.properties.userProperties
                                    contentType:msg.properties.contentType
                        subscriptionIdentifiers:msg.properties.subscriptionIdentifiers];
                }


                if ([self.delegate respondsToSelector:@selector(newMessageWithFeedback:data:onTopic:qos:retained:mid:)]) {
                    processed = [self.delegate newMessageWithFeedback:self
                                                                 data:data
                                                              onTopic:topic
                                                                  qos:msg.qos
                                                             retained:msg.retainFlag
                                                                  mid:msgId];
                }
                if ([self.delegate respondsToSelector:@selector(newMessageWithFeedbackV5:data:onTopic:qos:retained:mid:payloadFormatIndicator:publicationExpiryInterval:topicAlias:responseTopic:correlationData:userProperties:contentType:subscriptionIdentifiers:)]) {
                    processed = [self.delegate newMessageWithFeedbackV5:self
                                                                   data:data
                                                                onTopic:topic
                                                                    qos:msg.qos
                                                               retained:msg.retainFlag
                                                                    mid:0
                                                 payloadFormatIndicator:msg.properties.payloadFormatIndicator
                                              publicationExpiryInterval:msg.properties.publicationExpiryInterval
                                                             topicAlias:msg.properties.topicAlias
                                                          responseTopic:msg.properties.responseTopic
                                                        correlationData:msg.properties.correlationData
                                                         userProperties:msg.properties.userProperties
                                                            contentType:msg.properties.contentType
                                                subscriptionIdentifiers:msg.properties.subscriptionIdentifiers];
                }

                if (self.messageHandler) {
                    self.messageHandler(data, topic);
                }
                if (processed) {
                    (void)[self encode:[MQTTMessage pubackMessageWithMessageId:msgId
                                                                 protocolLevel:self.protocolLevel
                                                                    returnCode:MQTTSuccess
                                                                  reasonString:nil
                                                                userProperties:nil]];
                }
                return;
            } else {
                if (![self.persistence storeMessageForClientId:self.clientId
                                                         topic:topic
                                                          data:data
                                                    retainFlag:msg.retainFlag
                                                           qos:msg.qos
                                                         msgId:msgId
                                                  incomingFlag:YES
                                                   commandType:MQTTPubrec
                                                      deadline:[NSDate dateWithTimeIntervalSinceNow:self.dupTimeout]
                                        payloadFormatIndicator:0
                                     publicationExpiryInterval:0
                                                    topicAlias:0
                                                 responseTopic:nil
                                               correlationData:nil
                                                userProperties:nil
                                                   contentType:nil]) {
                    DDLogWarn(@"[MQTTSession] dropping incoming messages");
                } else {
                    [self.persistence sync];
                    [self tell];
                    (void)[self encode:[MQTTMessage pubrecMessageWithMessageId:msgId
                                                                 protocolLevel:self.protocolLevel
                                                                    returnCode:MQTTSuccess
                                                                  reasonString:nil
                                                                userProperties:nil]];
                }
            }
        }
    }
}

- (void)handlePuback:(MQTTMessage*)msg {
    id<MQTTFlow> flow = [self.persistence flowforClientId:self.clientId
                                             incomingFlag:NO
                                                messageId:msg.mid];
    if (flow) {
        if ((flow.commandType).intValue == MQTTPublish && (flow.qosLevel).intValue == MQTTQosLevelAtLeastOnce) {
            if ([self.delegate respondsToSelector:@selector(messageDelivered:msgID:)]) {
                [self.delegate messageDelivered:self msgID:msg.mid];
            }
            if ([self.delegate respondsToSelector:@selector(messageDelivered:msgID:topic:data:qos:retainFlag:)]) {
                [self.delegate messageDelivered:self
                                          msgID:msg.mid
                                          topic:flow.topic
                                           data:flow.data
                                            qos:(flow.qosLevel).intValue
                                     retainFlag:(flow.retainedFlag).boolValue];
            }
            if ([self.delegate respondsToSelector:@selector(messageDeliveredV5:msgID:topic:data:qos:retainFlag:payloadFormatIndicator:publicationExpiryInterval:topicAlias:responseTopic:correlationData:userProperties:contentType:)]) {
                NSArray <NSDictionary <NSString *, NSString *> *> *userProperties;
                userProperties = [NSJSONSerialization JSONObjectWithData:flow.userProperties options:0 error:nil];

                [self.delegate messageDeliveredV5:self
                                            msgID:msg.mid
                                            topic:flow.topic
                                             data:flow.data
                                              qos:(flow.qosLevel).intValue
                                       retainFlag:(flow.retainedFlag).boolValue
                           payloadFormatIndicator:flow.payloadFormatIndicator
                        publicationExpiryInterval:flow.publicationExpiryInterval
                                       topicAlias:flow.topicAlias
                                    responseTopic:flow.responseTopic
                                  correlationData:flow.correlationData
                                   userProperties:userProperties
                                      contentType:flow.contentType];
            }
            if (self.synchronPub && self.synchronPubMid == msg.mid) {
                self.synchronPub = FALSE;
            }
            MQTTPublishHandler publishHandler = (self.publishHandlers)[@(msg.mid)];
            if (publishHandler) {
                [self.publishHandlers removeObjectForKey:@(msg.mid)];
                [self onPublish:publishHandler error:nil];
            }
            [self.persistence deleteFlow:flow];
            [self.persistence sync];
            [self tell];
        }
    }
}

- (void)handleSuback:(MQTTMessage*)msg {
    UInt8 const *bytes = msg.data.bytes;
    UInt16 messageId = (256 * bytes[0] + bytes[1]);
    msg.mid = messageId;

    NSData *data = [msg.data subdataWithRange:NSMakeRange(2, msg.data.length - 2)];
    if (self.protocolLevel == MQTTProtocolVersion50) {
        int propertiesLength = [MQTTProperties getVariableLength:data];
        int variableLength = [MQTTProperties variableIntLength:propertiesLength];
        msg.properties = [[MQTTProperties alloc] initFromData:data];
        NSRange range = NSMakeRange(variableLength + propertiesLength, data.length - variableLength - propertiesLength);
        data = [data subdataWithRange:range];
    }

    NSMutableArray *qoss = [[NSMutableArray alloc] init];
    bytes = data.bytes;
    for (int i = 0; i < data.length; i++) {
        [qoss addObject:@(bytes[i])];
    }
    if ([self.delegate respondsToSelector:@selector(subAckReceived:msgID:grantedQoss:)]) {
        [self.delegate subAckReceived:self
                                msgID:msg.mid grantedQoss:qoss];
    }
    if ([self.delegate respondsToSelector:@selector(subAckReceivedV5:msgID:reasonString:userProperties:reasonCodes:)]) {
        [self.delegate subAckReceivedV5:self
                                msgID:msg.mid
                         reasonString:msg.properties.reasonString
                       userProperties:msg.properties.userProperties
                          reasonCodes:qoss];
    }
    if (self.synchronSub && self.synchronSubMid == msg.mid) {
        self.synchronSub = FALSE;
    }
    MQTTSubscribeHandler subscribeHandler = (self.subscribeHandlers)[@(msg.mid)];
    if (subscribeHandler) {
        [self.subscribeHandlers removeObjectForKey:@(msg.mid)];
        [self onSubscribe:subscribeHandler error:nil
                    gQoss:qoss];
    }
    MQTTSubscribeHandlerV5 subscribeHandlerV5 = (self.subscribeHandlersV5)[@(msg.mid)];
    if (subscribeHandlerV5) {
        [self.subscribeHandlersV5 removeObjectForKey:@(msg.mid)];
        [self onSubscribeV5:subscribeHandlerV5
                      error:nil
               reasonString:msg.properties.reasonString
             userProperties:msg.properties.userProperties
                reasonCodes:qoss];
    }
}

- (void)handleUnsuback:(MQTTMessage *)msg {
    UInt8 const *bytes = msg.data.bytes;
    UInt16 messageId = (256 * bytes[0] + bytes[1]);
    msg.mid = messageId;

    NSData *data = [msg.data subdataWithRange:NSMakeRange(2, msg.data.length - 2)];
    if (self.protocolLevel == MQTTProtocolVersion50) {
        int propertiesLength = [MQTTProperties getVariableLength:data];
        int variableLength = [MQTTProperties variableIntLength:propertiesLength];
        msg.properties = [[MQTTProperties alloc] initFromData:data];
        NSRange range = NSMakeRange(variableLength + propertiesLength, data.length - variableLength - propertiesLength);
        data = [data subdataWithRange:range];
    }

    NSMutableArray *reasonCodes = [[NSMutableArray alloc] init];
    bytes = data.bytes;
    for (int i = 0; i < data.length; i++) {
        [reasonCodes addObject:@(bytes[i])];
    }

    if ([self.delegate respondsToSelector:@selector(unsubAckReceived:msgID:)]) {
        [self.delegate unsubAckReceived:self msgID:msg.mid];
    }
    if ([self.delegate respondsToSelector:@selector(unsubAckReceivedV5:msgID:reasonString:userProperties:reasonCodes:)]) {
        [self.delegate unsubAckReceivedV5:self
                                  msgID:msg.mid
                           reasonString:msg.properties.reasonString
                         userProperties:msg.properties.userProperties
                            reasonCodes:reasonCodes];
    }
    if (self.synchronUnsub && self.synchronUnsubMid == msg.mid) {
        self.synchronUnsub = FALSE;
    }
    MQTTUnsubscribeHandler unsubscribeHandler = (self.unsubscribeHandlers)[@(msg.mid)];
    if (unsubscribeHandler) {
        [self.unsubscribeHandlers removeObjectForKey:@(msg.mid)];
        [self onUnsubscribe:unsubscribeHandler error:nil];
    }
    MQTTUnsubscribeHandlerV5 unsubscribeHandlerV5 = (self.unsubscribeHandlersV5)[@(msg.mid)];
    if (unsubscribeHandlerV5) {
        [self.unsubscribeHandlersV5 removeObjectForKey:@(msg.mid)];
        [self onUnsubscribeV5:unsubscribeHandlerV5
                        error:nil
                 reasonString:msg.properties.reasonString
               userProperties:msg.properties.userProperties
                  reasonCodes:reasonCodes];
    }
}

- (void)handlePubrec:(MQTTMessage *)message {
    MQTTMessage *pubrelmessage = [MQTTMessage pubrelMessageWithMessageId:message.mid
                                                           protocolLevel:self.protocolLevel
                                                              returnCode:MQTTSuccess
                                                            reasonString:nil
                                                          userProperties:nil];
    id<MQTTFlow> flow = [self.persistence flowforClientId:self.clientId
                                             incomingFlag:NO
                                                messageId:message.mid];
    if (flow) {
        if ((flow.commandType).intValue == MQTTPublish && (flow.qosLevel).intValue == MQTTQosLevelExactlyOnce) {
            flow.commandType = @(MQTTPubrel);
            flow.deadline = [NSDate dateWithTimeIntervalSinceNow:self.dupTimeout];
            [self.persistence sync];
        }
    }
    (void)[self encode:pubrelmessage];
}

- (void)handlePubrel:(MQTTMessage *)message {
    id<MQTTFlow> flow = [self.persistence flowforClientId:self.clientId
                                             incomingFlag:YES
                                                messageId:message.mid];
    if (flow) {
        BOOL processed = true;
        NSData *data = flow.data;
        if (self.protocolLevel == MQTTProtocolVersion50) {
            int propertiesLength = [MQTTProperties getVariableLength:data];
            int variableLength = [MQTTProperties variableIntLength:propertiesLength];
            NSRange range = NSMakeRange(variableLength + propertiesLength, data.length - variableLength - propertiesLength);
            data = [data subdataWithRange:range];
        }


        if ([self.delegate respondsToSelector:@selector(newMessage:data:onTopic:qos:retained:mid:)]) {
            [self.delegate newMessage:self
                                 data:data
                              onTopic:flow.topic
                                  qos:(flow.qosLevel).intValue
                             retained:(flow.retainedFlag).boolValue
                                  mid:(flow.messageId).intValue
             ];
        }
        if ([self.delegate respondsToSelector:@selector(newMessageWithFeedback:data:onTopic:qos:retained:mid:)]) {
            processed = [self.delegate newMessageWithFeedback:self
                                                         data:data
                                                      onTopic:flow.topic
                                                          qos:(flow.qosLevel).intValue
                                                     retained:(flow.retainedFlag).boolValue
                                                          mid:(flow.messageId).intValue
                         ];
        }

        if(self.messageHandler){
            self.messageHandler(flow.data, flow.topic);
        }
        if (processed) {
            [self.persistence deleteFlow:flow];
            [self.persistence sync];
            [self tell];
            (void)[self encode:[MQTTMessage pubcompMessageWithMessageId:message.mid
                                                          protocolLevel:self.protocolLevel
                                                             returnCode:MQTTSuccess
                                                           reasonString:nil
                                                         userProperties:nil]];
        }
    }
}

- (void)handlePubcomp:(MQTTMessage *)message {
    id<MQTTFlow> flow = [self.persistence flowforClientId:self.clientId
                                             incomingFlag:NO
                                                messageId:message.mid];
    if (flow && (flow.commandType).intValue == MQTTPubrel) {
        if ([self.delegate respondsToSelector:@selector(messageDelivered:msgID:)]) {
            [self.delegate messageDelivered:self msgID:message.mid];
        }
        if ([self.delegate respondsToSelector:@selector(messageDelivered:msgID:topic:data:qos:retainFlag:)]) {
            [self.delegate messageDelivered:self
                                      msgID:message.mid
                                      topic:flow.topic
                                       data:flow.data
                                        qos:(flow.qosLevel).intValue
                                 retainFlag:(flow.retainedFlag).boolValue];
        }
        if ([self.delegate respondsToSelector:@selector(messageDeliveredV5:msgID:topic:data:qos:retainFlag:payloadFormatIndicator:publicationExpiryInterval:topicAlias:responseTopic:correlationData:userProperties:contentType:)]) {
            NSArray <NSDictionary <NSString *, NSString *> *> *userProperties;
            userProperties = [NSJSONSerialization JSONObjectWithData:flow.userProperties options:0 error:nil];

            [self.delegate messageDeliveredV5:self
                                        msgID:message.mid
                                        topic:flow.topic
                                         data:flow.data
                                          qos:(flow.qosLevel).intValue
                                   retainFlag:(flow.retainedFlag).boolValue
                       payloadFormatIndicator:flow.payloadFormatIndicator
                    publicationExpiryInterval:flow.publicationExpiryInterval
                                   topicAlias:flow.topicAlias
                                responseTopic:flow.responseTopic
                              correlationData:flow.correlationData
                               userProperties:userProperties
                                  contentType:flow.contentType];
        }

        if (self.synchronPub && self.synchronPubMid == message.mid) {
            self.synchronPub = FALSE;
        }
        MQTTPublishHandler publishHandler = (self.publishHandlers)[@(message.mid)];
        if (publishHandler) {
            [self.publishHandlers removeObjectForKey:@(message.mid)];
            [self onPublish:publishHandler error:nil];
        }
        [self.persistence deleteFlow:flow];
        [self.persistence sync];
        [self tell];
    }
}

- (void)connectionError:(NSError *)error {
    [self error:MQTTSessionEventConnectionError error:error];
    if ([self.delegate respondsToSelector:@selector(connectionError:error:)]) {
        [self.delegate connectionError:self error:error];
    }
    if (self.connectHandler) {
        MQTTConnectHandler connectHandler = self.connectHandler;
        self.connectHandler = nil;
        [self onConnect:connectHandler error:error];
    }
}

- (void)protocolError:(NSError *)error {
    [self error:MQTTSessionEventProtocolError error:error];
    if ([self.delegate respondsToSelector:@selector(protocolError:error:)]) {
        [self.delegate protocolError:self error:error];
    }
}

- (void)error:(MQTTSessionEvent)eventCode error:(NSError *)error {
    self.status = MQTTSessionStatusError;
    if ([self.delegate respondsToSelector:@selector(handleEvent:event:error:)]) {
        [self.delegate handleEvent:self event:eventCode error:error];
    }
    [self closeInternal];

    if(self.connectionHandler){
        self.connectionHandler(eventCode);
    }

    if(eventCode == MQTTSessionEventConnectionClosedByBroker && self.connectHandler) {
        error = [NSError errorWithDomain:MQTTSessionErrorDomain
                                    code:MQTTSessionErrorConnectionRefused
                                userInfo:@{NSLocalizedDescriptionKey : @"Server has closed connection without connack."}];

        MQTTConnectHandler connectHandler = self.connectHandler;
        self.connectHandler = nil;
        [self onConnect:connectHandler error:error];
    }

    self.synchronPub = FALSE;
    self.synchronPubMid = 0;
    self.synchronSub = FALSE;
    self.synchronSubMid = 0;
    self.synchronUnsub = FALSE;
    self.synchronUnsubMid = 0;
    self.synchronConnect = FALSE;
    self.synchronDisconnect = FALSE;
}

- (UInt16)nextMsgId {
    DDLogVerbose(@"nextMsgId synchronizing");
    @synchronized(self) {
        DDLogVerbose(@"nextMsgId synchronized");
        self.txMsgId++;
        while (self.txMsgId == 0 || [self.persistence flowforClientId:self.clientId
                                                         incomingFlag:NO
                                                            messageId:self.txMsgId] != nil) {
            self.txMsgId++;
        }
        DDLogVerbose(@"nextMsgId synchronized done");
        return self.txMsgId;
    }
}

- (void)tell {
    NSUInteger incoming = [self.persistence allFlowsforClientId:self.clientId
                                                   incomingFlag:YES].count;
    NSUInteger outflowing = [self.persistence allFlowsforClientId:self.clientId
                                                     incomingFlag:NO].count;
    if ([self.delegate respondsToSelector:@selector(buffered:flowingIn:flowingOut:)]) {
        [self.delegate buffered:self
                      flowingIn:incoming
                     flowingOut:outflowing];
    }
    if ([self.delegate respondsToSelector:@selector(buffered:queued:flowingIn:flowingOut:)]) {
        [self.delegate buffered:self
                         queued:0
                      flowingIn:incoming
                     flowingOut:outflowing];
    }
}

/*
 * Threaded block callbacks
 */
- (void)onConnect:(MQTTConnectHandler)connectHandler error:(NSError *)error {
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObject:connectHandler forKey:@"Block"];
    if (error) {
        dict[@"Error"] = error;
    }
    NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(onConnectExecute:) object:dict];
    [thread start];
}

- (void)onConnectExecute:(NSDictionary *)dict {
    MQTTConnectHandler connectHandler = dict[@"Block"];
    NSError *error = dict[@"Error"];
    connectHandler(error);
}

- (void)onDisconnect:(MQTTDisconnectHandler)disconnectHandler error:(NSError *)error {
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObject:disconnectHandler forKey:@"Block"];
    if (error) {
        dict[@"Error"] = error;
    }
    NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(onDisconnectExecute:) object:dict];
    [thread start];
}

- (void)onDisconnectExecute:(NSDictionary *)dict {
    MQTTDisconnectHandler disconnectHandler = dict[@"Block"];
    NSError *error = dict[@"Error"];
    disconnectHandler(error);
}

- (void)onSubscribe:(MQTTSubscribeHandler)subscribeHandler error:(NSError *)error gQoss:(NSArray *)gqoss{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObject:subscribeHandler forKey:@"Block"];
    if (error) {
        dict[@"Error"] = error;
    }
    if (gqoss) {
        dict[@"GQoss"] = gqoss;
    }
    NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(onSubscribeExecute:) object:dict];
    [thread start];
}

- (void)onSubscribeV5:(MQTTSubscribeHandlerV5)subscribeHandlerV5
                error:(NSError *)error
         reasonString:(NSString *)reasonString
       userProperties:(NSArray <NSDictionary <NSString *, NSString *> *> *)userProperties
          reasonCodes:(NSArray <NSNumber *> *)reasonCodes {
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObject:subscribeHandlerV5 forKey:@"Block"];
    if (error) {
        dict[@"Error"] = error;
    }
    if (reasonString) {
        dict[@"ReasonString"] = reasonString;
    }
    if (userProperties) {
        dict[@"UserProperties"] = userProperties;
    }
    if (reasonCodes) {
        dict[@"ReasonCodes"] = reasonCodes;
    }
    NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(onSubscribeExecuteV5:) object:dict];
    [thread start];
}

- (void)onSubscribeExecute:(NSDictionary *)dict {
    MQTTSubscribeHandler subscribeHandler = dict[@"Block"];
    NSError *error = dict[@"Error"];
    NSArray *gqoss = dict[@"GQoss"];
    subscribeHandler(error, gqoss);
}

- (void)onSubscribeExecuteV5:(NSDictionary *)dict {
    MQTTSubscribeHandlerV5 subscribeHandler = dict[@"Block"];
    NSError *error = dict[@"Error"];
    NSString *reasonString = dict[@"ReasonString"];
    NSArray *userProperties = dict[@"UserProperties"];
    NSArray *reasonCodes = dict[@"ReasonCodes"];
    subscribeHandler(error, reasonString, userProperties, reasonCodes);
}

- (void)onUnsubscribe:(MQTTUnsubscribeHandler)unsubscribeHandler error:(NSError *)error {
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObject:unsubscribeHandler forKey:@"Block"];
    if (error) {
        dict[@"Error"] = error;
    }
    NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(onUnsubscribeExecute:) object:dict];
    [thread start];
}
- (void)onUnsubscribeV5:(MQTTUnsubscribeHandlerV5)unsubscribeHandler
                  error:(NSError *)error
           reasonString:(NSString *)reasonString
         userProperties:(NSArray <NSDictionary <NSString *, NSString *> *> *)userProperties
            reasonCodes:(NSArray <NSNumber *> *)reasonCodes {
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObject:unsubscribeHandler forKey:@"Block"];
    if (error) {
        dict[@"Error"] = error;
    }
    if (reasonString) {
        dict[@"ReasonString"] = reasonString;
    }
    if (userProperties) {
        dict[@"UserProperties"] = userProperties;
    }
    if (reasonCodes) {
        dict[@"ReasonCodes"] = reasonCodes;
    }
    NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(onUnsubscribeExecuteV5:) object:dict];
    [thread start];
}

- (void)onUnsubscribeExecute:(NSDictionary *)dict {
    MQTTUnsubscribeHandler unsubscribeHandler = dict[@"Block"];
    NSError *error = dict[@"Error"];
    unsubscribeHandler(error);
}

- (void)onUnsubscribeExecuteV5:(NSDictionary *)dict {
    MQTTUnsubscribeHandlerV5 unsubscribeHandlerV5 = dict[@"Block"];
    NSError *error = dict[@"Error"];
    NSString *reasonString = dict[@"ReasonString"];
    NSArray *userProperties = dict[@"UserProperties"];
    NSArray *reasonCodes = dict[@"ReasonCodes"];
    unsubscribeHandlerV5(error, reasonString, userProperties, reasonCodes);
}

- (void)onPublish:(MQTTPublishHandler)publishHandler error:(NSError *)error {
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObject:publishHandler forKey:@"Block"];
    if (error) {
        dict[@"Error"] = error;
    }
    NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(onPublishExecute:) object:dict];
    [thread start];
}

- (void)onPublishExecute:(NSDictionary *)dict {
    MQTTPublishHandler publishHandler = dict[@"Block"];
    NSError *error = dict[@"Error"];
    publishHandler(error);
}

#pragma mark - MQTTTransport interface

- (void)connect {

    if (MQTTStrict.strict &&
        self.clientId && self.clientId.length < 1 &&
        !self.cleanSessionFlag) {
        NSException* myException = [NSException
                                    exceptionWithName:@"clientId must be at least 1 character long if cleanSessionFlag is off"
                                    reason:[NSString stringWithFormat:@"clientId length = %lu",
                                            (unsigned long)[self.clientId dataUsingEncoding:NSUTF8StringEncoding].length]
                                    userInfo:nil];
        @throw myException;
    }

    if (MQTTStrict.strict &&
        !self.clientId) {
        NSException* myException = [NSException
                                    exceptionWithName:@"clientId must not be nil"
                                    reason:[NSString stringWithFormat:@"clientId length = %lu",
                                            (unsigned long)[self.clientId dataUsingEncoding:NSUTF8StringEncoding].length]
                                    userInfo:nil];
        @throw myException;
    }

    if (MQTTStrict.strict &&
        [self.clientId dataUsingEncoding:NSUTF8StringEncoding].length > 65535L) {
        NSException* myException = [NSException
                                    exceptionWithName:@"clientId may not be longer than 65535 bytes in UTF8 representation"
                                    reason:[NSString stringWithFormat:@"clientId length = %lu",
                                            (unsigned long)[self.clientId dataUsingEncoding:NSUTF8StringEncoding].length]
                                    userInfo:nil];
        @throw myException;
    }

    if (MQTTStrict.strict &&
        ![self.clientId dataUsingEncoding:NSUTF8StringEncoding]) {
        NSException* myException = [NSException
                                    exceptionWithName:@"clientId must not contain non-UTF8 characters"
                                    reason:[NSString stringWithFormat:@"clientId = %@", self.clientId]
                                    userInfo:nil];
        @throw myException;
    }

    if (MQTTStrict.strict &&
        [self.userName dataUsingEncoding:NSUTF8StringEncoding].length > 65535L) {
        NSException* myException = [NSException
                                    exceptionWithName:@"userName may not be longer than 65535 bytes in UTF8 representation"
                                    reason:[NSString stringWithFormat:@"userName length = %lu", (unsigned long)[self.userName dataUsingEncoding:NSUTF8StringEncoding].length]
                                    userInfo:nil];
        @throw myException;
    }

    if (MQTTStrict.strict &&
        self.userName &&
        ![self.userName dataUsingEncoding:NSUTF8StringEncoding]) {
        NSException* myException = [NSException
                                    exceptionWithName:@"userName must not contain non-UTF8 characters"
                                    reason:[NSString stringWithFormat:@"userName = %@", self.userName]
                                    userInfo:nil];
        @throw myException;
    }

    if (MQTTStrict.strict &&
        self.password &&
        !self.userName &&
        self.protocolLevel != MQTTProtocolVersion50) {
        NSException* myException = [NSException
                                    exceptionWithName:@"password specified without userName"
                                    reason:[NSString stringWithFormat:@"password = %@", self.password]
                                    userInfo:nil];
        @throw myException;
    }

    if (MQTTStrict.strict &&
        self.protocolLevel != MQTTProtocolVersion31 &&
        self.protocolLevel != MQTTProtocolVersion311 &&
        self.protocolLevel != MQTTProtocolVersion50) {
        NSException* myException = [NSException
                                    exceptionWithName:@"Illegal protocolLevel"
                                    reason:[NSString stringWithFormat:@"%d is not 3, 4, or 5", self.protocolLevel]
                                    userInfo:nil];
        @throw myException;
    }

    if (MQTTStrict.strict &&
        !self.willFlag &&
        self.willTopic) {
        NSException* myException = [NSException
                                    exceptionWithName:@"Will topic must be nil if willFlag is false"
                                    reason:[NSString stringWithFormat:@"%@", self.willTopic]
                                    userInfo:nil];
        @throw myException;
    }

    if (MQTTStrict.strict &&
        !self.willFlag &&
        self.willMsg) {
        NSException* myException = [NSException
                                    exceptionWithName:@"Will message must be nil if willFlag is false"
                                    reason:[NSString stringWithFormat:@"%@", self.willMsg]
                                    userInfo:nil];
        @throw myException;
    }

    if (MQTTStrict.strict &&
        !self.willFlag &&
        self.willRetainFlag) {
        NSException* myException = [NSException
                                    exceptionWithName:@"Will retain must be false if willFlag is false"
                                    reason:[NSString stringWithFormat:@"%d", self.willRetainFlag]
                                    userInfo:nil];
        @throw myException;
    }

    if (MQTTStrict.strict &&
        !self.willFlag &&
        self.willQoS != MQTTQosLevelAtMostOnce) {
        NSException* myException = [NSException
                                    exceptionWithName:@"Will QoS Level must be 0 if willFlag is false"
                                    reason:[NSString stringWithFormat:@"%d", self.willQoS]
                                    userInfo:nil];
        @throw myException;
    }

    if (MQTTStrict.strict &&
        self.willQoS != MQTTQosLevelAtMostOnce &&
        self.willQoS != MQTTQosLevelAtLeastOnce &&
        self.willQoS != MQTTQosLevelExactlyOnce) {
        NSException* myException = [NSException
                                    exceptionWithName:@"Illegal will QoS level"
                                    reason:[NSString stringWithFormat:@"%d is not 0, 1, or 2", self.willQoS]
                                    userInfo:nil];
        @throw myException;
    }

    if (MQTTStrict.strict &&
        self.willFlag &&
        !self.willTopic) {
        NSException* myException = [NSException
                                    exceptionWithName:@"Will topic must not be nil if willFlag is true"
                                    reason:[NSString stringWithFormat:@"%@", self.willTopic]
                                    userInfo:nil];
        @throw myException;
    }

    if (MQTTStrict.strict &&
        self.willTopic &&
        self.willTopic.length < 1) {
        NSException* myException = [NSException
                                    exceptionWithName:@"Will topic must be at least 1 character long"
                                    reason:[NSString stringWithFormat:@"%@", self.willTopic]
                                    userInfo:nil];
        @throw myException;
    }

    if (MQTTStrict.strict &&
        self.willTopic &&
        [self.willTopic dataUsingEncoding:NSUTF8StringEncoding].length > 65535L) {
        NSException* myException = [NSException
                                    exceptionWithName:@"willTopic may not be longer than 65535 bytes in UTF8 representation"
                                    reason:[NSString stringWithFormat:@"willTopic length = %lu", (unsigned long)[self.willTopic dataUsingEncoding:NSUTF8StringEncoding].length]
                                    userInfo:nil];
        @throw myException;
    }

    if (MQTTStrict.strict &&
        self.willTopic &&
        ![self.willTopic dataUsingEncoding:NSUTF8StringEncoding]) {
        NSException* myException = [NSException
                                    exceptionWithName:@"willTopic must not contain non-UTF8 characters"
                                    reason:[NSString stringWithFormat:@"willTopic = %@", self.willTopic]
                                    userInfo:nil];
        @throw myException;
    }

    if (MQTTStrict.strict &&
        self.willTopic &&
        ([self.willTopic containsString:@"+"] ||
         [self.willTopic containsString:@"#"])
        ) {
        NSException* myException = [NSException
                                    exceptionWithName:@"willTopic must not contain wildcards"
                                    reason:[NSString stringWithFormat:@"willTopic = %@", self.self.willTopic]
                                    userInfo:nil];
        @throw myException;
    }

    if (MQTTStrict.strict &&
        self.willFlag &&
        !self.willMsg) {
        NSException* myException = [NSException
                                    exceptionWithName:@"Will message must not be nil if willFlag is true"
                                    reason:[NSString stringWithFormat:@"%@", self.willMsg]
                                    userInfo:nil];
        @throw myException;
    }

    if (MQTTStrict.strict &&
        self.maximumPacketSize &&
        (self.maximumPacketSize.unsignedLongValue == 0 ||
         self.maximumPacketSize.unsignedLongValue >  2684354565)) {
        NSException* myException = [NSException
                                    exceptionWithName:@"Maximum Packet Size must not be zero or greater than 2,684,354,565"
                                    reason:[NSString stringWithFormat:@"%@", self.maximumPacketSize]
                                    userInfo:nil];
        @throw myException;
    }

    DDLogVerbose(@"[MQTTSession] connecting");
    if (self.cleanSessionFlag) {
        [self.persistence deleteAllFlowsForClientId:self.clientId];
        [self.subscribeHandlers removeAllObjects];
        [self.subscribeHandlersV5 removeAllObjects];
        [self.unsubscribeHandlers removeAllObjects];
        [self.unsubscribeHandlersV5 removeAllObjects];
        [self.publishHandlers removeAllObjects];
    }
    [self tell];

    self.status = MQTTSessionStatusConnecting;

    self.decoder = [[MQTTDecoder alloc] init];
    self.decoder.runLoop = self.runLoop;
    self.decoder.runLoopMode = self.runLoopMode;
    self.decoder.delegate = self;
    [self.decoder open];

    self.transport.delegate = self;
    [self.transport open];
}

- (void)connectWithConnectHandler:(MQTTConnectHandler)connectHandler {
    DDLogVerbose(@"[MQTTSession] connectWithConnectHandler:%p", connectHandler);
    self.connectHandler = connectHandler;
    [self connect];
}

- (BOOL)encode:(MQTTMessage *)message {
    if (message) {
        NSData *wireFormat = message.wireFormat;
        if (wireFormat) {
            if (MQTTStrict.strict &&
                self.brokerMaximumPacketSize &&
                self.brokerMaximumPacketSize.unsignedLongValue < wireFormat.length) {
                NSException* myException = [NSException
                                            exceptionWithName:@"The Client MUST NOT send packets exceeding Maximum Packet Size to the Server [MQTT-3.2.2-15]"
                                            reason:[NSString stringWithFormat:@"%lu/%@",
                                                    (unsigned long)wireFormat.length,
                                                    self.brokerMaximumPacketSize]
                                            userInfo:nil];
                @throw myException;
            }

            if (self.delegate) {
                if ([self.delegate respondsToSelector:@selector(sending:type:qos:retained:duped:mid:data:)]) {
                    [self.delegate sending:self
                                      type:message.type
                                       qos:message.qos
                                  retained:message.retainFlag
                                     duped:message.dupFlag
                                       mid:message.mid
                                      data:message.data];
                }
            }
            DDLogVerbose(@"[MQTTSession] mqttTransport send");
            return [self.transport send:wireFormat];
        } else {
            DDLogError(@"[MQTTSession] trying to send message without wire format");
            return false;
        }
    } else {
        DDLogError(@"[MQTTSession] trying to send nil message");
        return false;
    }
}

#pragma mark - MQTTTransport delegate
- (void)mqttTransport:(id<MQTTTransport>)mqttTransport didReceiveMessage:(NSData *)message {
    DDLogVerbose(@"[MQTTSession] mqttTransport didReceiveMessage");

    [self.decoder decodeMessage:message];

}

- (void)mqttTransportDidClose:(id<MQTTTransport>)mqttTransport {
    DDLogVerbose(@"[MQTTSession] mqttTransport mqttTransportDidClose");

    [self error:MQTTSessionEventConnectionClosedByBroker error:nil];

}

- (void)mqttTransportDidOpen:(id<MQTTTransport>)mqttTransport {
    DDLogVerbose(@"[MQTTSession] mqttTransportDidOpen");

    DDLogVerbose(@"[MQTTSession] sending CONNECT");

    if (!self.connectMessage) {
        (void)[self encode:[MQTTMessage connectMessageWithClientId:self.clientId
                                                          userName:self.userName
                                                          password:self.password
                                                         keepAlive:self.keepAliveInterval
                                                      cleanSession:self.cleanSessionFlag
                                                              will:self.willFlag
                                                         willTopic:self.willTopic
                                                           willMsg:self.willMsg
                                                           willQoS:self.willQoS
                                                        willRetain:self.willRetainFlag
                                                     protocolLevel:self.protocolLevel
                                             sessionExpiryInterval:self.sessionExpiryInterval
                                                        authMethod:self.authMethod
                                                          authData:self.authData
                                         requestProblemInformation:self.requestProblemInformation
                                                 willDelayInterval:self.willDelayInterval
                                        requestResponseInformation:self.requestResponseInformation
                                                    receiveMaximum:self.receiveMaximum
                                                 topicAliasMaximum:self.topicAliasMaximum
                                                    userProperties:self.userProperties
                                                 maximumPacketSize:self.maximumPacketSize]];
    } else {
        (void)[self encode:self.connectMessage];
    }
}

- (void)mqttTransport:(id<MQTTTransport>)mqttTransport didFailWithError:(NSError *)error {
    DDLogWarn(@"[MQTTSession] mqttTransport didFailWithError %@", error);

    [self connectionError:error];
}
@end
