//
//  MQTTTestHelpers.m
//  MQTTClient
//
//  Created by Christoph Krey on 09.12.15.
//  Copyright © 2015-2016 Christoph Krey. All rights reserved.
//

#import "MQTTLog.h"
#import "MQTTTestHelpers.h"
#import "MQTTCFSocketTransport.h"
#import "MQTTInMemoryPersistence.h"
#import "MQTTCoreDataPersistence.h"
#import "MQTTWebsocketTransport.h"
#import "MQTTSSLSecurityPolicy.h"

@implementation MQTTTestHelpers

- (void)setUp {
    [super setUp];
    
#ifdef LUMBERJACK
   if (![[DDLog allLoggers] containsObject:[DDTTYLogger sharedInstance]])
    [DDLog addLogger:[DDTTYLogger sharedInstance] withLevel:DDLogLevelAll];
    if (![[DDLog allLoggers] containsObject:[DDASLLogger sharedInstance]])
    [DDLog addLogger:[DDASLLogger sharedInstance] withLevel:DDLogLevelWarning];
#endif

    NSURL *url = [[NSBundle bundleForClass:[MQTTTestHelpers class]] URLForResource:@"MQTTTestHelpers"
                                                                     withExtension:@"plist"];
    NSDictionary *plist = [NSDictionary dictionaryWithContentsOfURL:url];
    NSArray *brokerList = [plist objectForKey:@"brokerList"];
    NSDictionary *brokers = [plist objectForKey:@"brokers"];

    self.brokers = [[NSMutableDictionary alloc] init];
    for (NSString *brokerName in brokerList) {
        NSDictionary *broker = [brokers objectForKey:brokerName];
        if (broker) {
            [self.brokers setObject:broker forKey:brokerName];
        }
    }
//
//    NSDictionary *eclipseBroker = @{
//                                    @"host": @"m2m.eclipse.org",
//                                    @"port": @1883,
//                                    @"tls": @NO,
//                                    @"protocollevel": @4,
//                                    @"timeout": @10
//                                    };
//    [self.brokers setObject:eclipseBroker forKey:@"eclipseBroker"];
//
//    
//    NSDictionary *pahoBroker = @{
//                                 @"host": @"iot.eclipse.org",
//                                 @"port": @1883,
//                                 @"tls": @NO,
//                                 @"protocollevel": @4,
//                                 @"timeout": @10
//                                 };
//    [self.brokers setObject:pahoBroker forKey:@"pahoBroker"];
//
//    
//    NSDictionary *m2mBroker = @{
//                                @"host": @"q.m2m.io",
//                                @"port": @1883,
//                                @"tls": @NO,
//                                @"protocollevel": @4,
//                                @"timeout": @10
//                                };
//    [self.brokers setObject:m2mBroker forKey:@"m2mBroker"];
//
//    
//    NSDictionary *hivemqBroker = @{
//                                   @"host": @"broker.mqtt-dashboard.com",
//                                   @"port": @1883,
//                                   @"tls": @NO,
//                                   @"protocollevel": @4,
//                                   @"timeout": @30
//                                   };
//    [self.brokers setObject:hivemqBroker forKey:@"hivemqBroker"];
//
//    
//    NSDictionary *rabbitmqBroker = @{
//                                     @"host": @"dev.rabbitmq.com",
//                                     @"port": @1883,
//                                     @"tls": @NO,
//                                     @"protocollevel": @4,
//                                     @"timeout": @10
//                                     };
//    [self.brokers setObject:rabbitmqBroker forKey:@"rabbitmqBroker"];

    self.timer = [NSTimer scheduledTimerWithTimeInterval:1
                                                  target:self
                                                selector:@selector(ticker:)
                                                userInfo:nil
                                                 repeats:true];
}

- (void)tearDown {
    [self.timer invalidate];
    [super tearDown];
}

