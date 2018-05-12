//
// MQTTDecoder.m
// MQTTClient.framework
//
// Copyright © 2013-2017, Christoph Krey. All rights reserved.
//

#import "MQTTDecoder.h"

#import "MQTTLog.h"

@interface MQTTDecoder() {
    void *QueueIdentityKey;
}

@property (nonatomic) NSMutableArray<NSInputStream *> *streams;

@end

@implementation MQTTDecoder

- (instancetype)init {
    self = [super init];
    self.state = MQTTDecoderStateInitializing;
    self.streams = [NSMutableArray arrayWithCapacity:5];
    self.queue = dispatch_get_main_queue();
    return self;
}

- (void)dealloc {
    [self close];
}

- (void)setQueue:(dispatch_queue_t)queue {
    _queue = queue;
    
    // We're going to use dispatch_queue_set_specific() to "mark" our queue.
    // The dispatch_queue_set_specific() and dispatch_get_specific() functions take a "void *key" parameter.
    // Later we can use dispatch_get_specific() to determine if we're executing on our queue.
    // From the documentation:
    //
    // > Keys are only compared as pointers and are never dereferenced.
    // > Thus, you can use a pointer to a static variable for a specific subsystem or
    // > any other value that allows you to identify the value uniquely.
    //
    // So we're just going to use the memory address of an ivar.
    
    dispatch_queue_set_specific(_queue, &QueueIdentityKey, (__bridge void *)_queue, NULL);
}

- (void)decodeMessage:(NSData *)data {
    NSInputStream *stream = [NSInputStream inputStreamWithData:data];
    CFReadStreamRef readStream = (__bridge CFReadStreamRef)stream;
    CFReadStreamSetDispatchQueue(readStream, self.queue);
    [self openStream:stream];
}

- (void)openStream:(NSInputStream *)stream {
    [self.streams addObject:stream];
    stream.delegate = self;
    DDLogVerbose(@"[MQTTDecoder] #streams=%lu", (unsigned long)self.streams.count);
    if (self.streams.count == 1) {
        [stream open];
    }
}

- (void)open {
    self.state = MQTTDecoderStateDecodingHeader;
}

- (void)internalClose {
    if (self.streams) {
        for (NSInputStream *stream in self.streams) {
            [stream close];
            [stream setDelegate:nil];
        }
        [self.streams removeAllObjects];
    }
}

- (void)close {
    // https://github.com/novastone-media/MQTT-Client-Framework/issues/325
    // We need to make sure that we are closing streams on their queue
    // Otherwise, we end up with race condition where delegate is deallocated
    // but still used by run loop event
    if (self.queue != dispatch_get_specific(&QueueIdentityKey)) {
        dispatch_sync(self.queue, ^{
            [self internalClose];
        });
    } else {
        [self internalClose];
    }
}

- (void)stream:(NSStream *)sender handleEvent:(NSStreamEvent)eventCode {
    // We contact our delegate, MQTTSession at some point in this method
    // This call can cause MQTTSession to dealloc and thus, MQTTDecoder to dealloc
    // So we end up with invalid object in the middle of the method
    // To prevent this we retain self for duration of this method call
    MQTTDecoder *strongDecoder = self;
    (void)strongDecoder;
    
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
            } else {
                DDLogWarn(@"[MQTTDecoder] oops received (%lu)=%@...", (unsigned long)self.dataBuffer.length,
                             [self.dataBuffer subdataWithRange:NSMakeRange(0, MIN(256, self.dataBuffer.length))]);
            }
        }
    }
    
    if (eventCode & NSStreamEventHasSpaceAvailable) {
        DDLogVerbose(@"[MQTTDecoder] NSStreamEventHasSpaceAvailable");
    }
    
    if (eventCode & NSStreamEventEndEncountered) {
        DDLogVerbose(@"[MQTTDecoder] NSStreamEventEndEncountered");
        
        if (self.streams) {
            [stream setDelegate:nil];
            [stream close];
            [self.streams removeObject:stream];
            if (self.streams.count) {
                NSInputStream *stream = (self.streams)[0];
                [stream open];
            }
        }
    }
    
    if (eventCode & NSStreamEventErrorOccurred) {
        DDLogVerbose(@"[MQTTDecoder] NSStreamEventErrorOccurred");
        
        self.state = MQTTDecoderStateConnectionError;
        NSError *error = stream.streamError;
        if (self.streams) {
            [self.streams removeObject:stream];
            if (self.streams.count) {
                NSInputStream *stream = (self.streams)[0];
                [stream open];
            }
        }
        [self.delegate decoder:self handleEvent:MQTTDecoderEventConnectionError error:error];
    }
}

@end
