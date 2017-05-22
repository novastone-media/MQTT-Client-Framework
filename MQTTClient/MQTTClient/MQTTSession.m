//
// MQTTSession.m
// MQTTClient.framework
//
// Copyright © 2013-2017, Christoph Krey. All rights reserved.
//


#import "MQTTSession.h"
#import "MQTTDecoder.h"
#import "MQTTProperties.h"
#import "MQTTMessage.h"
#import "MQTTCoreDataPersistence.h"

@class MQTTSSLSecurityPolicy;

//#define myLogLevel DDLogLevelVerbose

#import "MQTTLog.h"

NSString * const MQTTSessionErrorDomain = @"MQTT";

@interface MQTTSession() <MQTTDecoderDelegate, MQTTTransportDelegate>

@property (nonatomic, readwrite) MQTTSessionStatus status;
@property (nonatomic, readwrite) BOOL sessionPresent;

@property (strong, nonatomic) NSTimer *keepAliveTimer;
@property (strong, nonatomic) NSNumber *serverKeepAlive;
@property (nonatomic) UInt16 effectiveKeepAlive;
@property (strong, nonatomic) NSTimer *checkDupTimer;

@property (strong, nonatomic) MQTTDecoder *decoder;

@property (copy, nonatomic) MQTTDisconnectHandler disconnectHandler;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, MQTTSubscribeHandler> *subscribeHandlers;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, MQTTUnsubscribeHandler> *unsubscribeHandlers;
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
    self.unsubscribeHandlers = [[NSMutableDictionary alloc] init];
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

- (void)setClientId:(NSString *)clientId
{
    if (!clientId) {
        clientId = [NSString stringWithFormat:@"MQTTClient%.0f",fmod([[NSDate date] timeIntervalSince1970], 1.0) * 1000000.0];
    }
    
    //NSAssert(clientId.length > 0 || self.cleanSessionFlag, @"clientId must be at least 1 character long if cleanSessionFlag is off");
    
    //NSAssert([clientId dataUsingEncoding:NSUTF8StringEncoding], @"clientId contains non-UTF8 characters");
    //NSAssert([clientId dataUsingEncoding:NSUTF8StringEncoding].length <= 65535L, @"clientId may not be longer than 65535 bytes in UTF8 representation");
    
    _clientId = clientId;
}

- (void)setUserName:(NSString *)userName
{
    if (userName) {
        //NSAssert([userName dataUsingEncoding:NSUTF8StringEncoding], @"userName contains non-UTF8 characters");
        //NSAssert([userName dataUsingEncoding:NSUTF8StringEncoding].length <= 65535L, @"userName may not be longer than 65535 bytes in UTF8 representation");
    }
    
    _userName = userName;
}

- (void)setPassword:(NSString *)password
{
    if (password) {
        //NSAssert(self.userName, @"password specified without userName");
        //NSAssert([password dataUsingEncoding:NSUTF8StringEncoding], @"password contains non-UTF8 characters");
        //NSAssert([password dataUsingEncoding:NSUTF8StringEncoding].length <= 65535L, @"password may not be longer than 65535 bytes in UTF8 representation");
    }
    _password = password;
}

