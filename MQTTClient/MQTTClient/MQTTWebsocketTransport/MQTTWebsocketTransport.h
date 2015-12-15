//
//  MQTTWebsocketTransport.h
//  MQTTClient
//
//  Created by Christoph Krey on 06.12.15.
//  Copyright © 2015 Christoph Krey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MQTTTransport.h"
#import <SocketRocket/SRWebSocket.h>

@interface MQTTWebsocketTransport : NSObject <MQTTTransport, SRWebSocketDelegate>
@property (strong, nonatomic) NSString *host;
@property (nonatomic) UInt16 port;
@property (nonatomic) BOOL tls;
@property (nonatomic) BOOL allowUntrustedCertificates;
@property (strong, nonatomic) NSArray *pinnedCertificates;

@end
