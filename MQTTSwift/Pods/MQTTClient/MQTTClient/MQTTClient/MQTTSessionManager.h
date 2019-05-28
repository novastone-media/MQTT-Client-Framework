//
//  MQTTSessionManager.h
//  MQTTClient
//
//  Created by Christoph Krey on 09.07.14.
//  Copyright © 2013-2017 Christoph Krey. All rights reserved.
//

#import <Foundation/Foundation.h>
#if TARGET_OS_IPHONE == 1
#import <UIKit/UIKit.h>
#endif
#import "MQTTSession.h"
#import "MQTTSessionLegacy.h"
#import "MQTTSSLSecurityPolicy.h"

@class MQTTSessionManager;

/** delegate gives your application access to received messages
 */
@protocol MQTTSessionManagerDelegate <NSObject>

/**
 Enumeration of MQTTSessionManagerState values
 */
typedef NS_ENUM(int, MQTTSessionManagerState) {
    MQTTSessionManagerStateStarting,
    MQTTSessionManagerStateConnecting,
    MQTTSessionManagerStateError,
    MQTTSessionManagerStateConnected,
    MQTTSessionManagerStateClosing,
    MQTTSessionManagerStateClosed
};

@optional

/** gets called when a new message was received

 @param data the data received, might be zero length
 @param topic the topic the data was published to
 @param retained indicates if the data retransmitted from server storage
 */
- (void)handleMessage:(NSData *)data onTopic:(NSString *)topic retained:(BOOL)retained;

/** gets called when a new message was received
 @param sessionManager the instance of MQTTSessionManager whose state changed
 @param data the data received, might be zero length
 @param topic the topic the data was published to
 @param retained indicates if the data retransmitted from server storage
 */
- (void)sessionManager:(MQTTSessionManager *)sessionManager
     didReceiveMessage:(NSData *)data
               onTopic:(NSString *)topic
              retained:(BOOL)retained;

/** gets called when a published message was actually delivered
 @param msgID the Message Identifier of the delivered message
 @note this method is called after a publish with qos 1 or 2 only
 */
- (void)messageDelivered:(UInt16)msgID;

/** gets called when a published message was actually delivered
 @param sessionManager the instance of MQTTSessionManager whose state changed
 @param msgID the Message Identifier of the delivered message
 @note this method is called after a publish with qos 1 or 2 only
 */
- (void)sessionManager:(MQTTSessionManager *)sessionManager didDeliverMessage:(UInt16)msgID;

/** gets called when the connection status changes
 @param sessionManager the instance of MQTTSessionManager whose state changed
 @param newState the new connection state of the sessionManager. This will be identical to `sessionManager.state`.
 */
- (void)sessionManager:(MQTTSessionManager *)sessionManager didChangeState:(MQTTSessionManagerState)newState;

@end

/** SessionManager handles the MQTT session for your application
 */
@interface MQTTSessionManager : NSObject <MQTTSessionDelegate>

/** Underlying MQTTSession currently in use.
 */
@property (strong, nonatomic, readonly) MQTTSession *session;

/** host an NSString containing the hostName or IP address of the Server
 */
@property (readonly) NSString *host;

/** port an unsigned 32 bit integer containing the IP port number of the Server
 */
@property (readonly) UInt32 port;

/** the delegate receiving incoming messages
 */
@property (weak, nonatomic) id<MQTTSessionManagerDelegate> delegate;

/** indicates if manager requires tear down
 */
@property (readonly) BOOL requiresTearDown;

/** subscriptions is a dictionary of NSNumber instances indicating the MQTTQoSLevel.
 *  The keys are topic filters.
 *  The SessionManager subscribes to the given subscriptions after successfull (re-)connect
 *  according to the cleansession parameter and the state of the session as indicated by the broker.
 *  Setting a new subscriptions dictionary initiates SUBSCRIBE or UNSUBSCRIBE messages by SessionManager
 *  by comparing the old and new subscriptions.
 */
@property (strong, nonatomic) NSDictionary<NSString *, NSNumber *> *subscriptions;

/** effectiveSubscriptions s a dictionary of NSNumber instances indicating the granted MQTTQoSLevel, or 0x80 for subscription failure.
 *  The keys are topic filters.
 *  effectiveSubscriptions is observable and is updated everytime subscriptions change
 *  @code
        ...
        MQTTSessionManager *manager = [[MQTTSessionManager alloc] init];
        manager.delegate = self;
 
        [manager addObserver:self
            forKeyPath:@"effectiveSubscriptions"
            options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
            context:nil];
            manager.subscriptions = [@{@"#": @(0)} mutableCopy];
            [manager connectTo: ...
        ...
        [manager removeObserver:self forKeyPath:@"effectiveSubscriptions"];
        ...
 
    - (void)observeValueForKeyPath:(NSString *)keyPath
        ofObject:(id)object
        change:(NSDictionary<NSString *,id> *)change
        context:(void *)context {
        if ([keyPath isEqualToString:@"effectiveSubscriptions"]) {
            MQTTSessionManager *manager = (MQTTSessionManager *)object;
            DDLogVerbose(@"effectiveSubscriptions changed: %@", manager.effectiveSubscriptions);
        }
    }
 *  @endcode
 */
@property (readonly, strong, nonatomic) NSDictionary<NSString *, NSNumber *> *effectiveSubscriptions;

/** SessionManager status
 */
@property (nonatomic, readonly) MQTTSessionManagerState state;

/** SessionManager last error code when state equals MQTTSessionManagerStateError
 */
