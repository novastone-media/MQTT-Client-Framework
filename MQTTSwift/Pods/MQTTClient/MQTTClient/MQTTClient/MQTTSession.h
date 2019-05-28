//
// MQTTSession.h
// MQTTClient.framework
//

/**
 Using MQTT in your Objective-C application
 
 @author Christoph Krey c@ckrey.de
 @copyright Copyright © 2013-2017, Christoph Krey. All rights reserved.
 
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
#import "MQTTTransport.h"

@class MQTTSession;
@class MQTTSSLSecurityPolicy;

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

/**
 The error domain used for all errors created by MQTTSession
 */
extern NSString * const MQTTSessionErrorDomain;

/**
 The error codes used for all errors created by MQTTSession
 */
typedef NS_ENUM(NSInteger, MQTTSessionError) {
    MQTTSessionErrorConnectionRefused = -8, // Sent if the server closes the connection without sending an appropriate error CONNACK
    MQTTSessionErrorIllegalMessageReceived = -7,
    MQTTSessionErrorDroppingOutgoingMessage = -6, // For some reason the value is the same as for MQTTSessionErrorNoResponse
    MQTTSessionErrorNoResponse = -6, // For some reason the value is the same as for MQTTSessionErrorDroppingOutgoingMessage
    MQTTSessionErrorEncoderNotReady = -5,
    MQTTSessionErrorInvalidConnackReceived = -2, // Sent if the message received from server was an invalid connack message
    MQTTSessionErrorNoConnackReceived = -1, // Sent if first message received from server was no connack message

    MQTTSessionErrorConnackUnacceptableProtocolVersion = 1, // Value as defined by MQTT Protocol
    MQTTSessionErrorConnackIdentifierRejected = 2, // Value as defined by MQTT Protocol
    MQTTSessionErrorConnackServeUnavailable = 3, // Value as defined by MQTT Protocol
    MQTTSessionErrorConnackBadUsernameOrPassword = 4, // Value as defined by MQTT Protocol
    MQTTSessionErrorConnackNotAuthorized = 5, // Value as defined by MQTT Protocol
    MQTTSessionErrorConnackReserved = 6, // Should be value 6-255, as defined by MQTT Protocol
};

/** Session delegate gives your application control over the MQTTSession
 @note all callback methods are optional
 */

@protocol MQTTSessionDelegate <NSObject>

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

/** gets called when a published message was actually delivered
 @param session the MQTTSession reporting the delivery
 @param msgID the Message Identifier of the delivered message
 @param topic the topic of the delivered message
 @param data the data Identifier of the delivered message
 @param qos the QoS level of the delivered message
 @param retainFlag the retain Flag of the delivered message
 @note this method is called after a publish with qos 1 or 2 only
 */
- (void)messageDelivered:(MQTTSession *)session
                   msgID:(UInt16)msgID
                   topic:(NSString *)topic
                    data:(NSData *)data
                     qos:(MQTTQosLevel)qos
              retainFlag:(BOOL)retainFlag;

/** gets called when a subscription is acknowledged by the MQTT broker
 @param session the MQTTSession reporting the acknowledge
 @param msgID the Message Identifier of the SUBSCRIBE message
 @param qoss an array containing the granted QoS(s) related to the SUBSCRIBE message
    (see subscribeTopic, subscribeTopics)
 */
- (void)subAckReceived:(MQTTSession *)session msgID:(UInt16)msgID grantedQoss:(NSArray<NSNumber *> *)qoss;

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
- (void)sending:(MQTTSession *)session type:(MQTTCommandType)type qos:(MQTTQosLevel)qos retained:(BOOL)retained duped:(BOOL)duped mid:(UInt16)mid data:(NSData *)data;

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
- (void)received:(MQTTSession *)session type:(MQTTCommandType)type qos:(MQTTQosLevel)qos retained:(BOOL)retained duped:(BOOL)duped mid:(UInt16)mid data:(NSData *)data;

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
- (BOOL)ignoreReceived:(MQTTSession *)session type:(MQTTCommandType)type qos:(MQTTQosLevel)qos retained:(BOOL)retained duped:(BOOL)duped mid:(UInt16)mid data:(NSData *)data;

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
typedef void (^MQTTSubscribeHandler)(NSError *error, NSArray<NSNumber *> *gQoss);
typedef void (^MQTTUnsubscribeHandler)(NSError *error);
typedef void (^MQTTPublishHandler)(NSError *error);

