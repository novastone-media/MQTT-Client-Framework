//
// MQTTCFSocketEncoder.h
// MQTTClient.framework
//
// Copyright (c) 2013-2015, Christoph Krey
//

#import <Foundation/Foundation.h>
#import "MQTTSSLSecurityPolicy.h"

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
@property (nonatomic, readonly) MQTTCFSocketEncoderState state;
@property (nonatomic, readonly) NSError *error;
@property (strong, nonatomic) NSOutputStream *stream;
@property (strong, nonatomic) NSRunLoop *runLoop;
@property (strong, nonatomic) NSString *runLoopMode;
@property(strong, nonatomic) MQTTSSLSecurityPolicy *securityPolicy;
@property(strong, nonatomic) NSString *securityDomain;
@property (weak, nonatomic ) id<MQTTCFSocketEncoderDelegate> delegate;

- (void)open;
- (void)close;
- (BOOL)send:(NSData *)data;

@end

