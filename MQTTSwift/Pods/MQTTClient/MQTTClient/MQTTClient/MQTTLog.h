//
//  MQTTLog.h
//  MQTTClient
//
//  Created by Christoph Krey on 10.02.16.
//  Copyright © 2016-2017 Christoph Krey. All rights reserved.
//

@import Foundation;

#ifdef LUMBERJACK

#define LOG_LEVEL_DEF ddLogLevel
#import <CocoaLumberjack/CocoaLumberjack.h>

#else /* LUMBERJACK */

typedef NS_OPTIONS(NSUInteger, DDLogFlag){
    /**
     *  0...00001 DDLogFlagError
     */
    DDLogFlagError      = (1 << 0),

    /**
     *  0...00010 DDLogFlagWarning
     */
    DDLogFlagWarning    = (1 << 1),

    /**
     *  0...00100 DDLogFlagInfo
     */
    DDLogFlagInfo       = (1 << 2),

    /**
     *  0...01000 DDLogFlagDebug
     */
    DDLogFlagDebug      = (1 << 3),

    /**
     *  0...10000 DDLogFlagVerbose
     */
    DDLogFlagVerbose    = (1 << 4)
};


typedef NS_ENUM(NSUInteger, DDLogLevel){
DDLogLevelOff       = 0,

/**
 *  Error logs only
 */
DDLogLevelError     = (DDLogFlagError),

/**
 *  Error and warning logs
 */
DDLogLevelWarning   = (DDLogLevelError   | DDLogFlagWarning),

/**
 *  Error, warning and info logs
 */
DDLogLevelInfo      = (DDLogLevelWarning | DDLogFlagInfo),

/**
 *  Error, warning, info and debug logs
 */
DDLogLevelDebug     = (DDLogLevelInfo    | DDLogFlagDebug),

/**
 *  Error, warning, info, debug and verbose logs
 */
DDLogLevelVerbose   = (DDLogLevelDebug   | DDLogFlagVerbose),

/**
 *  All logs (1...11111)
 */
DDLogLevelAll       = NSUIntegerMax
};

#ifdef DEBUG

#define DDLogVerbose if (ddLogLevel & DDLogFlagVerbose) NSLog
#define DDLogDebug if (ddLogLevel & DDLogFlagDebug) NSLog
#define DDLogWarn if (ddLogLevel & DDLogFlagWarning) NSLog
#define DDLogInfo if (ddLogLevel & DDLogFlagInfo) NSLog
#define DDLogError if (ddLogLevel & DDLogFlagError) NSLog

#else

#define DDLogVerbose(...)
#define DDLogDebug(...)
#define DDLogWarn(...)
#define DDLogInfo(...)
#define DDLogError(...)

#endif /* DEBUG */
#endif /* LUMBERJACK */

extern DDLogLevel ddLogLevel;

/** MQTTLog lets you define the log level for MQTTClient
 *  independently of using CocoaLumberjack
 */
@interface MQTTLog: NSObject

/** setLogLevel controls the log level for MQTTClient
 *  @param logLevel as follows:
 *
 *  default for DEBUG builds is DDLogLevelVerbose
 *  default for RELEASE builds is DDLogLevelWarning
 *
 *  Available log levels:
 *  DDLogLevelAll
 *  DDLogLevelVerbose
 *  DDLogLevelDebug
 *  DDLogLevelInfo
 *  DDLogLevelWarning
 *  DDLogLevelError
 *  DDLogLevelOff
 */
+ (void)setLogLevel:(DDLogLevel)logLevel;

@end