/** Session implements the MQTT protocol for your application
 *
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
@property (strong, nonatomic) id<MQTTPersistence> persistence;

/** block called once when connection is established
 */
@property (copy, nonatomic) MQTTConnectHandler connectHandler;

/** block called when connection is established
 */
@property (strong) void (^connectionHandler)(MQTTSessionEvent event);

/** block called when message is received
 */
@property (strong) void (^messageHandler)(NSData* message, NSString* topic);

/** Session status
 */
@property (nonatomic, readonly) MQTTSessionStatus status;

/** Indicates if the broker found a persistent session when connecting with cleanSession:FALSE
 */
@property (nonatomic, readonly) BOOL sessionPresent;

/** streamSSLLevel an NSString containing the security level for read and write streams
 * For list of possible values see:
 * https://developer.apple.com/documentation/corefoundation/cfstream/cfstream_socket_security_level_constants
 * Please also note that kCFStreamSocketSecurityLevelTLSv1_2 is not in a list
 * and cannot be used as constant, but you can use it as a string value
 * defaults to kCFStreamSocketSecurityLevelNegotiatedSSL
 */
@property (strong, nonatomic) NSString *streamSSLLevel;

/** host an NSString containing the hostName or IP address of the Server
 */
@property (readonly) NSString *host;

/** port an unsigned 32 bit integer containing the IP port number of the Server
 */
@property (readonly) UInt32 port;

/** The Client Identifier identifies the Client to the Server. If nil, a random clientId is generated.
 */
@property (strong, nonatomic) NSString *clientId;

/** see userName an NSString object containing the user's name (or ID) for authentication. May be nil. */
@property (strong, nonatomic) NSString *userName;

/** see password an NSString object containing the user's password. If userName is nil, password must be nil as well.*/
@property (strong, nonatomic) NSString *password;

/** see keepAliveInterval The Keep Alive is a time interval measured in seconds.
 * The MQTTClient ensures that the interval between Control Packets being sent does not exceed
 * the Keep Alive value. In the  absence of sending any other Control Packets, the Client sends a PINGREQ Packet.
 */
@property (nonatomic) UInt16 keepAliveInterval;

/** The serverKeepAlive is a time interval measured in seconds.
 *  This value may be set by the broker and overrides keepAliveInterval if present
 *  Zero means the broker does not perform any keep alive checks
 */
@property (readonly, strong, nonatomic) NSNumber *serverKeepAlive;

/** effectiveKeepAlive is a time interval measured in seconds
 *  It indicates the effective keep alive interval after a successfull connect
 *  where keepAliveInterval might have been overridden by the broker.
 */
@property (readonly, nonatomic) UInt16 effectiveKeepAlive;


/**
 * dupTimeout If PUBACK or PUBREC not received, message will be resent after this interval
 */
@property (nonatomic) double dupTimeout;

/** leanSessionFlag specifies if the server should discard previous session information. */
@property (nonatomic) BOOL cleanSessionFlag;

/** willFlag If the Will Flag is set to YES this indicates that
 * a Will Message MUST be published by the Server when the Server detects
 * that the Client is disconnected for any reason other than the Client flowing a DISCONNECT Packet.
 */
@property (nonatomic) BOOL willFlag;

/** willTopic If the Will Flag is set to YES, the Will Topic is a string, nil otherwise. */
@property (strong, nonatomic) NSString *willTopic;

/** willMsg If the Will Flag is set to YES the Will Message must be specified, nil otherwise. */
@property (strong, nonatomic) NSData *willMsg;

/** willQoS specifies the QoS level to be used when publishing the Will Message.
 * If the Will Flag is set to NO, then the Will QoS MUST be set to 0.
 * If the Will Flag is set to YES, the Will QoS MUST be a valid MQTTQosLevel.
 */
@property (nonatomic) MQTTQosLevel willQoS;

/** willRetainFlag indicates if the server should publish the Will Messages with retainFlag.
 * If the Will Flag is set to NO, then the Will Retain Flag MUST be set to NO .
 * If the Will Flag is set to YES: If Will Retain is set to NO, the Serve
 * MUST publish the Will Message as a non-retained publication [MQTT-3.1.2-14].
 * If Will Retain is set to YES, the Server MUST publish the Will Message as a retained publication [MQTT-3.1.2-15].
 */
