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
                   connectMessage:(MQTTMessage *)theConnectMessage
                     cleanSession:(BOOL)cleanSessionFlag
                             will:(BOOL)willFlag
                        willTopic:(NSString *)willTopic
                          willMsg:(NSData *)willMsg
                          willQoS:(MQTTQosLevel)willQoS
                   willRetainFlag:(BOOL)willRetainFlag
                    protocolLevel:(UInt8)protocolLevel
                            queue:(dispatch_queue_t)queue
                   securityPolicy:(MQTTSSLSecurityPolicy *)securityPolicy
                     certificates:(NSArray *)certificates {
    DDLogVerbose(@"[MQTTSessionLegacy] initWithClientId:%@ ", clientId);

    self = [self init];
    self.connectMessage = theConnectMessage;
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

- (void)publishJson:(id)payload onTopic:(NSString*)theTopic {
    NSData *data = [NSJSONSerialization dataWithJSONObject:payload options:0 error:nil];
    if (data) {
        [self publishData:data onTopic:theTopic retain:FALSE qos:MQTTQosLevelAtLeastOnce];
    }
}
@end
