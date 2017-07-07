//
//  MQTTLog.m
//  MQTTClient
//
//  Created by Josip Cavar on 06/07/2017.
//
//

#import "MQTTLog.h"

@implementation MQTTLog

#ifdef LUMBERJACK

#ifdef DEBUG

DDLogLevel ddLogLevel = DDLogLevelVerbose;

#else

DDLogLevel ddLogLevel = DDLogLevelWarning;

#endif /* DEBUG */

+ (void)setLogLevel:(DDLogLevel)logLevel {
    ddLogLevel = logLevel;
}

#endif

@end
