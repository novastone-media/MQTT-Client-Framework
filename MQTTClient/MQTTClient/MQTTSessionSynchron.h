//
// MQTTSessionSynchron.h
// MQTTClient.framework
//

/**
 Synchronous API
 
 @author Christoph Krey krey.christoph@gmail.com
 @copyright Copyright © 2013-2016, Christoph Krey 

 */


#import <Foundation/Foundation.h>
#import "MQTTSession.h"

@interface MQTTSession(Synchron)

/** connects to the specified MQTT server synchronously
 
 @param timeout defines the maximum time to wait. Defaults to 0 for no timeout.
 
 @return true if the connection was established
 
 @code
 #import "MQTTClient.h"
 
 MQTTSession *session = [[MQTTSession alloc] init];
 
 [session connectAndWaitTimeout:30];
 @endcode
 
 */
- (BOOL)connectAndWaitTimeout:(NSTimeInterval)timeout;


/** connects to the specified MQTT server synchronously
 
 @param host see connectAndWaitToHost:port:usingSSL:timeout: for details
 @param port see connectAndWaitToHost:port:usingSSL:timeout: for details
 @param usingSSL see connectAndWaitToHost:port:usingSSL:timeout: for details
 
 @return true if the connection was established
 
 @code
 #import "MQTTClient.h"
 
 MQTTSession *session = [[MQTTSession alloc] init];
 
 [session connectAndWaitToHost:@"192.168.0.1" port:1883 usingSSL:NO];
 @endcode
 
 @deprecated as not all connection parameters are supported, use connectAndWaitTimeout

 */
- (BOOL)connectAndWaitToHost:(NSString *)host
                        port:(UInt32)port
                    usingSSL:(BOOL)usingSSL;

/** connects to the specified MQTT server synchronously
 
 @param host specifies the hostname or ip address to connect to. Defaults to @"localhost".
 @param port spefifies the port to connect to
 @param usingSSL specifies whether to use SSL or not
 @param timeout defines the maximum time to wait
 
 @return true if the connection was established
 
 @code
 #import "MQTTClient.h"
 
 MQTTSession *session = [[MQTTSession alloc] init];
 
 [session connectAndWaitToHost:@"192.168.0.1" port:1883 usingSSL:NO];
 @endcode
 @deprecated as not all connection parameters are supported, use connectAndWaitTimeout

 */

- (BOOL)connectAndWaitToHost:(NSString *)host
                        port:(UInt32)port
                    usingSSL:(BOOL)usingSSL
                     timeout:(NSTimeInterval)timeout;

/** subscribes to a topic at a specific QoS level synchronously
 
 @param topic the Topic Filter to subscribe to.
 
 @param qosLevel specifies the QoS Level of the subscription.
 qosLevel can be 0, 1, or 2.
 
 @return TRUE if successfully subscribed
 
 @code
 #import "MQTTClient.h"
 
 MQTTSession *session = [[MQTTSession alloc] init];
 
 [session connectAndWaitTimeout:30];
 
 [session subscribeAndWaitToTopic:@"example/#" atLevel:2];
 
 @endcode
 
 */
- (BOOL)subscribeAndWaitToTopic:(NSString *)topic
                        atLevel:(MQTTQosLevel)qosLevel;

/** subscribes to a topic at a specific QoS level synchronously
 
 @param topic the Topic Filter to subscribe to.
 
 @param qosLevel specifies the QoS Level of the subscription.
 qosLevel can be 0, 1, or 2.
 @param timeout defines the maximum time to wait
 
 @return TRUE if successfully subscribed
 
 @code
 #import "MQTTClient.h"
 
 MQTTSession *session = [[MQTTSession alloc] init];
 
 [session connectAndWaitTimeout:30];
 
 [session subscribeAndWaitToTopic:@"example/#" atLevel:2 timeout:10];
 
 @endcode
 
 */
- (BOOL)subscribeAndWaitToTopic:(NSString *)topic
                        atLevel:(MQTTQosLevel)qosLevel
                        timeout:(NSTimeInterval)timeout;

/** subscribes a number of topics
 
 @param topics an NSDictionary<NSString *, NSNumber *> containing the Topic Filters to subscribe to as keys and
    the corresponding QoS as NSNumber values
 
 @return the Message Identifier of the SUBSCRIBE message.
 
 @note returns immediately. To check results, register as an MQTTSessionDelegate and watch for events.
 
 @code
 #import "MQTTClient.h"
 
 MQTTSession *session = [[MQTTSession alloc] init];
 
 [session connectAndWaitTimeout:30];
 
 [session subscribeAndWaitToTopics:@{
 @"example/#": @(0),
 @"example/status": @(2),
 @"other/#": @(1)
 }];
 
 @endcode
 */
- (BOOL)subscribeAndWaitToTopics:(NSDictionary<NSString *, NSNumber *> *)topics;

/** subscribes a number of topics
 
 @param topics an NSDictionary<NSString *, NSNumber *> containing the Topic Filters to subscribe to as keys and
 the corresponding QoS as NSNumber values
 @param timeout defines the maximum time to wait
 
 @return TRUE if the subscribe was succesfull
 
 @code
 #import "MQTTClient.h"
 
 MQTTSession *session = [[MQTTSession alloc] init];
 
 [session connectAndWaitTimeout:30];
 
 [session subscribeAndWaitToTopics:@{
 @"example/#": @(0),
 @"example/status": @(2),
 @"other/#": @(1)
 }
 timeout:10];
 
 @endcode
 */
- (BOOL)subscribeAndWaitToTopics:(NSDictionary<NSString *, NSNumber *> *)topics
                         timeout:(NSTimeInterval)timeout;