@property (nonatomic) BOOL willRetainFlag;

/** protocolLevel specifies the protocol to be used */
@property (nonatomic) MQTTProtocolVersion protocolLevel;

/** sessionExpiryInterval specifies the number of seconds after which a session should expire MQTT v5.0*/
@property (strong, nonatomic) NSNumber *sessionExpiryInterval;

/** authMethod specifies the number of seconds after which a session should expire MQTT v5.0*/
@property (strong, nonatomic) NSString *authMethod;

/** authData specifies the number of seconds after which a session should expire MQTT v5.0*/
@property (strong, nonatomic) NSData *authData;

/** requestProblemInformation specifies the number of seconds after which a session should expire MQTT v5.0*/
@property (strong, nonatomic) NSNumber *requestProblemInformation;

/** willDelayInterval specifies the number of seconds after which a session should expire MQTT v5.0*/
@property (strong, nonatomic) NSNumber *willDelayInterval;

/** requestResponseInformation specifies the number of seconds after which a session should expire MQTT v5.0*/
@property (strong, nonatomic) NSNumber *requestResponseInformation;

/** receiveMaximum specifies the number of seconds after which a session should expire MQTT v5.0*/
@property (strong, nonatomic) NSNumber *receiveMaximum;

/** topicAliasMaximum specifies the number of seconds after which a session should expire MQTT v5.0*/
@property (strong, nonatomic) NSNumber *topicAliasMaximum;

/** topicAliasMaximum specifies the number of seconds after which a session should expire MQTT v5.0*/
@property (strong, nonatomic) NSDictionary <NSString *, NSString*> *userProperty;

/** maximumPacketSize specifies the number of seconds after which a session should expire MQTT v5.0*/
@property (strong, nonatomic) NSNumber *maximumPacketSize;

/** queue The queue where the streams are scheduled. */
@property (strong, nonatomic) dispatch_queue_t queue;


/** for mqttio-OBJC backward compatibility
 the connect message used is stored here
 */
@property (strong, nonatomic) MQTTMessage *connectMessage;

/** the transport provider for MQTTClient
 *
 * assign an in instance of a class implementing the MQTTTransport protocol e.g.
 * MQTTCFSocketTransport before connecting.
 */
@property (strong, nonatomic) id <MQTTTransport> transport;

/** certificates an NSArray holding client certificates or nil */
@property (strong, nonatomic) NSArray *certificates;

/** Require for VoIP background service
 * defaults to NO
 */
@property (nonatomic) BOOL voip;

/** connect to the given host through the given transport with the given
 *  MQTT session parameters asynchronously
 *
 */


- (void)connect;

/** connects to the specified MQTT server
 
 @param connectHandler identifies a block which is executed on successfull or unsuccessfull connect. Might be nil
 error is nil in the case of a successful connect
 sessionPresent indicates in MQTT 3.1.1 if persistent session data was present at the server
 returns nothing and returns immediately. To check the connect results, register as an MQTTSessionDelegate and
 - watch for events
 - watch for connect or connectionRefused messages
 - watch for error messages
 or use the connectHandler block
 
 @code
 #import "MQTTClient.h"
 
 MQTTSession *session = [[MQTTSession alloc] init];
 ...
 [session connectWithConnectHandler:^(NSError *error, BOOL sessionPresent) {
 if (error) {
 NSLog(@"Error Connect %@", error.localizedDescription);
 } else {
 NSLog(@"Connected sessionPresent:%d", sessionPresent);
 }
 }];
 @endcode
 
 */

- (void)connectWithConnectHandler:(MQTTConnectHandler)connectHandler;


/** disconnect gracefully
 *
 */
- (void)disconnect;

/** disconnect V5
 *  @param returnCode the returncode send to the broker
 *  @param sessionExpiryInterval the time in seconds before the session can be deleted
 *  @param reasonString a string explaining the reason
 *  @param userProperty additional dictionary of user key/value combinations
 */
- (void)disconnectWithReturnCode:(MQTTReturnCode)returnCode
           sessionExpiryInterval:(NSNumber *)sessionExpiryInterval
                    reasonString:(NSString *)reasonString
                    userProperty:(NSDictionary <NSString *, NSString *> *)userProperty;


