//
//  MQTTClientPublishTests.m
//  MQTTClient
//
//  Created by Christoph Krey on 05.02.14.
//  Copyright (c) 2014 Christoph Krey. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MQTTClient.h"
#import "MQTTClientTests.h"

@interface MQTTClientPublishTests : XCTestCase <MQTTSessionDelegate>
@property (strong, nonatomic) MQTTSession *session;
@property (nonatomic) NSInteger event;
@property (strong, nonatomic) NSError *error;
@property (nonatomic) UInt16 mid;
@property (nonatomic) UInt16 sentMid;
@property (nonatomic) NSInteger qos;
@property (nonatomic) BOOL timeout;
@property (nonatomic) NSTimeInterval timeoutValue;
@property (nonatomic) NSInteger type;
@property (nonatomic) BOOL blockQos2;

@end

@implementation MQTTClientPublishTests

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testPublish_r0_q0_noPayload
{
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        [self connect:parameters];
        [self testPublish:nil
                  onTopic:[NSString stringWithFormat:@"%@/%s", TOPIC, __FUNCTION__]
                   retain:NO
                  atLevel:0];
        [self shutdown:parameters];
    }
}

- (void)testPublish_r0_q0_zeroLengthPayload
{
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        [self connect:parameters];
        [self testPublish:[[NSData alloc] init]
                  onTopic:[NSString stringWithFormat:@"%@/%s", TOPIC, __FUNCTION__]
                   retain:NO
                  atLevel:0];
        [self shutdown:parameters];
    }
}

- (void)testPublish_r0_q0
{
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        [self connect:parameters];
        [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
                  onTopic:[NSString stringWithFormat:@"%@/%s", TOPIC, __FUNCTION__]
                   retain:NO
                  atLevel:0];
        [self shutdown:parameters];
    }
}

/*
 * [MQTT-1.5.3-3]
 * A UTF-8 encoded sequence 0xEF 0xBB 0xBF is always to be interpreted to mean
 * U+FEFF ("ZERO WIDTH NO-BREAK SPACE") wherever it appears in a string and
 * MUST NOT be skipped over or stripped off by a packet receiver.
 */
- (void)testPublish_r0_q0_0xFEFF_MQTT_1_5_3_3
{
    unichar feff = 0xFEFF;

    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        [self connect:parameters];
        [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
                  onTopic:[NSString stringWithFormat:@"%@<%C>/%s", TOPIC, feff, __FUNCTION__]
                   retain:NO
                  atLevel:0];
        [self shutdown:parameters];
    }
}

/*
 * [MQTT-1.5.3-1]
 * The character data in a UTF-8 encoded string MUST be well-formed UTF-8 as defined by the
 * Unicode specification [Unicode] and restated in RFC 3629 [RFC3629]. In particular this data MUST NOT
 * include encodings of code points between U+D800 and U+DFFF. If a Server or Client receives a Control
 * Packet containing ill-formed UTF-8 it MUST close the Network Connection.
 */
- (void)testPublish_r0_q0_0xD800_MQTT_1_5_3_1
{
    NSLog(@"can't test [MQTT-1.5.3-1]");
    NSString *stringWithD800 = [NSString stringWithFormat:@"%@/%C/%s", TOPIC, 0xD800, __FUNCTION__];
    NSLog(@"stringWithNull(%lu) %@", (unsigned long)stringWithD800.length, stringWithD800.description);
    
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        [self connect:parameters];
        [self testPublishCloseExpected:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
                               onTopic:stringWithD800
                                retain:NO
                               atLevel:MQTTQosLevelAtMostOnce];
        [self shutdown:parameters];
    }
}

/*
 * [MQTT-1.5.3-2]
 * A UTF-8 encoded string MUST NOT include an encoding of the null character U+0000.
 * If a receiver (Server or Client) receives a Control Packet containing U+0000 it MUST close the Network Connection.
 */
- (void)testPublish_r0_q0_0x0000_MQTT_1_5_3_2
{
    NSString *stringWithNull = [NSString stringWithFormat:@"%@/%C/%s", TOPIC, 0, __FUNCTION__];
    NSLog(@"stringWithNull(%lu) %@", (unsigned long)stringWithNull.length, stringWithNull.description);

    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        [self connect:parameters];
        [self testPublishCloseExpected:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
                               onTopic:stringWithNull
                                retain:NO
                               atLevel:MQTTQosLevelAtMostOnce];
        [self shutdown:parameters];
    }
}

