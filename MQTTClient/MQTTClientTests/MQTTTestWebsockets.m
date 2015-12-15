//
//  MQTTTestWebsockets.m
//  MQTTClient
//
//  Created by Christoph Krey on 05.12.15.
//  Copyright © 2015 Christoph Krey. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <CocoaLumberjack/Cocoalumberjack.h>

#import "MQTTClient.h"
#import "MQTTTestHelpers.h"
#import <SocketRocket/SRWebSocket.h>
#import "MQTTWebsocketTransport.h"

@interface MQTTTestWebsockets : XCTestCase <SRWebSocketDelegate, MQTTSessionDelegate>
@property (strong, nonatomic) SRWebSocket *websocket;
@property (strong, nonatomic) MQTTSession *session;
@property (strong, nonatomic) NSError *error;
@property (nonatomic) int event;
@property (nonatomic) BOOL timeout;
@property (nonatomic) BOOL next;
@property (nonatomic) BOOL abort;
@end

@implementation MQTTTestWebsockets

- (void)setUp {
    [super setUp];
    
    if (![[DDLog allLoggers] containsObject:[DDTTYLogger sharedInstance]])
        [DDLog addLogger:[DDTTYLogger sharedInstance] withLevel:DDLogLevelAll];
    if (![[DDLog allLoggers] containsObject:[DDASLLogger sharedInstance]])
        [DDLog addLogger:[DDASLLogger sharedInstance] withLevel:DDLogLevelWarning];
    
}

- (void)tearDown {
    [super tearDown];
}

- (void)testWSTRANSPORT {
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        if ([parameters[@"websocket"] boolValue]) {
            
            MQTTWebsocketTransport *wsTransport = [[MQTTWebsocketTransport alloc] init];
            wsTransport.host = parameters[@"host"];
            wsTransport.port = [parameters[@"port"] intValue];
            wsTransport.tls = [parameters[@"tls"] boolValue];
            
            self.session = [[MQTTSession alloc] init];
            self.session.transport = wsTransport;
            
            self.session.delegate = self;
            
            self.event = -1;
            self.timeout = FALSE;
            [self performSelector:@selector(ackTimeout:)
                       withObject:parameters[@"timeout"]
                       afterDelay:[parameters[@"timeout"] intValue]];
            
            [self.session CONNECT];
            
            while (!self.timeout && self.event == -1) {
                NSLog(@"waiting for connection");
                [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
            }
            [NSObject cancelPreviousPerformRequestsWithTarget:self];
            
            
            XCTAssert(!self.timeout, @"timeout");
            XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
            
            
            self.event = -1;
            self.timeout = FALSE;
            [self performSelector:@selector(ackTimeout:)
                       withObject:parameters[@"timeout"]
                       afterDelay:[parameters[@"timeout"] intValue]];
            
            [self.session DISCONNECT];
            
            while (!self.timeout && self.event == -1) {
                NSLog(@"waiting for disconnect");
                [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
            }
            [NSObject cancelPreviousPerformRequestsWithTarget:self];
            
            XCTAssert(!self.timeout, @"timeout");
            XCTAssertEqual(self.event, MQTTSessionEventConnectionClosedByBroker, @"Not ClosedByBroker %ld %@", (long)self.event, self.error);
        }
    }
    
}

- (void)testWSConnect {
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
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
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
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
                XCTAssert(!self.timeout, @"timeout");
                XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
                
                self.timeout = FALSE;
                [self performSelector:@selector(ackTimeout:)
                           withObject:parameters[@"timeout"]
                           afterDelay:[parameters[@"timeout"] intValue]];
                
                [self.session subscribeAndWaitToTopic:@"$SYS/#" atLevel:MQTTQosLevelAtLeastOnce timeout:[parameters[@"timeout"] intValue]];
                [self.session subscribeAndWaitToTopic:@"#" atLevel:MQTTQosLevelAtLeastOnce timeout:[parameters[@"timeout"] intValue]];
                
                while (!self.timeout) {
                    NSLog(@"looping for messages");
                    [self.session publishAndWaitData:[[[NSDate date] description] dataUsingEncoding:NSUTF8StringEncoding]
                                             onTopic:@"MQTTClient"
                                              retain:false
                                                 qos:MQTTQosLevelAtLeastOnce];
                    
                    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
                }
                
                [NSObject cancelPreviousPerformRequestsWithTarget:self];
                XCTAssert(self.timeout, @"timeout");
                
                
                [self shutdown:parameters];
            }
        }
    }
}


