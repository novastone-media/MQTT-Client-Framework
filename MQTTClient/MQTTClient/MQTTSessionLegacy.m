//
// MQTTSessionLegacy.m
// MQTTClient.framework
//
// Copyright © 2013-2017, Christoph Krey. All rights reserved.
//
// based on
//
// Copyright (c) 2011, 2013, 2lemetry LLC
//
// All rights reserved. This program and the accompanying materials
// are made available under the terms of the Eclipse Public License v1.0
// which accompanies this distribution, and is available at
// http://www.eclipse.org/legal/epl-v10.html
//
// Contributors:
//    Kyle Roche - initial API and implementation and/or initial documentation
//

/**
 Using MQTT in your Objective-C application
 
 This file contains implementation for mqttio-OBJC backward compatibility
 
 @author Christoph Krey c@ckrey.de
 @see http://mqtt.org
 */

#import "MQTTSession.h"
#import "MQTTSessionLegacy.h"
#import "MQTTCFSocketTransport.h"
#import "MQTTSSLSecurityPolicyTransport.h"

#import "MQTTLog.h"

@interface MQTTSession()
@property (strong, nonatomic) MQTTSSLSecurityPolicy *securityPolicy;

@end

@implementation MQTTSession(Legacy)

- (MQTTSession *)initWithClientId:(NSString *)clientId
                         userName:(NSString *)userName
                         password:(NSString *)password
                        keepAlive:(UInt16)keepAliveInterval
                     cleanSession:(BOOL)cleanSessionFlag
                             will:(BOOL)willFlag
                        willTopic:(NSString *)willTopic
                          willMsg:(NSData *)willMsg
                          willQoS:(MQTTQosLevel)willQoS
                   willRetainFlag:(BOOL)willRetainFlag
                    protocolLevel:(UInt8)protocolLevel
                            queue:(dispatch_queue_t)queue {
    return [self initWithClientId:clientId
                         userName:userName
                         password:password
                        keepAlive:keepAliveInterval
                     cleanSession:cleanSessionFlag
                             will:willFlag
                        willTopic:willTopic
                          willMsg:willMsg
                          willQoS:willQoS
                   willRetainFlag:willRetainFlag
                    protocolLevel:protocolLevel
                          queue:queue
                   securityPolicy:nil];
}

- (MQTTSession *)initWithClientId:(NSString *)clientId
                         userName:(NSString *)userName
                         password:(NSString *)password
                        keepAlive:(UInt16)keepAliveInterval
                     cleanSession:(BOOL)cleanSessionFlag
                             will:(BOOL)willFlag
                        willTopic:(NSString *)willTopic
                          willMsg:(NSData *)willMsg
                          willQoS:(MQTTQosLevel)willQoS
                   willRetainFlag:(BOOL)willRetainFlag
                    protocolLevel:(UInt8)protocolLevel
                            queue:(dispatch_queue_t)queue
                   securityPolicy:(MQTTSSLSecurityPolicy *) securityPolicy {
    return [self initWithClientId:clientId
                         userName:userName
                         password:password
                        keepAlive:keepAliveInterval
                     cleanSession:cleanSessionFlag
                             will:willFlag
                        willTopic:willTopic
                          willMsg:willMsg
                          willQoS:willQoS
                   willRetainFlag:willRetainFlag
                    protocolLevel:protocolLevel
                          queue:queue
                   securityPolicy:securityPolicy
                     certificates:nil];
    
}

- (MQTTSession *)initWithClientId:(NSString *)clientId
                         userName:(NSString *)userName
                         password:(NSString *)password
                        keepAlive:(UInt16)keepAliveInterval
                     cleanSession:(BOOL)cleanSessionFlag
                             will:(BOOL)willFlag
                        willTopic:(NSString *)willTopic
                          willMsg:(NSData *)willMsg
                          willQoS:(MQTTQosLevel)willQoS
                   willRetainFlag:(BOOL)willRetainFlag
                    protocolLevel:(UInt8)protocolLevel
                            queue:(dispatch_queue_t)queue
                   securityPolicy:(MQTTSSLSecurityPolicy *) securityPolicy
                     certificates:(NSArray *)certificates {
    DDLogVerbose(@"[MQTTSessionLegacy] initWithClientId:%@ ", clientId);

    self = [self init];
    self.clientId = clientId;
    self.userName = userName;
    self.password = password;
    self.keepAliveInterval = keepAliveInterval;
    self.cleanSessionFlag = cleanSessionFlag;
    self.willFlag = willFlag;
    self.willTopic = willTopic;
    self.willMsg = willMsg;
    self.willQoS = willQoS;
    self.willRetainFlag = willRetainFlag;
    self.protocolLevel = protocolLevel;
    self.queue = queue;
    self.securityPolicy = securityPolicy;
    self.certificates = certificates;
    
    return self;
}