- (void)testPublish_r0_q1
{
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        [self connect:parameters];
        [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
                  onTopic:[NSString stringWithFormat:@"%@/%s", TOPIC, __FUNCTION__]
                   retain:NO
                  atLevel:1];
        [self shutdown:parameters];
    }
}

- (void)testPublish_a_lot_of_q0
{
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        [self connect:parameters];
        for (int i = 0; i < ALOT; i++) {
            NSData *data = [[NSString stringWithFormat:@"%@/%s/%d", TOPIC, __FUNCTION__, i] dataUsingEncoding:NSUTF8StringEncoding];
            NSString *topic = [NSString stringWithFormat:@"%@/%s/%d", TOPIC, __FUNCTION__, i];
            self.sentMid = [self.session publishData:data onTopic:topic retain:false qos:MQTTQosLevelAtMostOnce];
            NSLog(@"testing publish %d", self.sentMid);
        }
        [self shutdown:parameters];
    }
}

- (void)testPublish_a_lot_of_q1
{
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        [self connect:parameters];
        self.session.persistence.maxWindowSize = 256;
        for (int i = 0; i < ALOT; i++) {
            NSData *data = [[NSString stringWithFormat:@"%@/%s/%d", TOPIC, __FUNCTION__, i] dataUsingEncoding:NSUTF8StringEncoding];
            NSString *topic = [NSString stringWithFormat:@"%@/%s/%d", TOPIC, __FUNCTION__, i];
            self.sentMid = [self.session publishData:data onTopic:topic retain:false qos:MQTTQosLevelAtLeastOnce];
            NSLog(@"testing publish %d", self.sentMid);
        }
        self.mid = 0;
        self.timeout = false;
        self.event = -1;
        [self performSelector:@selector(ackTimeout:)
                   withObject:nil
                   afterDelay:self.timeoutValue];
        
        while (self.mid != self.sentMid && !self.timeout && self.event == -1) {
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }
        
        [self shutdown:parameters];
    }
}

- (void)testPublish_a_lot_of_q2
{
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        [self connect:parameters];
        for (int i = 0; i < ALOT; i++) {
            NSData *data = [[NSString stringWithFormat:@"%@/%s/%d", TOPIC, __FUNCTION__, i] dataUsingEncoding:NSUTF8StringEncoding];
            NSString *topic = [NSString stringWithFormat:@"%@/%s/%d", TOPIC, __FUNCTION__, i];
            self.sentMid = [self.session publishData:data onTopic:topic retain:false qos:MQTTQosLevelExactlyOnce];
            NSLog(@"testing publish %d", self.sentMid);
        }
        self.mid = 0;
        self.event = -1;
        
        while (self.mid != self.sentMid && !self.timeout && self.event == -1) {
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }
        
        [self shutdown:parameters];
    }
}

/*
 * [MQTT-3.3.1-11]
 * A zero byte retained message MUST NOT be stored as a retained message on the Server.
 */
- (void)testPublish_r1_MQTT_3_3_1_11
{
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        [self connect:parameters];
        [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
                  onTopic:[NSString stringWithFormat:@"%@/%s", TOPIC, __FUNCTION__]
                   retain:YES
                  atLevel:MQTTQosLevelAtLeastOnce];
        [self testPublish:[@"" dataUsingEncoding:NSUTF8StringEncoding]
                  onTopic:[NSString stringWithFormat:@"%@/%s", TOPIC, __FUNCTION__]
                   retain:YES
                  atLevel:MQTTQosLevelAtLeastOnce];
        [self shutdown:parameters];
    }
}

- (void)testPublish_r0_q2
{
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        [self connect:parameters];
        [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
                  onTopic:[NSString stringWithFormat:@"%@/%s", TOPIC, __FUNCTION__]
                   retain:NO
                  atLevel:2];
        [self shutdown:parameters];
    }
}

- (void)testPublish_r1_q2
{
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        [self connect:parameters];
        [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
                  onTopic:[NSString stringWithFormat:@"%@/%s", TOPIC, __FUNCTION__]
                   retain:YES
                  atLevel:2];
        [self shutdown:parameters];
    }
}

/*
 * [MQTT-3.3.2-1]
 * The Topic Name MUST be present as the first field in the PUBLISH Packet Variable header.
 * It MUST be a UTF-8 encoded string.
 */
