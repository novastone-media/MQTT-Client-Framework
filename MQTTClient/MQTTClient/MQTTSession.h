//
// MQTTSession.h
// MQTTClient.framework
//

/**
 Using MQTT in your Objective-C application
 
 @author Christoph Krey krey.christoph@gmail.com
 @copyright Copyright (c) 2013-2015, Christoph Krey 
 
 based on Copyright (c) 2011, 2013, 2lemetry LLC
    All rights reserved. This program and the accompanying materials
    are made available under the terms of the Eclipse Public License v1.0
    which accompanies this distribution, and is available at
    http://www.eclipse.org/legal/epl-v10.html
 
 @see http://mqtt.org
 */


#import <Foundation/Foundation.h>

#import "MQTTMessage.h"
#import "MQTTPersistence.h"

@class MQTTSession;
@class MQTTSSLSecurityPolicy;

/** Session delegate gives your application control over the MQTTSession
 @note handleEvent and newMessage are required interfaces, the rest is optional
 */

@protocol MQTTSessionDelegate <NSObject>

/**
 Enumeration of MQTTSession states
 */
typedef NS_ENUM(NSInteger, MQTTSessionStatus) {
    MQTTSessionStatusCreated,
    MQTTSessionStatusConnecting,
    MQTTSessionStatusConnected,
    MQTTSessionStatusDisconnecting,
    MQTTSessionStatusClosed,
    MQTTSessionStatusError
};

/**
 Enumeration of MQTTSession events
 */
typedef NS_ENUM(NSInteger, MQTTSessionEvent) {
    MQTTSessionEventConnected,
    MQTTSessionEventConnectionRefused,
    MQTTSessionEventConnectionClosed,
    MQTTSessionEventConnectionError,
    MQTTSessionEventProtocolError,
    MQTTSessionEventConnectionClosedByBroker
};

@optional

/** gets called when a new message was received
 @param session the MQTTSession reporting the new message
 @param data the data received, might be zero length
 @param topic the topic the data was published to
 @param qos the qos of the message
 @param retained indicates if the data retransmitted from server storage
 @param mid the Message Identifier of the message if qos = 1 or 2, zero otherwise
 */
- (void)newMessage:(MQTTSession *)session
              data:(NSData *)data
           onTopic:(NSString *)topic
               qos:(MQTTQosLevel)qos
          retained:(BOOL)retained
               mid:(unsigned int)mid;

/** gets called when a new message was received
 @param session the MQTTSession reporting the new message
 @param data the data received, might be zero length
 @param topic the topic the data was published to
 @param qos the qos of the message
 @param retained indicates if the data retransmitted from server storage
 @param mid the Message Identifier of the message if qos = 1 or 2, zero otherwise
 @return true if the message was or will be processed, false if the message shall not be ack-ed
 */
- (BOOL)newMessageWithFeedback:(MQTTSession *)session
                          data:(NSData *)data
                       onTopic:(NSString *)topic
                           qos:(MQTTQosLevel)qos
                      retained:(BOOL)retained
                           mid:(unsigned int)mid;

/** for mqttio-OBJC backward compatibility
 @param session see newMessage for description
 @param data see newMessage for description
 @param topic see newMessage for description
 */
- (void)session:(MQTTSession*)session newMessage:(NSData*)data onTopic:(NSString*)topic;

/** gets called when a connection is established, closed or a problem occurred
 @param session the MQTTSession reporting the event
 @param eventCode the code of the event
 @param error an optional additional error object with additional information
 */
- (void)handleEvent:(MQTTSession *)session event:(MQTTSessionEvent)eventCode error:(NSError *)error;

/** for mqttio-OBJC backward compatibility
 @param session the MQTTSession reporting the event
 @param eventCode the code of the event
 */
- (void)session:(MQTTSession*)session handleEvent:(MQTTSessionEvent)eventCode;

/** gets called when a connection has been successfully established
 @param session the MQTTSession reporting the connect
 
 */
- (void)connected:(MQTTSession *)session;

/** gets called when a connection has been successfully established
 @param session the MQTTSession reporting the connect
 @param sessionPresent represents the Session Present flag sent by the broker
 
 */
- (void)connected:(MQTTSession *)session sessionPresent:(BOOL)sessionPresent;

/** gets called when a connection has been refused
 @param session the MQTTSession reporting the refusal
 @param error an optional additional error object with additional information
 */
- (void)connectionRefused:(MQTTSession *)session error:(NSError *)error;

/** gets called when a connection has been closed
 @param session the MQTTSession reporting the close

 */
- (void)connectionClosed:(MQTTSession *)session;

/** gets called when a connection error happened
 @param session the MQTTSession reporting the connect error
 @param error an optional additional error object with additional information
 */
- (void)connectionError:(MQTTSession *)session error:(NSError *)error;

/** gets called when an MQTT protocol error happened
 @param session the MQTTSession reporting the protocol error
 @param error an optional additional error object with additional information
 */
- (void)protocolError:(MQTTSession *)session error:(NSError *)error;

/** gets called when a published message was actually delivered
 @param session the MQTTSession reporting the delivery
 @param msgID the Message Identifier of the delivered message
 @note this method is called after a publish with qos 1 or 2 only
 */
- (void)messageDelivered:(MQTTSession *)session msgID:(UInt16)msgID;

/** gets called when a subscription is acknowledged by the MQTT broker
 @param session the MQTTSession reporting the acknowledge
 @param msgID the Message Identifier of the SUBSCRIBE message
 @param qoss an array containing the granted QoS(s) related to the SUBSCRIBE message
    (see subscribeTopic, subscribeTopics)
 */
- (void)subAckReceived:(MQTTSession *)session msgID:(UInt16)msgID grantedQoss:(NSArray *)qoss;

/** gets called when an unsubscribe is acknowledged by the MQTT broker
 @param session the MQTTSession reporting the acknowledge
 @param msgID the Message Identifier of the UNSUBSCRIBE message
 */
