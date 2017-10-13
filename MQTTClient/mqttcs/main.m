
//
//  main.m
//  mqttcs
//
//  Created by Christoph Krey on 02.09.17.
//  Copyright © 2017 Christoph Krey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MQTTSession.h"
#import "MQTTCFSocketTransport.h"
#import "MQTTLog.h"
#import "MQTTStrict.h"
#import "MQTTWill.h"

#import "stdio.h"

@interface NSObject (jsonString)
@end

@implementation NSObject (jsonString)

- (NSString *)escapedJsonString {
    NSString *escapedJsonString = [self.jsonString stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    return escapedJsonString;
}

- (NSString *)jsonString {
    NSString *jsonString = @"None";
    if ([NSJSONSerialization isValidJSONObject:self]) {
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self options:0 error:nil];
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    return jsonString;
}

@end

@interface NSFileHandle (prints)
@end

@implementation NSFileHandle (prints)

- (void)prints:(NSString  * _Nonnull )s {
    [self writeData:[s dataUsingEncoding:NSUTF8StringEncoding]];
}

@end

@interface D : NSObject <MQTTSessionDelegate>
@property BOOL debug;
@end

@implementation D

-(void)connected:(MQTTSession *)session {
    [[NSFileHandle fileHandleWithStandardOutput] prints:
     [NSString stringWithFormat:@"{\"cmd\": \"info\", \"info\": \"connected %@/%@\"}\n",
      session.clientId, session.assignedClientIdentifier]
     ];
}

- (void)connectionClosed:(MQTTSession *)session {
    [[NSFileHandle fileHandleWithStandardOutput] prints:
     [NSString stringWithFormat:@"{\"cmd\": \"info\", \"info\": \"connection closed %@/%@\"}\n",
      session.clientId, session.assignedClientIdentifier]
     ];
}

- (void)connectionError:(MQTTSession *)session error:(NSError *)error {
    [[NSFileHandle fileHandleWithStandardOutput] prints:
     [NSString stringWithFormat:@"{\"cmd\": \"error\", \"error\": \"connectionError %@/%@ %@\"}\n",
      session.clientId, session.assignedClientIdentifier, error]
     ];
}

- (void)handleEvent:(MQTTSession *)session event:(MQTTSessionEvent)eventCode error:(NSError *)error {
    [[NSFileHandle fileHandleWithStandardOutput] prints:
     [NSString stringWithFormat:@"{\"cmd\": \"debug\", \"debug\": \"handleEvent %@/%@ %ld %@\"}\n",
      session.clientId, session.assignedClientIdentifier, (long)eventCode, error]
     ];
}

- (void)received:(MQTTSession *)session
            type:(MQTTCommandType)type
             qos:(MQTTQosLevel)qos
        retained:(BOOL)retained
           duped:(BOOL)duped
             mid:(UInt16)mid
            data:(NSData *)data {
    if (self.debug) {
        [[NSFileHandle fileHandleWithStandardOutput] prints:
         [NSString stringWithFormat:@"{\"cmd\": \"debug\", \"debug\": \"received %@/%@ t%u q%u r%u d%u m%hu (%lu) %@\"}\n",
          session.clientId, session.assignedClientIdentifier,
          type,
          qos,
          retained,
          duped,
          mid,
          (unsigned long)data.length,
          data.description
          ]
         ];
    }
}

-(void)sending:(MQTTSession *)session
          type:(MQTTCommandType)type
           qos:(MQTTQosLevel)qos
      retained:(BOOL)retained
         duped:(BOOL)duped
           mid:(UInt16)mid
          data:(NSData *)data {
    if (self.debug) {
        [[NSFileHandle fileHandleWithStandardOutput] prints:
         [NSString stringWithFormat:@"{\"cmd\": \"debug\", \"debug\": \"sending %@/%@ t%u q%u r%u d%u m%hu (%lu) %@\"}\n",
          session.clientId, session.assignedClientIdentifier,
          type,
          qos,
          retained,
          duped,
          mid,
          (unsigned long)data.length,
          data.description
          ]
         ];
    }
}

- (void)messageDeliveredV5:(MQTTSession *)session
                     msgID:(UInt16)msgID
                     topic:(NSString *)topic
                      data:(NSData *)data
                       qos:(MQTTQosLevel)qos
                retainFlag:(BOOL)retainFlag
    payloadFormatIndicator:(NSNumber *)payloadFormatIndicator
 publicationExpiryInterval:(NSNumber *)publicationExpiryInterval
                topicAlias:(NSNumber *)topicAlias
             responseTopic:(NSString *)responseTopic
           correlationData:(NSData *)correlationData
            userProperties:(NSArray<NSDictionary<NSString *,NSString *> *> *)userProperties
               contentType:(NSString *)contentType {
    if (self.debug) {
        [[NSFileHandle fileHandleWithStandardOutput] prints:
         [NSString stringWithFormat:@"{\"cmd\": \"info\", \"info\": \"messageDeliveredV5 %@: %@ r%u q%u pFI=%@ pEI=%@ tA=%@ rT=%@ cD=%@ uP=%@ cT=%@\"}\n",
          topic,
          data,
          retainFlag,
          qos,
          payloadFormatIndicator,
          publicationExpiryInterval,
          topicAlias,
          responseTopic,
          correlationData,
          userProperties.jsonString,
          contentType]
         ];
    }

}

-(void)newMessageV5:(MQTTSession *)session
               data:(NSData *)data
            onTopic:(NSString *)topic
                qos:(MQTTQosLevel)qos
           retained:(BOOL)retained
                mid:(unsigned int)mid
payloadFormatIndicator:(NSNumber *)payloadFormatIndicator
publicationExpiryInterval:(NSNumber *)publicationExpiryInterval
         topicAlias:(NSNumber *)topicAlias
      responseTopic:(NSString *)responseTopic
    correlationData:(NSData *)correlationData
     userProperties:(NSArray<NSDictionary<NSString *,NSString *> *> *)userProperties
        contentType:(NSString *)contentType
subscriptionIdentifiers:(NSArray<NSNumber *> * _Nullable)subscriptionIdentifiers {
    NSMutableDictionary *newMessageV5 = [[NSMutableDictionary alloc] init];
    newMessageV5[@"cmd"] = @"callback";
    newMessageV5[@"callback"] = @"newMessageV5";
    newMessageV5[@"s"] = session.clientId;
    newMessageV5[@"d"] = [data base64EncodedStringWithOptions:0];
    NSString *s = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (s) {
        newMessageV5[@"dAS"] = s;
    }
    id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    if (json) {
        newMessageV5[@"dAJ"] = json;
    }
    newMessageV5[@"t"] = topic;
    newMessageV5[@"q"] = @(qos);
    newMessageV5[@"r"] = @(retained);
    newMessageV5[@"mid"] = @(mid);
    newMessageV5[@"pFI"] = payloadFormatIndicator;
    newMessageV5[@"pEI"] = publicationExpiryInterval;
    newMessageV5[@"tA"] = topicAlias;
    newMessageV5[@"rT"] = responseTopic;
    newMessageV5[@"cD"] = [correlationData base64EncodedDataWithOptions:0];;
    newMessageV5[@"uP"] = userProperties;
    newMessageV5[@"cT"] = contentType;
    newMessageV5[@"sI"] = subscriptionIdentifiers;

    NSData *newMessageV5Data = [NSJSONSerialization dataWithJSONObject:newMessageV5 options:0 error:nil];
    NSString *newMessageV5String = [[NSString alloc] initWithData:newMessageV5Data encoding:NSUTF8StringEncoding];
    [[NSFileHandle fileHandleWithStandardOutput] prints:[NSString stringWithFormat:@"%@\n", newMessageV5String]];
}

@end

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        [[NSFileHandle fileHandleWithStandardOutput] prints:@"{\"cmd\": \"info\", \"info\": \"start\"}\n"];

        NSFileHandle *inputFileHandle = [NSFileHandle fileHandleWithStandardInput];
        int c;

        opterr = 0;

        while ((c = getopt (argc, (char * const *)argv, "i:")) != -1)
            switch (c) {
                case 'i': {
                    inputFileHandle = [NSFileHandle fileHandleForReadingAtPath:
                                       [NSString stringWithCString:optarg encoding:NSUTF8StringEncoding]];
                    break;
                }
                case '?':
                    if (optopt == 'i') {
                        [[NSFileHandle fileHandleWithStandardOutput] prints:
                         [NSString stringWithFormat:@"{\"cmd\": \"error\", \"error\": \"Option -%c requires an argument.\"}\n",
                          optopt]
                         ];
                    }
                    else if (isprint (optopt)) {
                        [[NSFileHandle fileHandleWithStandardOutput] prints:
                         [NSString stringWithFormat:@"{\"cmd\": \"error\", \"error\": \"Unknown option -%c.\"}\n",
                          optopt]
                         ];
                    }
                    else {
                        [[NSFileHandle fileHandleWithStandardOutput] prints:
                         [NSString stringWithFormat:@"{\"cmd\": \"error\", \"error\": \"Unknown option character `\\x%x'.\"}\n",
                          optopt]
                         ];
                        return 1;
                    }
                default: {
                    abort ();
                }
            }

        for (int index = optind; index < argc; index++) {
            [[NSFileHandle fileHandleWithStandardOutput] prints:
             [NSString stringWithFormat:@"{\"cmd\": \"error\", \"error\": \"Non-option argument %s\"}\n",
              argv[index]]
             ];
        }

        NSRunLoop *r = [NSRunLoop currentRunLoop];
        [MQTTLog setLogLevel:DDLogLevelWarning];

        MQTTSession *s = [[MQTTSession alloc] init];
        D *d = [[D alloc] init];
        d.debug = false;
        s.delegate = d;
        s.protocolLevel = MQTTProtocolVersion50;

        MQTTCFSocketTransport *t = [[MQTTCFSocketTransport alloc] init];
        s.transport = t;

        NSData *inputData = [inputFileHandle readDataToEndOfFile];
        NSError *error;
        id inputJSON = [NSJSONSerialization JSONObjectWithData:inputData options:0 error:&error];

        NSArray *processJSON;
        if (inputJSON) {
            if ([inputJSON isKindOfClass:[NSArray class]]) {
                processJSON = inputJSON;
            } else {
                processJSON = @[inputJSON];
            }

            BOOL __block busy = false;
            for (id rowJSON in processJSON) {
                @try {
                    if ([rowJSON isKindOfClass:[NSDictionary class]]) {
                        NSDictionary *dictJSON = (NSDictionary *)rowJSON;
                        NSString *cmd = dictJSON[@"cmd"];
                        if (cmd && [cmd isKindOfClass:[NSString class]]) {

                            /*                                        _
                             *   ___  ___   _ __   _ __    ___   ___ | |_
                             *  / __|/ _ \ | '_ \ | '_ \  / _ \ / __|| __|
                             * | (__| (_) || | | || | | ||  __/| (__ | |_
                             *  \___|\___/ |_| |_||_| |_| \___| \___| \__|              _                       _  _
                             */

                            if ([cmd isEqualToString:@"connect"]) {

                                NSString *host = dictJSON[@"host"];
                                if (host) {
                                    t.host = host;
                                }

                                NSNumber *port = dictJSON[@"port"];
                                if (port) {
                                    t.port = port.unsignedShortValue;
                                }

                                NSNumber *mqttProtocolLevel = dictJSON[@"mqttProtocolLevel"];
                                if (mqttProtocolLevel) {
                                    s.protocolLevel = mqttProtocolLevel.unsignedShortValue;
                                }

                                NSNumber *keepAlive = dictJSON[@"keepAlive"];
                                if (keepAlive) {
                                    s.keepAliveInterval = keepAlive.unsignedShortValue;
                                }

                                NSNumber *cleanStart = dictJSON[@"cleanStart"];
                                if (cleanStart) {
                                    s.cleanSessionFlag = cleanStart.boolValue;
                                }

                                NSString *willTopic = dictJSON[@"willTopic"];
                                NSString *willMessageString = dictJSON[@"willMessage"];
                                NSNumber *willQoS = dictJSON[@"willQoS"];
                                NSNumber *willRetain = dictJSON[@"willRetain"];
                                if (willTopic) {
                                    s.will = [[MQTTWill alloc]
                                              initWithTopic:willTopic
                                              data:willMessageString ? [willMessageString dataUsingEncoding:NSUTF8StringEncoding] : [[NSData alloc] init]
                                              retainFlag:willRetain ? willRetain.boolValue : false
                                              qos:willQoS ? willQoS.unsignedCharValue : MQTTQosLevelAtMostOnce];
                                }

                                s.willDelayInterval = dictJSON[@"willDelayInterval"];
                                s.sessionExpiryInterval = dictJSON[@"sessionExpiryInterval"];

                                s.userName = dictJSON[@"userName"];
                                s.password = dictJSON[@"password"];
                                s.maximumPacketSize = dictJSON[@"maximumPacketSize"];
                                s.receiveMaximum = dictJSON[@"receiveMaximum"];
                                s.clientId = dictJSON[@"clientIdentifier"];

                                NSString *authenticationData = dictJSON[@"authenticationData"];
                                if (authenticationData) {
                                    s.authData = [authenticationData dataUsingEncoding:NSUTF8StringEncoding];
                                }
                                s.authMethod = dictJSON[@"authenticationMethod"];
                                s.userProperties = dictJSON[@"userProperties"];
                                s.requestProblemInformation = dictJSON[@"requestProblemInformation"];
                                s.requestResponseInformation = dictJSON[@"requestResponseInformation"];
                                s.topicAliasMaximum = dictJSON[@"topicAliasMaximum"];

                                [[NSFileHandle fileHandleWithStandardOutput] prints:
                                 [NSString stringWithFormat:@"{\"cmd\": \"info\", \"info\": \"connecting to %@:%d (%d) mPS=%@\"}\n",
                                  s.transport.host,
                                  s.transport.port,
                                  s.protocolLevel,
                                  s.maximumPacketSize]
                                 ];

                                busy = true;
                                [s connectWithConnectHandler:^(NSError *e){
                                    busy = false;
                                    if (e) {
                                        [[NSFileHandle fileHandleWithStandardOutput] prints:
                                         [NSString stringWithFormat:@"{\"cmd\": \"error\", \"error\": \"not connected to %@:%d\"}\n",
                                          s.transport.host,
                                          s.transport.port
                                          ]
                                         ];
                                    } else {
                                        [[NSFileHandle fileHandleWithStandardOutput] prints:
                                         [NSString stringWithFormat:@"{\"cmd\": \"success\", \"success\": \"connected to %@:%d\", "
                                          "\"sP\":%d, "
                                          "\"bMPS\":%@, "
                                          "\"kA\":%d, "
                                          "\"sKA\":%@, "
                                          "\"eKA\":%d, "
                                          "\"bAM\":%@, "
                                          "\"bAD\":%@, "
                                          "\"bRI\":%@, "
                                          "\"sR\":%@, "
                                          "\"rS\":%@, "
                                          "\"bSEI\":%@, "
                                          "\"bRM\":%@, "
                                          "\"bTAM\":%@, "
                                          "\"mQ\":%@, "
                                          "\"rA\":%@, "
                                          "\"bUP\":%@, "
                                          "\"wSA\":%@, "
                                          "\"sIA\":%@, "
                                          "\"sSA\":%@"
                                          "}\n",
                                          s.transport.host,
                                          s.transport.port,
                                          s.sessionPresent,
                                          s.brokerMaximumPacketSize,
                                          s.keepAliveInterval,
                                          s.serverKeepAlive,
                                          s.effectiveKeepAlive,
                                          s.brokerAuthMethod,
                                          s.brokerAuthData,
                                          s.brokerResponseInformation,
                                          s.serverReference,
                                          s.reasonString,
                                          s.brokerSessionExpiryInterval,
                                          s.brokerReceiveMaximum,
                                          s.brokerTopicAliasMaximum,
                                          s.maximumQoS,
                                          s.retainAvailable,
                                          s.brokerUserProperties.jsonString,
                                          s.wildcardSubscriptionAvailable,
                                          s.subscriptionIdentifiersAvailable,
                                          s.sharedSubscriptionAvailable
                                          ]];
                                    }
                                }];

                                /*      _  _                                             _
                                 *   __| |(_) ___   ___  ___   _ __   _ __    ___   ___ | |_
                                 *  / _` || |/ __| / __|/ _ \ | '_ \ | '_ \  / _ \ / __|| __|
                                 * | (_| || |\__ \| (__| (_) || | | || | | ||  __/| (__ | |_
                                 *  \__,_||_||___/ \___|\___/ |_| |_||_| |_| \___| \___| \__|                                        _
                                 */

                            } else if ([cmd isEqualToString:@"disconnect"]) {

                                NSNumber *returnCode = dictJSON[@"returnCode"];
                                if (!returnCode) {
                                    returnCode = @(0);
                                }

                                NSNumber *sessionExpiryInterval = dictJSON[@"sessionExpiryInterval"];
                                NSString *reasonString = dictJSON[@"reasonString"];
                                NSArray <NSDictionary <NSString *, NSString *> *> *userProperties = dictJSON[@"userProperties"];

                                [[NSFileHandle fileHandleWithStandardOutput] prints:
                                 [NSString stringWithFormat:@"{\"cmd\": \"info\", \"info\": \"disconnecting from %@:%d rC=%d sEI=%@ rS=%@ uP=%@\"}\n",
                                  s.transport.host, s.transport.port,
                                  returnCode.unsignedCharValue,
                                  sessionExpiryInterval,
                                  reasonString,
                                  userProperties.escapedJsonString
                                  ]
                                 ];

                                busy = true;
                                [s closeWithReturnCode:returnCode.unsignedCharValue
                                 sessionExpiryInterval:sessionExpiryInterval
                                          reasonString:reasonString
                                        userProperties:userProperties
                                     disconnectHandler:^(NSError *e){
                                         busy = false;
                                         if (e) {
                                             [[NSFileHandle fileHandleWithStandardOutput] prints:
                                              [NSString stringWithFormat:@"{\"cmd\": \"error\", \"error\": \"not disconnected from %@:%d\"}\n",
                                               s.transport.host, s.transport.port]
                                              ];
                                         } else {
                                             [[NSFileHandle fileHandleWithStandardOutput] prints:
                                              [NSString stringWithFormat:@"{\"cmd\": \"success\", \"success\": \"disconnected from %@:%d\"}\n",
                                               s.transport.host, s.transport.port]
                                              ];
                                         }
                                     }];

                                /*              _                       _  _
                                 *  ___  _   _ | |__   ___   ___  _ __ (_)| |__    ___
                                 * / __|| | | || '_ \ / __| / __|| '__|| || '_ \  / _ \
                                 * \__ \| |_| || |_) |\__ \| (__ | |   | || |_) ||  __/
                                 * |___/ \__,_||_.__/ |___/ \___||_|   |_||_.__/  \___|
                                 */
                            } else if ([cmd isEqualToString:@"subscribe"]) {

                                NSNumber *qos = dictJSON[@"qos"];
                                if (!qos) {
                                    qos = @(MQTTQosLevelAtMostOnce);
                                }

                                NSNumber *retainHandling = dictJSON[@"retainHandling"];
                                if (!retainHandling) {
                                    retainHandling = @(MQTTSendRetained);
                                }

                                NSNumber *retainAsPublished = dictJSON[@"retainAsPublished"];
                                if (!retainAsPublished) {
                                    retainAsPublished = @(false);
                                }

                                NSNumber *noLocal = dictJSON[@"noLocal"];
                                if (!noLocal) {
                                    noLocal = @(false);
                                }

                                NSArray <NSDictionary <NSString *, NSString *> *> *userProperties = dictJSON[@"userProperties"];

                                NSNumber *subscribeOptions = @(
                                qos.intValue |
                                noLocal.intValue << 2 |
                                retainAsPublished.intValue << 3 |
                                retainHandling.intValue << 4
                                );

                                NSNumber *subscriptionIdentifier = dictJSON[@"subscriptionIdentifier"];

                                NSString *topic = dictJSON[@"topic"];
                                NSMutableDictionary *subs = [[NSMutableDictionary alloc] init];
                                if (topic) {
                                    subs[topic] = subscribeOptions;
                                }

                                [[NSFileHandle fileHandleWithStandardOutput] prints:
                                 [NSString stringWithFormat:@"{\"cmd\": \"info\", \"info\": \"subscribing \", \"subs\": %@, \"uP\": %@}\n",
                                  subs.jsonString,
                                  userProperties.jsonString]
                                 ];

                                busy = true;
                                [s subscribeToTopicsV5:subs
                                subscriptionIdentifier:subscriptionIdentifier.intValue
                                        userProperties:userProperties
                                      subscribeHandler:^(NSError *error,
                                                         NSString *reasonString,
                                                         NSArray <NSDictionary <NSString *, NSString*> *> *userProperties,
                                                         NSArray <NSNumber *> *reasonCodes) {
                                          busy = false;
                                          if (error) {
                                              [[NSFileHandle fileHandleWithStandardOutput] prints:
                                               [NSString stringWithFormat:@"{\"cmd\": \"error\", \"error\": \"subscribe error %@ %@ %@\"}\n",
                                                error, reasonString, userProperties]
                                               ];
                                              exit(1);
                                          } else {
                                              [[NSFileHandle fileHandleWithStandardOutput] prints:
                                               [NSString stringWithFormat:@"{\"cmd\": \"success\", \"success\": \"subscribed %@ %@ %@\"}\n",
                                                reasonCodes.escapedJsonString, reasonString, userProperties.escapedJsonString]
                                               ];
                                          }
                                      }];

                                /*                            _                       _  _
                                 *  _   _  _ __   ___  _   _ | |__   ___   ___  _ __ (_)| |__    ___
                                 * | | | || '_ \ / __|| | | || '_ \ / __| / __|| '__|| || '_ \  / _ \
                                 * | |_| || | | |\__ \| |_| || |_) |\__ \| (__ | |   | || |_) ||  __/
                                 *  \__,_||_| |_||___/ \__,_||_.__/ |___/ \___||_|   |_||_.__/  \___|             _                       _  _
                                 */
                            } else if ([cmd isEqualToString:@"unsubscribe"]) {

                                NSString *topic = dictJSON[@"topic"];
                                NSMutableArray *unsubs = [[NSMutableArray alloc] init];
                                if (topic) {
                                    [unsubs addObject:topic];
                                }

                                NSArray <NSDictionary <NSString *, NSString *> *> *userProperties = dictJSON[@"userProperties"];

                                [[NSFileHandle fileHandleWithStandardOutput] prints:
                                 [NSString stringWithFormat:@"{\"cmd\": \"info\", \"info\": \"unsubscribing \", \"unsubs\": %@, \"uP\": %@}\n",
                                  unsubs.jsonString,
                                  userProperties.jsonString]
                                 ];

                                busy = true;
                                [s unsubscribeTopicsV5:unsubs
                                        userProperties:userProperties
                                    unsubscribeHandler:^(NSError *error,
                                                         NSString *reasonString,
                                                         NSArray <NSDictionary <NSString *, NSString*> *> *userProperties,
                                                         NSArray <NSNumber *> *reasonCodes) {
                                        busy = false;
                                        if (error) {
                                            [[NSFileHandle fileHandleWithStandardOutput] prints:
                                             [NSString stringWithFormat:@"{\"cmd\": \"error\", \"error\": \"unsubscribe error %@ %@ %@\"}\n",
                                              error, reasonString, userProperties]
                                             ];
                                            exit(1);
                                        } else {
                                            [[NSFileHandle fileHandleWithStandardOutput] prints:
                                             [NSString stringWithFormat:@"{\"cmd\": \"success\", \"success\": \"unsubscribed %@ %@ %@\"}\n",
                                              reasonCodes.escapedJsonString, reasonString, userProperties.escapedJsonString]
                                             ];
                                        }
                                    }];

                                /*                _      _  _       _
                                 *  _ __   _   _ | |__  | |(_) ___ | |__
                                 * | '_ \ | | | || '_ \ | || |/ __|| '_ \
                                 * | |_) || |_| || |_) || || |\__ \| | | |
                                 * | .__/  \__,_||_.__/ |_||_||___/|_| |_|
                                 * |_|
                                 */
                            } else if ([cmd isEqualToString:@"publish"]) {

                                NSNumber *qos = dictJSON[@"qos"];
                                if (!qos) {
                                    qos = @(MQTTQosLevelAtMostOnce);
                                }

                                NSNumber *retain = dictJSON[@"retain"];
                                if (!retain) {
                                    retain = @(0);
                                }

                                NSNumber *topicAlias = dictJSON[@"topicAlias"];
                                NSNumber *payloadFormatIndicator = dictJSON[@"payloadFormatIndicator"];
                                NSNumber *publicationExpiryInterval = dictJSON[@"publicationExpiryInterval"];
                                NSString *responseTopic = dictJSON[@"responseTopic"];
                                NSString *dataString = dictJSON[@"data"];
                                NSString *correlationDataString = dictJSON[@"correlationData"];
                                NSArray <NSDictionary <NSString *, NSString *> *> *userProperties = dictJSON[@"userProperties"];
                                NSString *contentType = dictJSON[@"contentType"];
                                NSString *topic = dictJSON[@"topic"];

                                [[NSFileHandle fileHandleWithStandardOutput] prints:
                                 [NSString stringWithFormat:@"{\"cmd\": \"info\", \"info\": \"publishing %@: %@ r%u q%u pFI=%@ pEI=%@ tA=%@ rT=%@ cD=%@ uP=%@ cT=%@\"}\n",
                                  topic,
                                  dataString,
                                  retain.boolValue,
                                  qos.unsignedCharValue,
                                  payloadFormatIndicator,
                                  publicationExpiryInterval,
                                  topicAlias,
                                  responseTopic,
                                  correlationDataString,
                                  userProperties.jsonString,
                                  contentType]
                                 ];

                                UInt16 __block mid = [s publishDataV5:[dataString dataUsingEncoding:NSUTF8StringEncoding]
                                                              onTopic:topic
                                                               retain:retain.boolValue
                                                                  qos:qos.unsignedCharValue
                                               payloadFormatIndicator:payloadFormatIndicator
                                            publicationExpiryInterval:publicationExpiryInterval
                                                           topicAlias:topicAlias
                                                        responseTopic:responseTopic
                                                      correlationData:[correlationDataString dataUsingEncoding:NSUTF8StringEncoding]
                                                       userProperties:userProperties
                                                          contentType:contentType
                                                       publishHandler:^(NSError *error) {
                                                           if (error) {
                                                               [[NSFileHandle fileHandleWithStandardOutput] prints:
                                                                [NSString stringWithFormat:@"{\"cmd\": \"error\", \"error\": \"publish error %@\"}\n",
                                                                 error]
                                                                ];
                                                               exit(1);
                                                           } else {
                                                               [[NSFileHandle fileHandleWithStandardOutput] prints:
                                                                [NSString stringWithFormat:@"{\"cmd\": \"success\", \"success\": \"published mid %u\"}\n",
                                                                 mid]
                                                                ];
                                                           }
                                                       }];

                                /*                  _  _
                                 * __      __ __ _ (_)| |_
                                 * \ \ /\ / // _` || || __|
                                 *  \ V  V /| (_| || || |_
                                 *   \_/\_/  \__,_||_| \__|
                                 */

                            } else if ([cmd isEqualToString:@"wait"]) {

                                NSNumber *seconds = dictJSON[@"seconds"];
                                if (!seconds) {
                                    seconds = @(5);
                                }

                                [[NSFileHandle fileHandleWithStandardOutput] prints:
                                 [NSString stringWithFormat:@"{\"cmd\": \"info\", \"info\": \"waiting for %@ seconds\"}\n",
                                  seconds]
                                 ];

                                busy = true;
                                [r runUntilDate:[NSDate dateWithTimeIntervalSinceNow:seconds.doubleValue]];
                                busy = false;

                                /*                      __  _
                                 *   ___  ___   _ __   / _|(_)  __ _
                                 *  / __|/ _ \ | '_ \ | |_ | | / _` |
                                 * | (__| (_) || | | ||  _|| || (_| |
                                 *  \___|\___/ |_| |_||_|  |_| \__, |
                                 *                             |___/
                                 */
                            } else if ([cmd isEqualToString:@"config"]) {

                                NSNumber *logLevel = dictJSON[@"logLevel"];
                                if (!logLevel) {
                                    logLevel = @(DDLogLevelWarning);
                                }

                                NSNumber *debug = dictJSON[@"debug"];
                                if (!debug) {
                                    debug = @(false);
                                }

                                NSNumber *strict = dictJSON[@"strict"];
                                if (!strict) {
                                    strict = @(false);
                                }

                                [[NSFileHandle fileHandleWithStandardOutput] prints:
                                 [NSString stringWithFormat:@"{\"cmd\": \"config\", \"config\": \"logLevel is now %@, debug is now %@, strict is now %@\"}\n",
                                  logLevel,
                                  debug,
                                  strict]
                                 ];

                                busy = true;
                                [MQTTLog setLogLevel:logLevel.intValue];
                                d.debug = debug.intValue;
                                MQTTStrict.strict = strict.boolValue;
                                busy = false;

                                /*            _  _
                                 *  ___ __  __(_)| |_
                                 * / _ \\ \/ /| || __|
                                 *|  __/ >  < | || |_
                                 * \___|/_/\_\|_| \__|
                                 */
                            } else if ([cmd isEqualToString:@"exit"]) {
                                [[NSFileHandle fileHandleWithStandardOutput] prints:@"{\"cmd\": \"info\", \"info\": \"exit\"}\n"];

                                exit(0);

                            } else {
                                [[NSFileHandle fileHandleWithStandardOutput] prints:
                                 [NSString stringWithFormat:@"{\"cmd\": \"error\", \"error\": \"unkown cmd %@\"}\n",
                                  cmd]
                                 ];
                            }

                        } else {
                            [[NSFileHandle fileHandleWithStandardOutput] prints:
                             [NSString stringWithFormat:@"{\"cmd\": \"error\", \"error\": \"no cmd in %@\"}\n",
                              ((NSObject *)dictJSON).escapedJsonString]
                             ];
                        }

                        while (busy) {
                            [r runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
                        }

                    } else {
                        [[NSFileHandle fileHandleWithStandardOutput] prints:
                         [NSString stringWithFormat:@"{\"cmd\": \"error\", \"error\": \"skipping %@\"}\n",
                          ((NSObject *)rowJSON).escapedJsonString]
                         ];
                    }
                } @catch (NSException *exception) {
                    [[NSFileHandle fileHandleWithStandardOutput] prints:
                     [NSString stringWithFormat:@"{\"cmd\": \"error\", \"error\": \"caught exception %@ %@\"}\n",
                      exception.name, exception.reason]
                     ];
                }
            }

        } else {
            NSString *inputDataString = [[NSString alloc] initWithData:inputData encoding:NSUTF8StringEncoding];
            [[NSFileHandle fileHandleWithStandardOutput] prints:
             [NSString stringWithFormat:@"{\"cmd\": \"error\", \"error\": \"ignoring %@ %@\"}\n",
              [inputDataString stringByReplacingOccurrencesOfString:@"\n" withString:@" "],
              error.localizedDescription]
             ];
            
        }

        while (true) {
            [r runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
        }
    }
    return 0;
}