- (void)testPublishNoUTF8_MQTT_3_3_2_1
{
    NSLog(@"Can't test[MQTT-3.3.2-1]");
}

- (void)testPublishWithPlus_MQTT_3_3_2_2
{
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        [self connect:parameters];

        NSString *topic = [NSString stringWithFormat:@"%@/+%s", TOPIC, __FUNCTION__];
        NSLog(@"publishing to topic:%@", topic);

        [self testPublishCloseExpected:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
                               onTopic:topic
                                retain:YES
                               atLevel:2];
        [self shutdown:parameters];
    }
}

- (void)testPublishWithHash_MQTT_3_3_2_2
{
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        [self connect:parameters];
        NSString *topic = [NSString stringWithFormat:@"%@/#%s", TOPIC, __FUNCTION__];
        NSLog(@"publishing to topic:%@", topic);

        [self testPublishCloseExpected:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
                               onTopic:topic
                                retain:YES
                               atLevel:2];
        [self shutdown:parameters];
    }
}

- (void)testPublishEmptyTopic_MQTT_4_7_3_1
{
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        [self connect:parameters];
        [self testPublishCloseExpected:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
                               onTopic:@""
                                retain:YES
                               atLevel:2];
        [self shutdown:parameters];
    }
}

- (void)testPublish_q1
{
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        [self connect:parameters];
        [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
                  onTopic:[NSString stringWithFormat:@"%@/%s", TOPIC, __FUNCTION__]
                   retain:NO
                  atLevel:MQTTQosLevelAtLeastOnce];
        [self shutdown:parameters];
    }
}

- (void)testPublish_q1_x2
{
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        [self connect:parameters];
        [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
                  onTopic:[NSString stringWithFormat:@"%@/1%s", TOPIC, __FUNCTION__]
                   retain:NO
                  atLevel:MQTTQosLevelAtLeastOnce];

        [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
                  onTopic:[NSString stringWithFormat:@"%@/2%s", TOPIC, __FUNCTION__]
                   retain:NO
                  atLevel:MQTTQosLevelAtLeastOnce];
        [self shutdown:parameters];
        [self connect:parameters];
        [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
                  onTopic:[NSString stringWithFormat:@"%@/3%s", TOPIC, __FUNCTION__]
                   retain:NO
                  atLevel:MQTTQosLevelAtLeastOnce];
        [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
                  onTopic:[NSString stringWithFormat:@"%@/4%s", TOPIC, __FUNCTION__]
                   retain:NO
                  atLevel:MQTTQosLevelAtLeastOnce];
        [self shutdown:parameters];
    }
}

- (void)testPublish_q2
{
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        [self connect:parameters];
        [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
                  onTopic:[NSString stringWithFormat:@"%@/1%s", TOPIC, __FUNCTION__]
                   retain:NO
                  atLevel:MQTTQosLevelExactlyOnce];
        [self shutdown:parameters];
    }
}

- (void)testPublish_q2_x2
{
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        [self connect:parameters];
        [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
                  onTopic:[NSString stringWithFormat:@"%@/1%s", TOPIC, __FUNCTION__]
                   retain:NO
                  atLevel:MQTTQosLevelExactlyOnce];
        [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
                  onTopic:[NSString stringWithFormat:@"%@/2%s", TOPIC, __FUNCTION__]
                   retain:NO
                  atLevel:MQTTQosLevelExactlyOnce];
        [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
                  onTopic:[NSString stringWithFormat:@"%@/3%s", TOPIC, __FUNCTION__]
                   retain:NO
                  atLevel:MQTTQosLevelExactlyOnce];
        [self shutdown:parameters];
        [self connect:parameters];
        [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
                  onTopic:[NSString stringWithFormat:@"%@/4%s", TOPIC, __FUNCTION__]
                   retain:NO
                  atLevel:MQTTQosLevelExactlyOnce];
        [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
                  onTopic:[NSString stringWithFormat:@"%@/5%s", TOPIC, __FUNCTION__]
                   retain:NO
                  atLevel:MQTTQosLevelExactlyOnce];
        [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
                  onTopic:[NSString stringWithFormat:@"%@/6%s", TOPIC, __FUNCTION__]
                   retain:NO
                  atLevel:MQTTQosLevelExactlyOnce];
        [self shutdown:parameters];
    }
}


