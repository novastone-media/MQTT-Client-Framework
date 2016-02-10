//
// MQTTDecoder.m
// MQTTClient.framework
//
// Copyright © 2013-2016, Christoph Krey
//

#import "MQTTDecoder.h"

#import "MQTTLog.h"

@interface MQTTDecoder()
@property (nonatomic) NSMutableArray<NSInputStream *> *streams;
@end

@implementation MQTTDecoder

- (instancetype)init {
    self = [super init];
    self.state = MQTTDecoderStateInitializing;
    self.runLoop = [NSRunLoop currentRunLoop];
    self.runLoopMode = NSRunLoopCommonModes;
    self.streams = [NSMutableArray arrayWithCapacity:5];
    return self;
}

- (void)decodeMessage:(NSData *)data {
    NSInputStream *stream = [NSInputStream inputStreamWithData:data];
    [self openStream:stream];
}

- (void)openStream:(NSInputStream*)stream {
    [self.streams addObject:stream];
    [stream setDelegate:self];
    DDLogVerbose(@"[MQTTDecoder] #streams=%lu", (unsigned long)self.streams.count);
    if (self.streams.count == 1) {
        [stream scheduleInRunLoop:self.runLoop forMode:self.runLoopMode];
        [stream open];
    }
}

- (void)open {
    self.state = MQTTDecoderStateDecodingHeader;
}

- (void)close {
    if (self.streams) {
        for (NSInputStream *stream in self.streams) {
            [stream close];
            [stream removeFromRunLoop:self.runLoop forMode:self.runLoopMode];
            [stream setDelegate:nil];
        }
        [self.streams removeAllObjects];
    }
}

- (void)stream:(NSStream*)sender handleEvent:(NSStreamEvent)eventCode {
    NSInputStream *stream = (NSInputStream *)sender;
    
    if (eventCode & NSStreamEventOpenCompleted) {
        DDLogVerbose(@"[MQTTDecoder] NSStreamEventOpenCompleted");
    }
    
    if (eventCode & NSStreamEventHasBytesAvailable) {
        DDLogVerbose(@"[MQTTDecoder] NSStreamEventHasBytesAvailable");
        
        if (self.state == MQTTDecoderStateDecodingHeader) {
            UInt8 buffer;
            NSInteger n = [stream read:&buffer maxLength:1];
            if (n == -1) {
                self.state = MQTTDecoderStateConnectionError;
                [self.delegate decoder:self handleEvent:MQTTDecoderEventConnectionError error:stream.streamError];
            } else if (n == 1) {
                self.length = 0;
                self.lengthMultiplier = 1;
                self.state = MQTTDecoderStateDecodingLength;
                self.dataBuffer = [[NSMutableData alloc] init];
                [self.dataBuffer appendBytes:&buffer length:1];
                self.offset = 1;
                DDLogVerbose(@"[MQTTDecoder] fixedHeader=0x%02x", buffer);
            }
        }
        while (self.state == MQTTDecoderStateDecodingLength) {
            // TODO: check max packet length(prevent evil server response)
            UInt8 digit;
            NSInteger n = [stream read:&digit maxLength:1];
            if (n == -1) {
                self.state = MQTTDecoderStateConnectionError;
                [self.delegate decoder:self handleEvent:MQTTDecoderEventConnectionError error:stream.streamError];
                break;
            } else if (n == 0) {
                break;
            }
            DDLogVerbose(@"[MQTTDecoder] digit=0x%02x 0x%02x %d %d", digit, digit & 0x7f, (unsigned int)self.length, (unsigned int)self.lengthMultiplier);
            [self.dataBuffer appendBytes:&digit length:1];
            self.offset++;
            self.length += ((digit & 0x7f) * self.lengthMultiplier);
            if ((digit & 0x80) == 0x00) {
                self.state = MQTTDecoderStateDecodingData;
            } else {
                self.lengthMultiplier *= 128;
            }
        }
        DDLogVerbose(@"[MQTTDecoder] remainingLength=%d", (unsigned int)self.length);

        if (self.state == MQTTDecoderStateDecodingData) {
            if (self.length > 0) {
                NSInteger n, toRead;
                UInt8 buffer[768];
                toRead = self.length + self.offset - self.dataBuffer.length;
                if (toRead > sizeof buffer) {
                    toRead = sizeof buffer;
                }
                n = [stream read:buffer maxLength:toRead];
                if (n == -1) {
                    self.state = MQTTDecoderStateConnectionError;
                    [self.delegate decoder:self handleEvent:MQTTDecoderEventConnectionError error:stream.streamError];
                } else {
                    DDLogVerbose(@"[MQTTDecoder] read %ld %ld", (long)toRead, (long)n);
                    [self.dataBuffer appendBytes:buffer length:n];
                }
            }
            if (self.dataBuffer.length == self.length + self.offset) {
                DDLogVerbose(@"[MQTTDecoder] received (%lu)=%@...", (unsigned long)self.dataBuffer.length,
                                    [self.dataBuffer subdataWithRange:NSMakeRange(0, MIN(256, self.dataBuffer.length))]);
                [self.delegate decoder:self didReceiveMessage:self.dataBuffer];
                self.dataBuffer = nil;
                self.state = MQTTDecoderStateDecodingHeader;
            }
        }
    }
    
    if (eventCode & NSStreamEventHasSpaceAvailable) {
        DDLogVerbose(@"[MQTTDecoder] NSStreamEventHasSpaceAvailable");
    }
    
    if (eventCode & NSStreamEventEndEncountered) {
        DDLogVerbose(@"[MQTTDecoder] NSStreamEventEndEncountered");
        
        if (self.streams) {
            [self.streams removeObject:stream];
            if (self.streams.count) {
                NSInputStream *stream = [self.streams objectAtIndex:0];
                [stream scheduleInRunLoop:self.runLoop forMode:self.runLoopMode];
                [stream open];
            }
        }
    }
    
    if (eventCode & NSStreamEventErrorOccurred) {
        DDLogVerbose(@"[MQTTDecoder] NSStreamEventErrorOccurred");
        
        self.state = MQTTDecoderStateConnectionError;
        NSError *error = [stream streamError];
        if (self.streams) {
            [self.streams removeObject:stream];
            if (self.streams.count) {
                NSInputStream *stream = [self.streams objectAtIndex:0];
                [stream scheduleInRunLoop:self.runLoop forMode:self.runLoopMode];
                [stream open];
            }
        }
        [self.delegate decoder:self handleEvent:MQTTDecoderEventConnectionError error:error];
    }
}

@end
