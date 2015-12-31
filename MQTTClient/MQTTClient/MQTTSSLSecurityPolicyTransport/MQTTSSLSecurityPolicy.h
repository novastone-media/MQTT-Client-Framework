//
// MQTTSSLSecurityPolicy.h
// MQTTClient.framework
//
// Created by @bobwenx on 15/6/1.
//
// based on
//
// Copyright (c) 2011–2015 AFNetwork (http://alamofire.org/)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <Foundation/Foundation.h>
#import <Security/Security.h>

/**
## SSL Pinning Modes

The following constants are provided by `MQTTSSLPinningModeNone` as possible SSL pinning modes.

enum {
MQTTSSLPinningModeNone,
MQTTSSLPinningModePublicKey,
MQTTSSLPinningModeCertificate,
}

`MQTTSSLPinningModeNone`
Do not used pinned certificates to validate servers.

`MQTTSSLPinningModePublicKey`
Validate host certificates against public keys of pinned certificates.

`MQTTSSLPinningModeCertificate`
Validate host certificates against pinned certificates.
*/
typedef NS_ENUM(NSUInteger, MQTTSSLPinningMode) {
    // Do not used pinned certificates to validate servers.
    MQTTSSLPinningModeNone,
    // Validate host certificates against public keys of pinned certificates.
    MQTTSSLPinningModePublicKey,
    // Validate host certificates against pinned certificates.
    MQTTSSLPinningModeCertificate,
};

/**
`MQTTSSLSecurityPolicy` evaluates server trust against pinned X.509 certificates and public keys over secure connections.
 
If your app using security model which require pinning SSL certificates to helps prevent man-in-the-middle attacks
and other vulnerabilities. you need to set securityPolicy to properly value(see MQTTSSLSecurityPolicy.h for more detail).

NOTE: about self-signed server certificates:
if your server using Self-signed certificates to establish SSL/TLS connection, you need to set property:
MQTTSSLSecurityPolicy.allowInvalidCertificates=YES.

If SSL is enabled, by default it only evaluate server's certificates using CA infrastructure, and for most case, this type of check is enough.
However, if your app using security model which require pinning SSL certificates to helps prevent man-in-the-middle attacks
and other vulnerabilities. you may need to set securityPolicy to properly value(see MQTTSSLSecurityPolicy.h for more detail).

NOTE: about self-signed server certificates:
In CA infrastructure, you may establish a SSL/TLS connection with server which using self-signed certificates
by install the certificates into OS keychain(either programmatically or manually). however, this method has some disadvantages:
1. every socket you app created will trust certificates you added.
2. if user choice to remove certificates from keychain, you app need to handling certificates re-adding.

If you only want to verify the cert for the socket you are creating and for no other sockets in your app, you need to use
MQTTSSLSecurityPolicy.
And if you use self-signed server certificates, your need to set property: MQTTSSLSecurityPolicy.allowInvalidCertificates=YES

Adding pinned SSL certificates to your app helps prevent man-in-the-middle attacks and other vulnerabilities.
Applications dealing with sensitive customer data or financial information are strongly encouraged to route all communication
over an SSL/TLS connection with SSL pinning configured and enabled.
*/
@interface MQTTSSLSecurityPolicy : NSObject
/**
The criteria by which server trust should be evaluated against the pinned SSL certificates. Defaults to `MQTTSSLPinningMode`.
*/
@property (readonly, nonatomic, assign) MQTTSSLPinningMode SSLPinningMode;

/**
Whether to evaluate an entire SSL certificate chain, or just the leaf certificate. Defaults to `YES`.
*/
@property (nonatomic, assign) BOOL validatesCertificateChain;

/**
The certificates used to evaluate server trust according to the SSL pinning mode. By default, this property is set to any (`.cer`) certificates included in the app bundle.
Note: Array item type: NSData - Bytes of X.509 certificate file in der format.
Note that if you create an array with duplicate certificates, the duplicate certificates will be removed.
*/
@property (nonatomic, strong) NSArray *pinnedCertificates;

/**
Whether or not to trust servers with an invalid or expired SSL certificates. Defaults to `NO`.
Note: If your server-certificates are self signed, your should set this property to 'YES'.
*/
@property (nonatomic, assign) BOOL allowInvalidCertificates;

/**
Whether or not to validate the domain name in the certificate's CN field. Defaults to `YES`.
*/
@property (nonatomic, assign) BOOL validatesDomainName;

///-----------------------------------------
/// @name Getting Specific Security Policies
///-----------------------------------------

/**
Returns the shared default security policy, which does not allow invalid certificates, validates domain name, and does not validate against pinned certificates or public keys.

@return The default security policy.
*/
+ (instancetype)defaultPolicy;

///---------------------
/// @name Initialization
///---------------------

/**
Creates and returns a security policy with the specified pinning mode.

@param pinningMode The SSL pinning mode.

@return A new security policy.
*/
+ (instancetype)policyWithPinningMode:(MQTTSSLPinningMode)pinningMode;

///------------------------------
/// @name Evaluating Server Trust
///------------------------------

/**
Whether or not the specified server trust should be accepted, based on the security policy.

This method should be used when responding to an authentication challenge from a server.

@param serverTrust The X.509 certificate trust of the server.
@param domain The domain of serverTrust. If `nil`, the domain will not be validated.

@return Whether or not to trust the server.
*/
- (BOOL)evaluateServerTrust:(SecTrustRef)serverTrust
                  forDomain:(NSString *)domain;
@end