/*
 * |#define                |MAC      |IOS      |IOS SIMULATOR  |TV       |TV SIMULATOR |WATCH   |WATCH SIMULATOR |
 * |-----------------------|---------|---------|---------------|---------|-------------|--------|----------------|
 * |TARGET_OS_MAC          |    1    |    1    |       1       |    1    |      1      |        |                |
 * |TARGET_OS_WIN32        |    0    |    0    |       0       |    0    |      0      |        |                |
 * |TARGET_OS_UNIX         |    0    |    0    |       0       |    0    |      0      |        |                |
 * |TARGET_OS_IPHONE       |    0    |    1    |       1       |    1    |      1      |        |                |
 * |TARGET_OS_IOS          |    0    |    1    |       1       |    0    |      0      |        |                |
 * |TARGET_OS_WATCH        |    0    |    0    |       0       |    0    |      0      |        |                |
 * |TARGET_OS_TV           |    0    |    0    |       0       |    1    |      1      |        |                |
 * |TARGET_OS_SIMULATOR    |    0    |    0    |       1       |    0    |      1      |        |                |
 * |TARGET_OS_EMBEDDED     |    0    |    1    |       0       |    1    |      0      |        |                |
 *
 * define TARGET_IPHONE_SIMULATOR         TARGET_OS_SIMULATOR deprecated
 * define TARGET_OS_NANO                  TARGET_OS_WATCH deprecated
 *
 * all #defines in TargetConditionals.h
 */

- (void)test_preprocessor {
#if TARGET_OS_MAC == 1
    DDLogVerbose(@"TARGET_OS_MAC==1");
#endif
#if TARGET_OS_MAC == 0
    DDLogVerbose(@"TARGET_OS_MAC==0");
#endif
    DDLogVerbose(@"TARGET_OS_MAC %d", TARGET_OS_MAC);
    DDLogVerbose(@"TARGET_OS_WIN32 %d", TARGET_OS_WIN32);
    DDLogVerbose(@"TARGET_OS_UNIX %d", TARGET_OS_UNIX);
    DDLogVerbose(@"TARGET_OS_IPHONE %d", TARGET_OS_IPHONE);
    DDLogVerbose(@"TARGET_OS_IOS %d", TARGET_OS_IOS);
    DDLogVerbose(@"TARGET_OS_WATCH %d", TARGET_OS_WATCH);
    DDLogVerbose(@"TARGET_OS_TV %d", TARGET_OS_TV);
    DDLogVerbose(@"TARGET_OS_SIMULATOR %d", TARGET_OS_SIMULATOR);
    DDLogVerbose(@"TARGET_OS_EMBEDDED %d", TARGET_OS_EMBEDDED);
}

- (void)ticker:(NSTimer *)timer {
    DDLogVerbose(@"[MQTTTestHelpers] ticker");
}

- (void)timedout:(id)object {
    DDLogVerbose(@"[MQTTTestHelpers] timedout");
    self.timedout = TRUE;
}

- (void)messageDelivered:(MQTTSession *)session msgID:(UInt16)msgID {
    DDLogVerbose(@"[MQTTTestHelpers] messageDelivered %d", msgID);
    self.deliveredMessageMid = msgID;
}

- (void)newMessage:(MQTTSession *)session data:(NSData *)data onTopic:(NSString *)topic qos:(MQTTQosLevel)qos retained:(BOOL)retained mid:(unsigned int)mid {
    DDLogVerbose(@"[MQTTTestHelpers] newMessage q%d r%d m%d %@:%@",
                 qos, retained, mid, topic, data);
    self.messageMid = mid;
    if (topic && [topic hasPrefix:@"$"]) {
        self.SYSreceived = true;
    }
}

- (void)handleMessage:(NSData *)data onTopic:(NSString *)topic retained:(BOOL)retained {
    DDLogVerbose(@"[MQTTTestHelpers] handleMessage r%d %@:%@",
                 retained, topic, data);
    if (topic && [topic hasPrefix:@"$"]) {
        self.SYSreceived = true;
    }
}

