//
//  MQTTLog.h
//  MQTTClient
//
//  Created by Christoph Krey on 10.02.16.
//  Copyright © 2016-2017 Christoph Krey. All rights reserved.
//

#ifdef LUMBERJACK
#define LOG_LEVEL_DEF ddLogLevel
#import <CocoaLumberjack/CocoaLumberjack.h>
#ifndef myLogLevel
#ifdef DEBUG
static const DDLogLevel ddLogLevel = DDLogLevelWarning;
#else
static const DDLogLevel ddLogLevel = DDLogLevelWarning;
#endif /* DEBUG */
#else
static const DDLogLevel ddLogLevel = myLogLevel;
#endif /* myLogLevel */
#else
#ifdef DEBUG
#define DDLogVerbose NSLog
#define DDLogWarn NSLog
#define DDLogInfo NSLog
#define DDLogError NSLog
#else
#define DDLogVerbose(...)
#define DDLogWarn(...)
#define DDLogInfo(...)
#define DDLogError(...)
#endif /* DEBUG */
#endif /* LUMBERJACK */
