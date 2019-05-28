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

DDLogLevel ddLogLevel = DDLogLevelVerbose;

#else

DDLogLevel ddLogLevel = DDLogLevelWarning;

#endif

+ (void)setLogLevel:(DDLogLevel)logLevel {
    ddLogLevel = logLevel;
}

@end
