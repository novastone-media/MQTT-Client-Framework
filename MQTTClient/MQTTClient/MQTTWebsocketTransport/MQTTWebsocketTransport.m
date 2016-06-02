//
//  MQTTWebsocketTransport.m
//  MQTTClient
//
//  Created by Christoph Krey on 06.12.15.
//  Copyright © 2015-2016 Christoph Krey. All rights reserved.
//

#import "MQTTWebsocketTransport.h"

#import "../MQTTLog.h"

@interface MQTTWebsocketTransport()
@property (strong, nonatomic) SRWebSocket *websocket;
@end

@implementation MQTTWebsocketTransport
@synthesize state;
@synthesize delegate;
@synthesize runLoop;
@synthesize runLoopMode;

- (instancetype)init {
    self = [super init];
    self.host = @"localhost";
    self.port = 80;
    self.path = @"/mqtt";
    self.tls = false;
    self.allowUntrustedCertificates = false;
    self.pinnedCertificates = nil;
    return self;
}

- (void)open {
    DDLogVerbose(@"[MQTTWebsocketTransport] open");
    self.state = MQTTTransportOpening;
    
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[self endpointURL]];
    urlRequest.SR_SSLPinnedCertificates = self.pinnedCertificates;
    NSArray <NSString *> *protocols = @[@"mqtt"];
    
    self.websocket = [[SRWebSocket alloc] initWithURLRequest:urlRequest
                                                   protocols:protocols
                              allowsUntrustedSSLCertificates:self.allowUntrustedCertificates];
    
    self.websocket.delegate = self;
    [self.websocket open];
}

- (NSURL*) endpointURL {
    NSString *protocol = (self.tls) ? @"wss" : @"ws";
    NSString *portString = (self.port == 0) ? @"" : [NSString stringWithFormat:@":%d",(unsigned int)self.port];
    NSString *path = self.path;
    NSString *urlString = [NSString stringWithFormat:@"%@://%@%@%@",
                           protocol,
                           self.host,
                           portString,
                           path];
    NSURL *url = [NSURL URLWithString:urlString];
    return url;
}

- (BOOL)send:(nonnull NSData *)data {
    DDLogVerbose(@"[MQTTWebsocketTransport] send(%ld):%@", (unsigned long)data.length,
                 [data subdataWithRange:NSMakeRange(0, MIN(256, data.length))]);
    if (self.websocket.readyState == SR_OPEN) {
        [self.websocket send:data];
        return true;
    } else {
        return false;
    }
}

- (void)close {
    DDLogVerbose(@"[MQTTWebsocketTransport] close");
    self.state = MQTTTransportClosing;
    [self.websocket close];
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
    NSData *data;
    if ([message isKindOfClass:[NSData class]]) {
        data = (NSData *)message;
    }
    DDLogVerbose(@"[MQTTWebsocketTransport] didReceiveMessage(%ld)", (unsigned long)(data ? data.length : -1));

    if (self.delegate) {
        if ([self.delegate respondsToSelector:@selector(mqttTransport:didReceiveMessage:)]) {
            [self.delegate mqttTransport:self didReceiveMessage:message];
        }
    }
}

- (void)webSocketDidOpen:(SRWebSocket *)webSocket{
    DDLogVerbose(@"[MQTTWebsocketTransport] connected to websocket");
    self.state = MQTTTransportOpen;
    if (self.delegate) {
        if ([self.delegate respondsToSelector:@selector(mqttTransportDidOpen:)]) {
            [self.delegate mqttTransportDidOpen:self];
        }
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error{
    DDLogInfo(@"[MQTTWebsocketTransport] Failed to connect : %@",[error debugDescription]);
    self.state = MQTTTransportClosed;
    self.websocket.delegate = nil;
    [self.websocket close];
    if (self.delegate) {
        if ([self.delegate respondsToSelector:@selector(mqttTransport:didFailWithError:)]) {
            [self.delegate mqttTransport:self didFailWithError:error];
        }
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean{
    DDLogVerbose(@"[MQTTWebsocketTransport] ConnectionClosed : %@",reason);
    self.state = MQTTTransportClosed;
    self.websocket.delegate = nil;
    if (self.delegate) {
        if ([self.delegate respondsToSelector:@selector(mqttTransportDidClose:)]) {
            [self.delegate mqttTransportDidClose:self];
        }
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didReceivePong:(NSData *)pongPayload{
    DDLogVerbose(@"[MQTTWebsocketTransport] webSocket didReceivePong:%@", pongPayload);
}

@end
