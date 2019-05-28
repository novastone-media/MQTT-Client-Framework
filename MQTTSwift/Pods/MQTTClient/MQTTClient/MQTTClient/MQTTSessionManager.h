//
//  MQTTSessionManager.h
//  MQTTClient
//
//  Created by Christoph Krey on 09.07.14.
//  Copyright © 2013-2016 Christoph Krey. All rights reserved.
//

#import <Foundation/Foundation.h>
#if TARGET_OS_IPHONE == 1
#import <UIKit/UIKit.h>
#endif
#import "MQTTSession.h"
#import "MQTTSessionLegacy.h"
#import "MQTTSSLSecurityPolicy.h"

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

/** gets called when a new message was received
 @param data the data received, might be zero length
 @param topic the topic the data was published to
 @param retained indicates if the data retransmitted from server storage
 */
- (void)handleMessage:(NSData *)data onTopic:(NSString *)topic retained:(BOOL)retained;

@optional

/** gets called when a published message was actually delivered
 @param msgID the Message Identifier of the delivered message
 @note this method is called after a publish with qos 1 or 2 only
 */
- (void)messageDelivered:(UInt16)msgID;
@end

/** SessionManager handles the MQTT session for your application
 */
@interface MQTTSessionManager : NSObject <MQTTSessionDelegate>

/** the delegate receiving incoming messages
 */
@property (weak, nonatomic) id<MQTTSessionManagerDelegate> delegate;

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
 * @return the initialized MQTTSessionManager object
 */

- (MQTTSessionManager *)initWithPersistence:(BOOL)persistent
                              maxWindowSize:(NSUInteger)maxWindowSize
                                maxMessages:(NSUInteger)maxMessages
                                    maxSize:(NSUInteger)maxSize;



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
     certificates:(NSArray *)certificates;

/** Convenience alternative to full paramter connectTo
 * @param host see connectTo description
 * @param port see connectTo description
 * @param tls see connectTo description
 * @param keepalive see connectTo description
 * @param clean see connectTo description
 * @param auth see connectTo description
 * @param user see connectTo description
 * @param pass see connectTo description
 * @param will see connectTo description
 * @param willTopic see connectTo description
 * @param willMsg see connectTo description
 * @param willQos see connectTo description
 * @param willRetainFlag see connectTo description
 * @param clientId see connectTo description
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
     withClientId:(NSString *)clientId;

/** Convenience alternative to full paramter connectTo
 * @param host see connectTo description
 * @param port see connectTo description
 * @param tls see connectTo description
 * @param keepalive see connectTo description
 * @param clean see connectTo description
 * @param auth see connectTo description
 * @param user see connectTo description
 * @param pass see connectTo description
 * @param willTopic the Will Topic is a string, must not be nil
 * @param will the Will Message, might be zero length
 * @param willQos see connectTo description
 * @param willRetainFlag see connectTo description
 * @param clientId see connectTo description
 */

- (void)connectTo:(NSString *)host
                  port:(NSInteger)port
                   tls:(BOOL)tls
             keepalive:(NSInteger)keepalive
                 clean:(BOOL)clean
                  auth:(BOOL)auth
                  user:(NSString *)user
                  pass:(NSString *)pass
             willTopic:(NSString *)willTopic
                  will:(NSData *)will
               willQos:(MQTTQosLevel)willQos
        willRetainFlag:(BOOL)willRetainFlag
          withClientId:(NSString *)clientId;

/** Re-Connects to the MQTT broker using the parameters for given in the connectTo method
 */
- (void)connectToLast;

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
- (void)disconnect;

@end
