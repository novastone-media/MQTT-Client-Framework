//
//  MQTTCFSocketTransport.m
//  MQTTClient
//
//  Created by Christoph Krey on 06.12.15.
//  Copyright © 2015 Christoph Krey. All rights reserved.
//

#import "MQTTCFSocketTransport.h"

@interface MQTTCFSocketTransport()
@property (strong, nonatomic) MQTTCFSocketEncoder *encoder;
@property (strong, nonatomic) MQTTCFSocketDecoder *decoder;
@end

@implementation MQTTCFSocketTransport
@synthesize state;
@synthesize delegate;

- (instancetype)init {
    self = [super init];
    self.state = MQTTTransportCreated;
    self.host = @"localhost";
    self.port = 1883;
    self.tls = false;
    self.securityPolicy = nil;
    self.certificates = nil;
    return self;
}

- (void)open {
    NSLog(@"[MQTTCFSocketTransport] open");
    self.state = MQTTTransportOpening;

    NSError* connectError;

    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;

    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)self.host, self.port, &readStream, &writeStream);

    CFReadStreamSetProperty(readStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
    CFWriteStreamSetProperty(writeStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);

    if (self.tls) {
        NSMutableDictionary *sslOptions = [[NSMutableDictionary alloc] init];
        
        if (!self.securityPolicy)
        {
            // use OS CA model
            [sslOptions setObject:(NSString *)kCFStreamSocketSecurityLevelNegotiatedSSL
                           forKey:(NSString*)kCFStreamSSLLevel];
            if (self.certificates) {
                [sslOptions setObject:self.certificates
                               forKey:(NSString *)kCFStreamSSLCertificates];
            }
        }
        else
        {
            // delegate certificates verify operation to our secure policy.
            // by disabling chain validation, it becomes our responsibility to verify that the host at the other end can be trusted.
            // the server's certificates will be verified during MQTT encoder/decoder processing.
            [sslOptions setObject:(NSString *)kCFStreamSocketSecurityLevelNegotiatedSSL
                           forKey:(NSString*)kCFStreamSSLLevel];
            [sslOptions setObject:[NSNumber numberWithBool:NO]
                           forKey:(NSString *)kCFStreamSSLValidatesCertificateChain];
            if (self.certificates) {
                [sslOptions setObject:self.certificates
                               forKey:(NSString *)kCFStreamSSLCertificates];
            }
            
        }
        
        if(!CFReadStreamSetProperty(readStream, kCFStreamPropertySSLSettings, (__bridge CFDictionaryRef)(sslOptions))){
            connectError = [NSError errorWithDomain:@"MQTT"
                                               code:errSSLInternal
                                           userInfo:@{NSLocalizedDescriptionKey : @"Fail to init ssl input stream!"}];
        }
        if(!CFWriteStreamSetProperty(writeStream, kCFStreamPropertySSLSettings, (__bridge CFDictionaryRef)(sslOptions))){
            connectError = [NSError errorWithDomain:@"MQTT"
                                               code:errSSLInternal
                                           userInfo:@{NSLocalizedDescriptionKey : @"Fail to init ssl output stream!"}];
        }
    }
    
    if(!connectError){
        self.encoder = [[MQTTCFSocketEncoder alloc] init];
        self.encoder.stream = CFBridgingRelease(writeStream);
        self.encoder.securityPolicy = self.tls ? self.securityPolicy : nil;
        self.encoder.securityDomain = self.tls ? self.host : nil;
        self.encoder.delegate = self;
        [self.encoder open];
        
        self.decoder = [[MQTTCFSocketDecoder alloc] init];
        self.decoder.stream =  CFBridgingRelease(readStream);
        self.decoder.securityPolicy = self.tls ? self.securityPolicy : nil;
        self.decoder.securityDomain = self.tls ? self.host : nil;
        self.decoder.delegate = self;
        [self.decoder open];
        
    } else {
        [self close];
    }
}

- (void)close {
    NSLog(@"[MQTTCFSocketTransport] close");
    self.state = MQTTTransportClosing;

    if (self.encoder) {
        [self.encoder close];
        self.encoder.delegate = nil;
    }
    
    if (self.decoder) {
        [self.decoder close];
        self.decoder.delegate = nil;
    }
}

- (BOOL)send:(NSData *)data {
    return [self.encoder send:data];
}

- (void)decoder:(MQTTCFSocketDecoder *)sender didReceiveMessage:(NSData *)data {
    [self.delegate mqttTransport:self didReceiveMessage:data];
}

- (void)decoder:(MQTTCFSocketDecoder *)sender didFailWithError:(NSError *)error {
    //self.state = MQTTTransportClosing;
    //[self.delegate mqttTransport:self didFailWithError:error];
}
- (void)encoder:(MQTTCFSocketEncoder *)sender didFailWithError:(NSError *)error {
    self.state = MQTTTransportClosing;
    [self.delegate mqttTransport:self didFailWithError:error];
}

- (void)decoderdidClose:(MQTTCFSocketDecoder *)sender {
    self.state = MQTTTransportClosed;
    [self.delegate mqttTransportDidClose:self];
}
- (void)encoderdidClose:(MQTTCFSocketEncoder *)sender {
    //self.state = MQTTTransportClosed;
    //[self.delegate mqttTransportDidClose:self];
}

- (void)decoderDidOpen:(MQTTCFSocketDecoder *)sender {
    //self.state = MQTTTransportOpen;
    //[self.delegate mqttTransportDidOpen:self];
}
- (void)encoderDidOpen:(MQTTCFSocketEncoder *)sender {
    self.state = MQTTTransportOpen;
    [self.delegate mqttTransportDidOpen:self];
}
@end