- (void)unsubAckReceived:(MQTTSession *)session msgID:(UInt16)msgID;

/** gets called when a command is sent to the MQTT broker
 use this for low level monitoring of the MQTT connection
 @param session the MQTTSession reporting the sent command
 @param type the MQTT command type
 @param qos the Quality of Service of the command
 @param retained the retained status of the command
 @param duped the duplication status of the command
 @param mid the Message Identifier of the command
 @param data the payload data of the command if any, might be zero length
 */
- (void)sending:(MQTTSession *)session type:(int)type qos:(MQTTQosLevel)qos retained:(BOOL)retained duped:(BOOL)duped mid:(UInt16)mid data:(NSData *)data;

/** gets called when a command is received from the MQTT broker
 use this for low level monitoring of the MQTT connection
 @param session the MQTTSession reporting the received command
 @param type the MQTT command type
 @param qos the Quality of Service of the command
 @param retained the retained status of the command
 @param duped the duplication status of the command
 @param mid the Message Identifier of the command
 @param data the payload data of the command if any, might be zero length
 */
- (void)received:(MQTTSession *)session type:(int)type qos:(MQTTQosLevel)qos retained:(BOOL)retained duped:(BOOL)duped mid:(UInt16)mid data:(NSData *)data;

/** gets called when a command is received from the MQTT broker
 use this for low level control of the MQTT connection
 @param session the MQTTSession reporting the received command
 @param type the MQTT command type
 @param qos the Quality of Service of the command
 @param retained the retained status of the command
 @param duped the duplication status of the command
 @param mid the Message Identifier of the command
 @param data the payload data of the command if any, might be zero length
 @return true if the sessionmanager should ignore the received message
 */
- (BOOL)ignoreReceived:(MQTTSession *)session type:(int)type qos:(MQTTQosLevel)qos retained:(BOOL)retained duped:(BOOL)duped mid:(UInt16)mid data:(NSData *)data;

/** gets called when the content of MQTTClients internal buffers change
 use for monitoring the completion of transmitted and received messages
 @param session the MQTTSession reporting the change
 @param queued for backward compatibility only: MQTTClient does not queue messages anymore except during QoS protocol
 @param flowingIn the number of incoming messages not acknowledged by the MQTTClient yet
 @param flowingOut the number of outgoing messages not yet acknowledged by the MQTT broker
 */
- (void)buffered:(MQTTSession *)session
          queued:(NSUInteger)queued
       flowingIn:(NSUInteger)flowingIn
      flowingOut:(NSUInteger)flowingOut;

/** gets called when the content of MQTTClients internal buffers change
 use for monitoring the completion of transmitted and received messages
 @param session the MQTTSession reporting the change
 @param flowingIn the number of incoming messages not acknowledged by the MQTTClient yet
 @param flowingOut the number of outgoing messages not yet acknowledged by the MQTT broker
 */
- (void)buffered:(MQTTSession *)session
       flowingIn:(NSUInteger)flowingIn
      flowingOut:(NSUInteger)flowingOut;

@end

typedef void (^MQTTConnectHandler)(NSError *error);
typedef void (^MQTTDisconnectHandler)(NSError *error);
typedef void (^MQTTSubscribeHandler)(NSError *error, NSArray *gQoss);
typedef void (^MQTTUnsubscribeHandler)(NSError *error);
typedef void (^MQTTPublishHandler)(NSError *error);

/** Session implements the MQTT protocol for your application
 */

@interface MQTTSession : NSObject

/** set this member variable to receive delegate messages
 @code
 #import "MQTTClient.h"
 
 @interface MyClass : NSObject <MQTTSessionDelegate>
 ...
 @end
 
 ...
 MQTTSession *session = [[MQTTSession alloc] init];
 session.delegate = self;
 ...
 - (void)handleEvent:(MQTTSession *)session
        event:(MQTTSessionEvent)eventCode
        error:(NSError *)error {
    ...
 }
 - (void)newMessage:(MQTTSession *)session
        data:(NSData *)data
        onTopic:(NSString *)topic
        qos:(MQTTQosLevel)qos
        retained:(BOOL)retained
        mid:(unsigned int)mid {
    ...
 }
 @endcode
 
 */

@property (weak, nonatomic) id<MQTTSessionDelegate> delegate;

/** Control MQTT persistence by setting the properties of persistence before connecting to an MQTT broker.
    The settings are specific to a clientId.
 
    persistence.persistent = YES or NO (default) to establish file or in memory persistence. IMPORTANT: set immediately after creating the MQTTSession before calling any other method. Otherwise the default value (NO) will be used
        for this session.
 
    persistence.maxWindowSize (a positive number, default is 16) to control the number of messages sent before waiting for acknowledgement in Qos 1 or 2. Additional messages are
        stored and transmitted later.
 
    persistence.maxSize (a positive number of bytes, default is 64 MB) to limit the size of the persistence file. Messages published after the limit is reached are dropped.
 
    persistence.maxMessages (a positive number, default is 1024) to limit the number of messages stored. Additional messages published are dropped.
 
    Messages are deleted after they have been acknowledged.
*/
@property (strong, nonatomic) MQTTPersistence *persistence;

/** for mqttio-OBJC backward compatibility */
@property (strong) void (^connectionHandler)(MQTTSessionEvent event);
/** for mqttio-OBJC backward compatibility */
@property (strong) void (^messageHandler)(NSData* message, NSString* topic);

/** Session status
 */
@property (nonatomic, readonly) MQTTSessionStatus status;

/** Indicates if the broker found a persistent session when connecting with cleanSession:FALSE
 */
@property (nonatomic, readonly) BOOL sessionPresent;

/** see initWithClientId for description
 */
@property (strong, nonatomic) NSString *clientId;
/** see initWithClientId for description
 */
@property (strong, nonatomic) NSString *userName;
/** see initWithClientId for description
 */
