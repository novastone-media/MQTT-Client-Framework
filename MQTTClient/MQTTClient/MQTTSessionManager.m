//
//  MQTTSessionManager.m
//  MQTTClient
//
//  Created by Christoph Krey on 09.07.14.
//  Copyright © 2013-2017 Christoph Krey. All rights reserved.
//

#import "MQTTSessionManager.h"
#import "MQTTCoreDataPersistence.h"
#import "MQTTSSLSecurityPolicyTransport.h"
#import "MQTTLog.h"
#import "MQTTWill.h"
#import "ReconnectTimer.h"
#import "ForegroundReconnection.h"

@interface MQTTSessionManager()

@property (nonatomic, readwrite) MQTTSessionManagerState state;
@property (nonatomic, readwrite) NSError *lastErrorCode;

@property (strong, nonatomic) ReconnectTimer *reconnectTimer;
@property (nonatomic) BOOL reconnectFlag;

@property (strong, nonatomic) MQTTSession *session;

#if TARGET_OS_IPHONE == 1
@property (strong, nonatomic) ForegroundReconnection *foregroundReconnection;
#endif

@property (nonatomic) BOOL persistent;
@property (nonatomic) NSUInteger maxWindowSize;
@property (nonatomic) NSUInteger maxSize;
@property (nonatomic) NSUInteger maxMessages;

@property (strong, nonatomic) NSDictionary<NSString *, NSNumber *> *internalSubscriptions;
@property (strong, nonatomic) NSDictionary<NSString *, NSNumber *> *effectiveSubscriptions;
@property (strong, nonatomic) NSLock *subscriptionLock;

@end

#define RECONNECT_TIMER 1.0
#define RECONNECT_TIMER_MAX_DEFAULT 64.0
#define BACKGROUND_DISCONNECT_AFTER 8.0

@implementation MQTTSessionManager
- (instancetype)init {
    self = [self initWithPersistence:MQTT_PERSISTENT
                       maxWindowSize:MQTT_MAX_WINDOW_SIZE
                         maxMessages:MQTT_MAX_MESSAGES
                             maxSize:MQTT_MAX_SIZE
          maxConnectionRetryInterval:RECONNECT_TIMER_MAX_DEFAULT
                 connectInForeground:YES];
    return self;
}

- (MQTTSessionManager *)initWithPersistence:(BOOL)persistent
                              maxWindowSize:(NSUInteger)maxWindowSize
                                maxMessages:(NSUInteger)maxMessages
                                    maxSize:(NSUInteger)maxSize
                 maxConnectionRetryInterval:(NSTimeInterval)maxRetryInterval
                        connectInForeground:(BOOL)connectInForeground {
    self = [super init];
    
    [self updateState:MQTTSessionManagerStateStarting];
    self.internalSubscriptions = [[NSMutableDictionary alloc] init];
    self.effectiveSubscriptions = [[NSMutableDictionary alloc] init];
    
    self.persistent = persistent;
    self.maxWindowSize = maxWindowSize;
    self.maxSize = maxSize;
    self.maxMessages = maxMessages;
    self.reconnectTimer = [[ReconnectTimer alloc] initWithRetryInterval:RECONNECT_TIMER
                                                       maxRetryInterval:maxRetryInterval
                                                         reconnectBlock:^{
                                                             __weak MQTTSessionManager *weakSelf = self;
                                                             [weakSelf reconnect];
                                                         }];
#if TARGET_OS_IPHONE == 1
    if (connectInForeground) {
        self.foregroundReconnection = [[ForegroundReconnection alloc] initWithMQTTSessionManager:self];
    }
#endif
    self.subscriptionLock = [[NSLock alloc] init];
    
    return self;
}

- (void)connectTo:(NSString *)host
             port:(UInt32)port
              tls:(BOOL)tls
        keepalive:(NSInteger)keepalive
            clean:(BOOL)clean
             auth:(BOOL)auth
             user:(NSString *)user
             pass:(NSString *)pass
             will:(MQTTWill *)will
     withClientId:(NSString *)clientId
   securityPolicy:(MQTTSSLSecurityPolicy *)securityPolicy
     certificates:(NSArray *)certificates
    protocolLevel:(MQTTProtocolVersion)protocolLevel
          runLoop:(NSRunLoop *)runLoop {
    DDLogVerbose(@"MQTTSessionManager connectTo:%@", host);
    BOOL shouldReconnect = self.session != nil;

    self.session = [[MQTTSession alloc] init];
    self.session.clientId = clientId;
    self.session.userName = auth ? user : nil;
    self.session.password = auth ? pass : nil;
    self.session.keepAliveInterval = keepalive;
    self.session.cleanSessionFlag = clean;
    self.session.will = will;
    self.session.protocolLevel = protocolLevel;
    self.session.runLoop = runLoop;

    MQTTCoreDataPersistence *persistence = [[MQTTCoreDataPersistence alloc] init];

    persistence.persistent = self.persistent;
    persistence.maxWindowSize = self.maxWindowSize;
    persistence.maxSize = self.maxSize;
    persistence.maxMessages = self.maxMessages;

    self.session.persistence = persistence;

    if (securityPolicy) {
        MQTTSSLSecurityPolicyTransport *transport = [[MQTTSSLSecurityPolicyTransport alloc] init];
        transport.host = host;
        transport.port = port;
        transport.tls = tls;
        transport.securityPolicy = securityPolicy;
        transport.certificates = certificates;
        transport.runLoop = runLoop;
        self.session.transport = transport;

    } else {
        MQTTCFSocketTransport *transport = [[MQTTCFSocketTransport alloc] init];
        transport.host = host;
        transport.port = port;
        transport.tls = tls;
        transport.certificates = certificates;
        transport.runLoop = runLoop;
        self.session.transport = transport;
    }

    self.session.delegate = self;
    self.reconnectFlag = FALSE;

    if (shouldReconnect) {
        DDLogVerbose(@"[MQTTSessionManager] reconnecting");
        [self disconnect];
        [self reconnect];
    } else {
        DDLogVerbose(@"[MQTTSessionManager] connecting");
        [self connectToInternal];
    }
}

