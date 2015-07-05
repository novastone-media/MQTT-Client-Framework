//
//  MQTTClientTests.m
//  MQTTClientTests
//
//  Created by Christoph Krey on 13.01.14.
//  Copyright (c) 2014 Christoph Krey. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MQTTClient.h"
#import "MQTTClientTests.h"

@interface MQTTClientTests : XCTestCase <MQTTSessionDelegate>
@property (strong, nonatomic) MQTTSession *session;
@property (nonatomic) int event;
@property (strong, nonatomic) NSError *error;
@property (nonatomic) BOOL timeout;
@property (nonatomic) int type;
@property (nonatomic) BOOL ungraceful;
@end

@implementation MQTTClientTests

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
}

- (void)test_init {
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        self.session = [[MQTTSession alloc] init];
        [self connect:self.session parameters:parameters];
        XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
        [self shutdown:parameters];
    }
}

- (void)test_init_zero_clientId_clean {
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        self.session = [[MQTTSession alloc] initWithClientId:@""
                                                    userName:nil
                                                    password:nil
                                                   keepAlive:60
                                                cleanSession:YES
                                                        will:NO
                                                   willTopic:nil
                                                     willMsg:nil
                                                     willQoS:0
                                              willRetainFlag:NO
                                               protocolLevel:[parameters[@"protocollevel"] intValue]
                                                     runLoop:[NSRunLoop currentRunLoop]
                                                     forMode:NSRunLoopCommonModes];
        [self connect:self.session parameters:parameters];
        XCTAssert(!self.timeout, @"timeout");
        XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
        [self shutdown:parameters];
    }
}

/*
 * [MQTT-3.1.3-8]
 * If the Client supplies a zero-byte ClientId with CleanSession set to 0, the Server MUST
 * respond to the CONNECT Packet with a CONNACK return code 0x02 (Identifier rejected) and 
 * then close the Network Connection.
 * [MQTT-3.1.3-9]
 * If the Server rejects the ClientId it MUST respond to the CONNECT Packet with a
 * CONNACK return code 0x02 (Identifier rejected) and then close the Network Connection.
 */
- (void)test_init_zero_clientId_noclean_MQTT_3_1_3_8_MQTT_3_1_3_9 {
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        self.session = [[MQTTSession alloc] initWithClientId:@""
                                                    userName:nil
                                                    password:nil
                                                   keepAlive:60
                                                cleanSession:NO
                                                        will:NO
                                                   willTopic:nil
                                                     willMsg:nil
                                                     willQoS:0
                                              willRetainFlag:NO
                                               protocolLevel:[parameters[@"protocollevel"] intValue]
                                                     runLoop:[NSRunLoop currentRunLoop]
                                                     forMode:NSRunLoopCommonModes];
        [self connect:self.session parameters:parameters];
        XCTAssert(!self.timeout, @"timeout");
        XCTAssertEqual(self.event, MQTTSessionEventConnectionRefused, @"MQTTSessionEventConnectionRefused %@", self.error);
        XCTAssert(self.error.code == 0x02, @"error = %@", self.error);
        [self shutdown:parameters];
    }
}

- (void)test_init_long_clientId {
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        self.session = [[MQTTSession alloc] initWithClientId:@"123456789.123456789.1234"
                                                    userName:nil
                                                    password:nil
                                                   keepAlive:60
                                                cleanSession:YES
                                                        will:NO
                                                   willTopic:nil
                                                     willMsg:nil
                                                     willQoS:0
                                              willRetainFlag:NO
                                               protocolLevel:[parameters[@"protocollevel"] intValue]
                                                     runLoop:[NSRunLoop currentRunLoop]
                                                     forMode:NSRunLoopCommonModes];
        [self connect:self.session parameters:parameters];
        XCTAssert(!self.timeout, @"timeout");
        XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
        [self shutdown:parameters];
    }
}

- (void)test_init_no_clientId {
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
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
                                               protocolLevel:[parameters[@"protocollevel"] intValue]
                                                     runLoop:[NSRunLoop currentRunLoop]
                                                     forMode:NSRunLoopCommonModes];
        [self connect:self.session parameters:parameters];
        XCTAssert(!self.timeout, @"timeout");
        XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
        [self shutdown:parameters];
    }
}

