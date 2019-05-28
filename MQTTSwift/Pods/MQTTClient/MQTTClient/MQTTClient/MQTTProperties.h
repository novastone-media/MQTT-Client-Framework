//
//  MQTTProperties.h
//  MQTTClient
//
//  Created by Christoph Krey on 04.04.17.
//  Copyright © 2017 Christoph Krey. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(UInt8, MQTTPropertyIdentifier) {
    MQTTPayloadFormatIndicator = 1,
    MQTTPublicationExpiryInterval = 2,
    MQTTContentType = 3,
    MQTTResponseTopic = 8,
    MQTTCorrelationData = 9,
    MQTTSubscriptionIdentifier = 11,
    MQTTSessionExpiryInterval = 17,
    MQTTAssignedClientIdentifier = 18,
    MQTTServerKeepAlive = 19,
    MQTTAuthMethod = 21,
    MQTTAuthData = 22,
    MQTTRequestProblemInformation = 23,
    MQTTWillDelayInterval = 24,
    MQTTRequestResponseInformation = 25,
    MQTTResponseInformation = 26,
    MQTTServerReference = 28,
    MQTTReasonString = 31,
    MQTTReceiveMaximum = 33,
    MQTTTopicAliasMaximum = 34,
    MQTTTopicAlias = 35,
    MQTTMaximumQoS = 36,
    MQTTRetainAvailable = 37,
    MQTTUserProperty = 38,
    MQTTMaximumPacketSize = 39,
    MQTTWildcardSubscriptionAvailable = 40,
    MQTTSubscriptionIdentifiersAvailable = 41,
    MQTTSharedSubscriptionAvailable = 42
};


@interface MQTTProperties : NSObject

@property (strong, nonatomic) NSNumber *payloadFormatIndicator;
@property (strong, nonatomic) NSNumber *publicationExpiryInterval;
@property (strong, nonatomic) NSString *contentType;
@property (strong, nonatomic) NSString *responseTopic;
@property (strong, nonatomic) NSData *correlationData;
@property (strong, nonatomic) NSNumber *subscriptionIdentifier;
@property (strong, nonatomic) NSNumber *sessionExpiryInterval;
@property (strong, nonatomic) NSString *assignedClientIdentifier;
@property (strong, nonatomic) NSNumber *serverKeepAlive;
@property (strong, nonatomic) NSString *authMethod;
@property (strong, nonatomic) NSData *authData;
@property (strong, nonatomic) NSNumber *requestProblemInformation;
@property (strong, nonatomic) NSNumber *willDelayInterval;
@property (strong, nonatomic) NSNumber *requestResponseInformation;
@property (strong, nonatomic) NSString *responseInformation;
@property (strong, nonatomic) NSString *serverReference;
@property (strong, nonatomic) NSString *reasonString;
@property (strong, nonatomic) NSNumber *receiveMaximum;
@property (strong, nonatomic) NSNumber *topicAliasMaximum;
@property (strong, nonatomic) NSNumber *topicAlias;
@property (strong, nonatomic) NSNumber *maximumQoS;
@property (strong, nonatomic) NSNumber *retainAvailable;
@property (strong, nonatomic) NSMutableDictionary <NSString *, NSString *> *userProperty;
@property (strong, nonatomic) NSNumber *maximumPacketSize;
@property (strong, nonatomic) NSNumber *wildcardSubscriptionAvailable;
@property (strong, nonatomic) NSNumber *subscriptionIdentifiersAvailable;
@property (strong, nonatomic) NSNumber *sharedSubscriptionAvailable;

- (instancetype)initFromData:(NSData *)data NS_DESIGNATED_INITIALIZER;
+ (int)getVariableLength:(NSData *)data;
+ (int)variableIntLength:(int)length;

@end
