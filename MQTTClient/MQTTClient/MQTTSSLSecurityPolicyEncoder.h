//
// MQTTSSLSecurityPolicyEncoder.h
// MQTTClient.framework
//
// Copyright © 2013-2017, Christoph Krey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MQTTSSLSecurityPolicy.h"
#import "MQTTCFSocketEncoder.h"

@interface MQTTSSLSecurityPolicyEncoder : MQTTCFSocketEncoder
@property(strong, nonatomic) MQTTSSLSecurityPolicy *securityPolicy;
@property(strong, nonatomic) NSString *securityDomain;

@end