- (void)test_connect_standard_port {
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
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
                                               protocolLevel:[parameters[@"protocollevel"] intValue]
                                                     runLoop:[NSRunLoop currentRunLoop]
                                                     forMode:NSRunLoopCommonModes];
        [self connect:self.session parameters:parameters];
        XCTAssert(!self.timeout, @"timeout");
        XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
        [self shutdown:parameters];
    }
}

- (void)test_connect_short {
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        self.session = [[MQTTSession alloc] initWithClientId:nil
                                                    userName:nil
                                                    password:nil
                                                   keepAlive:60
                                                cleanSession:YES];
        [self connect:self.session parameters:parameters];
        XCTAssert(!self.timeout, @"timeout");
        XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
        [self shutdown:parameters];
    }
}

/*
 * [MQTT-3.1.2-8]
 * If the Will Flag is set to 1 this indicates that, if the Connect request is accepted, a Will
 * Message MUST be stored on the Server and associated with the Network Connection. The Will Message
 * MUST be published when the Network Connection is subsequently closed unless the Will Message has
 * been deleted by the Server on receipt of a DISCONNECT Packet.
 * [MQTT-3.1.2-16]
 * If the Will Flag is set to 1 and If Will Retain is set to 0, the Server MUST publish the Will
 * Message as a non-retained message.
 */
- (void)test_connect_will_non_retained_MQTT_3_1_2_8_MQTT_3_1_2_16 {
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];

        MQTTSession *subscribingSession = [[MQTTSession alloc] initWithClientId:@"MQTTClient-sub"
                                                                       userName:nil
                                                                       password:nil
                                                                      keepAlive:60
                                                                   cleanSession:YES
                                                                           will:NO
                                                                      willTopic:nil
                                                                        willMsg:nil
                                                                        willQoS:0
                                                                 willRetainFlag:NO
                                                                  protocolLevel:[parameters[@"protocollevel"] intValue]
                                                                        runLoop:[NSRunLoop currentRunLoop]
                                                                        forMode:NSRunLoopCommonModes];
        if (![subscribingSession connectAndWaitToHost:parameters[@"host"] port:[parameters[@"port"] intValue] usingSSL:[parameters[@"tls"] boolValue]]) {
            XCTFail(@"no connection for sub to %@", broker);
        }
        [subscribingSession subscribeAndWaitToTopic:TOPIC atLevel:0];

        self.session = [[MQTTSession alloc] initWithClientId:nil
                                                    userName:nil
                                                    password:nil
                                                   keepAlive:10
                                                cleanSession:YES
                                                        will:YES
                                                   willTopic:TOPIC
                                                     willMsg:[@"will-qos0-non-retained" dataUsingEncoding:NSUTF8StringEncoding]
                                                     willQoS:0
                                              willRetainFlag:NO
                                               protocolLevel:[parameters[@"protocollevel"] intValue]
                                                     runLoop:[NSRunLoop currentRunLoop]
                                                     forMode:NSRunLoopCommonModes];
        [self connect:self.session parameters:parameters];
        XCTAssert(!self.timeout, @"timeout");
        XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);

        self.ungraceful = TRUE;
        [self shutdown:parameters];
        [subscribingSession closeAndWait];
    }
}

/*
 * [MQTT-3.1.4-2]
 * If the ClientId represents a Client already connected to the Server then the Server MUST disconnect the existing Client.
 */

