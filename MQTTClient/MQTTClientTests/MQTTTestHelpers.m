//
//  MQTTTestHelpers.m
//  MQTTClient
//
//  Created by Christoph Krey on 09.12.15.
//  Copyright © 2015 Christoph Krey. All rights reserved.
//

#import "MQTTTestHelpers.h"
#import "MQTTCFSocketTransport.h"

#define LOG_LEVEL_DEF ddLogLevel
#import <CocoaLumberjack/CocoaLumberjack.h>
#ifdef DEBUG
static const DDLogLevel ddLogLevel = DDLogLevelVerbose;
#else
static const DDLogLevel ddLogLevel = DDLogLevelWarning;
#endif


@implementation MQTTTestHelpers

- (void)setUp {
    [super setUp];
    
    if (![[DDLog allLoggers] containsObject:[DDTTYLogger sharedInstance]])
        [DDLog addLogger:[DDTTYLogger sharedInstance] withLevel:DDLogLevelAll];
    if (![[DDLog allLoggers] containsObject:[DDASLLogger sharedInstance]])
        [DDLog addLogger:[DDASLLogger sharedInstance] withLevel:DDLogLevelWarning];
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1
                                                  target:self
                                                selector:@selector(ticker:)
                                                userInfo:@"ticker"
                                                 repeats:true];
}

- (void)tearDown {
    [self.timer invalidate];
    [super tearDown];
}


- (void)ticker:(NSTimer *)timer {
    DDLogVerbose(@"ticker %@", timer.userInfo);
}

- (void)timedout:(id)object {
    DDLogVerbose(@"timedout");
    self.timedout = TRUE;
}

- (void)messageDelivered:(MQTTSession *)session msgID:(UInt16)msgID {
    DDLogVerbose(@"messageDelivered %d", msgID);
}

- (void)newMessage:(MQTTSession *)session data:(NSData *)data onTopic:(NSString *)topic qos:(MQTTQosLevel)qos retained:(BOOL)retained mid:(unsigned int)mid {
    DDLogVerbose(@"newMessage q%d r%d m%d %@:%@",
                 qos, retained, mid, topic, data);
}

+ (NSArray *)clientCerts:(NSDictionary *)parameters {
    NSArray *clientCerts = nil;
    if (parameters[@"clientp12"] && parameters[@"clientp12pass"]) {
        
        NSString *path = [[NSBundle bundleForClass:[MQTTTestHelpers class]] pathForResource:parameters[@"clientp12"]
                                                                                            ofType:@"p12"];
        
        clientCerts = [MQTTCFSocketTransport clientCertsFromP12:path passphrase:parameters[@"clientp12pass"]];
        if (!clientCerts) {
            DDLogVerbose(@"invalid p12 file");
        }
    }
    return clientCerts;
}

+ (MQTTSSLSecurityPolicy *)securityPolicy:(NSDictionary *)parameters {
    MQTTSSLSecurityPolicy *securityPolicy = nil;
    
    if (parameters[@"serverCER"]) {
        
        NSString *path = [[NSBundle bundleForClass:[MQTTTestHelpers class]] pathForResource:parameters[@"serverCER"]
                                                                                            ofType:@"cer"];
        if (path) {
            NSData *certificateData = [NSData dataWithContentsOfFile:path];
            if (certificateData) {
                securityPolicy = [MQTTSSLSecurityPolicy policyWithPinningMode:MQTTSSLPinningModeCertificate];
                securityPolicy.pinnedCertificates = [[NSArray alloc] initWithObjects:certificateData, nil];
                securityPolicy.validatesCertificateChain = TRUE;
                securityPolicy.allowInvalidCertificates = FALSE;
                securityPolicy.validatesDomainName = TRUE;
            } else {
                NSLog(@"error reading cer file");
            }
        } else {
            NSLog(@"cer file not found");
        }
    }
    return securityPolicy;
}



@end
