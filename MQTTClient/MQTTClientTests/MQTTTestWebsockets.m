//
//  MQTTTestWebsockets.m
//  MQTTClient
//
//  Created by Christoph Krey on 05.12.15.
//  Copyright © 2015-2017 Christoph Krey. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "MQTTLog.h"
#import "MQTTTestHelpers.h"
#import <SocketRocket/SRWebSocket.h>
#import "MQTTWebsocketTransport.h"

@interface MQTTTestWebsockets : MQTTTestHelpers <SRWebSocketDelegate>
@property (strong, nonatomic) SRWebSocket *websocket;
@property (nonatomic) BOOL next;
@property (nonatomic) BOOL abort;
@end

@implementation MQTTTestWebsockets

- (void)testWSTRANSPORT {
    for (NSString *broker in self.brokers.allKeys) {
        DDLogVerbose(@"testing broker %@", broker);
        NSDictionary *parameters = self.brokers[broker];
        if ([parameters[@"websocket"] boolValue]) {
            
            MQTTWebsocketTransport *wsTransport = [[MQTTWebsocketTransport alloc] init];
            wsTransport.host = parameters[@"host"];
            wsTransport.port = [parameters[@"port"] intValue];
            wsTransport.tls = [parameters[@"tls"] boolValue];
            
            self.session = [[MQTTSession alloc] init];
            self.session.transport = wsTransport;
            
            self.session.delegate = self;
            
            self.event = -1;
            self.timedout = FALSE;
            [self performSelector:@selector(timedout:)
                       withObject:nil
                       afterDelay:[parameters[@"timeout"] intValue]];
            
            [self.session connectWithConnectHandler:nil];
            
            while (!self.timedout && self.event == -1) {
                DDLogVerbose(@"waiting for connection");
                [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
            }
            [NSObject cancelPreviousPerformRequestsWithTarget:self];
            
            
            XCTAssert(!self.timedout, @"timeout");
            XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
            
            
            self.event = -1;
            self.timedout = FALSE;
            [self performSelector:@selector(timedout:)
                       withObject:nil
                       afterDelay:[parameters[@"timeout"] intValue]];
            
            [self.session closeWithReturnCode:0
                        sessionExpiryInterval:nil
                                 reasonString:nil
                               userProperties:nil
                            disconnectHandler:nil];
            
            while (!self.timedout && self.event == -1) {
                DDLogVerbose(@"waiting for disconnect");
                [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
            }
            [NSObject cancelPreviousPerformRequestsWithTarget:self];
            
            XCTAssert(!self.timedout, @"timeout");
            XCTAssertEqual(self.event, MQTTSessionEventConnectionClosedByBroker, @"Not ClosedByBroker %ld %@", (long)self.event, self.error);
        }
    }
    
}

- (void)testWSConnect {
    for (NSString *broker in self.brokers.allKeys) {
        DDLogVerbose(@"testing broker %@", broker);
        NSDictionary *parameters = self.brokers[broker];
        if ([parameters[@"websocket"] boolValue]) {
            
            if (!parameters[@"serverCER"] && !parameters[@"clientp12"]) {
                
                MQTTWebsocketTransport *wsTransport = [[MQTTWebsocketTransport alloc] init];
                wsTransport.host = parameters[@"host"];
                wsTransport.port = [parameters[@"port"] intValue];
                wsTransport.tls = [parameters[@"tls"] boolValue];
                
                self.session = [[MQTTSession alloc] init];
                self.session.transport = wsTransport;
                [self connect:self.session parameters:parameters];
                [self shutdown:parameters];
            }
        }
    }
    
}

- (void)testWSSubscribe {
    for (NSString *broker in self.brokers.allKeys) {
        DDLogVerbose(@"testing broker %@", broker);
        NSDictionary *parameters = self.brokers[broker];
        if ([parameters[@"websocket"] boolValue]) {
            
            if (!parameters[@"serverCER"] && !parameters[@"clientp12"]) {
                
                MQTTWebsocketTransport *wsTransport = [[MQTTWebsocketTransport alloc] init];
                wsTransport.host = parameters[@"host"];
                wsTransport.port = [parameters[@"port"] intValue];
                wsTransport.tls = [parameters[@"tls"] boolValue];
                
                self.session = [[MQTTSession alloc] init];
                self.session.transport = wsTransport;
                self.session.userName = parameters[@"user"];
                self.session.password = parameters[@"pass"];
                [self connect:self.session parameters:parameters];
                XCTAssert(!self.timedout, @"timeout");
                XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
                
                self.timedout = FALSE;
                [self performSelector:@selector(timedout:)
                           withObject:nil
                           afterDelay:[parameters[@"timeout"] intValue]];

                [self.session subscribeToTopicV5:@"$SYS/#"
                                         atLevel:MQTTQosLevelAtLeastOnce
                                         noLocal:false
                               retainAsPublished:false
                                  retainHandling:MQTTSendRetained
                          subscriptionIdentifier:0
                                  userProperties:nil
                                subscribeHandler:nil];

                [self.session subscribeToTopicV5:@"#"
                                         atLevel:MQTTQosLevelAtLeastOnce
                                         noLocal:false
                               retainAsPublished:false
                                  retainHandling:MQTTSendRetained
                          subscriptionIdentifier:0
                                  userProperties:nil
                                subscribeHandler:nil];

                while (!self.timedout) {
                    DDLogVerbose(@"looping for messages");
                    [self.session publishDataV5:[[NSDate date].description dataUsingEncoding:NSUTF8StringEncoding]
                                        onTopic:@"MQTTClient"
                                         retain:false
                                            qos:MQTTQosLevelAtLeastOnce
                         payloadFormatIndicator:nil
                      messageExpiryInterval:nil
                                     topicAlias:nil
                                  responseTopic:nil
                                correlationData:nil
                                 userProperties:nil
                                    contentType:nil
                                 publishHandler:nil];

                    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
                }
                
                [NSObject cancelPreviousPerformRequestsWithTarget:self];
                XCTAssert(self.timedout, @"timeout");
                
                
                [self shutdown:parameters];
            }
        }
    }
}


- (void)testWSSubscribeLong {
    for (NSString *broker in self.brokers.allKeys) {
        DDLogVerbose(@"testing broker %@", broker);
        NSDictionary *parameters = self.brokers[broker];
        if ([parameters[@"websocket"] boolValue]) {
            
            if (!parameters[@"serverCER"] && !parameters[@"clientp12"]) {
                
                MQTTWebsocketTransport *wsTransport = [[MQTTWebsocketTransport alloc] init];
                wsTransport.host = parameters[@"host"];
                wsTransport.port = [parameters[@"port"] intValue];
                wsTransport.tls = [parameters[@"tls"] boolValue];
                
                self.session = [[MQTTSession alloc] init];
                self.session.transport = wsTransport;
                self.session.userName = parameters[@"user"];
                self.session.password = parameters[@"pass"];
                [self connect:self.session parameters:parameters];
                XCTAssert(!self.timedout, @"timeout");
                XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
                
                self.timedout = FALSE;
                [self performSelector:@selector(timedout:)
                           withObject:nil
                           afterDelay:[parameters[@"timeout"] intValue]];

                [self.session subscribeToTopicV5:@"MQTTClient"
                                         atLevel:MQTTQosLevelAtLeastOnce
                                         noLocal:false
                               retainAsPublished:false
                                  retainHandling:MQTTSendRetained
                          subscriptionIdentifier:0
                                  userProperties:nil
                                subscribeHandler:nil];

                NSString *payload = @"abcdefgh";
                
                while (!self.timedout && strlen([payload substringFromIndex:1].UTF8String) <= 1000) {
                    DDLogVerbose(@"looping for messages");
                    [self.session publishDataV5:[payload dataUsingEncoding:NSUTF8StringEncoding]
                                        onTopic:@"MQTTClient"
                                         retain:false
                                            qos:MQTTQosLevelAtLeastOnce
                         payloadFormatIndicator:nil
                      messageExpiryInterval:nil
                                     topicAlias:nil
                                  responseTopic:nil
                                correlationData:nil
                                 userProperties:nil
                                    contentType:nil
                                 publishHandler:nil];

                    payload = [payload stringByAppendingString:payload];
                    payload = [payload stringByAppendingString:payload];
                    
                    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
                }
                
                [NSObject cancelPreviousPerformRequestsWithTarget:self];
                XCTAssert(self.timedout, @"timeout");
                
                [self shutdown:parameters];
            }
        }
    }
}


- (void)webSocket:(SRWebSocket *)webSocket
didReceiveMessage:(id)message {
    NSData *data = (NSData *)message;
    DDLogVerbose(@"webSocket didReceiveMessage %ld", (unsigned long)data.length);
    self.next = true;
}

- (void)webSocketDidOpen:(SRWebSocket *)webSocket{
    DDLogVerbose(@"webSocketDidOpen");
}

- (void)webSocket:(SRWebSocket *)webSocket
 didFailWithError:(NSError *)error{
    DDLogVerbose(@"webSocket didFailWithError: %@", [error debugDescription]);
    self.abort = true;
}

- (void)webSocket:(SRWebSocket *)webSocket
 didCloseWithCode:(NSInteger)code
           reason:(NSString *)reason
         wasClean:(BOOL)wasClean {
    DDLogVerbose(@"webSocket didCloseWithCode: %ld %@ %d",
          (long)code, reason, wasClean);
    self.next = true;
}

- (void)webSocket:(SRWebSocket *)webSocket
   didReceivePong:(NSData *)pongPayload {
    DDLogVerbose(@"webSocket didReceivePong: %@",
                 pongPayload);
}

- (void)connect:(MQTTSession *)session parameters:(NSDictionary *)parameters{
    self.session.delegate = self;
    self.session.userName = parameters[@"user"];
    self.session.password = parameters[@"pass"];
    
    self.event = -1;
    self.timedout = FALSE;
    [self performSelector:@selector(timedout:)
               withObject:nil
               afterDelay:[parameters[@"timeout"] intValue]];
    
    [self.session connectWithConnectHandler:nil];
    
    while (!self.timedout && self.event == -1) {
        DDLogVerbose(@"waiting for connection");
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    XCTAssert(!self.timedout, @"timeout");
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
}

- (void)shutdown:(NSDictionary *)parameters {
    self.event = -1;
    self.timedout = FALSE;
    [self performSelector:@selector(timedout:)
               withObject:nil
               afterDelay:[parameters[@"timeout"] intValue]];
    
    [self.session closeWithReturnCode:0
                sessionExpiryInterval:nil
                         reasonString:nil
                       userProperties:nil
                    disconnectHandler:nil];
    
    while (!self.timedout && self.event == -1) {
        DDLogVerbose(@"waiting for disconnect");
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    XCTAssert(!self.timedout, @"timeout");
    XCTAssertEqual(self.event, MQTTSessionEventConnectionClosedByBroker, @"Not ClosedByBroker %ld %@", (long)self.event, self.error);
    
    self.session.delegate = nil;
    self.session = nil;
}



@end
