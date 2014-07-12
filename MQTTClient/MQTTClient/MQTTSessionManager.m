//
//  MQTTSessionManager.m
//  MQTTClient
//
//  Created by Christoph Krey on 09.07.14.
//  Copyright (c) 2014 Christoph Krey. All rights reserved.
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
@property (strong, nonatomic) NSString *user;
@property (strong, nonatomic) NSString *pass;
@property (strong, nonatomic) NSString *willTopic;
@property (strong, nonatomic) NSData *will;
@property (nonatomic) NSInteger willQos;
@property (nonatomic) BOOL willRetainFlag;
@property (strong, nonatomic) NSString *clientId;

@property (strong, nonatomic) NSTimer *disconnectTimer;
@property (strong, nonatomic) NSTimer *activityTimer;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundTask;
@property (strong, nonatomic) void (^completionHandler)(UIBackgroundFetchResult);



@end

#define RECONNECT_TIMER 1.0
#define RECONNECT_TIMER_MAX 64.0
#define BACKGROUND_DISCONNECT_AFTER 8.0


@implementation MQTTSessionManager 
- (id)init
{
    self = [super init];
    

    self.state = MQTTSessionManagerStateStarting;
    self.backgroundTask = UIBackgroundTaskInvalid;
    self.completionHandler = nil;

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
    return self;
}

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
        //![will isEqualToData:self.will] ||
        willQos != self.willQos ||
        willRetainFlag != self.willRetainFlag ||
        ![clientId isEqualToString:self.clientId]) {
        self.host = host;
        self.port = (int)port;
        self.tls = tls;
        self.keepalive = keepalive;
        self.clean = clean;
        self.auth = auth;
        self.user = user;
        self.pass = pass;
        self.willTopic = willTopic;
        self.will = will;
        self.willQos = willQos;
        self.willRetainFlag = willRetainFlag;
        self.clientId = clientId;
        
        self.session = [[MQTTSession alloc] initWithClientId:clientId
                                                    userName:auth ? user : nil
                                                    password:auth ? pass : nil
                                                   keepAlive:keepalive
                                                cleanSession:clean
                                                        will:YES
                                                   willTopic:willTopic
                                                     willMsg:will
                                                     willQoS:willQos
                                              willRetainFlag:willRetainFlag
                                               protocolLevel:3
                                                     runLoop:[NSRunLoop currentRunLoop]
                                                     forMode:NSDefaultRunLoopMode];
        self.session.delegate = self;
        self.reconnectTime = RECONNECT_TIMER;
        self.reconnectFlag = FALSE;
    }
    [self connectToInternal];
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
                                   @(MQTTSessionEventProtocolError): @"protocoll error"
                                   };
    NSLog(@"Connection MQTT eventCode: %@ (%ld) %@", events[@(eventCode)], (long)eventCode, error);
#endif
    [self.reconnectTimer invalidate];
    switch (eventCode) {
        case MQTTSessionEventConnected:
        {
            self.lastErrorCode = nil;
            self.state = MQTTSessionManagerStateConnected;
            
            if (self.clean || !self.reconnectFlag) {
                if (self.subscriptions && [self.subscriptions count]) {
                    [self.session subscribeToTopics:self.subscriptions];
                }
                self.reconnectFlag = TRUE;
            }
            
            break;
        }
        case MQTTSessionEventConnectionClosed:
            self.state = MQTTSessionStatusClosed;
            if (self.backgroundTask) {
                [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTask];
                self.backgroundTask = UIBackgroundTaskInvalid;
            }
            if (self.completionHandler) {
                self.completionHandler(UIBackgroundFetchResultNewData);
                self.completionHandler = nil;
            }

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
    [self.delegate handleMessage:data onTopic:topic retained:retained];
}

- (void)connectToInternal
{
    if (self.state == MQTTSessionManagerStateStarting) {
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

@end

