//
// MQTTSessionLegacy.h
// MQTTClient.framework
//

/**
 Using MQTT in your Objective-C application
 This file contains definitions for mqttio-OBJC backward compatibility
 
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
@interface MQTTSession(Create)

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

/** for mqttio-OBJC backward compatibility
 @param theTopic see subscribeToTopic for description
 */
- (void)subscribeTopic:(NSString*)theTopic;

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

@end