- (void)test_disconnect_when_same_clientID_connects_MQTT_3_1_4_2 {
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];

        self.session = [[MQTTSession alloc] initWithClientId:@"MQTTClient"
                                                    userName:nil
                                                    password:nil
                                                   keepAlive:10
                                                cleanSession:YES
                                                        will:NO
                                                   willTopic:nil
                                                     willMsg:nil
                                                     willQoS:0
                                              willRetainFlag:NO
                                               protocolLevel:[parameters[@"protocollevel"] intValue]
                                                     runLoop:[NSRunLoop currentRunLoop]
                                                     forMode:NSRunLoopCommonModes];
        [self connect:self.session parameters:parameters];
        XCTAssert(!self.timeout, @"timeout");
        XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);


        MQTTSession *sameSession = [[MQTTSession alloc] initWithClientId:@"MQTTClient"
                                                                userName:nil
                                                                password:nil
                                                               keepAlive:60
                                                            cleanSession:YES
                                                                    will:NO
                                                               willTopic:nil
                                                                 willMsg:nil
                                                                 willQoS:0
                                                          willRetainFlag:NO
                                                           protocolLevel:[parameters[@"protocollevel"] intValue]
                                                                 runLoop:[NSRunLoop currentRunLoop]
                                                                 forMode:NSRunLoopCommonModes];
        if (![sameSession connectAndWaitToHost:parameters[@"host"]
                                          port:[parameters[@"port"] intValue]
                                      usingSSL:[parameters[@"tls"] boolValue]]) {
            XCTFail(@"no connection for same Session to %@", broker);
        }

        [self shutdown:parameters];
        [sameSession closeAndWait];
    }
}

/*
 * [MQTT-3.1.2-8]
 * If the Will Flag is set to 1 this indicates that, if the Connect request is accepted, a Will
 * Message MUST be stored on the Server and associated with the Network Connection. The Will Message
 * MUST be published when the Network Connection is subsequently closed unless the Will Message has
 * been deleted by the Server on receipt of a DISCONNECT Packet.
 * [MQTT-3.1.2-17]
 * If the Will Flag is set to 1 and If Will Retain is set to 1, the Server MUST publish the Will
 * Message as a retained message.
 */
- (void)test_connect_will_retained_MQTT_3_1_2_8_MQTT_3_1_2_17 {
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];

        MQTTSession *subscribingSession = [[MQTTSession alloc] initWithClientId:@"MQTTClient-sub"
                                                                       userName:nil
                                                                       password:nil
                                                                      keepAlive:60
                                                                   cleanSession:YES
                                                                           will:NO
                                                                      willTopic:nil
                                                                        willMsg:nil
                                                                        willQoS:0
                                                                 willRetainFlag:NO
                                                                  protocolLevel:[parameters[@"protocollevel"] intValue]
                                                                        runLoop:[NSRunLoop currentRunLoop]
                                                                        forMode:NSRunLoopCommonModes];
        if (![subscribingSession connectAndWaitToHost:parameters[@"host"] port:[parameters[@"port"] intValue] usingSSL:[parameters[@"tls"] boolValue]]) {
            XCTFail(@"no connection for sub to %@", broker);
        }
        [subscribingSession subscribeAndWaitToTopic:TOPIC atLevel:0];

        self.session = [[MQTTSession alloc] initWithClientId:nil
                                                    userName:nil
                                                    password:nil
                                                   keepAlive:10
                                                cleanSession:YES
                                                        will:YES
                                                   willTopic:TOPIC
                                                     willMsg:[@"will-qos0-retained" dataUsingEncoding:NSUTF8StringEncoding]
                                                     willQoS:0
                                              willRetainFlag:YES
                                               protocolLevel:[parameters[@"protocollevel"] intValue]
                                                     runLoop:[NSRunLoop currentRunLoop]
                                                     forMode:NSRunLoopCommonModes];
        [self connect:self.session parameters:parameters];
        XCTAssert(!self.timeout, @"timeout");
        XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);

        self.ungraceful = TRUE;
        [self shutdown:parameters];
        [subscribingSession closeAndWait];
    }
}

/*
 * [MQTT-3.1.3-1]
 * These fields, if present, MUST appear in the order Client Identifier, Will Topic, Will Message, User Name, Password.
*/
- (void)test_connect_all_fields_MQTT_3_1_3_1 {
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        self.session = [[MQTTSession alloc] initWithClientId:@"ClientID"
                                                    userName:@"username"
                                                    password:@"password"
                                                   keepAlive:10
                                                cleanSession:YES
                                                        will:YES
                                                   willTopic:@"MQTTClient/will-qos0"
                                                     willMsg:[@"will-qos0" dataUsingEncoding:NSUTF8StringEncoding]
                                                     willQoS:0
                                              willRetainFlag:NO
                                               protocolLevel:[parameters[@"protocollevel"] intValue]
                                                     runLoop:[NSRunLoop currentRunLoop]
                                                     forMode:NSRunLoopCommonModes];
        [self connect:self.session parameters:parameters];
        XCTAssert(!self.timeout, @"timeout");
        XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);

        self.ungraceful = TRUE;
        [self shutdown:parameters];
    }
}