@property (strong, nonatomic) NSString *password;
/** see initWithClientId for description
 */
@property (nonatomic) UInt16 keepAliveInterval;
/** see initWithClientId for description
 */
@property (nonatomic) BOOL cleanSessionFlag;
/** see initWithClientId for description
 */
@property (nonatomic) BOOL willFlag;
/** see initWithClientId for description
 */
@property (strong, nonatomic) NSString *willTopic;
/** see initWithClientId for description
 */
@property (strong, nonatomic) NSData *willMsg;
/** see initWithClientId for description
 */
@property (nonatomic) MQTTQosLevel willQoS;
/** see initWithClientId for description
 */
@property (nonatomic) BOOL willRetainFlag;
/** see initWithClientId for description
 */
@property (nonatomic) UInt8 protocolLevel;
/** see initWithClientId for description
 */
@property (strong, nonatomic) NSRunLoop *runLoop;
/** see initWithClientId for description
 */
@property (strong, nonatomic) NSString *runLoopMode;

// ssl security policy
/**
* The security policy used to evaluate server trust for secure connections.
*
* if your app using security model which require pinning SSL certificates to helps prevent man-in-the-middle attacks
* and other vulnerabilities. you need to set securityPolicy to properly value(see MQTTSSLSecurityPolicy.h for more detail).
*
* NOTE: about self-signed server certificates:
* if your server using Self-signed certificates to establish SSL/TLS connection, you need to set property:
* MQTTSSLSecurityPolicy.allowInvalidCertificates=YES.
*/
@property (strong, nonatomic) MQTTSSLSecurityPolicy *securityPolicy;

/** see initWithClientId for description
*/
@property (strong, nonatomic) NSArray *certificates;

/** for mqttio-OBJC backward compatibility
 the connect message used is stored here
 */
@property (strong, nonatomic) MQTTMessage *connectMessage;

/** initialises the MQTT session with default values
 @return the initialised MQTTSession object
 @code
 #import "MQTTClient.h"
 
 MQTTSession *session = [[MQTTSession alloc] init];
 @endcode
 */
- (MQTTSession *)init;

/** alternative initializer
 @param clientId see initWithClientId for description.
 @param userName see initWithClientId for description.
 @param password see initWithClientId for description.
 @param keepAliveInterval see initWithClientId for description.
 @param cleanSessionFlag see initWithClientId for description.
 @param willFlag see initWithClientId for description.
 @param willTopic see initWithClientId for description.
 @param willMsg see initWithClientId for description.
 @param willQoS see initWithClientId for description.
 @param willRetainFlag see initWithClientId for description.
 @param protocolLevel see initWithClientId for description.
 @param runLoop see initWithClientId for description.
 @param runLoopMode see initWithClientId for description.
 @return the initialised MQTTSession object
 @exception NSInternalInconsistencyException if the parameters are invalid
 */
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
                          runLoop:(NSRunLoop *)runLoop
                          forMode:(NSString *)runLoopMode;

/** alternative initializer
 @param clientId see initWithClientId for description.
 @param userName see initWithClientId for description.
 @param password see initWithClientId for description.
 @param keepAliveInterval see initWithClientId for description.
 @param cleanSessionFlag see initWithClientId for description.
 @param willFlag see initWithClientId for description.
 @param willTopic see initWithClientId for description.
 @param willMsg see initWithClientId for description.
 @param willQoS see initWithClientId for description.
 @param willRetainFlag see initWithClientId for description.
 @param protocolLevel see initWithClientId for description.
 @param runLoop see initWithClientId for description.
 @param runLoopMode see initWithClientId for description.
 @param securityPolicy see initWithClientId for description.
 @return the initialised MQTTSession object
 @exception NSInternalInconsistencyException if the parameters are invalid
 */
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
                          runLoop:(NSRunLoop *)runLoop
                          forMode:(NSString *)runLoopMode
                   securityPolicy:(MQTTSSLSecurityPolicy *) securityPolicy;