@property (nonatomic, readonly) NSError *lastErrorCode;

/** initWithPersistence sets the MQTTPersistence properties other than default
 * @param persistent YES or NO (default) to establish file or in memory persistence.
 * @param maxWindowSize (a positive number, default is 16) to control the number of messages sent before waiting for acknowledgement in Qos 1 or 2. Additional messages are stored and transmitted later.
 * @param maxSize (a positive number of bytes, default is 64 MB) to limit the size of the persistence file. Messages published after the limit is reached are dropped.
 * @param maxMessages (a positive number, default is 1024) to limit the number of messages stored. Additional messages published are dropped.
 * @param maxRetryInterval The duration at which the connection-retry timer should be capped. When MQTTSessionManager receives a ClosedByBroker or an Error
 event, it will attempt to reconnect to the broker. The time in between connection attempts is doubled each time, until it remains at maxRetryInterval.
 Defaults to 64 seconds.
 * @param connectInForeground Whether or not to connect the MQTTSession when the app enters the foreground, and disconnect when it becomes inactive. When NO, the caller is responsible for calling -connectTo: and -disconnect. Defaults to YES.
 * @param streamSSLLevel an NSString containing the security level for read and write streams
 * For list of possible values see:
 * https://developer.apple.com/documentation/corefoundation/cfstream/cfstream_socket_security_level_constants
 * Please also note that kCFStreamSocketSecurityLevelTLSv1_2 is not in a list
 * and cannot be used as constant, but you can use it as a string value
 * defaults to kCFStreamSocketSecurityLevelNegotiatedSSL
 * @param queue Queue for MQTTSession.
 * @return the initialized MQTTSessionManager object
 */

- (MQTTSessionManager *)initWithPersistence:(BOOL)persistent
                              maxWindowSize:(NSUInteger)maxWindowSize
                                maxMessages:(NSUInteger)maxMessages
                                    maxSize:(NSUInteger)maxSize
                 maxConnectionRetryInterval:(NSTimeInterval)maxRetryInterval
                        connectInForeground:(BOOL)connectInForeground
                             streamSSLLevel:(NSString *)streamSSLLevel
                                      queue:(dispatch_queue_t)queue NS_DESIGNATED_INITIALIZER;

/** Connects to the MQTT broker and stores the parameters for subsequent reconnects
 * @param host specifies the hostname or ip address to connect to. Defaults to @"localhost".
 * @param port specifies the port to connect to
 * @param tls specifies whether to use SSL or not
 * @param keepalive The Keep Alive is a time interval measured in seconds. The MQTTClient ensures that the interval between Control Packets being sent does not exceed the Keep Alive value. In the  absence of sending any other Control Packets, the Client sends a PINGREQ Packet.
 * @param clean specifies if the server should discard previous session information.
 * @param auth specifies the user and pass parameters should be used for authenthication
 * @param user an NSString object containing the user's name (or ID) for authentication. May be nil.
 * @param pass an NSString object containing the user's password. If userName is nil, password must be nil as well.
 * @param will indicates whether a will shall be sent
 * @param willTopic the Will Topic is a string, may be nil
 * @param willMsg the Will Message, might be zero length or nil
 * @param willQos specifies the QoS level to be used when publishing the Will Message.
 * @param willRetainFlag indicates if the server should publish the Will Messages with retainFlag.
 * @param clientId The Client Identifier identifies the Client to the Server. If nil, a random clientId is generated.
 * @param securityPolicy A custom SSL security policy or nil.
 * @param certificates An NSArray of the pinned certificates to use or nil.
 * @param protocolLevel Protocol version of the connection.
 * @param connectHandler Called when first connected or if error occurred. It is not called on subsequent internal reconnects.
 */

- (void)connectTo:(NSString *)host
             port:(NSInteger)port
              tls:(BOOL)tls
        keepalive:(NSInteger)keepalive
            clean:(BOOL)clean
             auth:(BOOL)auth
             user:(NSString *)user
             pass:(NSString *)pass
             will:(BOOL)will
        willTopic:(NSString *)willTopic
          willMsg:(NSData *)willMsg
          willQos:(MQTTQosLevel)willQos
   willRetainFlag:(BOOL)willRetainFlag
     withClientId:(NSString *)clientId
   securityPolicy:(MQTTSSLSecurityPolicy *)securityPolicy
     certificates:(NSArray *)certificates
    protocolLevel:(MQTTProtocolVersion)protocolLevel
   connectHandler:(MQTTConnectHandler)connectHandler;

/** Re-Connects to the MQTT broker using the parameters for given in the connectTo method
 */
- (void)connectToLast:(MQTTConnectHandler)connectHandler;

/** publishes data on a given topic at a specified QoS level and retain flag

 @param data the data to be sent. length may range from 0 to 268,435,455 - 4 - _lengthof-topic_ bytes. Defaults to length 0.
 @param topic the Topic to identify the data
 @param retainFlag if YES, data is stored on the MQTT broker until overwritten by the next publish with retainFlag = YES
 @param qos specifies the Quality of Service for the publish
 qos can be 0, 1, or 2.
 @return the Message Identifier of the PUBLISH message. Zero if qos 0. If qos 1 or 2, zero if message was dropped
 @note returns immediately.
 */
- (UInt16)sendData:(NSData *)data topic:(NSString *)topic qos:(MQTTQosLevel)qos retain:(BOOL)retainFlag;

/** Disconnects gracefully from the MQTT broker
 */
- (void)disconnectWithDisconnectHandler:(MQTTDisconnectHandler)disconnectHandler;

@end