/*
 * [MQTT-3.1.2-1]
 * If the protocol name is incorrect the Server MAY disconnect the Client, or it MAY
 * continue processing the CONNECT packet in accordance with some other specification.
 * In the latter case, the Server MUST NOT continue to process the CONNECT packet in line with this specification.
 */
- (void)test_connect_other_protocollevel34__MQTT_3_1_2_1 {
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
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
                                               protocolLevel:[parameters[@"protocollevel"] intValue] == 3 ? 4 : 3
                                                     runLoop:[NSRunLoop currentRunLoop]
                                                     forMode:NSRunLoopCommonModes];
        [self connect:self.session parameters:parameters];
        XCTAssert(!self.timeout, @"timeout");
        XCTAssertEqual(self.event, MQTTSessionEventConnected, @"No MQTTSessionEventConnected %@", self.error);

        [self shutdown:parameters];
    }
}

/*
 * [MQTT-3.1.2-2]
 * The Server MUST respond to the CONNECT Packet with a CONNACK return code
 * 0x01 (unacceptable protocol level) and then disconnect the Client if the Protocol
 * Level is not supported by the Server.
 * [MQTT-3.2.2-5]
 * If a server sends a CONNACK packet containing a non-zero return code it MUST then close the Network Connection.
 */
- (void)test_connect_illegal_protocollevel5_MQTT_3_1_2_2_MQTT_3_2_2_5 {
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
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
                                               protocolLevel:5
                                                     runLoop:[NSRunLoop currentRunLoop]
                                                     forMode:NSRunLoopCommonModes];
        [self connect:self.session parameters:parameters];
        XCTAssert(!self.timeout, @"timeout");
        XCTAssertEqual(self.event, MQTTSessionEventConnectionRefused, @"MQTTSessionEventConnectionRefused %@", self.error);
        XCTAssert(self.error.code == 0x01, @"error = %@", self.error);
        [self shutdown:parameters];
    }
}

/*
 * [MQTT-3.1.2-1]
 * If the protocol name is incorrect the Server MAY disconnect the Client, or it MAY
 * continue processing the CONNECT packet in accordance with some other specification.
 * In the latter case, the Server MUST NOT continue to process the CONNECT packet in line with this specification.
 */
- (void)test_connect_illegal_protocollevel0_MQTT_3_1_2_1 {
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
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
                                               protocolLevel:0
                                                     runLoop:[NSRunLoop currentRunLoop]
                                                     forMode:NSRunLoopCommonModes];
        [self connect:self.session parameters:parameters];
        XCTAssert(!self.timeout, @"timeout");
        if (self.event == MQTTSessionEventConnectionClosedByBroker || (self.event == MQTTSessionEventConnectionRefused && self.error && self.error.code == 0x01)) {
            // Success, although week definition
        } else {
            XCTFail(@"connect returned event:%d, error:%@", self.event, self.error);
        }
        [self shutdown:parameters];
    }
}