/** initialises the MQTT session
*
* this constructor can specifies SSL securityPolicy. the default value of securityPolicy is nil(which do nothing).
*
* if SSL is enabled, by default it only evaluate server's certificates using CA infrastructure, and for most case, this type of check is enough.
* However, if your app using security model which require pinning SSL certificates to helps prevent man-in-the-middle attacks
* and other vulnerabilities. you may need to set securityPolicy to properly value(see MQTTSSLSecurityPolicy.h for more detail).
*
* NOTE: about self-signed server certificates:
* In CA infrastructure, you may establish a SSL/TLS connection with server which using self-signed certificates
* by install the certificates into OS keychain(either programmatically or manually). however, this method has some disadvantages:
*  1. every socket you app created will trust certificates you added.
*  2. if user choice to remove certificates from keychain, you app need to handling certificates re-adding.
*
* If you only want to verify the cert for the socket you are creating and for no other sockets in your app, you need to use
* MQTTSSLSecurityPolicy.
* And if you use self-signed server certificates, your need to set property: MQTTSSLSecurityPolicy.allowInvalidCertificates=YES
* (see MQTTSSLSecurityPolicy.h for more detail).
*
* @param clientId The Client Identifier identifies the Client to the Server. If nil, a random clientId is generated.
* @param userName an NSString object containing the user's name (or ID) for authentication. May be nil.
* @param password an NSString object containing the user's password. If userName is nil, password must be nil as well.
* @param keepAliveInterval The Keep Alive is a time interval measured in seconds. The MQTTClient ensures that the interval between Control Packets being sent does not exceed the Keep Alive value. In the  absence of sending any other Control Packets, the Client sends a PINGREQ Packet.
* @param cleanSessionFlag specifies if the server should discard previous session information.
* @param willFlag If the Will Flag is set to YES this indicates that a Will Message MUST be published by the Server when the Server detects that the Client is disconnected for any reason other than the Client flowing a DISCONNECT Packet.
* @param willTopic If the Will Flag is set to YES, the Will Topic is a string, nil otherwise.
* @param willMsg If the Will Flag is set to YES the Will Message must be specified, nil otherwise.
* @param willQoS specifies the QoS level to be used when publishing the Will Message. If the Will Flag is set to NO, then the Will QoS MUST be set to 0. If the Will Flag is set to YES, the value of Will QoS can be 0 (0x00), 1 (0x01), or 2 (0x02).
* @param willRetainFlag indicates if the server should publish the Will Messages with retainFlag. If the Will Flag is set to NO, then the Will Retain Flag MUST be set to NO . If the Will Flag is set to YES: If Will Retain is set to NO, the Server MUST publish the Will Message as a non-retained publication [MQTT-3.1.2-14]. If Will Retain is set to YES, the Server MUST publish the Will Message as a retained publication [MQTT-3.1.2-15].
* @param protocolLevel specifies the protocol to be used. The value of the Protocol Level field for the version 3.1.1 of the protocol is 4. The value for the version 3.1 is 3.
* @param runLoop The runLoop where the streams are scheduled. If nil, defaults to [NSRunLoop currentRunLoop].
* @param runLoopMode The runLoopMode where the streams are scheduled. If nil, defaults to NSRunLoopCommonModes.
* @param securityPolicy The security policy used to evaluate server trust for secure connections.
* @param certificates An identity certificate used to reply to a server requiring client certificates according to the description given for SSLSetCertificate(). You may build the certificates array yourself or use the sundry method clientCertFromP12
* @return the initialised MQTTSession object
* @exception NSInternalInconsistencyException if the parameters are invalid
*
* @code
    #import "MQTTClient.h"

    NSString* certificate = [[NSBundle bundleForClass:[MQTTSession class]] pathForResource:@"certificate" ofType:@"cer"]; 
    MQTTSSLSecurityPolicy *securityPolicy = [MQTTSSLSecurityPolicy policyWithPinningMode:MQTTSSLPinningModeCertificate];
    securityPolicy.pinnedCertificates = @[ [NSData dataWithContentsOfFile:certificate] ];
    securityPolicy.allowInvalidCertificates = YES; // if your certificate is self-signed(which didn't coupled with CA infrastructure)

    MQTTSession *session = [[MQTTSession alloc]
                            initWithClientId:@"example-1234"
                            userName:@"user"
                            password:@"secret"
                            keepAlive:60
                            cleanSession:YES
                            will:YES
                            willTopic:@"example/status"
                            willMsg:[[@"Client off-line"] dataUsingEncoding:NSUTF8StringEncoding]
                            willQoS:2
                            willRetainFlag:YES
                            protocolLevel:4
                            runLoop:[NSRunLoop currentRunLoop]
                            forMode:NSRunLoopCommonModes
                            securityPolicy:securityPolicy
                            certificates:certificates];

    [session connectToHost:@"example-1234" port:1883 usingSSL:YES];
@endcode
*/
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
                          runLoop:(NSRunLoop *)runLoop
                          forMode:(NSString *)runLoopMode
                   securityPolicy:(MQTTSSLSecurityPolicy *) securityPolicy
                     certificates:(NSArray *)certificates;

/**
* for mqttio-OBJC backward compatibility
* @param theClientId see initWithClientId for description.
* @return the initialised MQTTSession object
* All other parameters are set to defaults
*/
- (id)initWithClientId:(NSString *)theClientId;

/** for mqttio-OBJC backward compatibility
 @param theClientId see initWithClientId for description.
 @param theRunLoop see initWithClientId for description.
 @param theRunLoopMode see initWithClientId for description.
 @return the initialised MQTTSession object
 All other parameters are set to defaults
 */
- (id)initWithClientId:(NSString*)theClientId
               runLoop:(NSRunLoop*)theRunLoop
               forMode:(NSString*)theRunLoopMode;

/** for mqttio-OBJC backward compatibility
 @param theClientId see initWithClientId for description.
 @param theUsername see initWithClientId for description.
 @param thePassword see initWithClientId for description.
 @return the initialised MQTTSession object
 All other parameters are set to defaults
 */
- (id)initWithClientId:(NSString*)theClientId
              userName:(NSString*)theUsername
              password:(NSString*)thePassword;

/** for mqttio-OBJC backward compatibility
 @param theClientId see initWithClientId for description.
 @param theUserName see initWithClientId for description.
 @param thePassword see initWithClientId for description.
 @param theRunLoop see initWithClientId for description.
 @param theRunLoopMode see initWithClientId for description.
 @return the initialised MQTTSession object
 All other parameters are set to defaults
 */
- (id)initWithClientId:(NSString*)theClientId
              userName:(NSString*)theUserName
              password:(NSString*)thePassword
               runLoop:(NSRunLoop*)theRunLoop
               forMode:(NSString*)theRunLoopMode;

/** for mqttio-OBJC backward compatibility
 @param theClientId see initWithClientId for description.
 @param theUsername see initWithClientId for description.
 @param thePassword see initWithClientId for description.
 @param theKeepAliveInterval see initWithClientId for description.
 @param cleanSessionFlag see initWithClientId for description.
 @return the initialised MQTTSession object
 All other parameters are set to defaults
 */
- (id)initWithClientId:(NSString*)theClientId
              userName:(NSString*)theUsername
              password:(NSString*)thePassword
             keepAlive:(UInt16)theKeepAliveInterval
          cleanSession:(BOOL)cleanSessionFlag;

/** for mqttio-OBJC backward compatibility
 @param theClientId see initWithClientId for description.
 @param theUsername see initWithClientId for description.
 @param thePassword see initWithClientId for description.
 @param theKeepAlive see initWithClientId for description.
 @param theCleanSessionFlag see initWithClientId for description.
 @param theRunLoop see initWithClientId for description.
 @param theMode see initWithClientId for description.
 @return the initialised MQTTSession object
 All other parameters are set to defaults
 */
