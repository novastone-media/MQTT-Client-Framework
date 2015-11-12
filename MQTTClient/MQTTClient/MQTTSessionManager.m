//
//  MQTTSessionManager.m
//  MQTTClient
//
//  Created by Christoph Krey on 09.07.14.
//  Copyright (c) 2013-2015 Christoph Krey. All rights reserved.
//

#import "MQTTSessionManager.h"

@interface MQTTSessionManager()
@property (nonatomic, readwrite) MQTTSessionManagerState state;
@property (nonatomic, readwrite) NSError *lastErrorCode;

@property (strong, nonatomic) NSTimer *reconnectTimer;
@property (nonatomic) double reconnectTime;
@property (nonatomic) BOOL reconnectFlag;

@property (strong, nonatomic) MQTTSession *session;

@property (strong, nonatomic) NSString *host;
@property (nonatomic) UInt32 port;
@property (nonatomic) BOOL tls;
@property (nonatomic) NSInteger keepalive;
@property (nonatomic) BOOL clean;
@property (nonatomic) BOOL auth;
@property (nonatomic) BOOL will;
@property (strong, nonatomic) NSString *user;
@property (strong, nonatomic) NSString *pass;
@property (strong, nonatomic) NSString *willTopic;
@property (strong, nonatomic) NSData *willMsg;
@property (nonatomic) NSInteger willQos;
@property (nonatomic) BOOL willRetainFlag;
@property (strong, nonatomic) NSString *clientId;
@property (strong, nonatomic) MQTTSSLSecurityPolicy *securityPolicy;
@property (strong, nonatomic) NSArray *certificates;

@property (strong, nonatomic) NSTimer *disconnectTimer;
@property (strong, nonatomic) NSTimer *activityTimer;
#if TARGET_OS_IPHONE == 1
@property (nonatomic) UIBackgroundTaskIdentifier backgroundTask;
#endif

@property (nonatomic) BOOL persistent;
@property (nonatomic) NSUInteger maxWindowSize;
@property (nonatomic) NSUInteger maxSize;
@property (nonatomic) NSUInteger maxMessages;

@property (strong, nonatomic) NSMutableDictionary *internalSubscriptions;

@end

#define RECONNECT_TIMER 1.0
#define RECONNECT_TIMER_MAX 64.0
#define BACKGROUND_DISCONNECT_AFTER 8.0

@implementation MQTTSessionManager
- (id)init
{
    self = [super init];

    self.state = MQTTSessionManagerStateStarting;
#if TARGET_OS_IPHONE == 1
    self.backgroundTask = UIBackgroundTaskInvalid;

    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];

    [defaultCenter addObserver:self
                      selector:@selector(appWillResignActive)
                          name:UIApplicationWillResignActiveNotification
                        object:nil];

    [defaultCenter addObserver:self
                      selector:@selector(appDidEnterBackground)
                          name:UIApplicationDidEnterBackgroundNotification
                        object:nil];

    [defaultCenter addObserver:self
                      selector:@selector(appDidBecomeActive)
                          name:UIApplicationDidBecomeActiveNotification
                        object:nil];
#endif
    return self;
}

- (MQTTSessionManager *)initWithPersistence:(BOOL)persistent
                              maxWindowSize:(NSUInteger)maxWindowSize
                                maxMessages:(NSUInteger)maxMessages
                                    maxSize:(NSUInteger)maxSize {
    self = [self init];
    self.persistent = persistent;
    self.maxWindowSize = maxWindowSize;
    self.maxSize = maxSize;
    self.maxMessages = maxMessages;
    return self;
}

#if TARGET_OS_IPHONE == 1
- (void)appWillResignActive
{
    [self disconnect];
}

- (void)appDidEnterBackground
{
    self.backgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        if (self.backgroundTask) {
            [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTask];
            self.backgroundTask = UIBackgroundTaskInvalid;
        }
    }];
}

- (void)appDidBecomeActive
{
    [self connectToLast];
}
#endif

- (void)connectTo:(NSString *)host
             port:(NSInteger)port
              tls:(BOOL)tls
        keepalive:(NSInteger)keepalive
            clean:(BOOL)clean
             auth:(BOOL)auth
             user:(NSString *)user
             pass:(NSString *)pass
        willTopic:(NSString *)willTopic
             will:(NSData *)will
          willQos:(MQTTQosLevel)willQos
   willRetainFlag:(BOOL)willRetainFlag
     withClientId:(NSString *)clientId
{
  [self connectTo:host
               port:port
                tls:tls
          keepalive:keepalive
              clean:clean
               auth:auth
               user:user
               pass:pass
               will:YES
          willTopic:willTopic
            willMsg:will
            willQos:willQos
     willRetainFlag:willRetainFlag
       withClientId:clientId];
}

