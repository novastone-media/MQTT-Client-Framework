//
//  MQTTTestHelpers.h
//  MQTTClient
//
//  Created by Christoph Krey on 09.12.15.
//  Copyright © 2015 Christoph Krey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>

#import "MQTTClient.h"
#import "MQTTSSLSecurityPolicy.h"


#define TOPIC @"MQTTClient"
#define MULTI 15  // some test servers are limited in concurrent sessions
#define BULK 99
#define ALOT 1024
#define PERSISTENT false

//#define BROKERLIST @[@"local", @"mosquitto", @"mosquittoTls", @"mosquittoTlsCerts", @"eclipse", @"paho", @"hivemq", @"m2m", @"rabbitmq"]
//#define BROKERLIST @[@"local"]
#define BROKERLIST @[@"64", @"w64"]

#define BROKERS @{ \
\
@"local": @{ \
@"host": @"localhost",  \
@"port": @1883,  \
@"tls": @NO, \
@"protocollevel": @4, \
@"timeout": @30 \
}, \
\
@"64": @{ \
@"host": @"192.168.178.64",  \
@"port": @1883,  \
@"tls": @NO, \
@"protocollevel": @4, \
@"timeout": @30 \
}, \
\
@"w64": @{ \
@"host": @"192.168.178.64",  \
@"port": @9001,  \
@"tls": @NO, \
@"protocollevel": @4, \
@"timeout": @60, \
@"websocket": @YES \
}, \
\
@"mosquittoTls": @{ \
@"host": @"test.mosquitto.org",  \
@"port": @8883,  \
@"tls": @YES, \
@"protocollevel": @4, \
@"timeout": @10, \
@"serverCER": @"mosquitto.org" \
}, \
\
@"mosquittoTlsCerts": @{ \
@"host": @"test.mosquitto.org",  \
@"port": @8884,  \
@"tls": @YES, \
@"protocollevel": @4, \
@"timeout": @10, \
@"serverCER": @"mosquitto.org", \
@"clientp12": @"KreyChristoph", \
@"clientp12pass": @"abcde" \
}, \
\
@"mosquitto": @{ \
@"host": @"test.mosquitto.org",  \
@"port": @1883,  \
@"tls": @NO, \
@"protocollevel": @4, \
@"timeout": @10 \
}, \
\
@"eclipse": @{ \
@"host": @"m2m.eclipse.org",  \
@"port": @1883,  \
@"tls": @NO, \
@"protocollevel": @4, \
@"timeout": @10 \
}, \
\
@"paho": @{ \
@"host": @"iot.eclipse.org",  \
@"port": @1883,  \
@"tls": @NO, \
@"protocollevel": @4, \
@"timeout": @10 \
}, \
\
@"m2m": @{ \
@"host": @"q.m2m.io",  \
@"port": @1883,  \
@"tls": @NO, \
@"protocollevel": @4, \
@"timeout": @10 \
}, \
\
@"hivemq": @{ \
@"host": @"broker.mqtt-dashboard.com",  \
@"port": @1883,  \
@"tls": @NO, \
@"protocollevel": @4, \
@"timeout": @30 \
}, \
\
@"rabbitmq": @{ \
@"host": @"dev.rabbitmq.com",  \
@"port": @1883,  \
@"tls": @NO, \
@"protocollevel": @3, \
@"timeout": @10 \
} \
\
}


@interface MQTTTestHelpers : XCTestCase <MQTTSessionDelegate>
- (void)timedout:(id)object;

+ (NSArray *)clientCerts:(NSDictionary *)parameters;
+ (MQTTSSLSecurityPolicy *)securityPolicy:(NSDictionary *)parameters;

@property (strong, nonatomic) MQTTSession *session;
@property (nonatomic) int event;
@property (strong, nonatomic) NSError *error;

@property (nonatomic) UInt16 subMid;
@property (nonatomic) UInt16 unsubMid;
@property (nonatomic) UInt16 messageMid;

@property (nonatomic) UInt16 sentSubMid;
@property (nonatomic) UInt16 sentUnsubMid;
@property (nonatomic) UInt16 sentMessageMid;

@property (nonatomic) BOOL SYSreceived;
@property (nonatomic) NSArray *qoss;

@property (nonatomic) BOOL timedout;
@property (strong, nonatomic) NSTimer *timer;
@property (nonatomic) NSTimeInterval timeoutValue;

@property (nonatomic) int type;

@end