- (id)initWithClientId:(NSString*)theClientId {
    
    return [self initWithClientId:theClientId
                         userName:nil
                         password:nil
                        keepAlive:60
                     cleanSession:YES
                             will:NO
                        willTopic:nil
                          willMsg:nil
                          willQoS:MQTTQosLevelAtMostOnce
                   willRetainFlag:FALSE
                    protocolLevel:4
                            queue:dispatch_get_main_queue()];
}

- (id)initWithClientId:(NSString *)theClientId
                 queue:(dispatch_queue_t)queue {
    
    return [self initWithClientId:theClientId
                         userName:nil
                         password:nil
                        keepAlive:60
                     cleanSession:YES
                             will:NO
                        willTopic:nil
                          willMsg:nil
                          willQoS:MQTTQosLevelAtMostOnce
                   willRetainFlag:FALSE
                    protocolLevel:4
                            queue:queue];
}

- (id)initWithClientId:(NSString *)theClientId
              userName:(NSString *)theUsername
              password:(NSString *)thePassword {
    
    return [self initWithClientId:theClientId
                         userName:theUsername
                         password:thePassword
                        keepAlive:60
                     cleanSession:YES
                             will:NO
                        willTopic:nil
                          willMsg:nil
                          willQoS:MQTTQosLevelAtMostOnce
                   willRetainFlag:FALSE
                    protocolLevel:4
                          queue:dispatch_get_main_queue()];
}

- (id)initWithClientId:(NSString *)theClientId
              userName:(NSString *)theUserName
              password:(NSString *)thePassword
                 queue:(dispatch_queue_t)queue {
    
    return [self initWithClientId:theClientId
                         userName:theUserName
                         password:thePassword
                        keepAlive:60
                     cleanSession:YES
                             will:NO
                        willTopic:nil
                          willMsg:nil
                          willQoS:MQTTQosLevelAtMostOnce
                   willRetainFlag:FALSE
                    protocolLevel:4
                            queue:queue];
}

- (id)initWithClientId:(NSString *)theClientId
              userName:(NSString *)theUsername
              password:(NSString *)thePassword
             keepAlive:(UInt16)theKeepAliveInterval
          cleanSession:(BOOL)cleanSessionFlag {
    
    return [self initWithClientId:theClientId
                         userName:theUsername
                         password:thePassword
                        keepAlive:theKeepAliveInterval
                     cleanSession:cleanSessionFlag
                             will:NO
                        willTopic:nil
                          willMsg:nil
                          willQoS:MQTTQosLevelAtMostOnce
                   willRetainFlag:FALSE
                    protocolLevel:4
                            queue:dispatch_get_main_queue()];
}

- (id)initWithClientId:(NSString *)theClientId
              userName:(NSString *)theUsername
              password:(NSString *)thePassword
             keepAlive:(UInt16)theKeepAlive
          cleanSession:(BOOL)theCleanSessionFlag
                 queue:(dispatch_queue_t)queue {
    
    return [self initWithClientId:theClientId
                         userName:theUsername
                         password:thePassword
                        keepAlive:theKeepAlive
                     cleanSession:theCleanSessionFlag
                             will:NO
                        willTopic:nil
                          willMsg:nil
                          willQoS:MQTTQosLevelAtMostOnce
                   willRetainFlag:FALSE
                    protocolLevel:4
                          queue:queue];
}

- (id)initWithClientId:(NSString *)theClientId
              userName:(NSString *)theUserName
              password:(NSString *)thePassword
             keepAlive:(UInt16)theKeepAliveInterval
          cleanSession:(BOOL)theCleanSessionFlag
             willTopic:(NSString *)willTopic
               willMsg:(NSData *)willMsg
               willQoS:(UInt8)willQoS
        willRetainFlag:(BOOL)willRetainFlag {
    
    return [self initWithClientId:theClientId
                         userName:theUserName
                         password:thePassword
                        keepAlive:theKeepAliveInterval
                     cleanSession:theCleanSessionFlag
                             will:YES
                        willTopic:willTopic
                          willMsg:willMsg
                          willQoS:willQoS
                   willRetainFlag:willRetainFlag
                    protocolLevel:4
                            queue:dispatch_get_main_queue()];
}

- (id)initWithClientId:(NSString *)theClientId
              userName:(NSString *)theUserName
              password:(NSString *)thePassword
             keepAlive:(UInt16)theKeepAliveInterval
          cleanSession:(BOOL)theCleanSessionFlag
             willTopic:(NSString *)willTopic
               willMsg:(NSData *)willMsg
               willQoS:(UInt8)willQoS
        willRetainFlag:(BOOL)willRetainFlag
                 queue:(dispatch_queue_t)queue {
    
    return [self initWithClientId:theClientId
                         userName:theUserName
                         password:thePassword
                        keepAlive:theKeepAliveInterval
                     cleanSession:theCleanSessionFlag
                             will:YES
                        willTopic:willTopic
                          willMsg:willMsg
                          willQoS:willQoS
                   willRetainFlag:willRetainFlag
                    protocolLevel:4
                          queue:queue];
}