- (UInt16)sendData:(NSData *)data topic:(NSString *)topic qos:(MQTTQosLevel)qos retain:(BOOL)retainFlag {
    if (self.state != MQTTSessionManagerStateConnected) {
        [self connectToLast];
    }
    UInt16 msgId = [self.session publishDataV5:data
                                       onTopic:topic
                                        retain:retainFlag
                                           qos:qos
                        payloadFormatIndicator:nil
                     messageExpiryInterval:nil
                                    topicAlias:nil
                                 responseTopic:nil
                               correlationData:nil
                                userProperties:nil
                                   contentType:nil
                                publishHandler:nil];
    return msgId;
}

- (void)disconnect {
    [self updateState:MQTTSessionManagerStateClosing];
    [self.session closeWithReturnCode:0
                sessionExpiryInterval:nil
                         reasonString:nil
                       userProperties:nil
                    disconnectHandler:nil];
    [self.reconnectTimer stop];
}

- (BOOL)requiresTearDown {
    return (self.state != MQTTSessionManagerStateClosed &&
            self.state != MQTTSessionManagerStateStarting);
}

- (void)updateState:(MQTTSessionManagerState)newState {
    self.state = newState;

    if ([self.delegate respondsToSelector:@selector(sessionManager:didChangeState:)]) {
        [self.delegate sessionManager:self didChangeState:newState];
    }
}


#pragma mark - MQTT Callback methods

- (void)handleEvent:(MQTTSession *)session event:(MQTTSessionEvent)eventCode error:(NSError *)error {
#ifdef DEBUG
    __unused const NSDictionary *events = @{
                                            @(MQTTSessionEventConnected): @"connected",
                                            @(MQTTSessionEventConnectionRefused): @"connection refused",
                                            @(MQTTSessionEventConnectionClosed): @"connection closed",
                                            @(MQTTSessionEventConnectionError): @"connection error",
                                            @(MQTTSessionEventProtocolError): @"protocoll error",
                                            @(MQTTSessionEventConnectionClosedByBroker): @"connection closed by broker"
                                            };
    DDLogVerbose(@"[MQTTSessionManager] eventCode: %@ (%ld) %@", events[@(eventCode)], (long)eventCode, error);
#endif
    switch (eventCode) {
        case MQTTSessionEventConnected:
            self.lastErrorCode = nil;
            [self updateState:MQTTSessionManagerStateConnected];
            [self.reconnectTimer resetRetryInterval];
            break;
            
        case MQTTSessionEventConnectionClosed:
            [self updateState:MQTTSessionManagerStateClosed];
            break;
            
        case MQTTSessionEventConnectionClosedByBroker:
            if (self.state != MQTTSessionManagerStateClosing) {
                [self triggerDelayedReconnect];
            }
            [self updateState:MQTTSessionManagerStateClosed];
            break;

        case MQTTSessionEventProtocolError:
        case MQTTSessionEventConnectionRefused:
        case MQTTSessionEventConnectionError:
            [self triggerDelayedReconnect];
            self.lastErrorCode = error;
            [self updateState:MQTTSessionManagerStateError];
            break;

        default:
            break;
    }
}

- (void)newMessage:(MQTTSession *)session data:(NSData *)data onTopic:(NSString *)topic qos:(MQTTQosLevel)qos retained:(BOOL)retained mid:(unsigned int)mid {
    if (self.delegate) {
        if ([self.delegate respondsToSelector:@selector(sessionManager:didReceiveMessage:onTopic:retained:)]) {
            [self.delegate sessionManager:self didReceiveMessage:data onTopic:topic retained:retained];
        }
        if ([self.delegate respondsToSelector:@selector(handleMessage:onTopic:retained:)]) {
            [self.delegate handleMessage:data onTopic:topic retained:retained];
        }
    }
}

