//
//  MQTTCFSocketTransport.m
//  MQTTClient
//
//  Created by Christoph Krey on 06.12.15.
//  Copyright © 2015 Christoph Krey. All rights reserved.
//

#import "MQTTCFSocketTransport.h"

#ifdef LUMBERJACK
#define LOG_LEVEL_DEF ddLogLevel
#import <CocoaLumberjack/CocoaLumberjack.h>
#ifdef DEBUG
static const DDLogLevel ddLogLevel = DDLogLevelVerbose;
#else
static const DDLogLevel ddLogLevel = DDLogLevelWarning;
#endif
#else
#define DDLogVerbose NSLog
#define DDLogWarn NSLog
#define DDLogInfo NSLog
#define DDLogError NSLog
#endif

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
    self.certificates = nil;
    return self;
}

- (void)open {
    DDLogVerbose(@"[MQTTCFSocketTransport] open");
    self.state = MQTTTransportOpening;

    NSError* connectError;

    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;

    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)self.host, self.port, &readStream, &writeStream);

    CFReadStreamSetProperty(readStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
    CFWriteStreamSetProperty(writeStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
    
    if (self.tls) {
        NSMutableDictionary *sslOptions = [[NSMutableDictionary alloc] init];
        
        [sslOptions setObject:(NSString *)kCFStreamSocketSecurityLevelNegotiatedSSL
                       forKey:(NSString*)kCFStreamSSLLevel];
        
        if (self.certificates) {
            [sslOptions setObject:self.certificates
                           forKey:(NSString *)kCFStreamSSLCertificates];
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
        self.encoder.delegate = self;
        [self.encoder open];
        
        self.decoder = [[MQTTCFSocketDecoder alloc] init];
        self.decoder.stream =  CFBridgingRelease(readStream);
        self.decoder.delegate = self;
        [self.decoder open];
        
    } else {
        [self close];
    }
}

- (void)close {
    DDLogVerbose(@"[MQTTCFSocketTransport] close");
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

- (BOOL)send:(nonnull NSData *)data {
    return [self.encoder send:data];
}

- (void)decoder:(MQTTCFSocketDecoder *)sender didReceiveMessage:(nonnull NSData *)data {
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

+ (NSArray *)clientCertsFromP12:(NSString *)path passphrase:(NSString *)passphrase {
    if (!path) {
        DDLogWarn(@"[MQTTCFSocketTransport] no p12 path given");
        return nil;
    }
    
    NSData *pkcs12data = [[NSData alloc] initWithContentsOfFile:path];
    if (!pkcs12data) {
        DDLogWarn(@"[MQTTCFSocketTransport] reading p12 failed");
        return nil;
    }
    
    if (!passphrase) {
        DDLogWarn(@"[MQTTCFSocketTransport] no passphrase given");
        return nil;
    }
    CFArrayRef keyref = NULL;
    OSStatus importStatus = SecPKCS12Import((__bridge CFDataRef)pkcs12data,
                                            (__bridge CFDictionaryRef)[NSDictionary
                                                                       dictionaryWithObject:passphrase
                                                                       forKey:(__bridge id)kSecImportExportPassphrase],
                                            &keyref);
    if (importStatus != noErr) {
        DDLogWarn(@"[MQTTCFSocketTransport] Error while importing pkcs12 [%d]", (int)importStatus);
        return nil;
    }
    
    CFDictionaryRef identityDict = CFArrayGetValueAtIndex(keyref, 0);
    if (!identityDict) {
        DDLogWarn(@"[MQTTCFSocketTransport] could not CFArrayGetValueAtIndex");
        return nil;
    }
    
    SecIdentityRef identityRef = (SecIdentityRef)CFDictionaryGetValue(identityDict,
                                                                      kSecImportItemIdentity);
    if (!identityRef) {
        DDLogWarn(@"[MQTTCFSocketTransport] could not CFDictionaryGetValue");
        return nil;
    };
    
    SecCertificateRef cert = NULL;
    OSStatus status = SecIdentityCopyCertificate(identityRef, &cert);
    if (status != noErr) {
        DDLogWarn(@"[MQTTCFSocketTransport] SecIdentityCopyCertificate failed [%d]", (int)status);
        return nil;
    }
    
    NSArray *clientCerts = [[NSArray alloc] initWithObjects:(__bridge id)identityRef, (__bridge id)cert, nil];
    return clientCerts;
}

@end