- (id)initWithClientId:(NSString *)theClientId
             keepAlive:(UInt16)theKeepAliveInterval
        connectMessage:(MQTTMessage *)theConnectMessage
                 queue:(dispatch_queue_t)queue {
    
    self.connectMessage = theConnectMessage;
    return [self initWithClientId:theClientId
                         userName:nil
                         password:nil
                        keepAlive:theKeepAliveInterval
                     cleanSession:YES
                             will:NO
                        willTopic:nil
                          willMsg:nil
                          willQoS:MQTTQosLevelAtMostOnce
                   willRetainFlag:FALSE
                    protocolLevel:4
                          queue:queue];
}

- (void)connectToHost:(NSString*)host port:(UInt32)port usingSSL:(BOOL)usingSSL {
    [self connectToHost:host port:port usingSSL:usingSSL connectHandler:nil];
}

- (void)connectToHost:(NSString *)host
                 port:(UInt32)port
             usingSSL:(BOOL)usingSSL
       connectHandler:(MQTTConnectHandler)connectHandler {
    DDLogVerbose(@"MQTTSessionLegacy connectToHost:%@ port:%d usingSSL:%d connectHandler:%p",
                 host, (unsigned int)port, usingSSL, connectHandler);
    
    if (self.securityPolicy) {
        MQTTSSLSecurityPolicyTransport *transport = [[MQTTSSLSecurityPolicyTransport alloc] init];
        transport.host = host;
        transport.port = port;
        transport.tls = usingSSL;
        transport.securityPolicy = self.securityPolicy;
        transport.certificates = self.certificates;
        transport.voip = self.voip;
        transport.queue = self.queue;
        self.transport = transport;
        
    } else {
        MQTTCFSocketTransport *transport = [[MQTTCFSocketTransport alloc] init];
        transport.host = host;
        transport.port = port;
        transport.tls = usingSSL;
        transport.certificates = self.certificates;
        transport.voip = self.voip;
        transport.queue = self.queue;
        self.transport = transport;
    }
    
    [self connectWithConnectHandler:connectHandler];
}


- (void)connectToHost:(NSString*)ip
                 port:(UInt32)port {
    [self connectToHost:ip port:port usingSSL:NO];
}

- (void)connectToHost:(NSString*)ip
                 port:(UInt32)port
withConnectionHandler:(void (^)(MQTTSessionEvent event))connHandler
       messageHandler:(void (^)(NSData* data, NSString* topic))messHandler {
    self.messageHandler = messHandler;
    self.connectionHandler = connHandler;
    
    [self connectToHost:ip port:port usingSSL:NO];
}

- (void)connectToHost:(NSString*)ip port:(UInt32)port
             usingSSL:(BOOL)usingSSL
withConnectionHandler:(void (^)(MQTTSessionEvent event))connHandler
       messageHandler:(void (^)(NSData* data, NSString* topic))messHandler {
    self.messageHandler = messHandler;
    self.connectionHandler = connHandler;
    
    [self connectToHost:ip port:port usingSSL:usingSSL];
}

- (void)subscribeTopic:(NSString*)theTopic {
    [self subscribeToTopic:theTopic atLevel:MQTTQosLevelAtLeastOnce];
}

- (void)publishData:(NSData*)theData onTopic:(NSString*)theTopic {
    [self publishData:theData onTopic:theTopic retain:NO qos:MQTTQosLevelAtLeastOnce];
}

- (void)publishDataAtLeastOnce:(NSData*)theData onTopic:(NSString*)theTopic {
    [self publishData:theData onTopic:theTopic retain:NO qos:MQTTQosLevelAtLeastOnce];
}

- (void)publishDataAtLeastOnce:(NSData*)theData onTopic:(NSString*)theTopic retain:(BOOL)retainFlag {
    [self publishData:theData onTopic:theTopic retain:retainFlag qos:MQTTQosLevelAtLeastOnce];
}

- (void)publishDataAtMostOnce:(NSData*)theData onTopic:(NSString*)theTopic {
    [self publishData:theData onTopic:theTopic retain:NO qos:MQTTQosLevelAtMostOnce];
}

- (void)publishDataAtMostOnce:(NSData*)theData onTopic:(NSString*)theTopic retain:(BOOL)retainFlag {
    [self publishData:theData onTopic:theTopic retain:retainFlag qos:MQTTQosLevelAtMostOnce];
}

- (void)publishDataExactlyOnce:(NSData*)theData onTopic:(NSString*)theTopic {
    [self publishData:theData onTopic:theTopic retain:NO qos:MQTTQosLevelExactlyOnce];
}

- (void)publishDataExactlyOnce:(NSData*)theData onTopic:(NSString*)theTopic retain:(BOOL)retainFlag {
    [self publishData:theData onTopic:theTopic retain:retainFlag qos:MQTTQosLevelExactlyOnce];
}

- (void)publishJson:(id)payload onTopic:(NSString*)theTopic {
    NSData *data = [NSJSONSerialization dataWithJSONObject:payload options:0 error:nil];
    if (data) {
        [self publishData:data onTopic:theTopic retain:FALSE qos:MQTTQosLevelAtLeastOnce];
    }
}
@end
