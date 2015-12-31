//
// MQTTSSLSecurityPolicyDecoder.h
// MQTTClient.framework
// 
// Copyright (c) 2013-2015, Christoph Krey
//

#import <Foundation/Foundation.h>
#import "MQTTSSLSecurityPolicy.h"
#import "MQTTCFSocketDecoder.h"

@interface MQTTSSLSecurityPolicyDecoder : MQTTCFSocketDecoder
@property(strong, nonatomic) MQTTSSLSecurityPolicy *securityPolicy;
@property(strong, nonatomic) NSString *securityDomain;

@end


