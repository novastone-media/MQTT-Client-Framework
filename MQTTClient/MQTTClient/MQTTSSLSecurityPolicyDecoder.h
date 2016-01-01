//
// MQTTSSLSecurityPolicyDecoder.h
// MQTTClient.framework
// 
// Copyright © 2013-2016, Christoph Krey
//

#import <Foundation/Foundation.h>
#import "MQTTSSLSecurityPolicy.h"
#import "MQTTCFSocketDecoder.h"

@interface MQTTSSLSecurityPolicyDecoder : MQTTCFSocketDecoder
@property(strong, nonatomic) MQTTSSLSecurityPolicy *securityPolicy;
@property(strong, nonatomic) NSString *securityDomain;

@end


