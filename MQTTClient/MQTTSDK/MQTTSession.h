//
// MQTTSession.h
// MQtt Client
// 
// Copyright (c) 2011, 2013, 2lemetry LLC
// 
// All rights reserved. This program and the accompanying materials
// are made available under the terms of the Eclipse Public License v1.0
// and Eclipse Distribution License v. 1.0 which accompanies this distribution.
// The Eclipse Public License is available at http://www.eclipse.org/legal/epl-v10.html
// and the Eclipse Distribution License is available at
// http://www.eclipse.org/org/documents/edl-v10.php.
// 
// Contributors:
//    Kyle Roche - initial API and implementation and/or initial documentation
// 

#import <Foundation/Foundation.h>
#import "MQTTMessage.h"

typedef enum {
    MQTTSessionStatusCreated,
    MQTTSessionStatusConnecting,
    MQTTSessionStatusConnected,
    MQTTSessionStatusError
} MQTTSessionStatus;

typedef enum {
    MQTTSessionEventConnected,
    MQTTSessionEventConnectionRefused,
    MQTTSessionEventConnectionClosed,
    MQTTSessionEventConnectionError,
    MQTTSessionEventProtocolError
} MQTTSessionEvent;

@class MQTTSession;

@protocol MQTTSessionDelegate

- (void)session:(MQTTSession*)session handleEvent:(MQTTSessionEvent)eventCode;
- (void)session:(MQTTSession*)session newMessage:(NSData*)data onTopic:(NSString*)topic;

@end

@interface MQTTSession : NSObject 

#pragma mark Constructors

- (id)initWithClientId:(NSString*)theClientId;
- (id)initWithClientId:(NSString*)theClientId runLoop:(NSRunLoop*)theRunLoop
               forMode:(NSString*)theRunLoopMode;
- (id)initWithClientId:(NSString*)theClientId
              userName:(NSString*)theUsername
              password:(NSString*)thePassword;
- (id)initWithClientId:(NSString*)theClientId
              userName:(NSString*)theUserName
              password:(NSString*)thePassword
               runLoop:(NSRunLoop*)theRunLoop
               forMode:(NSString*)theRunLoopMode;
- (id)initWithClientId:(NSString*)theClientId
              userName:(NSString*)theUsername
              password:(NSString*)thePassword
             keepAlive:(UInt16)theKeepAliveInterval
          cleanSession:(BOOL)cleanSessionFlag;
- (id)initWithClientId:(NSString*)theClientId
              userName:(NSString*)theUsername
              password:(NSString*)thePassword
             keepAlive:(UInt16)theKeepAlive
          cleanSession:(BOOL)theCleanSessionFlag
               runLoop:(NSRunLoop*)theRunLoop
               forMode:(NSString*)theMode;
- (id)initWithClientId:(NSString*)theClientId
              userName:(NSString*)theUserName
              password:(NSString*)thePassword
             keepAlive:(UInt16)theKeepAliveInterval
          cleanSession:(BOOL)theCleanSessionFlag
             willTopic:(NSString*)willTopic
               willMsg:(NSData*)willMsg
               willQoS:(UInt8)willQoS
        willRetainFlag:(BOOL)willRetainFlag;
- (id)initWithClientId:(NSString*)theClientId
              userName:(NSString*)theUserName
              password:(NSString*)thePassword
             keepAlive:(UInt16)theKeepAliveInterval
          cleanSession:(BOOL)theCleanSessionFlag
             willTopic:(NSString*)willTopic
               willMsg:(NSData*)willMsg
               willQoS:(UInt8)willQoS
        willRetainFlag:(BOOL)willRetainFlag
               runLoop:(NSRunLoop*)theRunLoop
               forMode:(NSString*)theRunLoopMode;
- (id)initWithClientId:(NSString*)theClientId
             keepAlive:(UInt16)theKeepAliveInterval
        connectMessage:(MQTTMessage*)theConnectMessage
               runLoop:(NSRunLoop*)theRunLoop
               forMode:(NSString*)theRunLoopMode;

#pragma mark Delegates and Callback blocks
@property (weak) id<MQTTSessionDelegate> delegate;
@property (strong) void (^connectionHandler)(MQTTSessionEvent event);
@property (strong) void (^messageHandler)(NSData* message, NSString* topic);

#pragma mark Connection Management
- (void)connectToHost:(NSString*)ip port:(UInt32)port;
- (void)connectToHost:(NSString*)ip port:(UInt32)port usingSSL:(BOOL)usingSSL;
- (void)connectToHost:(NSString*)ip port:(UInt32)port withConnectionHandler:(void (^)(MQTTSessionEvent event))connHandler messageHandler:(void (^)(NSData* data, NSString* topic))messHandler;
- (void)connectToHost:(NSString*)ip port:(UInt32)port usingSSL:(BOOL)usingSSL withConnectionHandler:(void (^)(MQTTSessionEvent event))connHandler messageHandler:(void (^)(NSData* data, NSString* topic))messHandler;
- (void)close;

#pragma mark Subscription Management
- (void)subscribeTopic:(NSString*)theTopic;
- (void)subscribeToTopic:(NSString*)topic atLevel:(UInt8)qosLevel;
- (void)unsubscribeTopic:(NSString*)theTopic;

#pragma mark Message Publishing
- (void)publishData:(NSData*)theData onTopic:(NSString*)theTopic;
- (void)publishDataAtLeastOnce:(NSData*)theData onTopic:(NSString*)theTopic;
- (void)publishDataAtLeastOnce:(NSData*)theData onTopic:(NSString*)theTopic retain:(BOOL)retainFlag;
- (void)publishDataAtMostOnce:(NSData*)theData onTopic:(NSString*)theTopic;
- (void)publishDataAtMostOnce:(NSData*)theData onTopic:(NSString*)theTopic retain:(BOOL)retainFlag;
- (void)publishDataExactlyOnce:(NSData*)theData onTopic:(NSString*)theTopic;
- (void)publishDataExactlyOnce:(NSData*)theData onTopic:(NSString*)theTopic retain:(BOOL)retainFlag;
- (void)publishJson:(id)payload onTopic:(NSString*)theTopic;

@end


