//
// MQTTDecoder.h
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
    MQTTDecoderEventProtocolError,
    MQTTDecoderEventConnectionClosed,
    MQTTDecoderEventConnectionError
} MQTTDecoderEvent;

typedef enum {
    MQTTDecoderStatusInitializing,
    MQTTDecoderStatusDecodingHeader,
    MQTTDecoderStatusDecodingLength,
    MQTTDecoderStatusDecodingData,
    MQTTDecoderStatusConnectionClosed,
    MQTTDecoderStatusConnectionError,
    MQTTDecoderStatusProtocolError
} MQTTDecoderStatus;

@class MQTTDecoder;

@protocol MQTTDecoderDelegate <NSObject>

- (void)decoder:(MQTTDecoder *)sender newMessage:(MQTTMessage*)msg;
- (void)decoder:(MQTTDecoder *)sender handleEvent:(MQTTDecoderEvent)eventCode error:(NSError *)error;

@end


@interface MQTTDecoder : NSObject <NSStreamDelegate>
@property (nonatomic)    MQTTDecoderStatus       status;
@property (strong, nonatomic)    NSInputStream*  stream;
@property (strong, nonatomic)    NSRunLoop*      runLoop;
@property (strong, nonatomic)    NSString*       runLoopMode;
@property (nonatomic)    UInt8           header;
@property (nonatomic)    UInt32          length;
@property (nonatomic)    UInt32          lengthMultiplier;
@property (strong, nonatomic)    NSMutableData*  dataBuffer;

@property (weak, nonatomic ) id<MQTTDecoderDelegate> delegate;

- (id)initWithStream:(NSInputStream *)stream
             runLoop:(NSRunLoop *)runLoop
         runLoopMode:(NSString *)mode;

- (id)initWithStream:(NSInputStream *)stream
             runLoop:(NSRunLoop *)runLoop
         runLoopMode:(NSString *)mode
        securityPolicy:(MQTTSSLSecurityPolicy *)securityPolicy
        securityDomain:(NSString *)securityDomain;

- (void)open;
- (void)close;
- (void)stream:(NSStream *)sender handleEvent:(NSStreamEvent)eventCode;
@end


