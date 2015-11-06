//
// MQTTEncoder.h
// MQTTClient.framework
//
// Copyright (c) 2013-2015, Christoph Krey
//
// based on
//
// Copyright (c) 2011, 2013, 2lemetry LLC
//
// All rights reserved. This program and the accompanying materials
// are made available under the terms of the Eclipse Public License v1.0
// which accompanies this distribution, and is available at
// http://www.eclipse.org/legal/epl-v10.html
//
// Contributors:
//    Kyle Roche - initial API and implementation and/or initial documentation
//

#import <Foundation/Foundation.h>
#import "MQTTMessage.h"
#import "MQTTSSLSecurityPolicy.h"

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

@protocol MQTTEncoderDelegate <NSObject>
- (void)encoder:(MQTTEncoder*)sender handleEvent:(MQTTEncoderEvent)eventCode error:(NSError *)error;
- (void)encoder:(MQTTEncoder*)sender sending:(int)type qos:(int)qos retained:(BOOL)retained duped:(BOOL)duped mid:(UInt16)mid data:(NSData *)data;
@end


@interface MQTTEncoder : NSObject <NSStreamDelegate>
@property (nonatomic)    MQTTEncoderStatus       status;
@property (strong, nonatomic)    NSOutputStream* stream;
@property (strong, nonatomic)    NSRunLoop*      runLoop;
@property (strong, nonatomic)    NSString*       runLoopMode;
@property (strong, nonatomic)    NSMutableData*  buffer;
@property (nonatomic)    NSInteger       byteIndex;
@property (weak, nonatomic)    id<MQTTEncoderDelegate>              delegate;

- (id)initWithStream:(NSOutputStream *)stream
             runLoop:(NSRunLoop *)runLoop
         runLoopMode:(NSString *)mode;

- (id)initWithStream:(NSOutputStream *)stream
             runLoop:(NSRunLoop *)runLoop
         runLoopMode:(NSString *)mode
      securityPolicy:(MQTTSSLSecurityPolicy *)securityPolicy
      securityDomain:(NSString *)securityDomain;

- (void)open;
- (void)close;
- (MQTTEncoderStatus)status;
- (void)stream:(NSStream*)sender handleEvent:(NSStreamEvent)eventCode;
- (BOOL)encodeMessage:(MQTTMessage*)msg;

@end

