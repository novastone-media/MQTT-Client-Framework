//
//  MQTTSSLSecurityPolicyTransport.h
//  MQTTClient
//
//  Created by Christoph Krey on 06.12.15.
//  Copyright © 2015-2017 Christoph Krey. All rights reserved.
//

#import "MQTTTransport.h"
#import "MQTTSSLSecurityPolicy.h"
#import "MQTTCFSocketTransport.h"

/** MQTTSSLSecurityPolicyTransport
 * implements an extension of the MQTTCFSocketTransport by replacing the OS's certificate chain evaluation
 */
@interface MQTTSSLSecurityPolicyTransport : MQTTCFSocketTransport

/**
 * The security policy used to evaluate server trust for secure connections.
 *
 * if your app using security model which require pinning SSL certificates to helps prevent man-in-the-middle attacks
 * and other vulnerabilities. you need to set securityPolicy to properly value(see MQTTSSLSecurityPolicy.h for more detail).
 *
 * NOTE: about self-signed server certificates:
 * if your server using Self-signed certificates to establish SSL/TLS connection, you need to set property:
 * MQTTSSLSecurityPolicy.allowInvalidCertificates=YES.
 */
@property (strong, nonatomic) MQTTSSLSecurityPolicy *securityPolicy;

@end
