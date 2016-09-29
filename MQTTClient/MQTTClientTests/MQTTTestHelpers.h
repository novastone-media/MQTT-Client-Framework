//
//  MQTTTestHelpers.h
//  MQTTClient
//
//  Created by Christoph Krey on 09.12.15.
//  Copyright © 2015-2016 Christoph Krey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>

#import "MQTTClient.h"
#import "MQTTSessionManager.h"
#import "MQTTSSLSecurityPolicy.h"

#define TOPIC @"MQTTClient"
#define MULTI 15 // some test servers are limited in concurrent sessions
#define BULK 100 // some test servers are limited in queue size
#define ALOT 1000 // some test servers are limited in queue size

@interface MQTTTestHelpers : XCTestCase <MQTTSessionDelegate, MQTTSessionManagerDelegate>
- (void)timedout:(id)object;

+ (MQTTSession *)session:(NSDictionary *)parameters;
+ (id<MQTTTransport>)transport:(NSDictionary *)parameters;
+ (id<MQTTPersistence>)persistence:(NSDictionary *)parameters;
+ (NSArray *)clientCerts:(NSDictionary *)parameters;
+ (MQTTSSLSecurityPolicy *)securityPolicy:(NSDictionary *)parameters;

@property (strong, nonatomic) NSMutableDictionary *brokers;
@property (strong, nonatomic) MQTTSession *session;

@property (nonatomic) int event;
@property (strong, nonatomic) NSError *error;

@property (nonatomic) UInt16 subMid;
@property (nonatomic) UInt16 unsubMid;
@property (nonatomic) UInt16 messageMid;

@property (nonatomic) UInt16 sentSubMid;
@property (nonatomic) UInt16 sentUnsubMid;
@property (nonatomic) UInt16 sentMessageMid;
@property (nonatomic) UInt16 deliveredMessageMid;

@property (nonatomic) BOOL SYSreceived;
@property (nonatomic) NSArray *qoss;

@property (nonatomic) BOOL timedout;
@property (strong, nonatomic) NSTimer *timer;
@property (nonatomic) NSTimeInterval timeoutValue;

@property (nonatomic) int type;

@end
