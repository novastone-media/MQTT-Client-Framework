//
// MQTTCFSocketEncoder.h
// MQTTClient.framework
//
// Copyright © 2013-2017, Christoph Krey. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, MQTTCFSocketEncoderState) {
    MQTTCFSocketEncoderStateInitializing,
    MQTTCFSocketEncoderStateReady,
    MQTTCFSocketEncoderStateError
};

@class MQTTCFSocketEncoder;

@protocol MQTTCFSocketEncoderDelegate <NSObject>
- (void)encoderDidOpen:(MQTTCFSocketEncoder *)sender;
- (void)encoder:(MQTTCFSocketEncoder *)sender didFailWithError:(NSError *)error;
- (void)encoderdidClose:(MQTTCFSocketEncoder *)sender;

@end

@interface MQTTCFSocketEncoder : NSObject <NSStreamDelegate>
@property (nonatomic) MQTTCFSocketEncoderState state;
@property (strong, nonatomic) NSError *error;
@property (strong, nonatomic) NSOutputStream *stream;
@property (strong, nonatomic) NSRunLoop *runLoop;
@property (strong, nonatomic) NSString *runLoopMode;
@property (weak, nonatomic ) id<MQTTCFSocketEncoderDelegate> delegate;

- (void)open;
- (void)close;
- (BOOL)send:(NSData *)data;

@end