- (void)testWSSubscribeLong {
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
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
                XCTAssert(!self.timeout, @"timeout");
                XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
                
                self.timeout = FALSE;
                [self performSelector:@selector(ackTimeout:)
                           withObject:parameters[@"timeout"]
                           afterDelay:[parameters[@"timeout"] intValue]];
                
                [self.session subscribeAndWaitToTopic:@"MQTTClient" atLevel:MQTTQosLevelAtLeastOnce timeout:[parameters[@"timeout"] intValue]];
                
                NSString *payload = @"abcdefgh";
                
                while (!self.timeout && strlen([[payload substringFromIndex:1] UTF8String]) <= 1000000) {
                    NSLog(@"looping for messages");
                    [self.session publishAndWaitData:[payload dataUsingEncoding:NSUTF8StringEncoding]
                                             onTopic:@"MQTTClient"
                                              retain:false
                                                 qos:MQTTQosLevelAtLeastOnce];
                    payload = [payload stringByAppendingString:payload];
                    payload = [payload stringByAppendingString:payload];
                    
                    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
                }
                
                [NSObject cancelPreviousPerformRequestsWithTarget:self];
                XCTAssert(self.timeout, @"timeout");
                
                [self shutdown:parameters];
            }
        }
    }
}


- (void)testWSLowLevel {
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        if ([parameters[@"websocket"] boolValue]) {
            
            BOOL usingSSL = [parameters[@"tls"] boolValue];
            UInt16 port = [parameters[@"port"] intValue];
            NSString *host = parameters[@"host"];
            
            NSString *protocol = (usingSSL) ? @"wss" : @"ws";
            NSString *portString = (port == 0) ? @"" : [NSString stringWithFormat:@":%d", (unsigned int)port];
            NSString *path = @"/mqtt";
            NSString *urlString = [NSString stringWithFormat:@"%@://%@%@%@", protocol, host, portString, path];
            NSURL *url = [NSURL URLWithString:urlString];
            NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
            
            self.websocket = [[SRWebSocket alloc] initWithURLRequest:urlRequest protocols:@[@"mqtt"]];
            self.websocket.delegate = self;
            self.abort = false;
            
            self.timeout = FALSE;
            [self performSelector:@selector(ackTimeout:)
                       withObject:parameters[@"timeout"]
                       afterDelay:[parameters[@"timeout"] intValue]];
            
            [self.websocket open];
            
            while (!self.websocket.readyState == SR_OPEN && !self.abort && !self.timeout) {
                NSLog(@"waiting for open");
                [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
            }
            [NSObject cancelPreviousPerformRequestsWithTarget:self];
            
            XCTAssert(!self.timeout, @"timeout");
            XCTAssertEqual(self.websocket.readyState, SR_OPEN, @"Websocket not open %ld", (long)self.websocket.readyState);
            
            MQTTMessage *connectMessage = [MQTTMessage connectMessageWithClientId:@"SRWebsocket"
                                                                         userName:nil
                                                                         password:nil
                                                                        keepAlive:10
                                                                     cleanSession:true
                                                                             will:NO
                                                                        willTopic:nil
                                                                          willMsg:nil
                                                                          willQoS:MQTTQosLevelAtLeastOnce
                                                                       willRetain:false
                                                                    protocolLevel:3];
            
            self.timeout = FALSE;
            [self performSelector:@selector(ackTimeout:)
                       withObject:parameters[@"timeout"]
                       afterDelay:[parameters[@"timeout"] intValue]];
            
            [self.websocket send:connectMessage.wireFormat];
            
            self.next = false;
            while (!self.next && !self.abort && !self.timeout) {
                NSLog(@"waiting for connect");
                [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
            }
            
            [NSObject cancelPreviousPerformRequestsWithTarget:self];
            
            XCTAssert(!self.timeout, @"timeout");
            XCTAssert(self.next, @"Websocket not response");
            
            
            [self.websocket close];
        }
    }
}

- (void)webSocket:(SRWebSocket *)webSocket
didReceiveMessage:(id)message {
    NSData *data = (NSData *)message;
    NSLog(@"webSocket didReceiveMessage %ld", data.length);
    self.next = true;
}

- (void)webSocketDidOpen:(SRWebSocket *)webSocket{
    NSLog(@"webSocketDidOpen");
}

- (void)webSocket:(SRWebSocket *)webSocket
 didFailWithError:(NSError *)error{
    NSLog(@"webSocket didFailWithError: %@", [error debugDescription]);
    self.abort = true;
}

- (void)webSocket:(SRWebSocket *)webSocket
 didCloseWithCode:(NSInteger)code
           reason:(NSString *)reason
         wasClean:(BOOL)wasClean {
    NSLog(@"webSocket didCloseWithCode: %ld %@ %d",
          (long)code,
          reason,
          wasClean);
    self.next = true;
}

- (void)webSocket:(SRWebSocket *)webSocket
   didReceivePong:(NSData *)pongPayload {
    NSLog(@"webSocket didReceivePong: %@",
          pongPayload);
}

- (void)newMessage:(MQTTSession *)session data:(NSData *)data onTopic:(NSString *)topic qos:(MQTTQosLevel)qos retained:(BOOL)retained mid:(unsigned int)mid {
    NSLog(@"newMessage:(%ld) onTopic:%@ qos:%d retained:%d mid:%d", data.length, topic, qos, retained, mid);
}

- (void)handleEvent:(MQTTSession *)session event:(MQTTSessionEvent)eventCode error:(NSError *)error {
    NSLog(@"handleEvent:%ld error:%@", (long)eventCode, error);
    self.event = eventCode;
    self.error = error;
}

- (void)sending:(MQTTSession *)session
           type:(MQTTCommandType)type
            qos:(MQTTQosLevel)qos
       retained:(BOOL)retained
          duped:(BOOL)duped
            mid:(UInt16)mid
           data:(NSData *)data {
    NSLog(@"sending: %02X q%d r%d d%d m%d (%ld)",
          type,
          qos,
          retained,
          duped,
          mid,
          data.length);
}

- (void)received:(MQTTSession *)session
            type:(MQTTCommandType)type
             qos:(MQTTQosLevel)qos
        retained:(BOOL)retained
           duped:(BOOL)duped
             mid:(UInt16)mid
            data:(NSData *)data {
    NSLog(@"received: %02X q%d r%d d%d m%d (%ld)",
          type,
          qos,
          retained,
          duped,
          mid,
          data.length);
}

- (void)ackTimeout:(NSNumber *)timeout {
    NSLog(@"ackTimeout: %f", [timeout doubleValue]);
    self.timeout = TRUE;
}

- (void)connect:(MQTTSession *)session parameters:(NSDictionary *)parameters{
    self.session.delegate = self;
    self.session.userName = parameters[@"user"];
    self.session.password = parameters[@"pass"];
    
    self.event = -1;
    self.timeout = FALSE;
    [self performSelector:@selector(ackTimeout:)
               withObject:parameters[@"timeout"]
               afterDelay:[parameters[@"timeout"] intValue]];
    
    [self.session CONNECT];
    
    while (!self.timeout && self.event == -1) {
        NSLog(@"waiting for connection");
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    XCTAssert(!self.timeout, @"timeout");
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
}

- (void)shutdown:(NSDictionary *)parameters {
    self.event = -1;
    self.timeout = FALSE;
    [self performSelector:@selector(ackTimeout:)
               withObject:parameters[@"timeout"]
               afterDelay:[parameters[@"timeout"] intValue]];
    
    [self.session DISCONNECT];
    
    while (!self.timeout && self.event == -1) {
        NSLog(@"waiting for disconnect");
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    XCTAssert(!self.timeout, @"timeout");
    XCTAssertEqual(self.event, MQTTSessionEventConnectionClosedByBroker, @"Not ClosedByBroker %ld %@", (long)self.event, self.error);
    
    self.session.delegate = nil;
    self.session = nil;
}



@end