- (void)test_ping {
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        self.session = [[MQTTSession alloc] initWithClientId:nil
                                                    userName:nil
                                                    password:nil
                                                   keepAlive:5
                                                cleanSession:YES
                                                        will:NO
                                                   willTopic:nil
                                                     willMsg:nil
                                                     willQoS:0
                                              willRetainFlag:NO
                                               protocolLevel:[parameters[@"protocollevel"] intValue]
                                                     runLoop:[NSRunLoop currentRunLoop]
                                                     forMode:NSRunLoopCommonModes];
        [self connect:self.session parameters:parameters];
        XCTAssert(!self.timeout, @"timeout");
        XCTAssertEqual(self.event, MQTTSessionEventConnected, @"No MQTTSessionEventConnected %@", self.error);

        self.event = -1;
        self.type = 0xff;
        [self performSelector:@selector(ackTimeout:)
                   withObject:parameters[@"timeout"]
                   afterDelay:[parameters[@"timeout"] intValue]];

        while (!self.timeout && self.event == -1 && self.type == 0xff) {
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }
        XCTAssertEqual(self.type, MQTTPingresp, @"No PingResp received %u", self.type);
        XCTAssertNotEqual(self.event, MQTTSessionEventConnectionClosed, @"MQTTSessionEventConnectionClosed %@", self.error);
        XCTAssertNotEqual(self.event, MQTTSessionEventProtocolError, @"MQTTSessionEventProtocolError %@", self.error);
        XCTAssertNotEqual(self.event, MQTTSessionEventConnectionClosedByBroker, @"MQTTSessionEventConnectionClosedByBroker %@", self.error);
        XCTAssert(!self.timeout, @"Timeout 200%% keepalive");
        [self shutdown:parameters];
    }
}

/*
 * [MQTT-3.1.2-5]
 * After the disconnection of a Session that had CleanSession set to 0,
 * the Server MUST store further QoS 1 and QoS 2 messages that match any
 * subscriptions that the client had at the time of disconnection as part of the Session state .
 */
- (void)test_pub_sub_no_cleansession_qos2_MQTT_3_1_2_5 {
    [self no_cleansession:MQTTQosLevelExactlyOnce];
}
- (void)test_pub_sub_no_cleansession_qos1_MQTT_3_1_2_5 {
    [self no_cleansession:MQTTQosLevelAtLeastOnce];
}
- (void)test_pub_sub_no_cleansession_qos0_MQTT_3_1_2_5 {
    [self no_cleansession:MQTTQosLevelAtMostOnce];
}

/*
 * [MQTT-4.3.3-2]
 * In the QoS 2 delivery protocol, the Receiver
 ** MUST respond with a PUBREC containing the Packet Identifier from the incoming PUBLISH Packet,
 *  having accepted ownership of the Application Message.
 ** Until it has received the corresponding PUBREL packet, the Receiver MUST acknowledge any
 *  subsequent PUBLISH packet with the same Packet Identifier by sending a PUBREC. It MUST NOT
 *  cause duplicate messages to be delivered to any onward recipients in this case.
 ** MUST respond to a PUBREL packet by sending a PUBCOMP packet containing the same Packet Identifier as the PUBREL.
 ** After it has sent a PUBCOMP, the receiver MUST treat any subsequent PUBLISH packet that
 *  contains that Packet Identifier as being a new publication.
 */

- (void)test_pub_sub_cleansession_qos2_MQTT_4_3_3_2 {
    [self cleansession:MQTTQosLevelExactlyOnce];
}
- (void)test_pub_sub_cleansession_qos1_MQTT_4_3_3_2 {
    [self cleansession:MQTTQosLevelAtLeastOnce];
}
- (void)test_pub_sub_cleansession_qos0_MQTT_4_3_3_2 {
    [self cleansession:MQTTQosLevelAtMostOnce];
}


/*
 * [MQTT-3.14.1-1]
 * The Server MUST validate that reserved bits are set to zero and disconnect the Client if they are not zero.
 */
- (void)test_disconnect_wrong_flags_MQTT_3_14_1_1 {
    NSLog(@"can't test [MQTT-3.14.1-1]");
    /*
     '[MQTT-4.3.2-2]',
     '[MQTT-4.3.2-3]',

     */
}

/*
 * [MQTT-3.1.4-5]
 * If the Server rejects the CONNECT, it MUST NOT process any data sent by the Client after the CONNECT Packet.
 */
- (void)test_dont_process_after_reject_MQTT_3_1_4_5 {
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
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
                                               protocolLevel:5
                                                     runLoop:[NSRunLoop currentRunLoop]
                                                     forMode:NSRunLoopCommonModes];
        [self connect:self.session parameters:parameters];
        [self.session subscribeTopic:TOPIC];
        [self.session publishData:[@"Data" dataUsingEncoding:NSUTF8StringEncoding] onTopic:TOPIC];

        XCTAssert(!self.timeout, @"timeout");
        XCTAssertEqual(self.event, MQTTSessionEventConnectionRefused, @"MQTTSessionEventConnectionRefused %@", self.error);
        XCTAssert(self.error.code == 0x01, @"error = %@", self.error);
        [self shutdown:parameters];
    }
}

