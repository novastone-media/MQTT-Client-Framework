//
//  MQTTTransport.h
//  MQTTClient
//
//  Created by Christoph Krey on 06.12.15.
//  Copyright © 2015 Christoph Krey. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MQTTTransportDelegate;

@protocol MQTTTransport <NSObject>

typedef NS_ENUM(NSInteger, MQTTTransportState) {
    MQTTTransportCreated = 0,
    MQTTTransportOpening,
    MQTTTransportOpen,
    MQTTTransportClosing,
    MQTTTransportClosed
};

@property (strong, nonatomic) id<MQTTTransportDelegate> delegate;
@property (nonatomic) MQTTTransportState state;
- (void)open;
- (BOOL)send:(NSData *)data;
- (void)close;

@end

@protocol MQTTTransportDelegate <NSObject>
- (void)mqttTransport:(id<MQTTTransport>)mqttTransport didReceiveMessage:(NSData *)message;

@optional
- (void)mqttTransportDidOpen:(id<MQTTTransport>)mqttTransport;
- (void)mqttTransport:(id<MQTTTransport>)mqttTransport didFailWithError:(NSError *)error;
- (void)mqttTransportDidClose:(id<MQTTTransport>)mqttTransport;

@end
