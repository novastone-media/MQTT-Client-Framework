//
// MQTTEncoder.m
// MQtt Client
// 
// Copyright (c) 2011, 2013, 2lemetry LLC
// 
// All rights reserved. This program and the accompanying materials
// are made available under the terms of the Eclipse Public License v1.0
// and Eclipse Distribution License v. 1.0 which accompanies this distribution.
// The Eclipse Public License is available at http://www.eclipse.org/legal/epl-v10.html
// and the Eclipse Distribution License is available at
// http://www.eclipse.org/org/documents/edl-v10.php.
// 
// Contributors:
//    Kyle Roche - initial API and implementation and/or initial documentation
// 

#import "MQTTEncoder.h"

@interface MQTTEncoder () {
    NSOutputStream* stream;
    NSRunLoop*      runLoop;
    NSString*       runLoopMode;
    NSMutableData*  buffer;
    NSInteger       byteIndex;
}

@end

@implementation MQTTEncoder

- (id)initWithStream:(NSOutputStream*)aStream
             runLoop:(NSRunLoop*)aRunLoop
         runLoopMode:(NSString*)aMode {
    _status = MQTTEncoderStatusInitializing;
    stream = aStream;
    [stream setDelegate:self];
    runLoop = aRunLoop;
    runLoopMode = aMode;
    return self;
}

- (void)open {
    [stream setDelegate:self];
    [stream scheduleInRunLoop:runLoop forMode:runLoopMode];
    [stream open];
}

- (void)close {
    [stream close];
    [stream setDelegate:nil];
    [stream removeFromRunLoop:runLoop forMode:runLoopMode];
    stream = nil;
}

- (void)stream:(NSStream*)sender handleEvent:(NSStreamEvent)eventCode {
    if(stream == nil)
        return;
    assert(sender == stream);
    switch (eventCode) {
        case NSStreamEventOpenCompleted:
            break;
        case NSStreamEventHasSpaceAvailable:
            if (_status == MQTTEncoderStatusInitializing) {
                _status = MQTTEncoderStatusReady;
                [_delegate encoder:self handleEvent:MQTTEncoderEventReady];
            }
            else if (_status == MQTTEncoderStatusReady) {
                [_delegate encoder:self handleEvent:MQTTEncoderEventReady];
            }
            else if (_status == MQTTEncoderStatusSending) {
                UInt8* ptr;
                NSInteger n, length;
                
                ptr = (UInt8*) [buffer bytes] + byteIndex;
                // Number of bytes pending for transfer
                length = [buffer length] - byteIndex;
                n = [stream write:ptr maxLength:length];
                if (n == -1) {
                    _status = MQTTEncoderStatusError;
                    [_delegate encoder:self handleEvent:MQTTEncoderEventErrorOccurred];
                }
                else if (n < length) {
                    byteIndex += n;
                }
                else {
                    buffer = NULL;
                    byteIndex = 0;
                    _status = MQTTEncoderStatusReady;
                }
            }
            break;
        case NSStreamEventErrorOccurred:
        case NSStreamEventEndEncountered:
            if (_status != MQTTEncoderStatusError) {
                _status = MQTTEncoderStatusError;
                [_delegate encoder:self handleEvent:MQTTEncoderEventErrorOccurred];
            }
            break;
        default:
            NSLog(@"Oops, event code not handled: 0x%02lx", eventCode);
            break;
    }
}

- (void)encodeMessage:(MQTTMessage*)msg {
    UInt8 header;
    NSInteger n, length;
    
    if (_status != MQTTEncoderStatusReady) {
        NSLog(@"Encoder not ready");
        return;
    }
    
    assert (buffer == NULL);
    assert (byteIndex == 0);
    
    buffer = [[NSMutableData alloc] init];
    
    // encode fixed header
    header = [msg type] << 4;
    if ([msg isDuplicate]) {
        header |= 0x08;
    }
    header |= [msg qos] << 1;
    if ([msg retainFlag]) {
        header |= 0x01;
    }
    [buffer appendBytes:&header length:1];
    
    // encode remaining length
    length = [[msg data] length];
    do {
        UInt8 digit = length % 128;
        length /= 128;
        if (length > 0) {
            digit |= 0x80;
        }
        [buffer appendBytes:&digit length:1];
    }
    while (length > 0);
    
    // encode message data
    if ([msg data] != NULL) {
        [buffer appendData:[msg data]];
    }
    
    n = [stream write:[buffer bytes] maxLength:[buffer length]];
    if (n == -1) {
        _status = MQTTEncoderStatusError;
        [_delegate encoder:self handleEvent:MQTTEncoderEventErrorOccurred];
    }
    else if (n < [buffer length]) {
        byteIndex += n;
        _status = MQTTEncoderStatusSending;
    }
    else {
        buffer = NULL;
        // XXX [delegate encoder:self handleEvent:MQTTEncoderEventReady];
    }
}

@end
