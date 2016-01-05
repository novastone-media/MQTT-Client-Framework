//
//  MQTTTransport.m
//  MQTTClient
//
//  Created by Christoph Krey on 05.01.16.
//  Copyright © 2016 Christoph Krey. All rights reserved.
//

#import "MQTTTransport.h"

#ifdef LUMBERJACK
#define LOG_LEVEL_DEF ddLogLevel
#import <CocoaLumberjack/CocoaLumberjack.h>
#ifdef DEBUG
static const DDLogLevel ddLogLevel = DDLogLevelVerbose;
#else
static const DDLogLevel ddLogLevel = DDLogLevelWarning;
#endif
#else
#define DDLogVerbose NSLog
#define DDLogWarn NSLog
#define DDLogInfo NSLog
#define DDLogError NSLog
#endif

@implementation MQTTTransport
@synthesize state;
@synthesize runLoop;
@synthesize runLoopMode;
@synthesize delegate;

- (instancetype)init {
    self = [super init];
    self.state = MQTTTransportCreated;
    self.runLoop = [NSRunLoop currentRunLoop];
    self.runLoopMode = NSRunLoopCommonModes;
    return self;
}

- (void)open {
    DDLogError(@"MQTTTransport is abstract class");
}

- (void)close {
    DDLogError(@"MQTTTransport is abstract class");
}

- (BOOL)send:(NSData *)data {
    DDLogError(@"MQTTTransport is abstract class");
    return FALSE;
}

@end