- (void)testPublish_q2_dup_MQTT_3_3_1_2
{
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        [self connect:parameters];
        self.timeoutValue= 90;
        self.blockQos2 = true;
        [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
                  onTopic:[NSString stringWithFormat:@"%@/1%s", TOPIC, __FUNCTION__]
                   retain:NO
                  atLevel:MQTTQosLevelExactlyOnce];
        [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
                  onTopic:[NSString stringWithFormat:@"%@/2%s", TOPIC, __FUNCTION__]
                   retain:NO
                  atLevel:MQTTQosLevelExactlyOnce];
        self.blockQos2 = true;
        [self testPublish:[@(__FUNCTION__) dataUsingEncoding:NSUTF8StringEncoding]
                  onTopic:[NSString stringWithFormat:@"%@/3%s", TOPIC, __FUNCTION__]
                   retain:NO
                  atLevel:MQTTQosLevelExactlyOnce];
        [self shutdown:parameters];
    }
}



/*
 * helpers
 */

- (NSArray *)clientCerts:(NSDictionary *)parameters {
    NSArray *clientCerts = nil;
    if (parameters[@"clientp12"] && parameters[@"clientp12pass"]) {
        
        NSString *path = [[NSBundle bundleForClass:[MQTTClientPublishTests class]] pathForResource:parameters[@"clientp12"]
                                                                                  ofType:@"p12"];
        
        clientCerts = [MQTTSession clientCertsFromP12:path passphrase:parameters[@"clientp12pass"]];
        if (!clientCerts) {
            XCTFail(@"invalid p12 file");
        }
    }
    return clientCerts;
}

- (MQTTSSLSecurityPolicy *)securityPolicy:(NSDictionary *)parameters {
    MQTTSSLSecurityPolicy *securityPolicy = nil;
    
    if (parameters[@"serverCER"]) {
        
        NSString *path = [[NSBundle bundleForClass:[MQTTClientPublishTests class]] pathForResource:parameters[@"serverCER"]
                                                                                  ofType:@"cer"];
        if (path) {
            NSData *certificateData = [NSData dataWithContentsOfFile:path];
            if (certificateData) {
                securityPolicy = [MQTTSSLSecurityPolicy policyWithPinningMode:MQTTSSLPinningModeCertificate];
                securityPolicy.pinnedCertificates = [[NSArray alloc] initWithObjects:certificateData, nil];
                securityPolicy.validatesCertificateChain = TRUE;
                securityPolicy.allowInvalidCertificates = FALSE;
                securityPolicy.validatesDomainName = TRUE;
            } else {
                XCTFail(@"error reading cer file");
            }
        } else {
            XCTFail(@"cer file not found");
        }
    }
    return securityPolicy;
}

- (void)testPublishCloseExpected:(NSData *)data onTopic:(NSString *)topic retain:(BOOL)retain atLevel:(UInt8)qos
{
    [self testPublishCore:data onTopic:topic retain:retain atLevel:qos];
    NSLog(@"testPublishCloseExpected event:%ld", (long)self.event);
    XCTAssert(
              (self.event == MQTTSessionEventConnectionClosedByBroker) ||
              (self.event == MQTTSessionEventConnectionError),
              @"No MQTTSessionEventConnectionClosedByBroker or MQTTSessionEventConnectionError happened");
}

- (void)testPublish:(NSData *)data onTopic:(NSString *)topic retain:(BOOL)retain atLevel:(UInt8)qos
{
    [self testPublishCore:data onTopic:topic retain:retain atLevel:qos];
    switch (qos % 4) {
        case 0:
            XCTAssert(self.event == -1, @"Event %ld happened", (long)self.event);
            XCTAssert(self.timeout, @"Responses during %f seconds timeout", self.timeoutValue);
            break;
        case 1:
            XCTAssert(self.event == -1, @"Event %ld happened", (long)self.event);
            XCTAssertFalse(self.timeout, @"Timeout after %f seconds", self.timeoutValue);
            XCTAssert(self.mid == self.sentMid, @"sentMid(%ld) != mid(%ld)", (long)self.sentMid, (long)self.mid);
            break;
        case 2:
            XCTAssert(self.event == -1, @"Event %ld happened", (long)self.event);
            XCTAssertFalse(self.timeout, @"Timeout after %f seconds", self.timeoutValue);
            XCTAssert(self.mid == self.sentMid, @"sentMid(%ld) != mid(%ld)", (long)self.sentMid, (long)self.mid);
            break;
        case 3:
        default:
            XCTAssert(self.event == (long)MQTTSessionEventConnectionClosed, @"no close received");
            break;
    }
}

