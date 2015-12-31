//
// MQTTCFSocketDecoder.m
// MQTTClient.framework
//
// Copyright (c) 2013-2015, Christoph Krey
//

#import "MQTTCFSocketDecoder.h"

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

@interface MQTTCFSocketDecoder()

@end

@implementation MQTTCFSocketDecoder

- (instancetype)init {
    self = [super init];
    self.state = MQTTCFSocketDecoderStateInitializing;
    
    self.stream = nil;
    self.runLoop = [NSRunLoop currentRunLoop];
    self.runLoopMode = NSRunLoopCommonModes;
    return self;
}

- (void)open {
    if (self.state == MQTTCFSocketDecoderStateInitializing) {
        [self.stream setDelegate:self];
        [self.stream scheduleInRunLoop:self.runLoop forMode:self.runLoopMode];
        [self.stream open];
    }
}

- (void)close {
    if (self.state == MQTTCFSocketDecoderStateReady || self.state == MQTTCFSocketDecoderStateError) {
        [self.stream close];
        [self.stream removeFromRunLoop:self.runLoop forMode:self.runLoopMode];
        [self.stream setDelegate:nil];
        self.state = MQTTCFSocketDecoderStateInitializing;
    }
}

- (void)stream:(NSStream*)sender handleEvent:(NSStreamEvent)eventCode {
    
    if (eventCode & NSStreamEventOpenCompleted) {
        DDLogVerbose(@"[MQTTCFSocketDecoder] NSStreamEventOpenCompleted");
        self.state = MQTTCFSocketDecoderStateReady;
        [self.delegate decoderDidOpen:self];
    }

    if (eventCode &  NSStreamEventHasBytesAvailable) {
        DDLogVerbose(@"[MQTTCFSocketDecoder] NSStreamEventHasBytesAvailable");
        if (self.state == MQTTCFSocketDecoderStateInitializing) {
            self.state = MQTTCFSocketDecoderStateReady;
        }
        
        if (self.state == MQTTCFSocketDecoderStateReady) {
            NSInteger n;
            UInt8 buffer[768];
            
            n = [self.stream read:buffer maxLength:sizeof(buffer)];
            if (n == -1) {
                self.state = MQTTCFSocketDecoderStateError;
                [self.delegate decoder:self didFailWithError:nil];
            } else {
                NSData *data = [NSData dataWithBytes:buffer length:n];
                DDLogVerbose(@"[MQTTCFSocketDecoder] received (%lu)=%@...", (unsigned long)data.length,
                             [data subdataWithRange:NSMakeRange(0, MIN(256, data.length))]);
                [self.delegate decoder:self didReceiveMessage:data];
            }
        }
    }
    if (eventCode &  NSStreamEventHasSpaceAvailable) {
        DDLogVerbose(@"[MQTTCFSocketDecoder] NSStreamEventHasSpaceAvailable");
    }
    
    if (eventCode &  NSStreamEventEndEncountered) {
        DDLogVerbose(@"[MQTTCFSocketDecoder] NSStreamEventEndEncountered");
        self.state = MQTTCFSocketDecoderStateInitializing;
        self.error = nil;
        [self.delegate decoderdidClose:self];
    }
    
    if (eventCode &  NSStreamEventErrorOccurred) {
        DDLogVerbose(@"[MQTTCFSocketDecoder] NSStreamEventErrorOccurred");
        self.state = MQTTCFSocketDecoderStateError;
        self.error = self.stream.streamError;
        [self.delegate decoder:self didFailWithError:self.error];
    }
}

@end