- (void)connectTo:(NSString *)host
             port:(NSInteger)port
              tls:(BOOL)tls
        keepalive:(NSInteger)keepalive
            clean:(BOOL)clean
             auth:(BOOL)auth
             user:(NSString *)user
             pass:(NSString *)pass
             will:(BOOL)will
        willTopic:(NSString *)willTopic
          willMsg:(NSData *)willMsg
          willQos:(MQTTQosLevel)willQos
   willRetainFlag:(BOOL)willRetainFlag
     withClientId:(NSString *)clientId
{
    [self connectTo:host
               port:port
                tls:tls
          keepalive:keepalive
              clean:clean
               auth:auth
               user:user
               pass:pass
               will:will
          willTopic:willTopic
            willMsg:willMsg
            willQos:willQos
     willRetainFlag:willRetainFlag
       withClientId:clientId
     securityPolicy:nil
       certificates:nil];
}

- (void)connectTo:(NSString *)host
             port:(NSInteger)port
              tls:(BOOL)tls
        keepalive:(NSInteger)keepalive
            clean:(BOOL)clean
             auth:(BOOL)auth
             user:(NSString *)user
             pass:(NSString *)pass
             will:(BOOL)will
        willTopic:(NSString *)willTopic
          willMsg:(NSData *)willMsg
          willQos:(MQTTQosLevel)willQos
   willRetainFlag:(BOOL)willRetainFlag
     withClientId:(NSString *)clientId
   securityPolicy:(MQTTSSLSecurityPolicy *)securityPolicy
     certificates:(NSArray *)certificates
{
    BOOL shouldReconnect = self.session != nil;
    if (!self.session ||
        ![host isEqualToString:self.host] ||
        port != self.port ||
        tls != self.tls ||
        keepalive != self.keepalive ||
        clean != self.clean ||
        auth != self.auth ||
        ![user isEqualToString:self.user] ||
        ![pass isEqualToString:self.pass] ||
        ![willTopic isEqualToString:self.willTopic] ||
        ![willMsg isEqualToData:self.willMsg] ||
        willQos != self.willQos ||
        willRetainFlag != self.willRetainFlag ||
        ![clientId isEqualToString:self.clientId] ||
        securityPolicy != self.securityPolicy ||
        certificates != self.certificates) {
        self.host = host;
        self.port = (int)port;
        self.tls = tls;
        self.keepalive = keepalive;
        self.clean = clean;
        self.auth = auth;
        self.user = user;
        self.pass = pass;
        self.will = will;
        self.willTopic = willTopic;
        self.willMsg = willMsg;
        self.willQos = willQos;
        self.willRetainFlag = willRetainFlag;
        self.clientId = clientId;
        self.securityPolicy = securityPolicy;
        self.certificates = certificates;

        self.session = [[MQTTSession alloc] initWithClientId:clientId
                                                    userName:auth ? user : nil
                                                    password:auth ? pass : nil
                                                   keepAlive:keepalive
                                                cleanSession:clean
                                                        will:will
                                                   willTopic:willTopic
                                                     willMsg:willMsg
                                                     willQoS:willQos
                                              willRetainFlag:willRetainFlag
                                               protocolLevel:4
                                                     runLoop:[NSRunLoop currentRunLoop]
                                                     forMode:NSDefaultRunLoopMode
                                              securityPolicy:securityPolicy
                                                certificates:certificates];
        
        self.session.persistence.persistent = self.persistent;
        self.session.persistence.maxWindowSize = self.maxWindowSize;
        self.session.persistence.maxSize = self.maxSize;
        self.session.persistence.maxMessages = self.maxMessages;
        
        self.session.delegate = self;
        self.reconnectTime = RECONNECT_TIMER;
        self.reconnectFlag = FALSE;
    }
    if(shouldReconnect){
        NSLog(@"MQTTSessionManager reconnecting");
        [self disconnect];
        [self reconnect];
    }else{
        NSLog(@"MQTTSessionManager connecting");
        [self connectToInternal];
    }
}

- (UInt16)sendData:(NSData *)data topic:(NSString *)topic qos:(MQTTQosLevel)qos retain:(BOOL)retainFlag
{
    if (self.state != MQTTSessionManagerStateConnected) {
        [self connectToLast];
    }
    UInt16 msgId = [self.session publishData:data
                                     onTopic:topic
                                      retain:retainFlag
                                         qos:qos];
    return msgId;
}

- (void)disconnect
{
    self.state = MQTTSessionManagerStateClosing;
    [self.session close];

    if (self.reconnectTimer) {
        [self.reconnectTimer invalidate];
        self.reconnectTimer = nil;
    }
}