- (id)initWithClientId:(NSString*)theClientId
              userName:(NSString*)theUsername
              password:(NSString*)thePassword
             keepAlive:(UInt16)theKeepAlive
          cleanSession:(BOOL)theCleanSessionFlag
               runLoop:(NSRunLoop*)theRunLoop
               forMode:(NSString*)theMode;

/** for mqttio-OBJC backward compatibility
 @param theClientId see initWithClientId for description.
 @param theUserName see initWithClientId for description.
 @param thePassword see initWithClientId for description.
 @param theKeepAliveInterval see initWithClientId for description.
 @param theCleanSessionFlag see initWithClientId for description.
 @param willTopic see initWithClientId for description.
 @param willMsg see initWithClientId for description.
 @param willQoS see initWithClientId for description.
 @param willRetainFlag see initWithClientId for description.
 @return the initialised MQTTSession object
 All other parameters are set to defaults
 */
- (id)initWithClientId:(NSString*)theClientId
              userName:(NSString*)theUserName
              password:(NSString*)thePassword
             keepAlive:(UInt16)theKeepAliveInterval
          cleanSession:(BOOL)theCleanSessionFlag
             willTopic:(NSString*)willTopic
               willMsg:(NSData*)willMsg
               willQoS:(UInt8)willQoS
        willRetainFlag:(BOOL)willRetainFlag;

/** for mqttio-OBJC backward compatibility
 @param theClientId see initWithClientId for description.
 @param theUserName see initWithClientId for description.
 @param thePassword see initWithClientId for description.
 @param theKeepAliveInterval see initWithClientId for description.
 @param theCleanSessionFlag see initWithClientId for description.
 @param willTopic see initWithClientId for description.
 @param willMsg see initWithClientId for description.
 @param willQoS see initWithClientId for description.
 @param willRetainFlag see initWithClientId for description.
 @param theRunLoop see initWithClientId for description.
 @param theRunLoopMode see initWithClientId for description.
 @return the initialised MQTTSession object
 All other parameters are set to defaults
 */
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

/** for mqttio-OBJC backward compatibility
 @param theClientId see initWithClientId for description.
 @param theKeepAliveInterval see initWithClientId for description.
 @param theConnectMessage has to be constructed using MQTTMessage connectMessage...
 @param theRunLoop see initWithClientId for description.
 @param theRunLoopMode see initWithClientId for description.
 @return the initialised MQTTSession object
 All other parameters are set to defaults
 */
- (id)initWithClientId:(NSString*)theClientId
             keepAlive:(UInt16)theKeepAliveInterval
        connectMessage:(MQTTMessage*)theConnectMessage
               runLoop:(NSRunLoop*)theRunLoop
               forMode:(NSString*)theRunLoopMode;

/** connects to the specified MQTT server
 
 @param host specifies the hostname or ip address to connect to. Defaults to @"localhost".
 @param port specifies the port to connect to
 @param usingSSL specifies whether to use SSL or not
 @param connectHandler identifies a block which is executed on successfull or unsuccessfull connect. Might be nil
    error is nil in the case of a successful connect
    sessionPresent indicates in MQTT 3.1.1 if persistent session data was present at the server
 
 @return nothing and returns immediately. To check the connect results, register as an MQTTSessionDelegate and
    - watch for events
    - watch for connect or connectionRefused messages
    - watch for error messages
    or use the connectHandler block
 
 @code
 #import "MQTTClient.h"
 
 MQTTSession *session = [[MQTTSession alloc] init];
 
 [session connectToHost:@"192.168.0.1" port:1883 usingSSL:NO connectHandler:^(NSError *error, BOOL sessionPresent) {
    if (error) {
        NSLog(@"Error Connect %@", error.localizedDescription);
    } else {
        NSLog(@"Connected sessionPresent:%d", sessionPresent);
    }
 }];
 @endcode
 
 */

- (void)connectToHost:(NSString *)host
                 port:(UInt32)port
             usingSSL:(BOOL)usingSSL
       connectHandler:(MQTTConnectHandler)connectHandler;

/** connects to the specified MQTT server
 
 @param host see connectToHost for description
 @param port see connectToHost for description
 @param usingSSL see connectToHost for description
 
 @return see connectToHost for description
 
 */
- (void)connectToHost:(NSString *)host port:(UInt32)port usingSSL:(BOOL)usingSSL;

/** for mqttio-OBJC backward compatibility
 @param ip see connectToHost for description
 @param port see connectoToHost for description
 */
- (void)connectToHost:(NSString*)ip port:(UInt32)port;

/** for mqttio-OBJC backward compatibility
 @param ip see connectToHost for description
 @param port see connectoToHost for description
 @param connHandler event handler block
 @param messHandler message handler block
 */
- (void)connectToHost:(NSString*)ip
                 port:(UInt32)port
withConnectionHandler:(void (^)(MQTTSessionEvent event))connHandler
       messageHandler:(void (^)(NSData* data, NSString* topic))messHandler;

/** for mqttio-OBJC backward compatibility
 @param ip see connectToHost for description
 @param port see connectoToHost for description
 @param usingSSL indicator to use TLS
 @param connHandler event handler block
 @param messHandler message handler block
 */
- (void)connectToHost:(NSString*)ip
                 port:(UInt32)port
             usingSSL:(BOOL)usingSSL
withConnectionHandler:(void (^)(MQTTSessionEvent event))connHandler
       messageHandler:(void (^)(NSData* data, NSString* topic))messHandler;


/** connects to the specified MQTT server synchronously
 
 @param host specifies the hostname or ip address to connect to. Defaults to @"localhost".
 @param port spefies the port to connect to
 @param usingSSL specifies whether to use SSL or not
 
 @return true if the connection was established
 
 @code
 #import "MQTTClient.h"
 
 MQTTSession *session = [[MQTTSession alloc] init];
 
 [session connectToHost:@"192.168.0.1" port:1883 usingSSL:NO];
 @endcode
 
 */