/** initialises the MQTT session with default values
 @return the initialised MQTTSession object
 @code
 #import "MQTTClient.h"
 
 MQTTSession *session = [[MQTTSession alloc] init];
 @endcode
 */
- (MQTTSession *)init;



/** subscribes to a topic at a specific QoS level
 
 @param topic see subscribeToTopic:atLevel:subscribeHandler: for description
 @param qosLevel  see subscribeToTopic:atLevel:subscribeHandler: for description
 @return the Message Identifier of the SUBSCRIBE message.
 
 @note returns immediately. To check results, register as an MQTTSessionDelegate and watch for events.
 
 @code
 #import "MQTTClient.h"
 
 MQTTSession *session = [[MQTTSession alloc] init];
 ...
 [session connect];
 ...
 [session subscribeToTopic:@"example/#" atLevel:2];
 
 @endcode
 
 */

- (UInt16)subscribeToTopic:(NSString *)topic
                   atLevel:(MQTTQosLevel)qosLevel;
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
 ...
 [session connect];
 ...
 [session subscribeToTopic:@"example/#" atLevel:2 subscribeHandler:^(NSError *error, NSArray<NSNumber *> *gQoss){
    if (error) {
        NSLog(@"Subscription failed %@", error.localizedDescription);
    } else {
        NSLog(@"Subscription sucessfull! Granted Qos: %@", gQoss);
    }
 }];
 
 @endcode
 
 */

- (UInt16)subscribeToTopic:(NSString *)topic
                   atLevel:(MQTTQosLevel)qosLevel
          subscribeHandler:(MQTTSubscribeHandler)subscribeHandler;

/** subscribes a number of topics
 
 @param topics an NSDictionary<NSString *, NSNumber *> containing the Topic Filters to subscribe to as keys and
    the corresponding QoS as NSNumber values
 
 @return the Message Identifier of the SUBSCRIBE message.
 
 @note returns immediately. To check results, register as an MQTTSessionDelegate and watch for events.
 
 @code
 #import "MQTTClient.h"
 
 MQTTSession *session = [[MQTTSession alloc] init];
 ...
 [session connect];
 
 [session subscribeToTopics:@{
 @"example/#": @(0),
 @"example/status": @(2),
 @"other/#": @(1)
 }];
 
 @endcode
 */


- (UInt16)subscribeToTopics:(NSDictionary<NSString *, NSNumber *> *)topics;

/** subscribes a number of topics
 
 @param topics an NSDictionary<NSString *, NSNumber *> containing the Topic Filters to subscribe to as keys and
    the corresponding QoS as NSNumber values
 @param subscribeHandler identifies a block which is executed on successfull or unsuccessfull subscription.
    Might be nil. error is nil in the case of a successful subscription. In this case gQoss represents an
    array of grantes Qos
 
 @return the Message Identifier of the SUBSCRIBE message.
 
 @note returns immediately. To check results, register as an MQTTSessionDelegate and watch for events.
 
 @code
 #import "MQTTClient.h"
 
 MQTTSession *session = [[MQTTSession alloc] init];
 ...
 [session connect];
 
 [session subscribeToTopics:@{
    @"example/#": @(0),
    @"example/status": @(2),
    @"other/#": @(1)
 } subscribeHandler:^(NSError *error, NSArray<NSNumber *> *gQoss){
    if (error) {
        NSLog(@"Subscription failed %@", error.localizedDescription);
    } else {
        NSLog(@"Subscription sucessfull! Granted Qos: %@", gQoss);
    }
 }];

 
 @endcode
 */


- (UInt16)subscribeToTopics:(NSDictionary<NSString *, NSNumber *> *)topics
           subscribeHandler:(MQTTSubscribeHandler)subscribeHandler;

/** unsubscribes from a topic
 
 @param topic the Topic Filter to unsubscribe from.

 @return the Message Identifier of the UNSUBSCRIBE message.
 
 @note returns immediately. To check results, register as an MQTTSessionDelegate and watch for events.
 
 @code
 #import "MQTTClient.h"
 
 MQTTSession *session = [[MQTTSession alloc] init];
 ...
 [session connect];
 
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


- (UInt16)unsubscribeTopic:(NSString *)topic
        unsubscribeHandler:(MQTTUnsubscribeHandler)unsubscribeHandler;

/** unsubscribes from a number of topics
 
 @param topics an NSArray<NSString *> of topics to unsubscribe from
 
 @return the Message Identifier of the UNSUBSCRIBE message.
 
 @note returns immediately. To check results, register as an MQTTSessionDelegate and watch for events.
 
 @code
 #import "MQTTClient.h"
 
 MQTTSession *session = [[MQTTSession alloc] init];
 ...
 [session connect];
 
 [session unsubscribeTopics:@[
 @"example/#",
 @"example/status",
 @"other/#"
 ]];
 
 @endcode
 
 */

