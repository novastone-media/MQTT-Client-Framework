//
// MQTTSession.h
// MQTTClient.framework
//
// Copyright (c) 2013, 2014, Christoph Krey
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
 
 @author Christoph Krey krey.christoph@gmail.com
 @see http://mqtt.org
 */


#import <Foundation/Foundation.h>
#import "MQTTDecoder.h"
#import "MQTTEncoder.h"

/**
 Enumeration of MQTTSession states
 */
typedef enum {
    MQTTSessionStatusCreated,
    MQTTSessionStatusConnecting,
    MQTTSessionStatusConnected,
    MQTTSessionStatusDisconnecting,
    MQTTSessionStatusClosed,
    MQTTSessionStatusError
} MQTTSessionStatus;

/**
 Enumeration of MQTTSession events
 */
typedef enum {
    MQTTSessionEventConnected,
    MQTTSessionEventConnectionRefused,
    MQTTSessionEventConnectionClosed,
    MQTTSessionEventConnectionError,
    MQTTSessionEventProtocolError
} MQTTSessionEvent;

@class MQTTSession;

@protocol MQTTSessionDelegate <NSObject>

- (void)handleEvent:(MQTTSession *)session event:(MQTTSessionEvent)eventCode error:(NSError *)error;
- (void)newMessage:(MQTTSession *)session
              data:(NSData *)data
           onTopic:(NSString *)topic
               qos:(int)qos
          retained:(BOOL)retained
               mid:(unsigned int)mid;

@optional
- (void)messageDelivered:(MQTTSession *)session msgID:(UInt16)msgID;
- (void)subAckReceived:(MQTTSession *)session msgID:(UInt16)msgID grantedQoss:(NSArray *)qoss;
- (void)unsubAckReceived:(MQTTSession *)session msgID:(UInt16)msgID;
- (void)sending:(int)type qos:(int)qos retained:(BOOL)retained duped:(BOOL)duped mid:(UInt16)mid data:(NSData *)data;
- (void)received:(int)type qos:(int)qos retained:(BOOL)retained duped:(BOOL)duped mid:(UInt16)mid data:(NSData *)data;
- (void)buffered:(MQTTSession *)session
          queued:(NSUInteger)queued
       flowingIn:(NSUInteger)flowingIn
      flowingOut:(NSUInteger)flowingOut;

@end

@interface MQTTSession : NSObject

@property (weak, nonatomic) id<MQTTSessionDelegate> delegate;
/**
 initialises the session with default values
 */
- (MQTTSession *)init;