- (BOOL)connectAndWaitToHost:(NSString *)host port:(UInt32)port usingSSL:(BOOL)usingSSL;

/** subscribes to a topic at a specific QoS level
 
 @param topic see subscribeToTopic:atLevel:subscribeHandler: for description
 @param qosLevel  see subscribeToTopic:atLevel:subscribeHandler: for description
 @return the Message Identifier of the SUBSCRIBE message.
 
 @note returns immediately. To check results, register as an MQTTSessionDelegate and watch for events.
 
 @code
 #import "MQTTClient.h"
 
 MQTTSession *session = [[MQTTSession alloc] init];
 
 [session connectToHost:@"192.168.0.1" port:1883 usingSSL:NO];
 ...
 [session subscribeToTopic:@"example/#" atLevel:2];
 
 @endcode
 
 */

- (UInt16)subscribeToTopic:(NSString *)topic atLevel:(MQTTQosLevel)qosLevel;
/** subscribes to a topic at a specific QoS level
 
 @param topic the Topic Filter to subscribe to.
 
 @param qosLevel specifies the QoS Level of the subscription.
 qosLevel can be 0, 1, or 2.
 @param subscribeHandler identifies a block which is executed on successfull or unsuccessfull subscription.
 Might be nil. error is nil in the case of a successful subscription. In this case gQoss represents an
 array of grantes Qos
 
 
 @return the Message Identifier of the SUBSCRIBE message.
 
 @note returns immediately. To check results, register as an MQTTSessionDelegate and watch for events.
 
 @code
 #import "MQTTClient.h"
 
 MQTTSession *session = [[MQTTSession alloc] init];
 
 [session connectToHost:@"192.168.0.1" port:1883 usingSSL:NO];
 ...
 [session subscribeToTopic:@"example/#" atLevel:2 subscribeHandler:^(NSError *error, NSArray *gQoss){
    if (error) {
        NSLog(@"Subscription failed %@", error.localizedDescription);
    } else {
        NSLog(@"Subscription sucessfull! Granted Qos: %@", gQoss);
    }
 }];
 
 @endcode
 
 */

- (UInt16)subscribeToTopic:(NSString *)topic atLevel:(MQTTQosLevel)qosLevel subscribeHandler:(MQTTSubscribeHandler)subscribeHandler;

/** for mqttio-OBJC backward compatibility
 @param theTopic see subscribeToTopic for description
 */
- (void)subscribeTopic:(NSString*)theTopic;

/** subscribes to a topic at a specific QoS level synchronously
 
 @param topic the Topic Filter to subscribe to.
 
 @param qosLevel specifies the QoS Level of the subscription.
 qosLevel can be 0, 1, or 2.
 
 @return TRUE if successfully subscribed
 
 @code
 #import "MQTTClient.h"
 
 MQTTSession *session = [[MQTTSession alloc] init];
 
 [session connectToHost:@"192.168.0.1" port:1883 usingSSL:NO];
 
 [session subscribeToTopic:@"example/#" atLevel:2];
 
 @endcode
 
 */

- (BOOL)subscribeAndWaitToTopic:(NSString *)topic atLevel:(MQTTQosLevel)qosLevel;


/** subscribes a number of topics
 
 @param topics an NSDictionary containing the Topic Filters to subscribe to as keys and the corresponding QoS as NSNumber values
 
 @return the Message Identifier of the SUBSCRIBE message.
 
 @note returns immediately. To check results, register as an MQTTSessionDelegate and watch for events.
 
 @code
 #import "MQTTClient.h"
 
 MQTTSession *session = [[MQTTSession alloc] init];
 
 [session connectToHost:@"192.168.0.1" port:1883 usingSSL:NO];
 
 [session subscribeToTopics:@{
 @"example/#": @(0),
 @"example/status": @(2),
 @"other/#": @(1)
 }];
 
 @endcode
 */


- (UInt16)subscribeToTopics:(NSDictionary *)topics;

/** subscribes a number of topics
 
 @param topics an NSDictionary containing the Topic Filters to subscribe to as keys and the corresponding QoS as NSNumber values
 @param subscribeHandler identifies a block which is executed on successfull or unsuccessfull subscription.
    Might be nil. error is nil in the case of a successful subscription. In this case gQoss represents an
    array of grantes Qos
 
 @return the Message Identifier of the SUBSCRIBE message.
 
 @note returns immediately. To check results, register as an MQTTSessionDelegate and watch for events.
 
 @code
 #import "MQTTClient.h"
 
 MQTTSession *session = [[MQTTSession alloc] init];
 
 [session connectToHost:@"192.168.0.1" port:1883 usingSSL:NO];
 
 [session subscribeToTopics:@{
    @"example/#": @(0),
    @"example/status": @(2),
    @"other/#": @(1)
 } subscribeHandler:^(NSError *error, NSArray *gQoss){
    if (error) {
        NSLog(@"Subscription failed %@", error.localizedDescription);
    } else {
        NSLog(@"Subscription sucessfull! Granted Qos: %@", gQoss);
    }
 }];

 
 @endcode
 */


- (UInt16)subscribeToTopics:(NSDictionary *)topics subscribeHandler:(MQTTSubscribeHandler)subscribeHandler;

/** subscribes a number of topics
 
 @param topics an NSDictionary containing the Topic Filters to subscribe to as keys and the corresponding QoS as NSNumber values
 
 @return TRUE if the subscribe was succesfull
 
 @code
 #import "MQTTClient.h"
 
 MQTTSession *session = [[MQTTSession alloc] init];
 
 [session connectToHost:@"192.168.0.1" port:1883 usingSSL:NO];
 
 [session subscribeToTopics:@{
 @"example/#": @(0),
 @"example/status": @(2),
 @"other/#": @(1)
 }];
 
 @endcode
 */


- (BOOL)subscribeAndWaitToTopics:(NSDictionary *)topics;

