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

extern DDLogLevel ddLogLevel;

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

@interface MQTTLog: NSObject

#ifdef LUMBERJACK

+ (void)setLogLevel:(DDLogLevel)logLevel;

#endif

@end
