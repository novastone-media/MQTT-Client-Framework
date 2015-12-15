//
//  MQTTCFSocketTransport.h
//  MQTTClient
//
//  Created by Christoph Krey on 06.12.15.
//  Copyright © 2015 Christoph Krey. All rights reserved.
//

#import "MQTTTransport.h"
#import "MQTTCFSocketDecoder.h"
#import "MQTTCFSocketEncoder.h"

@interface MQTTCFSocketTransport : NSObject <MQTTTransport, MQTTCFSocketDecoderDelegate, MQTTCFSocketEncoderDelegate>
@property (strong, nonatomic) NSString *host;
@property (nonatomic) UInt16 port;
@property (nonatomic) BOOL tls;

/** see initWithClientId for description
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
 
 self.session = [[MQTTSession alloc] initWithClientId:nil
 userName:nil
 password:nil
 keepAlive:60
 cleanSession:YES
 will:NO
 willTopic:nil
 willMsg:nil
 willQoS:0
 willRetainFlag:NO
 protocolLevel:4
 runLoop:[NSRunLoop currentRunLoop]
 forMode:NSRunLoopCommonModes
 securityPolicy:nil
 certificates:myCerts];
 [self.session connectToHost:@"localhost" port:8884 usingSSL:YES];
 ...
 }
 
 @endcode
 
 */

+ (NSArray *)clientCertsFromP12:(NSString *)path passphrase:(NSString *)passphrase;

@end
