//
//  MQTTTestHelpers.m
//  MQTTClient
//
//  Created by Christoph Krey on 09.12.15.
//  Copyright © 2015-2017 Christoph Krey. All rights reserved.
//

#import "MQTTLog.h"
#import "MQTTTestHelpers.h"
#import "MQTTCFSocketTransport.h"
#import "MQTTInMemoryPersistence.h"
#import "MQTTCoreDataPersistence.h"
//#import "MQTTWebsocketTransport.h"
#import "MQTTSSLSecurityPolicy.h"
#import "MQTTSSLSecurityPolicyTransport.h"

@implementation MQTTTestHelpers

static NSDictionary *brokers = nil;
static NSDictionary *allBrokers = nil;

+ (NSDictionary *)broker {
    return [MQTTTestHelpers allBrokers][@"local"];
}

+ (NSDictionary *)allBrokers {
    if (allBrokers == nil) {
        allBrokers = [MQTTTestHelpers loadAllBrokers];
    }
    return allBrokers;
}

+ (NSDictionary *)loadAllBrokers {
    NSURL *url = [[NSBundle bundleForClass:[MQTTTestHelpers class]] URLForResource:@"MQTTTestHelpers"
                                                                     withExtension:@"plist"];
    NSDictionary *plist = [NSDictionary dictionaryWithContentsOfURL:url];
    NSDictionary *plistBrokers = plist[@"brokers"];
    return plistBrokers;
}

- (void)setUp {
    [super setUp];
    [MQTTLog setLogLevel:DDLogLevelOff];
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
    DDLogWarn(@"[MQTTTestHelpers] timedout");
    self.timedout = TRUE;
}

- (void)messageDelivered:(MQTTSession *)session msgID:(UInt16)msgID {
    DDLogVerbose(@"[MQTTTestHelpers] messageDelivered %d", msgID);
    self.deliveredMessageMid = msgID;
}

- (void)messageDelivered:(MQTTSession *)session
                   msgID:(UInt16)msgID
                   topic:(NSString *)topic
                    data:(NSData *)data
                     qos:(MQTTQosLevel)qos
              retainFlag:(BOOL)retainFlag {
    DDLogVerbose(@"[MQTTTestHelpers] messageDelivered %d q%d r%d %@:%@",
                 msgID,
                 qos,
                 retainFlag,
                 topic,
                 (data.length < 64 ?
                  data.description :
                  [data subdataWithRange:NSMakeRange(0, 64)].description));
}

- (void)newMessage:(MQTTSession *)session data:(NSData *)data onTopic:(NSString *)topic qos:(MQTTQosLevel)qos retained:(BOOL)retained mid:(unsigned int)mid {
    DDLogVerbose(@"[MQTTTestHelpers] newMessage q%d r%d m%d %@:%@",
                 qos, retained, mid, topic, data);
    self.messageMid = mid;
    if (topic && [topic hasPrefix:@"$"]) {
        self.SYSreceived = true;
    }
}

- (void)sessionManager:(MQTTSessionManager *)sessionManager
     didReceiveMessage:(NSData *)data
               onTopic:(NSString *)topic
              retained:(BOOL)retained {
    DDLogVerbose(@"[MQTTTestHelpers] didReceiveMessage r%d %@:%@",
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

- (void)connected:(MQTTSession *)session sessionPresent:(BOOL)sessionPresent {
    self.connected = TRUE;
    self.sessionPresent = sessionPresent;
}

- (void)connectionRefused:(MQTTSession *)session error:(NSError *)error {
    self.error = error;
    self.connectionError = error;
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
    DDLogInfo(@"[MQTTTestHelpers] subAckReceived:%d grantedQoss:%@", msgID, qoss);
    self.subMid = msgID;
    self.qoss = qoss;
}

- (void)unsubAckReceived:(MQTTSession *)session msgID:(UInt16)msgID
{
    DDLogInfo(@"[MQTTTestHelpers] unsubAckReceived:%d", msgID);
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
                    securityPolicy.pinnedCertificates = @[certificateData];
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
        NSException *exception = [NSException exceptionWithName:@"WebSockets tests currently disabled" reason:@"" userInfo:nil];
        @throw exception;
        /*
         MQTTWebsocketTransport *websocketTransport = [[MQTTWebsocketTransport alloc] init];
         websocketTransport.host = parameters[@"host"];
         websocketTransport.port = [parameters[@"port"] intValue];
         websocketTransport.tls = [parameters[@"tls"] boolValue];
         if (parameters[@"path"]) {
         websocketTransport.path = parameters[@"path"];
         }
         websocketTransport.allowUntrustedCertificates = [parameters[@"allowUntrustedCertificates"] boolValue];
         
         transport = websocketTransport;
         */
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
    session.sessionExpiryInterval = @0;
    session.userName = parameters[@"user"];
    session.password = parameters[@"pass"];
    session.protocolLevel = [parameters[@"protocollevel"] intValue];
    session.persistence = [MQTTTestHelpers persistence:parameters];
    return session;
}

@end
