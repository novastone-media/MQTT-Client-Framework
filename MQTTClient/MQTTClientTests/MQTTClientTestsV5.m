//
//  MQTTClientTestsV5.m
//  MQTTClientTests
//
//  Created by Christoph Krey on 13.01.14.
//  Copyright © 2014-2017 Christoph Krey. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "MQTTLog.h"
#import "MQTTTestHelpers.h"
#import "MQTTSessionSynchron.h"
#import "MQTTCFSocketTransport.h"

@interface MQTTClientTestsV5 : MQTTTestHelpers
@property (nonatomic) BOOL ungraceful;
@property (nonatomic) int sent;
@property (nonatomic) int received;
@property (nonatomic) int processed;

@end

@implementation MQTTClientTestsV5

- (void)test_complete_v5 {
    for (NSString *broker in self.brokers.allKeys) {
        DDLogVerbose(@"testing broker %@", broker);
        NSDictionary *parameters = self.brokers[broker];
        if ([parameters[@"protocollevel"] integerValue] == MQTTProtocolVersion50) {
            self.session = [MQTTTestHelpers session:parameters];
            self.session.sessionExpiryInterval = @60U;
            self.session.authMethod = @"method";
            self.session.authData = [@"data" dataUsingEncoding:NSUTF8StringEncoding];
            self.session.requestProblemInformation = @1U;
            self.session.willDelayInterval = @30U;
            self.session.requestResponseInformation = @1U;
            self.session.receiveMaximum = @5U;
            self.session.topicAliasMaximum = @10U;
            self.session.userProperties = @[@{@"u1":@"v1"}, @{@"u2": @"v2"}];
            self.session.maximumPacketSize = @8192U;
            [self connect:parameters];
            XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
            [self shutdown:parameters
                returnCode:MQTTSuccess
     sessionExpiryInterval:nil
              reasonString:nil
            userProperties:nil];
        }
    }
}

- (void)test_v5_sessionExpiryInterval_5 {
    for (NSString *broker in self.brokers.allKeys) {
        DDLogVerbose(@"testing broker %@", broker);
        NSDictionary *parameters = self.brokers[broker];
        if ([parameters[@"protocollevel"] integerValue] == MQTTProtocolVersion50) {
            self.session = [MQTTTestHelpers session:parameters];
            self.session.sessionExpiryInterval = @5U;
            [self connect:parameters];
            XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
            [self shutdown:parameters
                returnCode:MQTTSuccess
     sessionExpiryInterval:nil
              reasonString:nil
            userProperties:nil];
        }
    }
}

- (void)test_v5_sessionExpiryInterval_0 {
    for (NSString *broker in self.brokers.allKeys) {
        DDLogVerbose(@"testing broker %@", broker);
        NSDictionary *parameters = self.brokers[broker];
        if ([parameters[@"protocollevel"] integerValue] == MQTTProtocolVersion50) {
            self.session = [MQTTTestHelpers session:parameters];
            self.session.sessionExpiryInterval = @0U;
            [self connect:parameters];
            XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
            [self shutdown:parameters
                returnCode:MQTTSuccess
     sessionExpiryInterval:nil
              reasonString:nil
            userProperties:nil];
        }
    }
}

- (void)test_v5_sessionExpiryInterval_none {
    for (NSString *broker in self.brokers.allKeys) {
        DDLogVerbose(@"testing broker %@", broker);
        NSDictionary *parameters = self.brokers[broker];
        if ([parameters[@"protocollevel"] integerValue] == MQTTProtocolVersion50) {
            self.session = [MQTTTestHelpers session:parameters];
            [self connect:parameters];
            XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
            [self shutdown:parameters
                returnCode:MQTTSuccess
     sessionExpiryInterval:nil
              reasonString:nil
            userProperties:nil];
        }
    }
}