- (void)setProtocolLevel:(MQTTProtocolVersion)protocolLevel
{
//    NSAssert(protocolLevel == MQTTProtocolVersion31 ||
//             protocolLevel == MQTTProtocolVersion311 ||
//             protocolLevel == MQTTProtocolVersion50,
//             @"allowed protocolLevel values are 3,4 or 5 only");
    _protocolLevel = protocolLevel;
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

- (UInt16)subscribeToTopic:(NSString *)topic
                   atLevel:(MQTTQosLevel)qosLevel {
    return [self subscribeToTopic:topic atLevel:qosLevel subscribeHandler:nil];
}

- (UInt16)subscribeToTopic:(NSString *)topic
                   atLevel:(MQTTQosLevel)qosLevel
          subscribeHandler:(MQTTSubscribeHandler)subscribeHandler {
    return [self subscribeToTopics:topic ? @{topic: @(qosLevel)} : @{} subscribeHandler:subscribeHandler];
}

- (UInt16)subscribeToTopics:(NSDictionary<NSString *, NSNumber *> *)topics {
    return [self subscribeToTopics:topics subscribeHandler:nil];
}

- (UInt16)subscribeToTopics:(NSDictionary<NSString *, NSNumber *> *)topics subscribeHandler:(MQTTSubscribeHandler)subscribeHandler {
    DDLogVerbose(@"[MQTTSession] subscribeToTopics:%@]", topics);
    
    //for (NSNumber *qos in [topics allValues]) {
    //NSAssert([qos intValue] >= 0 && [qos intValue] <= 2, @"qosLevel must be 0, 1, or 2");
    //}
    
    UInt16 mid = [self nextMsgId];
    if (subscribeHandler) {
        [self.subscribeHandlers setObject:[subscribeHandler copy] forKey:@(mid)];
    } else {
        [self.subscribeHandlers removeObjectForKey:@(mid)];
    }
    (void)[self encode:[MQTTMessage subscribeMessageWithMessageId:mid
                                                           topics:topics
                                                    protocolLevel:self.protocolLevel
                                           subscriptionIdentifier:nil]];
    
    return mid;
}

- (UInt16)unsubscribeTopic:(NSString*)topic {
    return [self unsubscribeTopic:topic unsubscribeHandler:nil];
}

- (UInt16)unsubscribeTopic:(NSString *)topic unsubscribeHandler:(MQTTUnsubscribeHandler)unsubscribeHandler {
    return [self unsubscribeTopics:topic ? @[topic] : @[] unsubscribeHandler:unsubscribeHandler];
}

- (UInt16)unsubscribeTopics:(NSArray<NSString *> *)topics {
    return [self unsubscribeTopics:topics unsubscribeHandler:nil];
}

- (UInt16)unsubscribeTopics:(NSArray<NSString *> *)topics unsubscribeHandler:(MQTTUnsubscribeHandler)unsubscribeHandler {
    DDLogVerbose(@"[MQTTSession] unsubscribeTopics:%@", topics);
    UInt16 mid = [self nextMsgId];
    if (unsubscribeHandler) {
        [self.unsubscribeHandlers setObject:[unsubscribeHandler copy] forKey:@(mid)];
    } else {
        [self.unsubscribeHandlers removeObjectForKey:@(mid)];
    }
    (void)[self encode:[MQTTMessage unsubscribeMessageWithMessageId:mid
                                                             topics:topics
                                                      protocolLevel:self.protocolLevel]];
    return mid;
}

- (UInt16)publishData:(NSData*)data
              onTopic:(NSString*)topic
               retain:(BOOL)retainFlag
                  qos:(MQTTQosLevel)qos {
    return [self publishData:data onTopic:topic retain:retainFlag qos:qos publishHandler:nil];
}

- (UInt16)publishData:(NSData *)data
              onTopic:(NSString *)topic
               retain:(BOOL)retainFlag
                  qos:(MQTTQosLevel)qos
       publishHandler:(MQTTPublishHandler)publishHandler
{
    DDLogVerbose(@"[MQTTSession] publishData:%@... onTopic:%@ retain:%d qos:%ld publishHandler:%p",
                 [data subdataWithRange:NSMakeRange(0, MIN(256, data.length))],
                 [topic substringWithRange:NSMakeRange(0, MIN(256, topic.length))],
                 retainFlag,
                 (long)qos,
                 publishHandler);
    
    //NSAssert(qos >= 0 && qos <= 2, @"qos must be 0, 1, or 2");
    
    UInt16 msgId = 0;
    if (!qos) {
        MQTTMessage *msg = [MQTTMessage publishMessageWithData:data
                                                       onTopic:topic
                                                           qos:qos
                                                         msgId:msgId
                                                    retainFlag:retainFlag
                                                       dupFlag:FALSE
                                                 protocolLevel:self.protocolLevel
                                        payloadFormatIndicator:nil
                                     publicationExpiryInterval:nil
                                                    topicAlias:nil
                                                 responseTopic:nil
                                               correlationData:nil
                                                  userProperty:nil
                                                   contentType:nil];
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
                if ([flow.commandType intValue] != MQTT_None) {
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
                                   payloadFormatIndicator:nil
                                publicationExpiryInterval:nil
                                               topicAlias:nil
                                            responseTopic:nil
                                          correlationData:nil
                                             userProperty:nil
                                              contentType:nil];
                flow = [self.persistence storeMessageForClientId:self.clientId
                                                           topic:topic
                                                            data:data
                                                      retainFlag:retainFlag
                                                             qos:qos
                                                           msgId:msgId
                                                    incomingFlag:NO
                                                     commandType:MQTTPublish
                                                        deadline:[NSDate dateWithTimeIntervalSinceNow:self.dupTimeout]];
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
                                                    deadline:[NSDate date]];
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
                [self.publishHandlers setObject:[publishHandler copy] forKey:@(msgId)];
            } else {
                [self.publishHandlers removeObjectForKey:@(msgId)];
            }
            
            if ([flow.commandType intValue] == MQTTPublish) {
                DDLogVerbose(@"[MQTTSession] PUBLISH %d", msgId);
                if (![self encode:msg]) {
                    DDLogInfo(@"[MQTTSession] queueing message %d after unsuccessfull attempt", msgId);
                    flow.commandType = [NSNumber numberWithUnsignedInt:MQTT_None];
                    flow.deadline = [NSDate date];
                    [self.persistence sync];
                }
            } else {
                DDLogVerbose(@"[MQTTSession] queueing message %d", msgId);
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
                 userProperty:nil
            disconnectHandler:disconnectHandler];
}

