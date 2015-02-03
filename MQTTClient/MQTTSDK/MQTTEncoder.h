//
// MQTTEncoder.h
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

#import <Foundation/Foundation.h>
#import "MQTTMessage.h"

typedef enum {
    MQTTEncoderEventReady,
    MQTTEncoderEventErrorOccurred
} MQTTEncoderEvent;

typedef enum {
    MQTTEncoderStatusInitializing,
    MQTTEncoderStatusReady,
    MQTTEncoderStatusSending,
    MQTTEncoderStatusEndEncountered,
    MQTTEncoderStatusError
} MQTTEncoderStatus;


@class MQTTEncoder;

@protocol MQTTEncoderDelegate

- (void)encoder:(MQTTEncoder*)sender handleEvent:(MQTTEncoderEvent)eventCode;

@end

@interface MQTTEncoder : NSObject <NSStreamDelegate> 

@property (weak) id<MQTTEncoderDelegate> delegate;
@property (assign) MQTTEncoderStatus status;

- (id)initWithStream:(NSOutputStream*)aStream
             runLoop:(NSRunLoop*)aRunLoop
         runLoopMode:(NSString*)aMode;

- (void)encodeMessage:(MQTTMessage*)msg;
- (void)open;
- (void)close;

@end