/*
 * Client Certificate
 */
- (void)test_client_certificate {
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        if (!parameters[@"clientp12"]) continue;
        if (!parameters[@"clientp12pass"]) continue;
        
        NSString *path = [[NSBundle bundleForClass:[MQTTClientTests class]] pathForResource:parameters[@"clientp12"]
                                                                                     ofType:@"p12"];
        
        NSArray *myCerts = [MQTTSession clientCertsFromP12:path passphrase:parameters[@"clientp12pass"]];
        if (!myCerts) {
            XCTFail(@"invalid p12 file");
            continue;
        }
        
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
        [self connect:self.session parameters:parameters];
        [self.session subscribeTopic:TOPIC];
        [self.session publishData:[@"Data" dataUsingEncoding:NSUTF8StringEncoding] onTopic:TOPIC];
        
        XCTAssert(!self.timeout, @"timeout");
        XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
        [self shutdown:parameters];
    }
}

/*
 * Pinned Certificate
 */
- (void)test_pinned_certificate {
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];
        if (!parameters[@"serverCER"]) continue;

        NSString *path = [[NSBundle bundleForClass:[MQTTClientTests class]] pathForResource:parameters[@"serverCER"]
                                                                                     ofType:@"cer"];
        if (!path) {
            XCTFail(@"cer file not found");
            continue;
        }
        
        NSData *certificateData = [NSData dataWithContentsOfFile:path];
        if (!certificateData) {
            XCTFail(@"error reading cer file");
            continue;
        }
    
        MQTTSSLSecurityPolicy *secpol = [MQTTSSLSecurityPolicy policyWithPinningMode:MQTTSSLPinningModeCertificate];
        secpol.pinnedCertificates = [[NSArray alloc] initWithObjects:certificateData, nil];
        secpol.validatesCertificateChain = NO;
        secpol.allowInvalidCertificates = TRUE;
        
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
                                              securityPolicy:secpol
                                                certificates:nil];
        [self connect:self.session parameters:parameters];
        [self.session subscribeTopic:TOPIC];
        [self.session publishData:[@"Data" dataUsingEncoding:NSUTF8StringEncoding] onTopic:TOPIC];
        
        XCTAssert(!self.timeout, @"timeout");
        XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
        [self shutdown:parameters];
    }
}

#pragma mark helpers