/** unsubscribes from a topic synchronously
 
 @param topic the Topic Filter to unsubscribe from.
 
 @return TRUE if sucessfully unsubscribed
 
 @code
 #import "MQTTClient.h"
 
 MQTTSession *session = [[MQTTSession alloc] init];
 
 [session connectAndWaitTimeout:30];

 ...
 
 [session unsubscribeAndWaitTopic:@"example/#"];
 
 @endcode
 */
- (BOOL)unsubscribeAndWaitTopic:(NSString *)topic;

/** unsubscribes from a topic synchronously
 
 @param topic the Topic Filter to unsubscribe from.
 @param timeout defines the maximum time to wait
 
 @return TRUE if sucessfully unsubscribed
 
 @code
 #import "MQTTClient.h"
 
 MQTTSession *session = [[MQTTSession alloc] init];
 
 [session connectAndWaitTimeout:30];
 
 ...
 
 [session unsubscribeAndWaitTopic:@"example/#" timeout:10];
 
 @endcode
 */
- (BOOL)unsubscribeAndWaitTopic:(NSString *)topic
                        timeout:(NSTimeInterval)timeout;


/** unsubscribes from a number of topics synchronously
 
 @param topics an NSArray<NSString *> of topics to unsubscribe from
 
 @return TRUE if the unsubscribe was successful
 
 @code
 #import "MQTTClient.h"
 
 MQTTSession *session = [[MQTTSession alloc] init];
 
 [session connectAndWaitTimeout:30];
 
 ...
 
 [session unsubscribeAndWaitTopics:@[
 @"example/#",
 @"example/status",
 @"other/#"
 ]];
 
 @endcode
 
 */
- (BOOL)unsubscribeAndWaitTopics:(NSArray<NSString *> *)topics;

/** unsubscribes from a number of topics synchronously
 
 @param topics an NSArray<NSString *> of topics to unsubscribe from
 @param timeout defines the maximum time to wait
 
 @return TRUE if the unsubscribe was successful
 
 @code
 #import "MQTTClient.h"
 
 MQTTSession *session = [[MQTTSession alloc] init];
 
 [session connectAndWaitTimeout:30];
 
 ...
 
 [session unsubscribeAndWaitTopics:@[
 @"example/#",
 @"example/status",
 @"other/#"
 ]
 timeout:10];
 
 @endcode
 
 */
- (BOOL)unsubscribeAndWaitTopics:(NSArray<NSString *> *)topics
                         timeout:(NSTimeInterval)timeout;


/** publishes synchronously data
 
 @param data see publishAndWaitData:onTopic:retain:qos:timeout: for details
 @param topic see publishAndWaitData:onTopic:retain:qos:timeout: for details
 @param retainFlag see publishAndWaitData:onTopic:retain:qos:timeout: for details
 @param qos see publishAndWaitData:onTopic:retain:qos:timeout: for details
 @returns TRUE if the publish was successful
 
 @code
 #import "MQTTClient.h"
 
 MQTTSession *session = [[MQTTSession alloc] init];
 
 [session connectAndWaitTimeout:30];
 
 [session publishAndWaitData:[@"Sample Data" dataUsingEncoding:NSUTF8StringEncoding]
 topic:@"example/data"
 retain:YES
 qos:1];
 @endcode
 
 */
- (BOOL)publishAndWaitData:(NSData *)data
                   onTopic:(NSString *)topic
                    retain:(BOOL)retainFlag
                       qos:(MQTTQosLevel)qos;

/** publishes synchronously data on a given topic at a specified QoS level and retain flag
 
 @param data the data to be sent. length may range from 0 to 268,435,455 - 4 - _lengthof-topic_ bytes. Defaults to length 0.
 @param topic the Topic to identify the data
 @param retainFlag if YES, data is stored on the MQTT broker until overwritten by the next publish with retainFlag = YES
 @param qos specifies the Quality of Service for the publish
 qos can be 0, 1, or 2.
 @param timeout defines the maximum time to wait
 @returns TRUE if the publish was successful
 
 @code
 #import "MQTTClient.h"
 
 MQTTSession *session = [[MQTTSession alloc] init];
 
 [session connectAndWaitTimeout:30];
 
 [session publishAndWaitData:[@"Sample Data" dataUsingEncoding:NSUTF8StringEncoding]
 topic:@"example/data"
 retain:YES
 qos:1
 timeout:10];
 @endcode
 
 */
- (BOOL)publishAndWaitData:(NSData *)data
                   onTopic:(NSString *)topic
                    retain:(BOOL)retainFlag
                       qos:(MQTTQosLevel)qos
                   timeout:(NSTimeInterval)timeout;

/** closes an MQTTSession gracefully synchronously
 If the connection was successfully established before, a DISCONNECT is sent.
 
 @code
 #import "MQTTClient.h"
 
 MQTTSession *session = [[MQTTSession alloc] init];
 
 [session connectAndWaitTimeout:30];
 
 ...
 
 [session closeAndWait];
 
 @endcode
 
 */
- (void)closeAndWait;

/** closes an MQTTSession gracefully synchronously
 @param timeout defines the maximum time to wait

 If the connection was successfully established before, a DISCONNECT is sent.
 
 @code
 #import "MQTTClient.h"
 
 MQTTSession *session = [[MQTTSession alloc] init];
 
 [session connectAndWaitTimeout:30];
 
 ...
 
 [session closeAndWait:10];
 
 @endcode
 
 */
- (void)closeAndWait:(NSTimeInterval)timeout;

@end