- (void)connected:(MQTTSession *)session sessionPresent:(BOOL)sessionPresent {
    if (session.cleanSessionFlag || !self.reconnectFlag || !sessionPresent) {
        NSDictionary *subscriptions = [self.internalSubscriptions copy];
        [self.subscriptionLock lock];
        self.effectiveSubscriptions = [[NSMutableDictionary alloc] init];
        [self.subscriptionLock unlock];
        if (subscriptions.count) {
            [self.session subscribeToTopicsV5:subscriptions
                       subscriptionIdentifier:0
                               userProperties:nil
                             subscribeHandler:^(NSError *error,
                                                NSString *reasonString,
                                                NSArray <NSDictionary <NSString *, NSString *> *> *userProperties,
                                                NSArray<NSNumber *> *reasonCodes) {
                if (!error) {
                    NSArray<NSString *> *allTopics = subscriptions.allKeys;
                    for (int i = 0; i < allTopics.count; i++) {
                        NSString *topic = allTopics[i];
                        NSNumber *reasonCode = reasonCodes[i];
                        [self.subscriptionLock lock];
                        NSMutableDictionary *newEffectiveSubscriptions = [self.subscriptions mutableCopy];
                        newEffectiveSubscriptions[topic] = reasonCode;
                        self.effectiveSubscriptions = newEffectiveSubscriptions;
                        [self.subscriptionLock unlock];
                    }
                }
            }];

        }
        self.reconnectFlag = TRUE;
    }
}

- (void)messageDelivered:(MQTTSession *)session msgID:(UInt16)msgID {
    if (self.delegate) {
        if ([self.delegate respondsToSelector:@selector(sessionManager:didDeliverMessage:)]) {
            [self.delegate sessionManager:self didDeliverMessage:msgID];
        }
        if ([self.delegate respondsToSelector:@selector(messageDelivered:)]) {
            [self.delegate messageDelivered:msgID];
        }
    }
}


- (void)connectToInternal {
    if (self.session && self.state == MQTTSessionManagerStateStarting) {
        [self updateState:MQTTSessionManagerStateConnecting];
        [self.session connectWithConnectHandler:nil];
    }
}

- (void)reconnect {
    [self updateState:MQTTSessionManagerStateStarting];
    [self connectToInternal];
}

- (void)connectToLast {
    if (self.state == MQTTSessionManagerStateConnected) {
        return;
    }
    [self.reconnectTimer resetRetryInterval];
    [self reconnect];
}

- (void)triggerDelayedReconnect {
    [self.reconnectTimer schedule];
}

- (NSDictionary<NSString *, NSNumber *> *)subscriptions {
    return self.internalSubscriptions;
}

- (void)setSubscriptions:(NSDictionary<NSString *, NSNumber *> *)newSubscriptions {
    if (self.state == MQTTSessionManagerStateConnected) {
        NSDictionary *currentSubscriptions = [self.effectiveSubscriptions copy];

        for (NSString *topicFilter in currentSubscriptions) {
            if (!newSubscriptions[topicFilter]) {
                [self.session unsubscribeTopicsV5:@[topicFilter]
                                   userProperties:nil
                               unsubscribeHandler:^(NSError *error,
                                                    NSString *reasonString,
                                                    NSArray <NSDictionary <NSString *, NSString *> *> *userProperties,
                                                    NSArray <NSNumber *> *reasonCodes) {
                    if (!error) {
                        [self.subscriptionLock lock];
                        NSMutableDictionary *newEffectiveSubscriptions = [self.subscriptions mutableCopy];
                        [newEffectiveSubscriptions removeObjectForKey:topicFilter];
                        self.effectiveSubscriptions = newEffectiveSubscriptions;
                        [self.subscriptionLock unlock];
                    }
                }];
            }
        }

        for (NSString *topicFilter in newSubscriptions) {
            if (!currentSubscriptions[topicFilter]) {
                NSNumber *number = newSubscriptions[topicFilter];
                MQTTQosLevel qos = number.unsignedIntValue;
                [self.session subscribeToTopicV5:topicFilter
                                         atLevel:qos
                                         noLocal:NO
                               retainAsPublished:NO
                                  retainHandling:MQTTSendRetained
                          subscriptionIdentifier:0
                                  userProperties:nil
                                subscribeHandler:^(NSError *error,
                                                    NSString *reasonString,
                                                    NSArray <NSDictionary <NSString *, NSString *> *> *userProperties,
                                                    NSArray <NSNumber *> *reasonCodes) {
                    if (!error) {
                        NSNumber *reasonCode = reasonCodes[0];
                        [self.subscriptionLock lock];
                        NSMutableDictionary *newEffectiveSubscriptions = [self.subscriptions mutableCopy];
                        newEffectiveSubscriptions[topicFilter] = reasonCode;
                        self.effectiveSubscriptions = newEffectiveSubscriptions;
                        [self.subscriptionLock unlock];
                    }
                }];
            }
        }
    }
    self.internalSubscriptions = newSubscriptions;
    DDLogVerbose(@"MQTTSessionManager internalSubscriptions: %@", self.internalSubscriptions);
}

@end
