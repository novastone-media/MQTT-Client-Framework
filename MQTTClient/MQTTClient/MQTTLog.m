//
//  MQTTLog.m
//  MQTTClient
//
//  Created by Josip Cavar on 06/07/2017.
//
//

#import "MQTTLog.h"

@implementation MQTTLog

#ifdef DEBUG

DDLogLevel MQTTLogLevel = DDLogLevelVerbose;

#else

DDLogLevel MQTTLogLevel = DDLogLevelWarning;

#endif

+ (void)setLogLevel:(DDLogLevel)logLevel {
    MQTTLogLevel = logLevel;
}

@end
