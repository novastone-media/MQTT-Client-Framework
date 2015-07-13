//
//  MQTTSessionManager.h
//  MQTTClient
//
//  Created by Christoph Krey on 09.07.14.
//  Copyright (c) 2013-2015 Christoph Krey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "MQTTSession.h"

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
@end

/** SessionManager handles the MQTT session for your application
 */
@interface MQTTSessionManager : NSObject <MQTTSessionDelegate>

/** the delegate receiving incoming messages
 */
@property (weak, nonatomic) id<MQTTSessionManagerDelegate> delegate;

/** subscriptions as a dictionary of NSNumber instances indicating the MQTTQoSLevel.
 *  The keys are topic filters.
 *  The SessionManager subscribes to the given subscriptions after successfull (re-)connect
 *  according to the cleansession parameter and the state of the session as indicated by the broker.
 */
@property (strong, nonatomic) NSMutableDictionary *subscriptions;

/** SessionManager status
 */
@property (nonatomic, readonly) MQTTSessionManagerState state;

/** SessionManager last error code when state equals MQTTSessionManagerStateError
 */
@property (nonatomic, readonly) NSError *lastErrorCode;

/** Connects to the MQTT broker and stores the parameters for subsequent reconnects
 * @param host specifies the hostname or ip address to connect to. Defaults to @"localhost".
 * @param port spefies the port to connect to
 * @param tls specifies whether to use SSL or not
 * @param keepalive The Keep Alive is a time interval measured in seconds. The MQTTClient ensures that the interval between Control Packets being sent does not exceed the Keep Alive value. In the  absence of sending any other Control Packets, the Client sends a PINGREQ Packet.
 * @param clean specifies if the server should discard previous session information.
 * @param auth specifies the user and pass parameters should be used for authenthication
 * @param user an NSString object containing the user's name (or ID) for authentication. May be nil.
 * @param pass an NSString object containing the user's password. If userName is nil, password must be nil as well.
 * @param willTopic the Will Topic is a string, must not be nil
 * @param will the Will Message, might be zero length
 * @param willQos specifies the QoS level to be used when publishing the Will Message.
 * @param willRetainFlag indicates if the server should publish the Will Messages with retainFlag.
 * @param clientId The Client Identifier identifies the Client to the Server. If nil, a random clientId is generated.
 * @return the initialised MQTTSessionManager object
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
