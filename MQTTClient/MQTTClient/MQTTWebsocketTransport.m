//
//  MQTTWebsocketTransport.m
//  MQTTClient
//
//  Created by Christoph Krey on 06.12.15.
//  Copyright © 2015 Christoph Krey. All rights reserved.
//

#import "MQTTWebsocketTransport.h"

@interface MQTTWebsocketTransport()
@property (strong, nonatomic) SRWebSocket *websocket;
@end

@implementation MQTTWebsocketTransport
@synthesize state;
@synthesize delegate;

- (instancetype)init {
    self = [super init];
    self.state = MQTTTransportCreated;
    self.host = @"localhost";
    self.port = 1883;
    self.tls = false;
    return self;
}

- (void)open {
    NSLog(@"[MQTTWebsocketTransport] open");
    self.state = MQTTTransportOpening;

    NSString *protocol = (self.tls) ? @"wss" : @"ws";
    NSString *portString = (self.port == 0) ? @"" : [NSString stringWithFormat:@":%d",(unsigned int)self.port];
    NSString *path = @"/mqtt";
    NSArray <NSString *> *protocols = @[@"mqtt"];
    NSString *urlString = [NSString stringWithFormat:@"%@://%@%@%@",
                           protocol,
                           self.host,
                           portString,
                           path];
    NSURL *url = [NSURL URLWithString:urlString];
    
    self.websocket = [[SRWebSocket alloc] initWithURL:url protocols:protocols];
    self.websocket.delegate = self;
    [self.websocket open];
}

- (BOOL)send:(NSData *)data {
    NSLog(@"[MQTTWebsocketTransport] send(%ld):%@", data.length, data);
    [self.websocket send:data];
    return true;
}

- (void)close {
    NSLog(@"[MQTTWebsocketTransport] close");
    self.state = MQTTTransportClosing;
    [self.websocket close];
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
    NSLog(@"[MQTTWebsocketTransport] didReceiveMessage():%@", message);

    if (self.delegate) {
        if ([self.delegate respondsToSelector:@selector(mqttTransport:didReceiveMessage:)]) {
            [self.delegate mqttTransport:self didReceiveMessage:message];
        }
    }
}

- (void)webSocketDidOpen:(SRWebSocket *)webSocket{
    NSLog(@"[MQTTWebsocketTransport] connected to websocket");
    self.state = MQTTTransportOpen;
    if (self.delegate) {
        if ([self.delegate respondsToSelector:@selector(mqttTransportDidOpen:)]) {
            [self.delegate mqttTransportDidOpen:self];
        }
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error{
    NSLog(@"[MQTTWebsocketTransport] Failed to connect : %@",[error debugDescription]);
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
    NSLog(@"[MQTTWebsocketTransport] ConnectionClosed : %@",reason);
    self.state = MQTTTransportClosed;
    self.websocket.delegate = nil;
    if (self.delegate) {
        if ([self.delegate respondsToSelector:@selector(mqttTransportDidClose:)]) {
            [self.delegate mqttTransportDidClose:self];
        }
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didReceivePong:(NSData *)pongPayload{
    NSLog(@"[MQTTWebsocketTransport] webSocket didReceivePong:%@", pongPayload);
}

@end