- (void)no_cleansession:(MQTTQosLevel)qos {
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];

        NSLog(@"Cleaning topic");
        MQTTSession *sendingSession = [[MQTTSession alloc] initWithClientId:@"MQTTClient-pub"
                                                                   userName:nil
                                                                   password:nil
                                                                  keepAlive:60
                                                               cleanSession:YES
                                                                       will:NO
                                                                  willTopic:nil
                                                                    willMsg:nil
                                                                    willQoS:0
                                                             willRetainFlag:NO
                                                              protocolLevel:[parameters[@"protocollevel"] intValue]
                                                                    runLoop:[NSRunLoop currentRunLoop]
                                                                    forMode:NSRunLoopCommonModes];
        if (![sendingSession connectAndWaitToHost:parameters[@"host"] port:[parameters[@"port"] intValue] usingSSL:[parameters[@"tls"] boolValue]]) {
            XCTFail(@"no connection for pub to %@", broker);
        }
        [sendingSession publishAndWaitData:[[NSData alloc] init] onTopic:TOPIC retain:true qos:qos];

        NSLog(@"Clearing old subs");
        self.session = [[MQTTSession alloc] initWithClientId:@"MQTTClient-sub"
                                                    userName:nil
                                                    password:nil
                                                   keepAlive:60
                                                cleanSession:YES
                                                        will:NO
                                                   willTopic:nil
                                                     willMsg:nil
                                                     willQoS:0
                                              willRetainFlag:NO
                                               protocolLevel:[parameters[@"protocollevel"] intValue]
                                                     runLoop:[NSRunLoop currentRunLoop]
                                                     forMode:NSRunLoopCommonModes];
        [self connect:self.session parameters:parameters];
        [self shutdown:parameters];

        NSLog(@"Subscribing to topic");
        self.session = [[MQTTSession alloc] initWithClientId:@"MQTTClient-sub"
                                                    userName:nil
                                                    password:nil
                                                   keepAlive:60
                                                cleanSession:NO
                                                        will:NO
                                                   willTopic:nil
                                                     willMsg:nil
                                                     willQoS:0
                                              willRetainFlag:NO
                                               protocolLevel:[parameters[@"protocollevel"] intValue]
                                                     runLoop:[NSRunLoop currentRunLoop]
                                                     forMode:NSRunLoopCommonModes];
        [self connect:self.session parameters:parameters];
        [self.session subscribeAndWaitToTopic:TOPIC atLevel:qos];
        [self shutdown:parameters];

        for (int i = 1; i < BULK; i++) {
            NSLog(@"publishing to topic %d", i);
            NSString *payload = [NSString stringWithFormat:@"payload %d", i];
            [sendingSession publishAndWaitData:[payload dataUsingEncoding:NSUTF8StringEncoding] onTopic:TOPIC retain:false qos:qos];
        }
        [sendingSession closeAndWait];

        NSLog(@"receiving from topic");
        self.session = [[MQTTSession alloc] initWithClientId:@"MQTTClient-sub"
                                                    userName:nil
                                                    password:nil
                                                   keepAlive:60
                                                cleanSession:NO
                                                        will:NO
                                                   willTopic:nil
                                                     willMsg:nil
                                                     willQoS:0
                                              willRetainFlag:NO
                                               protocolLevel:[parameters[@"protocollevel"] intValue]
                                                     runLoop:[NSRunLoop currentRunLoop]
                                                     forMode:NSRunLoopCommonModes];
        [self connect:self.session parameters:parameters];
        XCTAssertEqual(self.event, MQTTSessionEventConnected, @"No MQTTSessionEventConnected %@", self.error);

        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        self.timeout = FALSE;
        [self performSelector:@selector(ackTimeout:)
                   withObject:parameters[@"timeout"]
                   afterDelay:[parameters[@"timeout"] intValue]];

        while (!self.timeout) {
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }
        
        [self shutdown:parameters];
    }
}

- (void)cleansession:(MQTTQosLevel)qos {
    for (NSString *broker in BROKERLIST) {
        NSLog(@"testing broker %@", broker);
        NSDictionary *parameters = BROKERS[broker];

        NSLog(@"Cleaning topic");
        MQTTSession *sendingSession = [[MQTTSession alloc] initWithClientId:@"MQTTClient-pub"
                                                                   userName:nil
                                                                   password:nil
                                                                  keepAlive:60
                                                               cleanSession:YES
                                                                       will:NO
                                                                  willTopic:nil
                                                                    willMsg:nil
                                                                    willQoS:0
                                                             willRetainFlag:NO
                                                              protocolLevel:[parameters[@"protocollevel"] intValue]
                                                                    runLoop:[NSRunLoop currentRunLoop]
                                                                    forMode:NSRunLoopCommonModes];
        if (![sendingSession connectAndWaitToHost:parameters[@"host"] port:[parameters[@"port"] intValue] usingSSL:[parameters[@"tls"] boolValue]]) {
            XCTFail(@"no connection for pub to %@", broker);
        }
        [sendingSession publishAndWaitData:[[NSData alloc] init] onTopic:TOPIC retain:true qos:qos];

        NSLog(@"Clearing old subs");
        self.session = [[MQTTSession alloc] initWithClientId:@"MQTTClient-sub"
                                                    userName:nil
                                                    password:nil
                                                   keepAlive:60
                                                cleanSession:YES
                                                        will:NO
                                                   willTopic:nil
                                                     willMsg:nil
                                                     willQoS:0
                                              willRetainFlag:NO
                                               protocolLevel:[parameters[@"protocollevel"] intValue]
                                                     runLoop:[NSRunLoop currentRunLoop]
                                                     forMode:NSRunLoopCommonModes];
        [self connect:self.session parameters:parameters];
        [self shutdown:parameters];

        NSLog(@"Subscribing to topic");
        self.session = [[MQTTSession alloc] initWithClientId:@"MQTTClient-sub"
                                                    userName:nil
                                                    password:nil
                                                   keepAlive:60
                                                cleanSession:YES
                                                        will:NO
                                                   willTopic:nil
                                                     willMsg:nil
                                                     willQoS:0
                                              willRetainFlag:NO
                                               protocolLevel:[parameters[@"protocollevel"] intValue]
                                                     runLoop:[NSRunLoop currentRunLoop]
                                                     forMode:NSRunLoopCommonModes];
        [self connect:self.session parameters:parameters];
        [self.session subscribeAndWaitToTopic:TOPIC atLevel:qos];

        for (int i = 1; i < BULK; i++) {
            NSLog(@"publishing to topic %d", i);
            NSString *payload = [NSString stringWithFormat:@"payload %d", i];
            [sendingSession publishAndWaitData:[payload dataUsingEncoding:NSUTF8StringEncoding] onTopic:TOPIC retain:false qos:qos];
        }
        [sendingSession closeAndWait];

        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        self.timeout = FALSE;
        [self performSelector:@selector(ackTimeout:)
                   withObject:parameters[@"timeout"]
                   afterDelay:[parameters[@"timeout"] intValue]];

        while (!self.timeout) {
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }
        
        [self shutdown:parameters];
    }
}