- (void)handleEvent:(MQTTSession *)session event:(MQTTSessionEvent)eventCode error:(NSError *)error {
    DDLogVerbose(@"[MQTTTestHelpers] handleEvent:%ld error:%@", (long)eventCode, error);
    self.event = eventCode;
    self.error = error;
}

- (void)sending:(MQTTSession *)session
           type:(MQTTCommandType)type
            qos:(MQTTQosLevel)qos
       retained:(BOOL)retained
          duped:(BOOL)duped
            mid:(UInt16)mid
           data:(NSData *)data {
    DDLogVerbose(@"[MQTTTestHelpers] sending: %02X q%d r%d d%d m%d (%ld) %@",
                 type, qos, retained, duped, mid, data.length,
                 data.length < 64 ? data.description : [data subdataWithRange:NSMakeRange(0, 64)].description);
}

- (void)received:(MQTTSession *)session
            type:(MQTTCommandType)type
             qos:(MQTTQosLevel)qos
        retained:(BOOL)retained
           duped:(BOOL)duped
             mid:(UInt16)mid
            data:(NSData *)data {
    DDLogVerbose(@"[MQTTTestHelpers] received:%d qos:%d retained:%d duped:%d mid:%d data:%@",
                 type, qos, retained, duped, mid, data);
    self.type = type;
}

- (void)subAckReceived:(MQTTSession *)session msgID:(UInt16)msgID grantedQoss:(NSArray *)qoss
{
    DDLogVerbose(@"[MQTTTestHelpers] subAckReceived:%d grantedQoss:%@", msgID, qoss);
    self.subMid = msgID;
    self.qoss = qoss;
}

- (void)unsubAckReceived:(MQTTSession *)session msgID:(UInt16)msgID
{
    DDLogVerbose(@"[MQTTTestHelpers] unsubAckReceived:%d", msgID);
    self.unsubMid = msgID;
}


+ (NSArray *)clientCerts:(NSDictionary *)parameters {
    NSArray *clientCerts = nil;
    if (parameters[@"clientp12"] && parameters[@"clientp12pass"]) {
        
        NSString *path = [[NSBundle bundleForClass:[MQTTTestHelpers class]] pathForResource:parameters[@"clientp12"]
                                                                                     ofType:@"p12"];
        
        clientCerts = [MQTTCFSocketTransport clientCertsFromP12:path passphrase:parameters[@"clientp12pass"]];
        if (!clientCerts) {
            DDLogVerbose(@"[MQTTTestHelpers] invalid p12 file");
        }
    }
    return clientCerts;
}

+ (MQTTSSLSecurityPolicy *)securityPolicy:(NSDictionary *)parameters {
    MQTTSSLSecurityPolicy *securityPolicy = nil;
    
    if ([parameters[@"secpol"] boolValue]) {
        if (parameters[@"serverCER"]) {
            
            NSString *path = [[NSBundle bundleForClass:[MQTTTestHelpers class]] pathForResource:parameters[@"serverCER"]
                                                                                         ofType:@"cer"];
            if (path) {
                NSData *certificateData = [NSData dataWithContentsOfFile:path];
                if (certificateData) {
                    securityPolicy = [MQTTSSLSecurityPolicy policyWithPinningMode:MQTTSSLPinningModeCertificate];
                    securityPolicy.pinnedCertificates = [[NSArray alloc] initWithObjects:certificateData, nil];
                } else {
                    DDLogError(@"[MQTTTestHelpers] error reading cer file");
                }
            } else {
                DDLogError(@"[MQTTTestHelpers] cer file not found");
            }
        } else {
            securityPolicy = [MQTTSSLSecurityPolicy policyWithPinningMode:MQTTSSLPinningModeNone];
        }
        if (parameters[@"allowUntrustedCertificates"]) {
            securityPolicy.allowInvalidCertificates = [parameters[@"allowUntrustedCertificates"] boolValue];
        }
        if (parameters[@"validatesDomainName"]) {
            securityPolicy.validatesDomainName = [parameters[@"validatesDomainName"] boolValue];
        }
        if (parameters[@"validatesCertificateChain"]) {
            securityPolicy.validatesCertificateChain = [parameters[@"validatesCertificateChain"] boolValue];
        }
    }
    return securityPolicy;
}