- (UInt16)unsubscribeTopics:(NSArray<NSString *> *)topics;

/** unsubscribes from a number of topics
 
 @param topics an NSArray<NSString *> of topics to unsubscribe from
 
 @param unsubscribeHandler identifies a block which is executed on successfull or unsuccessfull subscription.
    Might be nil. error is nil in the case of a successful subscription. In this case gQoss represents an
    array of grantes Qos
 
 @return the Message Identifier of the UNSUBSCRIBE message.
 
 @note returns immediately.
 
 */
- (UInt16)unsubscribeTopics:(NSArray<NSString *> *)topics
         unsubscribeHandler:(MQTTUnsubscribeHandler)unsubscribeHandler;

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
 ...
 [session connect];
 
 [session publishData:[@"Sample Data" dataUsingEncoding:NSUTF8StringEncoding]
 topic:@"example/data"
 retain:YES
 qos:1];
 @endcode
 
 */

- (UInt16)publishData:(NSData *)data
              onTopic:(NSString *)topic
               retain:(BOOL)retainFlag
                  qos:(MQTTQosLevel)qos;

/** publishes data on a given topic at a specified QoS level and retain flag
 
 @param data the data to be sent. length may range from 0 to 268,435,455 - 4 - _lengthof-topic_ bytes. Defaults to length 0.
 @param topic the Topic to identify the data
 @param retainFlag if YES, data is stored on the MQTT broker until overwritten by the next publish with retainFlag = YES
 @param qos specifies the Quality of Service for the publish
 qos can be 0, 1, or 2.
 
 
 @param publishHandler identifies a block which is executed on successfull or unsuccessfull publsh. Might be nil
 error is nil in the case of a successful connect
 sessionPresent indicates in MQTT 3.1.1 if persistent session data was present at the server
 

 @return the Message Identifier of the PUBLISH message. Zero if qos 0. If qos 1 or 2, zero if message was dropped
 
 @note returns immediately. To check results, register as an MQTTSessionDelegate and watch for events.
 
 @code
 #import "MQTTClient.h"
 
 MQTTSession *session = [[MQTTSession alloc] init];
 ...
 [session connect];
 
 [session publishData:[@"Sample Data" dataUsingEncoding:NSUTF8StringEncoding]
 topic:@"example/data"
 retain:YES
 qos:1
 publishHandler:^(NSError *error){
 if (error) {
 DDLogVerbose(@"error: %@ %@", error.localizedDescription, payload);
 } else {
 DDLogVerbose(@"delivered:%@", payload);
 delivered++;
 }
 }];
 @endcode
 
 */

- (UInt16)publishData:(NSData *)data
              onTopic:(NSString *)topic
               retain:(BOOL)retainFlag
                  qos:(MQTTQosLevel)qos
       publishHandler:(MQTTPublishHandler)publishHandler;

/** closes an MQTTSession gracefully
 
 If the connection was successfully established before, a DISCONNECT is sent.
 
 @param disconnectHandler identifies a block which is executed on successfull or unsuccessfull disconnect. Might be nil. error is nil in the case of a successful disconnect

 @code
 #import "MQTTClient.h"
 
 MQTTSession *session = [[MQTTSession alloc] init];
 ...
 [session connect];
 
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

/** close V5
 *  @param returnCode the returncode send to the broker
 *  @param sessionExpiryInterval the time in seconds before the session can be deleted
 *  @param reasonString a string explaining the reason
 *  @param userProperty additional dictionary of user key/value combinations
 *  @param disconnectHandler will be called when the disconnect finished
 */
- (void)closeWithReturnCode:(MQTTReturnCode)returnCode
      sessionExpiryInterval:(NSNumber *)sessionExpiryInterval
               reasonString:(NSString *)reasonString
               userProperty:(NSDictionary <NSString *, NSString *> *)userProperty
          disconnectHandler:(MQTTDisconnectHandler)disconnectHandler;

@end