- (void)received:(MQTTSession *)session type:(int)type qos:(MQTTQosLevel)qos retained:(BOOL)retained duped:(BOOL)duped mid:(UInt16)mid data:(NSData *)data {
    NSLog(@"received:%d qos:%d retained:%d duped:%d mid:%d data:%@", type, qos, retained, duped, mid, data);
    self.type = type;
}

- (void)newMessage:(MQTTSession *)session data:(NSData *)data onTopic:(NSString *)topic qos:(MQTTQosLevel)qos retained:(BOOL)retained mid:(unsigned int)mid {
    NSLog(@"newMessage:%@ onTopic:%@ qos:%d retained:%d mid:%d", data, topic, qos, retained, mid);
}

- (void)handleEvent:(MQTTSession *)session event:(MQTTSessionEvent)eventCode error:(NSError *)error {
    NSLog(@"handleEvent:%ld error:%@", (long)eventCode, error);
    self.event = eventCode;
    self.error = error;
}

- (void)ackTimeout:(NSNumber *)timeout {
    NSLog(@"ackTimeout: %f", [timeout doubleValue]);
    self.timeout = TRUE;
}

- (void)connect:(MQTTSession *)session parameters:(NSDictionary *)parameters{
    session.delegate = self;
    self.event = -1;

    NSLog(@"connecting to:%@ port:%d tls:%d",
          parameters[@"host"],
          [parameters[@"port"] intValue],
          [parameters[@"tls"] boolValue]
    );
    
    [session connectToHost:parameters[@"host"]
                      port:[parameters[@"port"] intValue]
                  usingSSL:[parameters[@"tls"] boolValue]];

    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    self.timeout = FALSE;
    [self performSelector:@selector(ackTimeout:)
               withObject:parameters[@"timeout"]
               afterDelay:[parameters[@"timeout"] intValue]];
     

    while (!self.timeout && self.event == -1) {
        NSLog(@"waiting for connection");
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
}

- (void)shutdown:(NSDictionary *)parameters {
    if (!self.ungraceful) {
        self.event = -1;

        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        self.timeout = FALSE;
        [self performSelector:@selector(ackTimeout:)
                   withObject:parameters[@"timeout"]
                   afterDelay:[parameters[@"timeout"] intValue]];

        [self.session close];

        while (self.event == -1 && !self.timeout) {
            NSLog(@"waiting for disconnect");
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }

        XCTAssert(!self.timeout, @"timeout");
        [NSObject cancelPreviousPerformRequestsWithTarget:self];

        self.session.delegate = nil;
        self.session = nil;
    }
}

@end