+ (id<MQTTPersistence>)persistence:(NSDictionary *)parameters {
    id <MQTTPersistence> persistence;
    
    if (parameters[@"CoreData"]) {
        persistence = [[MQTTCoreDataPersistence alloc] init];
    } else {
        persistence = [[MQTTInMemoryPersistence alloc] init];
    }
    
    if (parameters[@"persistent"]) {
        persistence.persistent = [parameters[@"persistent"] boolValue];
    }
    
    if (parameters[@"maxSize"]) {
        persistence.maxSize = [parameters[@"maxSize"] unsignedIntValue];
    }
    
    if (parameters[@"maxSizeSize"]) {
        persistence.maxWindowSize = [parameters[@"maxWindowSize"] boolValue];
    }
    
    if (parameters[@"maxMessages"]) {
        persistence.maxMessages = [parameters[@"maxMessages"] boolValue];
    }
    
    return persistence;
}

+ (id<MQTTTransport>)transport:(NSDictionary *)parameters {
    id<MQTTTransport> transport;
    
    if ([parameters[@"websocket"] boolValue]) {
        MQTTWebsocketTransport *websocketTransport = [[MQTTWebsocketTransport alloc] init];
        websocketTransport.host = parameters[@"host"];
        websocketTransport.port = [parameters[@"port"] intValue];
        websocketTransport.tls = [parameters[@"tls"] boolValue];
        if (parameters[@"path"]) {
            websocketTransport.path = parameters[@"path"];
        }
        websocketTransport.allowUntrustedCertificates = [parameters[@"allowUntrustedCertificates"] boolValue];

        transport = websocketTransport;
    } else {
        MQTTSSLSecurityPolicy *securityPolicy = [MQTTTestHelpers securityPolicy:parameters];
        if (securityPolicy) {
            MQTTSSLSecurityPolicyTransport *sslSecPolTransport = [[MQTTSSLSecurityPolicyTransport alloc] init];
            sslSecPolTransport.host = parameters[@"host"];
            sslSecPolTransport.port = [parameters[@"port"] intValue];
            sslSecPolTransport.tls = [parameters[@"tls"] boolValue];
            sslSecPolTransport.certificates = [MQTTTestHelpers clientCerts:parameters];
            sslSecPolTransport.securityPolicy = securityPolicy;

            transport = sslSecPolTransport;
        } else {
            MQTTCFSocketTransport *cfSocketTransport = [[MQTTCFSocketTransport alloc] init];
            cfSocketTransport.host = parameters[@"host"];
            cfSocketTransport.port = [parameters[@"port"] intValue];
            cfSocketTransport.tls = [parameters[@"tls"] boolValue];
            cfSocketTransport.certificates = [MQTTTestHelpers clientCerts:parameters];
            transport = cfSocketTransport;
        }
    }
    return transport;
}

+ (MQTTSession *)session:(NSDictionary *)parameters {
    MQTTSession *session = [[MQTTSession alloc] init];
    session.transport = [MQTTTestHelpers transport:parameters];
    session.clientId = nil;
    session.userName = parameters[@"user"];
    session.password = parameters[@"pass"];
    session.protocolLevel = [parameters[@"protocollevel"] intValue];
    session.persistence = [MQTTTestHelpers persistence:parameters];
    session.securityPolicy = [MQTTTestHelpers securityPolicy:parameters];
    return session;
}

@end