/** unsubscribes from a topic
 
 @param topic the Topic Filter to unsubscribe from.

 @return the Message Identifier of the UNSUBSCRIBE message.
 
 @note returns immediately. To check results, register as an MQTTSessionDelegate and watch for events.
 
 @code
 #import "MQTTClient.h"
 
 MQTTSession *session = [[MQTTSession alloc] init];
 
 [session connectToHost:@"192.168.0.1" port:1883 usingSSL:NO];
 
 [session unsubscribeTopic:@"example/#"];
 
 @endcode
 */

- (UInt16)unsubscribeTopic:(NSString *)topic;

/** unsubscribes from a topic
 
 @param topic the Topic Filter to unsubscribe from.
 @param unsubscribeHandler identifies a block which is executed on successfull or unsuccessfull subscription.
 Might be nil. error is nil in the case of a successful subscription. In this case gQoss represents an
 array of grantes Qos
 
 @return the Message Identifier of the UNSUBSCRIBE message.
 
 @note returns immediately.
 
 */


- (UInt16)unsubscribeTopic:(NSString *)topic unsubscribeHandler:(MQTTUnsubscribeHandler)unsubscribeHandler;

/** unsubscribes from a topic synchronously
 
 @param topic the Topic Filter to unsubscribe from.
 
 @return TRUE if sucessfully unsubscribed
 
 @code
 #import "MQTTClient.h"
 
 MQTTSession *session = [[MQTTSession alloc] init];
 
 [session connectToHost:@"192.168.0.1" port:1883 usingSSL:NO];
 
 [session unsubscribeTopic:@"example/#"];
 
 @endcode
 */

- (BOOL)unsubscribeAndWaitTopic:(NSString *)topic;

/** unsubscribes from a number of topics
 
 @param topics an NSArray of topics to unsubscribe from
 
 @return the Message Identifier of the UNSUBSCRIBE message.
 
 @note returns immediately. To check results, register as an MQTTSessionDelegate and watch for events.
 
 @code
 #import "MQTTClient.h"
 
 MQTTSession *session = [[MQTTSession alloc] init];
 
 [session connectToHost:@"192.168.0.1" port:1883 usingSSL:NO];
 
 [session unsubscribeTopics:@[
 @"example/#",
 @"example/status",
 @"other/#"
 ]];
 
 @endcode
 
 */

- (UInt16)unsubscribeTopics:(NSArray *)topics;

/** unsubscribes from a number of topics
 
 @param topics an NSArray of topics to unsubscribe from
 
 @param unsubscribeHandler identifies a block which is executed on successfull or unsuccessfull subscription.
    Might be nil. error is nil in the case of a successful subscription. In this case gQoss represents an
    array of grantes Qos
 
 @return the Message Identifier of the UNSUBSCRIBE message.
 
 @note returns immediately.
 
 */


- (UInt16)unsubscribeTopics:(NSArray *)topics unsubscribeHandler:(MQTTUnsubscribeHandler)unsubscribeHandler;

/** unsubscribes from a number of topics synchronously
 
 @param topics an NSArray of topics to unsubscribe from
 
 @return TRUE if the unsubscribe was successful
 
 @code
 #import "MQTTClient.h"
 
 MQTTSession *session = [[MQTTSession alloc] init];
 
 [session connectToHost:@"192.168.0.1" port:1883 usingSSL:NO];
 
 [session unsubscribeTopics:@[
 @"example/#",
 @"example/status",
 @"other/#"
 ]];
 
 @endcode
 
 */

- (BOOL)unsubscribeAndWaitTopics:(NSArray *)topics;


/** publishes data on a given topic at a specified QoS level and retain flag
 
 @param data the data to be sent. length may range from 0 to 268,435,455 - 4 - _lengthof-topic_ bytes. Defaults to length 0.
 @param topic the Topic to identify the data
 @param retainFlag if YES, data is stored on the MQTT broker until overwritten by the next publish with retainFlag = YES
 @param qos specifies the Quality of Service for the publish
 qos can be 0, 1, or 2.
 @return the Message Identifier of the PUBLISH message. Zero if qos 0. If qos 1 or 2, zero if message was dropped
 
 @note returns immediately. To check results, register as an MQTTSessionDelegate and watch for events.
 
 @code
 #import "MQTTClient.h"
 
 MQTTSession *session = [[MQTTSession alloc] init];
 
 [session connectToHost:@"192.168.0.1" port:1883 usingSSL:NO];
 
 [session publishData:[@"Sample Data" dataUsingEncoding:NSUTF8StringEncoding]
 topic:@"example/data"
 retain:YES
 qos:1];
 @endcode
 
 */

- (UInt16)publishData:(NSData *)data onTopic:(NSString *)topic retain:(BOOL)retainFlag qos:(MQTTQosLevel)qos;

/** publishes data on a given topic at a specified QoS level and retain flag
 
 @param data the data to be sent. length may range from 0 to 268,435,455 - 4 - _lengthof-topic_ bytes. Defaults to length 0.
 @param topic the Topic to identify the data
 @param retainFlag if YES, data is stored on the MQTT broker until overwritten by the next publish with retainFlag = YES
 @param qos specifies the Quality of Service for the publish
 qos can be 0, 1, or 2.
 
 
 @param publishHandler identifies a block which is executed on successfull or unsuccessfull connect. Might be nil
 error is nil in the case of a successful connect
 sessionPresent indicates in MQTT 3.1.1 if persistent session data was present at the server
 

 @return the Message Identifier of the PUBLISH message. Zero if qos 0. If qos 1 or 2, zero if message was dropped
 
 @note returns immediately. To check results, register as an MQTTSessionDelegate and watch for events.
 
 @code
 #import "MQTTClient.h"
 
 MQTTSession *session = [[MQTTSession alloc] init];
 
 [session connectToHost:@"192.168.0.1" port:1883 usingSSL:NO];
 
 [session publishData:[@"Sample Data" dataUsingEncoding:NSUTF8StringEncoding]
 topic:@"example/data"
 retain:YES
 qos:1];
 @endcode
 
 */