- (void)test_v5_willDelayInterval_5 {
    for (NSString *broker in self.brokers.allKeys) {
        DDLogVerbose(@"testing broker %@", broker);
        NSDictionary *parameters = self.brokers[broker];
        if ([parameters[@"protocollevel"] integerValue] == MQTTProtocolVersion50) {
            self.session = [MQTTTestHelpers session:parameters];
            self.session.sessionExpiryInterval = @10U;
            self.session.willDelayInterval = @5U;
            self.session.will = [[MQTTWill alloc] initWithTopic:TOPIC
                                                           data:[@"will" dataUsingEncoding:NSUTF8StringEncoding]
                                                     retainFlag:false
                                                            qos:(MQTTQosLevel)MQTTQosLevelAtMostOnce];
            [self connect:parameters];
            XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
            [self shutdown:parameters
                returnCode:MQTTDisconnectWithWillMessage
     sessionExpiryInterval:nil
              reasonString:nil
            userProperties:nil];
        }
    }
}
- (void)test_v5_willDelayInterval_0 {
    for (NSString *broker in self.brokers.allKeys) {
        DDLogVerbose(@"testing broker %@", broker);
        NSDictionary *parameters = self.brokers[broker];
        if ([parameters[@"protocollevel"] integerValue] == MQTTProtocolVersion50) {
            self.session = [MQTTTestHelpers session:parameters];
            self.session.sessionExpiryInterval = @5U;
            self.session.willDelayInterval = @0U;
            self.session.will = [[MQTTWill alloc] initWithTopic:TOPIC
                                                           data:[@"will" dataUsingEncoding:NSUTF8StringEncoding]
                                                     retainFlag:false
                                                            qos:(MQTTQosLevel)MQTTQosLevelAtMostOnce];

            [self connect:parameters];
            XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
            [self shutdown:parameters
                returnCode:MQTTDisconnectWithWillMessage
     sessionExpiryInterval:nil
              reasonString:nil
            userProperties:nil];
        }
    }
}

- (void)test_v5_willDelayInterval_None {
    for (NSString *broker in self.brokers.allKeys) {
        DDLogVerbose(@"testing broker %@", broker);
        NSDictionary *parameters = self.brokers[broker];
        if ([parameters[@"protocollevel"] integerValue] == MQTTProtocolVersion50) {
            self.session = [MQTTTestHelpers session:parameters];
            self.session.sessionExpiryInterval = @0U;
            self.session.will = [[MQTTWill alloc] initWithTopic:TOPIC
                                                           data:[@"will" dataUsingEncoding:NSUTF8StringEncoding]
                                                     retainFlag:false
                                                            qos:(MQTTQosLevel)MQTTQosLevelAtMostOnce];
            [self connect:parameters];
            XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
            [self shutdown:parameters
                returnCode:MQTTDisconnectWithWillMessage
     sessionExpiryInterval:nil
              reasonString:nil
            userProperties:nil];
        }
    }
}


#pragma mark helpers

