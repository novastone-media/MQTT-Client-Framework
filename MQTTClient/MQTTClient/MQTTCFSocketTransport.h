//
//  MQTTCFSocketTransport.h
//  MQTTClient
//
//  Created by Christoph Krey on 06.12.15.
//  Copyright © 2015-2017 Christoph Krey. All rights reserved.
//

#import "MQTTTransport.h"
#import "MQTTCFSocketDecoder.h"
#import "MQTTCFSocketEncoder.h"

/** MQTTCFSocketTransport
 * implements an MQTTTransport on top of CFNetwork
 */
@interface MQTTCFSocketTransport : MQTTTransport <MQTTTransport, MQTTCFSocketDecoderDelegate, MQTTCFSocketEncoderDelegate>

/** streamSSLLevel an NSString containing the security level for read and write streams
 * For list of possible values see:
 * https://developer.apple.com/documentation/corefoundation/cfstream/cfstream_socket_security_level_constants
 * Please also note that kCFStreamSocketSecurityLevelTLSv1_2 is not in a list
 * and cannot be used as constant, but you can use it as a string value
 * defaults to kCFStreamSocketSecurityLevelNegotiatedSSL
 */
@property (strong, nonatomic) NSString *streamSSLLevel;

/** host an NSString containing the hostName or IP address of the host to connect to
 * defaults to @"localhost"
 */
@property (strong, nonatomic) NSString *host;

/** port an unsigned 32 bit integer containing the IP port number to connect to
 * defaults to 1883
 */
@property (nonatomic) UInt32 port;

/** tls a boolean indicating whether the transport should be using security 
 * defaults to NO
 */
@property (nonatomic) BOOL tls;

/** Require for VoIP background service
 * defaults to NO
 */
@property (nonatomic) BOOL voip;

/** certificates An identity certificate used to reply to a server requiring client certificates according
 * to the description given for SSLSetCertificate(). You may build the certificates array yourself or use the
 * sundry method clientCertFromP12.
 */
@property (strong, nonatomic) NSArray *certificates;

/** reads the content of a PKCS12 file and converts it to an certificates array for initWith...
 @param path the path to a PKCS12 file
 @param passphrase the passphrase to unlock the PKCS12 file
 @returns a certificates array or nil if an error occured
 
 @code
 NSString *path = [[NSBundle bundleForClass:[MQTTClientTests class]] pathForResource:@"filename"
 ofType:@"p12"];
 
 NSArray *myCerts = [MQTTCFSocketTransport clientCertsFromP12:path passphrase:@"passphrase"];
 if (myCerts) {
 
 self.session = [[MQTTSession alloc] init];
 ...
 self.session.certificates = myCerts;
 
 [self.session connect];
 ...
 }
 
 @endcode
 
 */

+ (NSArray *)clientCertsFromP12:(NSString *)path passphrase:(NSString *)passphrase;

@end
