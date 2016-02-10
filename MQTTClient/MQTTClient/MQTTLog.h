//
//  MQTTLog.h
//  MQTTClient
//
//  Created by Christoph Krey on 10.02.16.
//  Copyright © 2016 Christoph Krey. All rights reserved.
//

#ifndef MQTTLog_h

#define MQTTLog_h


#ifdef LUMBERJACK
    #define LOG_LEVEL_DEF ddLogLevel
    #import <CocoaLumberjack/CocoaLumberjack.h>
    #ifndef myLogLevel
        #ifdef DEBUG
            static const DDLogLevel ddLogLevel = DDLogLevelWarning;
        #else
            static const DDLogLevel ddLogLevel = DDLogLevelWarning;
        #endif
    #else
        static const DDLogLevel ddLogLevel = myLogLevel;
    #endif
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
        #endif
#endif


#endif /* MQTTLog_h */