- (void)closeWithReturnCode:(MQTTReturnCode)returnCode
      sessionExpiryInterval:(NSNumber *)sessionExpiryInterval
               reasonString:(NSString *)reasonString
               userProperty:(NSDictionary<NSString *,NSString *> *)userProperty
          disconnectHandler:(MQTTDisconnectHandler)disconnectHandler {
    DDLogVerbose(@"[MQTTSession] closeWithDisconnectHandler:%p ", disconnectHandler);
    self.disconnectHandler = disconnectHandler;

    if (self.status == MQTTSessionStatusConnected) {
        [self disconnectWithReturnCode:returnCode
                 sessionExpiryInterval:sessionExpiryInterval
                          reasonString:reasonString
                          userProperty:userProperty];
    } else {
        [self closeInternal];
    }
}

- (void)disconnect {
    [self disconnectWithReturnCode:MQTTSuccess
             sessionExpiryInterval:nil
                      reasonString:nil
                      userProperty:nil];
}

- (void)disconnectWithReturnCode:(MQTTReturnCode)returnCode
           sessionExpiryInterval:(NSNumber *)sessionExpiryInterval
                    reasonString:(NSString *)reasonString
                    userProperty:(NSDictionary<NSString *,NSString *> *)userProperty {
    DDLogVerbose(@"[MQTTSession] sending DISCONNECT");
    self.status = MQTTSessionStatusDisconnecting;

    (void)[self encode:[MQTTMessage disconnectMessage:self.protocolLevel
                                           returnCode:returnCode
                                sessionExpiryInterval:sessionExpiryInterval
                                         reasonString:reasonString
                                         userProperty:userProperty]];
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
        switch ([flow.commandType intValue]) {
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
    
    NSArray *allUnsubscribeHandlers = self.unsubscribeHandlers.allValues;
    [self.unsubscribeHandlers removeAllObjects];
    for (MQTTUnsubscribeHandler unsubscribeHandler in allUnsubscribeHandlers) {
        unsubscribeHandler(error);
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
        if ([flow.commandType intValue] != MQTT_None) {
            windowSize++;
        }
    }
    for (id<MQTTFlow> flow in flows) {
        DDLogVerbose(@"[MQTTSession] %@ flow %@ %@ %@", self.clientId, flow.deadline, flow.commandType, flow.messageId);
        if ([flow.deadline compare:[NSDate date]] == NSOrderedAscending) {
            switch ([flow.commandType intValue]) {
                case 0:
                    if (windowSize <= self.persistence.maxWindowSize) {
                        DDLogVerbose(@"[MQTTSession] PUBLISH queued message %@", flow.messageId);
                        message = [MQTTMessage publishMessageWithData:flow.data
                                                              onTopic:flow.topic
                                                                  qos:[flow.qosLevel intValue]
                                                                msgId:[flow.messageId intValue]
                                                           retainFlag:[flow.retainedFlag boolValue]
                                                              dupFlag:NO
                                                        protocolLevel:self.protocolLevel
                                               payloadFormatIndicator:nil
                                            publicationExpiryInterval:nil
                                                           topicAlias:nil
                                                        responseTopic:nil
                                                      correlationData:nil
                                                         userProperty:nil
                                                          contentType:nil];
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
                                                              qos:[flow.qosLevel intValue]
                                                            msgId:[flow.messageId intValue]
                                                       retainFlag:[flow.retainedFlag boolValue]
                                                          dupFlag:YES
                                                    protocolLevel:self.protocolLevel
                                           payloadFormatIndicator:nil
                                        publicationExpiryInterval:nil
                                                       topicAlias:nil
                                                    responseTopic:nil
                                                  correlationData:nil
                                                     userProperty:nil
                                                      contentType:nil];
                    if ([self encode:message]) {
                        flow.deadline = [NSDate dateWithTimeIntervalSinceNow:self.dupTimeout];
                        [self.persistence sync];
                    }
                    break;
                case MQTTPubrel:
                    DDLogInfo(@"[MQTTSession] resend PUBREL %@", flow.messageId);
                    message = [MQTTMessage pubrelMessageWithMessageId:[flow.messageId intValue]
                                                        protocolLevel:self.protocolLevel
                                                           returnCode:MQTTSuccess
                                                         reasonString:nil
                                                         userProperty:nil];
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
    MQTTMessage *message = [MQTTMessage messageFromData:data protocolLevel:self.protocolLevel];
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
                            if (message.returnCode && [message.returnCode intValue] == MQTTSuccess) {
                                self.status = MQTTSessionStatusConnected;
                                if (message.connectAcknowledgeFlags &&
                                    ([message.connectAcknowledgeFlags unsignedIntValue] & 0x01) == 0x01) {
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
                                    self.serverKeepAlive = message.properties.serverKeepAlive;
                                }
                                if (self.serverKeepAlive) {
                                    self.effectiveKeepAlive = [self.serverKeepAlive unsignedShortValue];
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
                                    switch ([message.returnCode intValue]) {
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
                                                                 code:[message.returnCode intValue]
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
                                                             code:[message.returnCode intValue]
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
    NSData *data = [msg data];
    if ([data length] < 2) {
        return;
    }
    UInt8 const *bytes = [data bytes];
    UInt16 topicLength = 256 * bytes[0] + bytes[1];
    if ([data length] < 2 + topicLength) {
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
    NSRange range = NSMakeRange(2 + topicLength, [data length] - topicLength - 2);
    data = [data subdataWithRange:range];

    if ([msg qos] == 0) {
        if (self.protocolLevel == MQTTProtocolVersion50) {
            int propertiesLength = [MQTTProperties getVariableLength:data];
            int variableLength = [MQTTProperties variableIntLength:propertiesLength];
            msg.properties = [[MQTTProperties alloc] initFromData:data];
            NSRange range = NSMakeRange(variableLength + propertiesLength, [data length] - variableLength - propertiesLength);
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
        if ([self.delegate respondsToSelector:@selector(newMessageWithFeedback:data:onTopic:qos:retained:mid:)]) {
            [self.delegate newMessageWithFeedback:self
                                             data:data
                                          onTopic:topic
                                              qos:msg.qos
                                         retained:msg.retainFlag
                                              mid:0];
        }
        if (self.messageHandler) {
            self.messageHandler(data, topic);
        }
    } else {
        if ([data length] >= 2) {
            bytes = [data bytes];
            UInt16 msgId = 256 * bytes[0] + bytes[1];
            msg.mid = msgId;
            data = [data subdataWithRange:NSMakeRange(2, [data length] - 2)];
            if ([msg qos] == 1) {
                if (self.protocolLevel == MQTTProtocolVersion50) {
                    int propertiesLength = [MQTTProperties getVariableLength:data];
                    int variableLength = [MQTTProperties variableIntLength:propertiesLength];
                    msg.properties = [[MQTTProperties alloc] initFromData:data];
                    NSRange range = NSMakeRange(variableLength + propertiesLength, [data length] - variableLength - propertiesLength);
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
                if ([self.delegate respondsToSelector:@selector(newMessageWithFeedback:data:onTopic:qos:retained:mid:)]) {
                    processed = [self.delegate newMessageWithFeedback:self
                                                                 data:data
                                                              onTopic:topic
                                                                  qos:msg.qos
                                                             retained:msg.retainFlag
                                                                  mid:msgId];
                }
                if (self.messageHandler) {
                    self.messageHandler(data, topic);
                }
                if (processed) {
                    (void)[self encode:[MQTTMessage pubackMessageWithMessageId:msgId
                                                                 protocolLevel:self.protocolLevel
                                                                    returnCode:MQTTSuccess
                                                                  reasonString:nil
                                                                  userProperty:nil]];
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
                                                      deadline:[NSDate dateWithTimeIntervalSinceNow:self.dupTimeout]]) {
                    DDLogWarn(@"[MQTTSession] dropping incoming messages");
                } else {
                    [self.persistence sync];
                    [self tell];
                    (void)[self encode:[MQTTMessage pubrecMessageWithMessageId:msgId
                                                                 protocolLevel:self.protocolLevel
                                                                    returnCode:MQTTSuccess
                                                                  reasonString:nil
                                                                  userProperty:nil]];
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
        if ([flow.commandType intValue] == MQTTPublish && [flow.qosLevel intValue] == MQTTQosLevelAtLeastOnce) {
            if ([self.delegate respondsToSelector:@selector(messageDelivered:msgID:)]) {
                [self.delegate messageDelivered:self msgID:msg.mid];
            }
            if ([self.delegate respondsToSelector:@selector(messageDelivered:msgID:topic:data:qos:retainFlag:)]) {
                [self.delegate messageDelivered:self
                                          msgID:msg.mid
                                          topic:flow.topic
                                           data:flow.data
                                            qos:[flow.qosLevel intValue]
                                     retainFlag:[flow.retainedFlag boolValue]];
            }
            if (self.synchronPub && self.synchronPubMid == msg.mid) {
                self.synchronPub = FALSE;
            }
            MQTTPublishHandler publishHandler = [self.publishHandlers objectForKey:@(msg.mid)];
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

- (void)handleSuback:(MQTTMessage*)msg
{
    if ([[msg data] length] >= 3) {
        UInt8 const *bytes = [[msg data] bytes];
        UInt16 messageId = (256 * bytes[0] + bytes[1]);
        msg.mid = messageId;
        NSMutableArray *qoss = [[NSMutableArray alloc] init];
        for (int i = 2; i < [[msg data] length]; i++) {
            [qoss addObject:@(bytes[i])];
        }
        if ([self.delegate respondsToSelector:@selector(subAckReceived:msgID:grantedQoss:)]) {
            [self.delegate subAckReceived:self msgID:msg.mid grantedQoss:qoss];
        }
        if (self.synchronSub && self.synchronSubMid == msg.mid) {
            self.synchronSub = FALSE;
        }
        MQTTSubscribeHandler subscribeHandler = [self.subscribeHandlers objectForKey:@(msg.mid)];
        if (subscribeHandler) {
            [self.subscribeHandlers removeObjectForKey:@(msg.mid)];
            [self onSubscribe:subscribeHandler error:nil gQoss:qoss];
        }
    }
}

- (void)handleUnsuback:(MQTTMessage *)message {
    if ([self.delegate respondsToSelector:@selector(unsubAckReceived:msgID:)]) {
        [self.delegate unsubAckReceived:self msgID:message.mid];
    }
    if (self.synchronUnsub && self.synchronUnsubMid == message.mid) {
        self.synchronUnsub = FALSE;
    }
    MQTTUnsubscribeHandler unsubscribeHandler = [self.unsubscribeHandlers objectForKey:@(message.mid)];
    if (unsubscribeHandler) {
        [self.unsubscribeHandlers removeObjectForKey:@(message.mid)];
        [self onUnsubscribe:unsubscribeHandler error:nil];
    }
}

- (void)handlePubrec:(MQTTMessage *)message {
    MQTTMessage *pubrelmessage = [MQTTMessage pubrelMessageWithMessageId:message.mid
                                                           protocolLevel:self.protocolLevel
                                                              returnCode:MQTTSuccess
                                                            reasonString:nil
                                                            userProperty:nil];
    id<MQTTFlow> flow = [self.persistence flowforClientId:self.clientId
                                             incomingFlag:NO
                                                messageId:message.mid];
    if (flow) {
        if ([flow.commandType intValue] == MQTTPublish && [flow.qosLevel intValue] == MQTTQosLevelExactlyOnce) {
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
            NSRange range = NSMakeRange(variableLength + propertiesLength, [data length] - variableLength - propertiesLength);
            data = [data subdataWithRange:range];
        }


        if ([self.delegate respondsToSelector:@selector(newMessage:data:onTopic:qos:retained:mid:)]) {
            [self.delegate newMessage:self
                                 data:data
                              onTopic:flow.topic
                                  qos:[flow.qosLevel intValue]
                             retained:[flow.retainedFlag boolValue]
                                  mid:[flow.messageId intValue]
             ];
        }
        if ([self.delegate respondsToSelector:@selector(newMessageWithFeedback:data:onTopic:qos:retained:mid:)]) {
            processed = [self.delegate newMessageWithFeedback:self
                                                         data:data
                                                      onTopic:flow.topic
                                                          qos:[flow.qosLevel intValue]
                                                     retained:[flow.retainedFlag boolValue]
                                                          mid:[flow.messageId intValue]
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
                                                           userProperty:nil]];
        }
    }
}

- (void)handlePubcomp:(MQTTMessage *)message {
    id<MQTTFlow> flow = [self.persistence flowforClientId:self.clientId
                                             incomingFlag:NO
                                                messageId:message.mid];
    if (flow && [flow.commandType intValue] == MQTTPubrel) {
        if ([self.delegate respondsToSelector:@selector(messageDelivered:msgID:)]) {
            [self.delegate messageDelivered:self msgID:message.mid];
        }
        if ([self.delegate respondsToSelector:@selector(messageDelivered:msgID:topic:data:qos:retainFlag:)]) {
            [self.delegate messageDelivered:self
                                      msgID:message.mid
                                      topic:flow.topic
                                       data:flow.data
                                        qos:[flow.qosLevel intValue]
                                 retainFlag:[flow.retainedFlag boolValue]];
        }

        if (self.synchronPub && self.synchronPubMid == message.mid) {
            self.synchronPub = FALSE;
        }
        MQTTPublishHandler publishHandler = [self.publishHandlers objectForKey:@(message.mid)];
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
    [self closeInternal];
    if ([self.delegate respondsToSelector:@selector(handleEvent:event:error:)]) {
        [self.delegate handleEvent:self event:eventCode error:error];
    }
    
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
        [dict setObject:error forKey:@"Error"];
    }
    NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(onConnectExecute:) object:dict];
    [thread start];
}

- (void)onConnectExecute:(NSDictionary *)dict {
    MQTTConnectHandler connectHandler = [dict objectForKey:@"Block"];
    NSError *error = [dict objectForKey:@"Error"];
    connectHandler(error);
}

- (void)onDisconnect:(MQTTDisconnectHandler)disconnectHandler error:(NSError *)error {
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObject:disconnectHandler forKey:@"Block"];
    if (error) {
        [dict setObject:error forKey:@"Error"];
    }
    NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(onDisconnectExecute:) object:dict];
    [thread start];
}

- (void)onDisconnectExecute:(NSDictionary *)dict {
    MQTTDisconnectHandler disconnectHandler = [dict objectForKey:@"Block"];
    NSError *error = [dict objectForKey:@"Error"];
    disconnectHandler(error);
}

- (void)onSubscribe:(MQTTSubscribeHandler)subscribeHandler error:(NSError *)error gQoss:(NSArray *)gqoss{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObject:subscribeHandler forKey:@"Block"];
    if (error) {
        [dict setObject:error forKey:@"Error"];
    }
    if (gqoss) {
        [dict setObject:gqoss forKey:@"GQoss"];
    }
    NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(onSubscribeExecute:) object:dict];
    [thread start];
}

- (void)onSubscribeExecute:(NSDictionary *)dict {
    MQTTSubscribeHandler subscribeHandler = [dict objectForKey:@"Block"];
    NSError *error = [dict objectForKey:@"Error"];
    NSArray *gqoss = [dict objectForKey:@"GQoss"];
    subscribeHandler(error, gqoss);
}

- (void)onUnsubscribe:(MQTTUnsubscribeHandler)unsubscribeHandler error:(NSError *)error {
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObject:unsubscribeHandler forKey:@"Block"];
    if (error) {
        [dict setObject:error forKey:@"Error"];
    }
    NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(onUnsubscribeExecute:) object:dict];
    [thread start];
}

- (void)onUnsubscribeExecute:(NSDictionary *)dict {
    MQTTUnsubscribeHandler unsubscribeHandler = [dict objectForKey:@"Block"];
    NSError *error = [dict objectForKey:@"Error"];
    unsubscribeHandler(error);
}

- (void)onPublish:(MQTTPublishHandler)publishHandler error:(NSError *)error {
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObject:publishHandler forKey:@"Block"];
    if (error) {
        [dict setObject:error forKey:@"Error"];
    }
    NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(onPublishExecute:) object:dict];
    [thread start];
}

- (void)onPublishExecute:(NSDictionary *)dict {
    MQTTPublishHandler publishHandler = [dict objectForKey:@"Block"];
    NSError *error = [dict objectForKey:@"Error"];
    publishHandler(error);
}

#pragma mark - MQTTTransport interface

- (void)connect {
    DDLogVerbose(@"[MQTTSession] connecting");
    if (self.cleanSessionFlag) {
        [self.persistence deleteAllFlowsForClientId:self.clientId];
        [self.subscribeHandlers removeAllObjects];
        [self.unsubscribeHandlers removeAllObjects];
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
                                                      userProperty:self.userProperty
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