- (UInt16)publishData:(NSData *)data onTopic:(NSString *)topic retain:(BOOL)retainFlag qos:(MQTTQosLevel)qos publishHandler:(MQTTPublishHandler)publishHandler;

/** for mqttio-OBJC backward compatibility
 @param theData see publishData for description
 @param theTopic see publishData for description
  */
- (void)publishData:(NSData*)theData onTopic:(NSString*)theTopic;

/** for mqttio-OBJC backward compatibility
 @param theData see publishData for description
 @param theTopic see publishData for description
 */
- (void)publishDataAtLeastOnce:(NSData*)theData onTopic:(NSString*)theTopic;

/** for mqttio-OBJC backward compatibility
 @param theData see publishData for description
 @param theTopic see publishData for description
 @param retainFlag see publishData for description
 */
- (void)publishDataAtLeastOnce:(NSData*)theData onTopic:(NSString*)theTopic retain:(BOOL)retainFlag;

/** for mqttio-OBJC backward compatibility
 @param theData see publishData for description
 @param theTopic see publishData for description
 */
- (void)publishDataAtMostOnce:(NSData*)theData onTopic:(NSString*)theTopic;

/** for mqttio-OBJC backward compatibility
 @param theData see publishData for description
 @param theTopic see publishData for description
 @param retainFlag see publishData for description
 */
- (void)publishDataAtMostOnce:(NSData*)theData onTopic:(NSString*)theTopic retain:(BOOL)retainFlag;

/** for mqttio-OBJC backward compatibility
 @param theData see publishData for description
 @param theTopic see publishData for description
 */
- (void)publishDataExactlyOnce:(NSData*)theData onTopic:(NSString*)theTopic;

/** for mqttio-OBJC backward compatibility
 @param theData see publishData for description
 @param theTopic see publishData for description
 @param retainFlag see publishData for description
 */
- (void)publishDataExactlyOnce:(NSData*)theData onTopic:(NSString*)theTopic retain:(BOOL)retainFlag;

/** for mqttio-OBJC backward compatibility
 @param payload JSON payload is converted to NSData and then send. See publishData for description
 @param theTopic see publishData for description
 */
- (void)publishJson:(id)payload onTopic:(NSString*)theTopic;

/** publishes synchronously data on a given topic at a specified QoS level and retain flag
 
 @param data the data to be sent. length may range from 0 to 268,435,455 - 4 - _lengthof-topic_ bytes. Defaults to length 0.
 @param topic the Topic to identify the data
 @param retainFlag if YES, data is stored on the MQTT broker until overwritten by the next publish with retainFlag = YES
 @param qos specifies the Quality of Service for the publish
 qos can be 0, 1, or 2.
 @returns TRUE if the publish was successful
 
 @code
 #import "MQTTClient.h"
 
 MQTTSession *session = [[MQTTSession alloc] init];
 
 [session connectToHost:@"192.168.0.1" port:1883 usingSSL:NO];
 
 [session publishAndWaitData:[@"Sample Data" dataUsingEncoding:NSUTF8StringEncoding]
 topic:@"example/data"
 retain:YES
 qos:1];
 @endcode
 
 */

- (BOOL)publishAndWaitData:(NSData *)data onTopic:(NSString *)topic retain:(BOOL)retainFlag qos:(MQTTQosLevel)qos;

/** closes an MQTTSession gracefully
 
 If the connection was successfully established before, a DISCONNECT is sent.
 
 @param disconnectHandler identifies a block which is executed on successfull or unsuccessfull disconnect. Might be nil. error is nil in the case of a successful disconnect

 @code
 #import "MQTTClient.h"
 
 MQTTSession *session = [[MQTTSession alloc] init];
 
 [session connectToHost:@"192.168.0.1" port:1883 usingSSL:NO];
 
 ...
 
 [session closeWithDisconnectHandler^(NSError *error) {
    if (error) {
        NSLog(@"Error Disconnect %@", error.localizedDescription);
    }
    NSLog(@"Session closed");
 }];

 
 @endcode
 
 */
- (void)closeWithDisconnectHandler:(MQTTDisconnectHandler)disconnectHandler;

/** closes an MQTTSession gracefully
  */
- (void)close;

/** closes an MQTTSession gracefully synchronously
 
 If the connection was successfully established before, a DISCONNECT is sent.
 
 @code
 #import "MQTTClient.h"
 
 MQTTSession *session = [[MQTTSession alloc] init];
 
 [session connectToHost:@"192.168.0.1" port:1883 usingSSL:NO];
 
 ...
 
 [session closeAndWait];
 
 @endcode
 
 */
- (void)closeAndWait;

/** reads the content of a PKCS12 file and converts it to an certificates array for initWith...
 @param path the path to a PKCS12 file
 @param passphrase the passphrase to unlock the PKCS12 file
 @returns a certificates array or nil if an error occured
 
 @code
 NSString *path = [[NSBundle bundleForClass:[MQTTClientTests class]] pathForResource:@"filename"
 ofType:@"p12"];
 
 NSArray *myCerts = [MQTTSession clientCertsFromP12:path passphrase:@"passphrase"];
 if (myCerts) {
 
 self.session = [[MQTTSession alloc] initWithClientId:nil
    userName:nil
    password:nil
    keepAlive:60
    cleanSession:YES
    will:NO
    willTopic:nil
    willMsg:nil
    willQoS:0
    willRetainFlag:NO
    protocolLevel:4
    runLoop:[NSRunLoop currentRunLoop]
    forMode:NSRunLoopCommonModes
    securityPolicy:nil
    certificates:myCerts];
 [self.session connectToHost:@"localhost" port:8884 usingSSL:YES];
 ...
 }

 @endcode
 
 */

+ (NSArray *)clientCertsFromP12:(NSString *)path passphrase:(NSString *)passphrase;


@end