- (void)no_cleansession:(MQTTQosLevel)qos {
    for (NSString *broker in self.brokers.allKeys) {
        DDLogVerbose(@"testing broker %@", broker);
        NSDictionary *parameters = self.brokers[broker];
        
        DDLogVerbose(@"Cleaning topic");
        
        MQTTSession *sendingSession = [MQTTTestHelpers session:parameters];
        sendingSession.clientId = @"MQTTClient-pub";

        __block BOOL done;
        done = false;
        [sendingSession connectWithConnectHandler:^(NSError *error) {
            done = true;
        }];

        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        self.timedout = FALSE;
        [self performSelector:@selector(timedout:)
                   withObject:nil
                   afterDelay:[parameters[@"timeout"] intValue]];

        while (!done && !self.timedout) {
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }

        done = false;
        [sendingSession publishDataV5:[[NSData alloc] init]
                              onTopic:TOPIC
                               retain:TRUE
                                  qos:qos
               payloadFormatIndicator:nil
            publicationExpiryInterval:nil
                           topicAlias:nil
                        responseTopic:nil
                      correlationData:nil
                       userProperties:nil
                          contentType:nil
                       publishHandler:^(NSError * _Nullable error, NSString * _Nullable reasonString, NSArray<NSDictionary<NSString *,NSString *> *> * _Nullable userProperties, NSNumber * _Nullable reasonCode) {
                           done = true;
                       }];

        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        self.timedout = FALSE;
        [self performSelector:@selector(timedout:)
                   withObject:nil
                   afterDelay:[parameters[@"timeout"] intValue]];

        while (!done && !self.timedout) {
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }

        DDLogVerbose(@"Clearing old subs");
        self.session = [MQTTTestHelpers session:parameters];
        self.session.clientId = @"MQTTClient-sub";
        [self connect:parameters];
        [self shutdown:parameters
            returnCode:MQTTSuccess
 sessionExpiryInterval:nil
          reasonString:nil
        userProperties:nil];

        DDLogVerbose(@"Subscribing to topic");
        self.session = [MQTTTestHelpers session:parameters];
        self.session.clientId = @"MQTTClient-sub";
        self.session.cleanSessionFlag = FALSE;
        
        [self connect:parameters];

        done = false;
        [self.session subscribeToTopicV5:TOPIC
                                 atLevel:qos
                                 noLocal:NO
                       retainAsPublished:NO
                          retainHandling:MQTTSendRetained
                  subscriptionIdentifier:0
                          userProperties:nil
                        subscribeHandler:^(NSError * _Nullable error, NSString * _Nullable reasonString, NSArray<NSDictionary<NSString *,NSString *> *> * _Nullable userProperties, NSArray<NSNumber *> * _Nullable reasonCodes) {
                            done = true;
                        }];

        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        self.timedout = FALSE;
        [self performSelector:@selector(timedout:)
                   withObject:nil
                   afterDelay:[parameters[@"timeout"] intValue]];

        while (!done && !self.timedout) {
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }

        [self shutdown:parameters
            returnCode:MQTTSuccess
 sessionExpiryInterval:nil
          reasonString:nil
        userProperties:nil];

        for (int i = 1; i < BULK; i++) {
            DDLogVerbose(@"publishing to topic %d", i);
            NSString *payload = [NSString stringWithFormat:@"payload %d", i];
            done = false;
            [sendingSession publishDataV5:[payload dataUsingEncoding:NSUTF8StringEncoding]
                                  onTopic:TOPIC
                                   retain:false
                                      qos:qos
                   payloadFormatIndicator:nil
                publicationExpiryInterval:nil
                               topicAlias:nil
                            responseTopic:nil
                          correlationData:nil
                           userProperties:nil
                              contentType:nil
                           publishHandler:^(NSError * _Nullable error, NSString * _Nullable reasonString, NSArray<NSDictionary<NSString *,NSString *> *> * _Nullable userProperties, NSNumber * _Nullable reasonCode) {
                               done = true;
                           }];
            [NSObject cancelPreviousPerformRequestsWithTarget:self];
            self.timedout = FALSE;
            [self performSelector:@selector(timedout:)
                       withObject:nil
                       afterDelay:[parameters[@"timeout"] intValue]];

            while (!done && !self.timedout) {
                [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
            }
        }
        done = false;
        [sendingSession closeWithReturnCode:MQTTSuccess
                      sessionExpiryInterval:nil
                               reasonString:nil
                             userProperties:nil
                          disconnectHandler:^(NSError * _Nullable error) {
                              done = true;
                          }];
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        self.timedout = FALSE;
        [self performSelector:@selector(timedout:)
                   withObject:nil
                   afterDelay:[parameters[@"timeout"] intValue]];

        while (!done && !self.timedout) {
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }

        DDLogVerbose(@"receiving from topic");
        self.session = [MQTTTestHelpers session:parameters];
        self.session.clientId = @"MQTTClient-sub";
        self.session.cleanSessionFlag = FALSE;
        
        [self connect:parameters];
        XCTAssertEqual(self.event, MQTTSessionEventConnected, @"No MQTTSessionEventConnected %@", self.error);
        
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        self.timedout = FALSE;
        [self performSelector:@selector(timedout:)
                   withObject:nil
                   afterDelay:[parameters[@"timeout"] intValue]];
        
        while (!self.timedout) {
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }
        
        [self shutdown:parameters
            returnCode:MQTTSuccess
 sessionExpiryInterval:nil
          reasonString:nil
        userProperties:nil];
    }
}

- (void)cleansession:(MQTTQosLevel)qos {
    for (NSString *broker in self.brokers.allKeys) {
        DDLogVerbose(@"testing broker %@", broker);
        NSDictionary *parameters = self.brokers[broker];
        
        DDLogVerbose(@"Cleaning topic");
        MQTTSession *sendingSession = [MQTTTestHelpers session:parameters];
        sendingSession.clientId = @"MQTTClient-pub";

        __block BOOL done;
        done = false;
        [sendingSession connectWithConnectHandler:^(NSError * _Nullable error) {
            done = true;
            if (error) {
                XCTFail(@"no connection for pub to %@", broker);
            }
        }];
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        self.timedout = FALSE;
        [self performSelector:@selector(timedout:)
                   withObject:nil
                   afterDelay:[parameters[@"timeout"] intValue]];

        while (!done && !self.timedout) {
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }

        [sendingSession publishDataV5:[[NSData alloc] init]
                              onTopic:TOPIC
                               retain:true
                                  qos:qos
               payloadFormatIndicator:nil
            publicationExpiryInterval:nil
                           topicAlias:nil
                        responseTopic:nil
                      correlationData:nil
                       userProperties:nil
                          contentType:nil
                       publishHandler:^(NSError * _Nullable error, NSString * _Nullable reasonString, NSArray<NSDictionary<NSString *,NSString *> *> * _Nullable userProperties, NSNumber * _Nullable reasonCode) {
                           done = true;
                       }];
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        self.timedout = FALSE;
        [self performSelector:@selector(timedout:)
                   withObject:nil
                   afterDelay:[parameters[@"timeout"] intValue]];

        while (!done && !self.timedout) {
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }

        DDLogVerbose(@"Clearing old subs");
        self.session = [MQTTTestHelpers session:parameters];
        self.session.clientId = @"MQTTClient-sub";
        [self connect:parameters];
        [self shutdown:parameters
            returnCode:MQTTSuccess
 sessionExpiryInterval:nil
          reasonString:nil
        userProperties:nil];

        DDLogVerbose(@"Subscribing to topic");
        self.session = [MQTTTestHelpers session:parameters];
        self.session.clientId = @"MQTTClient-sub";
        [self connect:parameters];

        done = false;
        [self.session subscribeToTopicV5:TOPIC
                                 atLevel:qos
                                 noLocal:NO
                       retainAsPublished:NO
                          retainHandling:MQTTSendRetained
                  subscriptionIdentifier:0
                          userProperties:nil
                        subscribeHandler:^(NSError * _Nullable error, NSString * _Nullable reasonString, NSArray<NSDictionary<NSString *,NSString *> *> * _Nullable userProperties, NSArray<NSNumber *> * _Nullable reasonCodes) {
                            done = true;
                        }];
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        self.timedout = FALSE;
        [self performSelector:@selector(timedout:)
                   withObject:nil
                   afterDelay:[parameters[@"timeout"] intValue]];

        while (!done && !self.timedout) {
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }

        for (int i = 1; i < BULK; i++) {
            DDLogVerbose(@"publishing to topic %d", i);
            NSString *payload = [NSString stringWithFormat:@"payload %d", i];
            done = false;
            [sendingSession publishDataV5:[payload dataUsingEncoding:NSUTF8StringEncoding]
                                  onTopic:TOPIC
                                   retain:false
                                      qos:qos
                   payloadFormatIndicator:nil
                publicationExpiryInterval:nil
                               topicAlias:nil
                            responseTopic:nil
                          correlationData:nil
                           userProperties:nil
                              contentType:nil
                           publishHandler:^(NSError * _Nullable error, NSString * _Nullable reasonString, NSArray<NSDictionary<NSString *,NSString *> *> * _Nullable userProperties, NSNumber * _Nullable reasonCode) {
                               done = true;
                           }];
            [NSObject cancelPreviousPerformRequestsWithTarget:self];
            self.timedout = FALSE;
            [self performSelector:@selector(timedout:)
                       withObject:nil
                       afterDelay:[parameters[@"timeout"] intValue]];

            while (!done && !self.timedout) {
                [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
            }


        }
        done = false;
        [sendingSession closeWithReturnCode:MQTTSuccess
                      sessionExpiryInterval:nil
                               reasonString:nil
                             userProperties:nil
                          disconnectHandler:^(NSError * _Nullable error) {
                              done = true;
                          }];
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        self.timedout = FALSE;
        [self performSelector:@selector(timedout:)
                   withObject:nil
                   afterDelay:[parameters[@"timeout"] intValue]];

        while (!done && !self.timedout) {
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }

        
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        self.timedout = FALSE;
        [self performSelector:@selector(timedout:)
                   withObject:nil
                   afterDelay:[parameters[@"timeout"] intValue]];
        
        while (!self.timedout) {
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }
        
        [self shutdown:parameters
            returnCode:MQTTSuccess
 sessionExpiryInterval:nil
          reasonString:nil
        userProperties:nil];
    }
}

- (BOOL)newMessageWithFeedbackV5:(MQTTSession *)session
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
         subscriptionIdentifiers:(NSArray<NSNumber *> *)subscriptionIdentifiers {
    DDLogVerbose(@"newMessageWithFeedback(%lu):%@ onTopic:%@ qos:%d retained:%d mid:%d",
                 (unsigned long)self.processed, data, topic, qos, retained, mid);
    if (self.processed > self.received - 10) {
        if (!retained && [topic isEqualToString:TOPIC]) {
            self.received++;
        }
        return true;
    } else {
        return false;
    }
}

- (void)connect:(NSDictionary *)parameters{
    self.session.delegate = self;
    self.event = -1;
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    self.timedout = FALSE;
    [self performSelector:@selector(timedout:)
               withObject:nil
               afterDelay:[parameters[@"timeout"] intValue]];
    
    [self.session connectWithConnectHandler:nil];
    
    while (!self.timedout && self.event == -1) {
        DDLogVerbose(@"waiting for connection");
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
}

- (void)shutdown:(NSDictionary *)parameters
      returnCode:(MQTTReturnCode)returnCode
sessionExpiryInterval:(NSNumber *)sessionExpiryInterval
    reasonString:(NSString *)reasonString
  userProperties:(NSArray <NSDictionary <NSString *, NSString *> *> *)userProperties {
    if (!self.ungraceful) {
        self.event = -1;

        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        self.timedout = FALSE;
        [self performSelector:@selector(timedout:)
                   withObject:nil
                   afterDelay:[parameters[@"timeout"] intValue]];

        [self.session closeWithReturnCode:returnCode
                    sessionExpiryInterval:sessionExpiryInterval
                             reasonString:reasonString
                           userProperties:userProperties
                        disconnectHandler:nil];

        while (self.event == -1 && !self.timedout) {
            DDLogVerbose(@"waiting for disconnect");
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }

        XCTAssert(!self.timedout, @"timeout");
        [NSObject cancelPreviousPerformRequestsWithTarget:self];

        self.session.delegate = nil;
        self.session = nil;
    }
}

@end
