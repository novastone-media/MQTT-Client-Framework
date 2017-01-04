//
// MQTTCFSocketDecoder.h
// MQTTClient.framework
// 
// Copyright © 2013-2017, Christoph Krey. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, MQTTCFSocketDecoderState) {
    MQTTCFSocketDecoderStateInitializing,
    MQTTCFSocketDecoderStateReady,
    MQTTCFSocketDecoderStateError
};

@class MQTTCFSocketDecoder;

@protocol MQTTCFSocketDecoderDelegate <NSObject>
- (void)decoder:(MQTTCFSocketDecoder *)sender didReceiveMessage:(NSData *)data;
- (void)decoderDidOpen:(MQTTCFSocketDecoder *)sender;
- (void)decoder:(MQTTCFSocketDecoder *)sender didFailWithError:(NSError *)error;
- (void)decoderdidClose:(MQTTCFSocketDecoder *)sender;

@end

@interface MQTTCFSocketDecoder : NSObject <NSStreamDelegate>
@property (nonatomic) MQTTCFSocketDecoderState state;
@property (strong, nonatomic) NSError *error;
@property (strong, nonatomic) NSInputStream *stream;
@property (strong, nonatomic) NSRunLoop *runLoop;
@property (strong, nonatomic) NSString *runLoopMode;
@property (weak, nonatomic ) id<MQTTCFSocketDecoderDelegate> delegate;

- (void)open;
- (void)close;

@end