#pragma mark - MQTT Callback methods

- (void)handleEvent:(MQTTSession *)session event:(MQTTSessionEvent)eventCode error:(NSError *)error
{
#ifdef DEBUG
    const NSDictionary *events = @{
                                   @(MQTTSessionEventConnected): @"connected",
                                   @(MQTTSessionEventConnectionRefused): @"connection refused",
                                   @(MQTTSessionEventConnectionClosed): @"connection closed",
                                   @(MQTTSessionEventConnectionError): @"connection error",
                                   @(MQTTSessionEventProtocolError): @"protocoll error",
                                   @(MQTTSessionEventConnectionClosedByBroker): @"connection closed by broker"
                                   };
    NSLog(@"MQTTSession eventCode: %@ (%ld) %@", events[@(eventCode)], (long)eventCode, error);
#endif
    [self.reconnectTimer invalidate];
    switch (eventCode) {
        case MQTTSessionEventConnected:
        {
            self.lastErrorCode = nil;
            self.state = MQTTSessionManagerStateConnected;
            break;
        }
        case MQTTSessionEventConnectionClosed:
        case MQTTSessionEventConnectionClosedByBroker:
            self.state = MQTTSessionManagerStateClosed;
#if TARGET_OS_IPHONE == 1
            if (self.backgroundTask) {
                [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTask];
                self.backgroundTask = UIBackgroundTaskInvalid;
            }
#endif
            self.state = MQTTSessionManagerStateStarting;
            break;
        case MQTTSessionEventProtocolError:
        case MQTTSessionEventConnectionRefused:
        case MQTTSessionEventConnectionError:
        {
            self.reconnectTimer = [NSTimer timerWithTimeInterval:self.reconnectTime
                                                          target:self
                                                        selector:@selector(reconnect)
                                                        userInfo:Nil repeats:FALSE];
            NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
            [runLoop addTimer:self.reconnectTimer
                      forMode:NSDefaultRunLoopMode];

            self.state = MQTTSessionManagerStateError;
            self.lastErrorCode = error;
            break;
        }
        default:
            break;
    }
}

- (void)newMessage:(MQTTSession *)session data:(NSData *)data onTopic:(NSString *)topic qos:(MQTTQosLevel)qos retained:(BOOL)retained mid:(unsigned int)mid
{
    if (self.delegate) {
        [self.delegate handleMessage:data onTopic:topic retained:retained];
    }
}

- (void)connected:(MQTTSession *)session sessionPresent:(BOOL)sessionPresent {
    if (self.clean || !self.reconnectFlag || !sessionPresent) {
        if (self.subscriptions && [self.subscriptions count]) {
            [self.session subscribeToTopics:self.subscriptions];
        }
        self.reconnectFlag = TRUE;
    }
}

- (void)messageDelivered:(MQTTSession *)session msgID:(UInt16)msgID {
    if (self.delegate) {
        if ([self.delegate respondsToSelector:@selector(messageDelivered:)]) {
            [self.delegate messageDelivered:msgID];
        }
    }
}


- (void)connectToInternal
{
    if (self.state == MQTTSessionManagerStateStarting
        && self.session != nil) {
        self.state = MQTTSessionManagerStateConnecting;
        [self.session connectToHost:self.host
                               port:self.port
                           usingSSL:self.tls];
    }
}

- (void)reconnect
{
    self.reconnectTimer = nil;
    self.state = MQTTSessionManagerStateStarting;

    if (self.reconnectTime < RECONNECT_TIMER_MAX) {
        self.reconnectTime *= 2;
    }
    [self connectToInternal];
}

- (void)connectToLast
{
    self.reconnectTime = RECONNECT_TIMER;

    [self connectToInternal];
}

- (NSDictionary *)subscriptions {
    return self.internalSubscriptions;
}

- (void)setSubscriptions:(NSDictionary *)newSubscriptions
{
    if (self.state==MQTTSessionManagerStateConnected) {
        for (NSString *topicFilter in self.subscriptions) {
            if (![newSubscriptions objectForKey:topicFilter]) {
                [self.session unsubscribeAndWaitTopic:topicFilter];
            }
        }
        
        for (NSString *topicFilter in newSubscriptions) {
            if (![self.subscriptions objectForKey:topicFilter]) {
                NSNumber *number = newSubscriptions[topicFilter];
                MQTTQosLevel qos = [number unsignedIntValue];
                [self.session subscribeToTopic:topicFilter atLevel:qos];
            }
        }
    }
    _internalSubscriptions=[newSubscriptions mutableCopy];
}

@end