/**
 initialises the session
 @param clientId The Client Identifier (ClientId) identifies the Client to the Server.
 
    Each Client connecting to the Server has a unique ClientId. The ClientId MUST be used by Clients and by Servers to identify
    state that they hold relating to this MQTT Session between the Client and the Server. [MQTT-3.1.3-2]
 
    The Client Identifier (ClientId) MUST be present and MUST be the first field in the payload. [MQTT-3.1.3-3]
 
    The ClientId MUST comprise only Unicode [Unicode63] characters, and the length of the UTF-8 encoding MUST be at least zero
    bytes and no more than 65535 bytes. [MQTT-3.1.3-4]
 
    The Server MAY restrict the ClientId it allows in terms of their lengths and the characters they contain,.The Server MUST
    allow ClientIds which are between 1 and 23 UTF-8 encoded bytes in length, and that contain only the characters
    "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ". [MQTT-3.1.3-5]
 
    A Server MAY allow a Client to supply a ClientId that has a length of zero bytes. However if it does so the Server MUST
    treat this as a special case and assign a unique ClientId to that Client. It MUST then process the CONNECT packet as if
    the Client had provided that unique ClientId. [MQTT-3.1.3-6]
 
    If the Client supplies a zero-byte ClientId, the Client MUST also set Clean Session to 1. [MQTT-3.1.3-7]
 
    If no clientID is specified (nil), a random clientID is generated.

 @param userName an NSString object containing the user's name (or ID)
 
    The userName MUST comprise only Unicode [Unicode63] characters, and the length of the UTF-8 encoding MUST be at least zero
    bytes and no more than 65535 bytes.

    userName may be nil.
 
 @param password an NSString object containing the user's password.
 
    The password MUST comprise only Unicode [Unicode63] characters, and the length of the UTF-8 encoding MUST be at least zero
    bytes and no more than 65535 bytes.
 
    if no userName is nil, password must be nil as well
 
 @param keepAliveInterval The Keep Alive is a time interval measured in seconds. It is the maximum time interval that is permitted to elapse between two successive Control Packets sent by the Client.
 
    The MQTTClient eensures that the interval between Control Packets being sent does not exceed the Keep Alive value. In the
    absence of sending any other Control Packets, the Client sends a PINGREQ Packet [MQTT-3.1.2-21].
 
    If the Server does not receive a Control Packet from the Client within one and a half times the Keep Alive time period,
    it MUST disconnect the Network Connection to the Client as if the network had failed. [MQTT-3.1.2-22]
 
    If a Client does not receive a PINGRESP Packet within a reasonable amount of time after it has sent a PINGREQ, it SHOULD close
    the Network Connection to the Server.
 
    A Keep Alive value of zero (0) has the effect of turning off the keep alive mechanism. This means that, in this case, the Server
    is NOT REQUIRED to disconnect the Client on the grounds of inactivity.
    Note that a Server MAY choose to disconnect a Client that it determines to be inactive or non-responsive at any time,
    regardless of the Keep Alive value provided by that Client.
 
    The actual value of the Keep Alive is application-specific, typically this is a few minutes. The maximum value is
    18 hours 12 minutes and 15 seconds.
 
 @param cleanSessionFlag specifies if the server should discard previous session information.
 
    If set to NO, the Server resumes communications with the Client based on state from the current Session
    (as identified by the Client identifier). If there is no Session associated with the Client identifier the
    Server creates a new Session. The Client and Server MUST store the Session after the Client and Server are
    disconnected [MQTT-3.1.2-4]. After disconnection, the Server MUST store further QoS 1 and QoS 2 messages that
    match any subscriptions that the client had at the time of disconnection as part of the Session state [MQTT-3.1.2-5].
    It MAY also store QoS 0 messages that meet the same criteria.
 
    If set to YES, the Client and Server MUST discard any previous Session and start a new one. This Session lasts as long as
    the Network Connection. State data associated with this session MUST NOT be reused in any subsequent Session [MQTT-3.1.2-6].
 
    The Session state in the Client consists of:
    *   QoS 1 and QoS 2 messages for which transmission to the Server is incomplete.
    *   The Client MAY store QoS 0 messages for later transmission.
 
    The Session state in the Server consists of:
    *   The Client’s subscriptions.
    *   All QoS 1 and QoS 2 messages for which transmission to the Client is incomplete or where transmission
        to the Client has not yet been started.
    *   The Server MAY store QoS 0 messages for which transmission to the Client has not yet been started.
 
    Retained publications do not form part of the Session state in the Server, they MUST NOT be deleted when
    the Session ends [MQTT-3.1.2.7].
 
 
    Typically, a Client will always connect using CleanSession NO or CleanSession YES and not swap between the two values.
    The choice will depend on the application. A Client using CleanSession YES will not receive old publications and has
    to subscribe afresh to any topics that it is interested in each time it connects. A Client using CleanSession NO will
    receive all QoS 1 or QoS 2 messages that were published whilst it was disconnected. Hence, to ensure that you do not
    lose messages while disconnected, use QoS 1 or QoS 2 with CleanSession NO.

    When a Client connects with cleanSession = NO it is requesting that the Server maintain its MQTT session state after it
    disconnects. Clients should only connect with cleanSession = NO if they intend to reconnect to the Server at some later
    point in time. When a Client has determined that it has no further use for the session it should do a final connect
    with cleanSession = YES and then disconnect.

 @param willFlag If the Will Flag is set to YES this indicates that a Will Message MUST be published by the Server when the
        Server detects that the Client is disconnected for any reason other than the Client flowing a DISCONNECT Packet [MQTT-3.1.2-8].
 
    This includes, but is not limited to, the flowing situations:
    *   An I/O error or network failure detected by the Server.
    *    The Client fails to communicate within the Keep Alive time.
    *    The Client closes the Network Connection without first sending a DISCONNECT Packet.
    *    The Server closes the Network Connection because of a protocol error.
 
    If the Will Flag is set to YES, the Will QoS and Will Retain fields in the Connect Flags will be used by the Server,
    and the Will Topic and Will Message fields MUST be present in the payload [MQTT-3.1.2-9].
 
    The will message MUST be removed from the stored Session state in the Server once it has been published or the Server
    has received a DISCONNECT packet from the Client. If the Will Flag is set to NO, no will message is published. [MQTT-3.1.2-10]

 @param willTopic If the Will Flag is set to YES, the Will Topic is a UTF-8 encoded string, nil otherwise.
 
 @param willMsg If the Will Flag is set to YES the Will Message must be specified, nil otherwise.

    The Will Message defines the Application Message that is to be published to the Will Topic if the Client is disconnected
    for any reason other than the Client sending a DISCONNECT Packet.
 
 @param willQoS specifies the QoS level to be used when publishing the Will Message.
 
    If the Will Flag is set to NO, then the Will QoS MUST be set to 0  (0x00) [MQTT-3.1.2-11].
    If the Will Flag is set to YES, the value of Will QoS can be 0 (0x00), 1 (0x01), or 2 (0x02). [MQTT-3.1.2-12].

 @param willRetainFlag indicates if the server should publish the Will Messages with retainFlag
 
    If the Will Flag is set to NO, then the Will Retain Flag MUST be set to NO [MQTT-3.1.2-13].
 
    If the Will Flag is set to YES:
        If Will Retain is set to NO, the Server MUST publish the Will Message as a non-retained publication [MQTT-3.1.2-14].
        If Will Retain is set to YES, the Server MUST publish the Will Message as a retained publication [MQTT-3.1.2-15].
 
 @param protocolLevel specifies the protocol to be used.
    The value of the Protocol Level field for the version 3.1.1 of the protocol is 4. The value for the version 3.1 is 3.
 @param runLoop
 @param runLoopMode
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
                          willQoS:(UInt8)willQoS
                   willRetainFlag:(BOOL)willRetainFlag
                    protocolLevel:(UInt8)protocolLevel
                          runLoop:(NSRunLoop *)runLoop
                          forMode:(NSString *)runLoopMode;

/**
 connects to the specified MQTT server
 
 @param host specifies the hostname or ip address to connect to
 @param port spefies the port to connect to
 @param usingSSL specifies whether to use SSL or not
 
 @returns nothing and returns immediately. To check the connect results, register as an MQTTSessionDelegate and watch for events.
 
 */
- (void)connectToHost:(NSString *)host port:(UInt32)port usingSSL:(BOOL)usingSSL;

/**
 subscribes to a topic at a specific QoS level
 
 @param topic
 @param qosLevel
 @return
 */

- (UInt16)subscribeToTopic:(NSString *)topic atLevel:(UInt8)qosLevel;


/**
 unsubscribes from a number of topics
 
 @param topics
 */


- (UInt16)subscribeToTopics:(NSDictionary *)topics;

/**
 unsubscribes from a topic
 
 @param topic
 */

- (UInt16)unsubscribeTopic:(NSString *)topic;

/**
 unsubscribes from a number of topics
 
 @param topics
 */

- (UInt16)unsubscribeTopics:(NSArray *)topics;

/**
 publises data on a given topic at a specified QoS level and retain flag
 
 @param data
 @param topic
 @param retainFlag
 @param qos
 */

- (UInt16)publishData:(NSData *)data onTopic:(NSString *)topic retain:(BOOL)retainFlag qos:(NSInteger)qos;

/**
 closes an MQTTSession gracefully
 
 If the connection was successfully established before, a DISCONNECT is sent.
 */
- (void)close;

@end