- (void)testPublishCore:(NSData *)data onTopic:(NSString *)topic retain:(BOOL)retain atLevel:(UInt8)qos
{
    self.mid = 0;
    self.sentMid = [self.session publishData:data onTopic:topic retain:retain qos:qos];
    [self performSelector:@selector(ackTimeout:)
               withObject:nil
               afterDelay:self.timeoutValue];

    while (self.mid == 0 && !self.timeout && self.event == -1) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
}

- (void)ackTimeout:(NSTimeInterval)timeout
{
    self.timeout = TRUE;
}

- (void)newMessage:(MQTTSession *)session data:(NSData *)data onTopic:(NSString *)topic qos:(MQTTQosLevel)qos retained:(BOOL)retained mid:(unsigned int)mid
{
    //NSLog(@"newMessage:%@ onTopic:%@ qos:%d retained:%d mid:%d", data, topic, qos, retained, mid);
    self.mid = mid;
}

- (void)handleEvent:(MQTTSession *)session event:(MQTTSessionEvent)eventCode error:(NSError *)error
{
    NSLog(@"handleEvent:%ld error:%@", (long)eventCode, error);
    self.event = eventCode;
    self.error = error;
}

- (void)messageDelivered:(MQTTSession *)session msgID:(UInt16)msgID
{
    NSLog(@"messageDelivered:%ld", (long)msgID);
    self.mid = msgID;
}

- (void)received:(MQTTSession *)session type:(int)type qos:(MQTTQosLevel)qos retained:(BOOL)retained duped:(BOOL)duped mid:(UInt16)mid data:(NSData *)data {
    //NSLog(@"received:%d qos:%d retained:%d duped:%d mid:%d data:%@", type, qos, retained, duped, mid, data);
    self.type = type;
}

- (BOOL)ignoreReceived:(MQTTSession *)session type:(int)type qos:(MQTTQosLevel)qos retained:(BOOL)retained duped:(BOOL)duped mid:(UInt16)mid data:(NSData *)data {
    //NSLog(@"ignoreReceived:%d qos:%d retained:%d duped:%d mid:%d data:%@", type, qos, retained, duped, mid, data);
    if (self.blockQos2 && type == MQTTPubrec) {
        self.blockQos2 = false;
        return true;
    }
    return false;
}

- (void)connect:(NSDictionary *)parameters {
    self.session = [[MQTTSession alloc] initWithClientId:nil
                                                userName:parameters[@"user"]
                                                password:parameters[@"pass"]
                                               keepAlive:60
                                            cleanSession:YES
                                                    will:NO
                                               willTopic:nil
                                                 willMsg:nil
                                                 willQoS:0
                                          willRetainFlag:NO
                                           protocolLevel:[parameters[@"protocollevel"] intValue]
                                                 runLoop:[NSRunLoop currentRunLoop]
                                                 forMode:NSRunLoopCommonModes
                                          securityPolicy:[self securityPolicy:parameters]
                                            certificates:[self clientCerts:parameters]];
    self.session.delegate = self;
    self.session.persistence.persistent = PERSISTENT;

    self.event = -1;

    self.timeout = FALSE;
    self.timeoutValue = [parameters[@"timeout"] doubleValue];
    [self performSelector:@selector(ackTimeout:)
               withObject:nil
               afterDelay:self.timeoutValue];

    [self.session connectToHost:parameters[@"host"]
                           port:[parameters[@"port"] intValue]
                       usingSSL:[parameters[@"tls"] boolValue]];

    while (self.event == -1 && !self.timeout) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }

    XCTAssert(!self.timeout, @"timeout");
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);

    [NSObject cancelPreviousPerformRequestsWithTarget:self];

    self.timeout = FALSE;
    self.type = -1;
    self.mid = 0;
    self.qos = -1;
    self.event = -1;
}

- (void)shutdown:(NSDictionary *)parameters {
    self.event = -1;

    self.timeout = FALSE;
    [self performSelector:@selector(ackTimeout:)
               withObject:parameters[@"timeout"]
               afterDelay:[parameters[@"timeout"] intValue]];

    [self.session close];

    while (self.event == -1 && !self.timeout) {
        //NSLog(@"waiting for disconnect");
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    
    XCTAssert(!self.timeout, @"timeout");
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    self.session.delegate = nil;
    self.session = nil;
}



@end
