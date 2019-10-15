//
//  MQTTClientTests.m
//  MQTTClientTests
//
//  Created by Christoph Krey on 13.01.14.
//  Copyright © 2014-2017 Christoph Krey. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "MQTTLog.h"
#import "MQTTStrict.h"
#import "MQTTTestHelpers.h"
#import "MQTTCFSocketTransport.h"

@interface MQTTClientTests : MQTTTestHelpers
@property (nonatomic) BOOL ungraceful;
@property (nonatomic) int received;

@end

@implementation MQTTClientTests

- (void)setUp {
    [super setUp];
    MQTTStrict.strict = NO;
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
- (void)DISABLEtest_init_zero_clientId_noclean_MQTT_3_1_3_8_MQTT_3_1_3_9 {
    NSDictionary *parameters = MQTTTestHelpers.broker;
    self.session = [MQTTTestHelpers session:parameters];
    self.session.clientId = @"";
    self.session.cleanSessionFlag = NO;
    [self connect:parameters];
    XCTAssertFalse(self.timedout);
    XCTAssertEqual(self.event, MQTTSessionEventConnectionRefused, @"MQTTSessionEventConnectionRefused %@", self.error);
    XCTAssert(self.error.code == 0x02, @"error = %@", self.error);
    [self shutdown:parameters];
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
- (void)test_init_zero_clientId_noclean_strict {
    MQTTStrict.strict = YES;
    NSDictionary *parameters = MQTTTestHelpers.broker;
    self.session = [MQTTTestHelpers session:parameters];
    self.session.cleanSessionFlag = FALSE;
    self.session.clientId = @"";
    XCTAssertThrows([self.session connect]);
}

- (void)test_init_long_clientId {
    NSDictionary *parameters = MQTTTestHelpers.broker;
    self.session = [MQTTTestHelpers session:parameters];
    self.session.clientId = @"123456789.123456789.1234";
    [self connect:parameters];
    XCTAssertFalse(self.timedout);
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
    [self shutdown:parameters];
}

- (void)test_init_nonrestricted_clientId {
    NSDictionary *parameters = MQTTTestHelpers.broker;
    self.session = [MQTTTestHelpers session:parameters];
    self.session.clientId = @"123456789.123456789.123";
    [self connect:parameters];
    XCTAssertFalse(self.timedout);
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
    [self shutdown:parameters];
}

- (void)test_init_no_clientId {
    NSDictionary *parameters = MQTTTestHelpers.broker;
    self.session = [MQTTTestHelpers session:parameters];
    self.session.clientId = nil;
    [self connect:parameters];
    XCTAssertFalse(self.timedout);
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
    [self shutdown:parameters];
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
- (void)SLOWtest_connect_will_non_retained_MQTT_3_1_2_8_MQTT_3_1_2_16 {
    NSDictionary *parameters = MQTTTestHelpers.broker;
    
    MQTTSession *subscribingSession = [MQTTTestHelpers session:parameters];
    subscribingSession.clientId = @"MQTTClient-sub";
    
    XCTestExpectation *expectation = [self expectationWithDescription:@""];
    [subscribingSession connectWithConnectHandler:^(NSError *error) {
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:[parameters[@"timeout"] unsignedIntValue] handler:nil];

    XCTestExpectation *subscribeExpectation = [self expectationWithDescription:@""];
    [subscribingSession subscribeToTopic:TOPIC atLevel:0 subscribeHandler:^(NSError *error, NSArray<NSNumber *> *gQoss) {
        [subscribeExpectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:[parameters[@"timeout"] unsignedIntValue] handler:nil];
    
    self.session =  [MQTTTestHelpers session:parameters];
    self.session.willFlag = TRUE;
    self.session.willTopic = TOPIC;
    self.session.willMsg = [@"will-qos0-non-retained" dataUsingEncoding:NSUTF8StringEncoding];
    
    [self connect:parameters];
    XCTAssertFalse(self.timedout);
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
    
    self.ungraceful = TRUE;
    [self shutdown:parameters];
    
    XCTestExpectation *closeExpectation = [self expectationWithDescription:@""];
    [subscribingSession closeWithDisconnectHandler:^(NSError *error) {
        [closeExpectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:[parameters[@"timeout"] unsignedIntValue] handler:nil];
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
- (void)SLOWtest_connect_will_retained_MQTT_3_1_2_8_MQTT_3_1_2_17 {
    NSDictionary *parameters = MQTTTestHelpers.broker;
    
    MQTTSession *subscribingSession = [MQTTTestHelpers session:parameters];
    subscribingSession.clientId = @"MQTTClient-sub";

    XCTestExpectation *expectation = [self expectationWithDescription:@""];
    [subscribingSession connectWithConnectHandler:^(NSError *error) {
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:[parameters[@"timeout"] unsignedIntValue] handler:nil];

    XCTestExpectation *subscribeExpectation = [self expectationWithDescription:@""];
    [subscribingSession subscribeToTopic:TOPIC atLevel:0 subscribeHandler:^(NSError *error, NSArray<NSNumber *> *gQoss) {
        [subscribeExpectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:[parameters[@"timeout"] unsignedIntValue] handler:nil];
    
    self.session =  [MQTTTestHelpers session:parameters];
    self.session.willFlag = TRUE;
    self.session.willTopic = TOPIC;
    self.session.willMsg = [@"will-qos0-retained" dataUsingEncoding:NSUTF8StringEncoding];
    
    self.session.willRetainFlag = TRUE;
    
    [self connect:parameters];
    XCTAssertFalse(self.timedout);
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
    
    self.ungraceful = YES;
    [self shutdown:parameters];
    
    XCTestExpectation *closeExpectation = [self expectationWithDescription:@""];
    [subscribingSession closeWithDisconnectHandler:^(NSError *error) {
        [closeExpectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:[parameters[@"timeout"] unsignedIntValue] handler:nil];
}

/*
 * [MQTT-3.1.2-15]
 * If the Will Flag is set to 0, then the Will Retain Flag MUST be set to 0.
 */

- (void)test_connect_will_unflagged_but_retain_not_0_MQTT_3_1_2_15 {
    NSDictionary *parameters = MQTTTestHelpers.broker;
    
    self.session =  [MQTTTestHelpers session:parameters];
    self.session.willFlag = NO;
    self.session.willRetainFlag = YES;
    
    [self connect:parameters];
    XCTAssertFalse(self.timedout);
    XCTAssertTrue(self.event ==
                  MQTTSessionEventConnectionClosedByBroker || MQTTSessionEventConnectionClosed,
                  @"Protocol violation not detected by broker");
    
    self.ungraceful = YES;
    [self shutdown:parameters];
}


/*
 * [MQTT-3.1.2-13]
 * If the Will Flag is set to 0, then the Will QoS MUST be set to 0 (0x00).
 */
- (void)test_connect_will_unflagged_but_qos_not_0_MQTT_3_1_2_13 {
    NSDictionary *parameters = MQTTTestHelpers.broker;
    
    self.session =  [MQTTTestHelpers session:parameters];
    self.session.willQoS = MQTTQosLevelExactlyOnce;
    
    [self connect:parameters];
    XCTAssertFalse(self.timedout);
    XCTAssertTrue(self.event ==
                  MQTTSessionEventConnectionClosedByBroker || MQTTSessionEventConnectionClosed,
                  @"Protocol violation not detected by broker");
    
    self.ungraceful = YES;
    [self shutdown:parameters];
}


/*
 * [MQTT-3.1.2-14]
 * If the Will Flag is set to 1, the value of Will QoS can be 0 (0x00), 1 (0x01), or 2 (0x02). It MUST NOT be 3 (0x03).
 */
- (void)test_connect_will_flagged_but_qos_3_MQTT_3_1_2_14 {
    NSDictionary *parameters = MQTTTestHelpers.broker;
    
    self.session =  [MQTTTestHelpers session:parameters];
    self.session.willFlag = TRUE;
    self.session.willTopic = @"MQTTClient";
    self.session.willMsg = [@"test_connect_will_flagged_but_qos_3_MQTT_3_1_2_14" dataUsingEncoding:NSUTF8StringEncoding];
    self.session.willQoS = 3;
    
    [self connect:parameters];
    XCTAssertFalse(self.timedout);
    XCTAssertTrue(self.event ==
                  MQTTSessionEventConnectionClosedByBroker || MQTTSessionEventConnectionClosed,
                  @"Protocol violation not detected by broker");
    
    self.ungraceful = YES;
    [self shutdown:parameters];
}


/*
 * [MQTT-3.1.2-11]
 * If the Will Flag is set to 0 the Will QoS and Will Retain fields in the Connect Flags
 * MUST be set to zero and the Will Topic and Will Message fields MUST NOT be present in the payload.
 */
- (void)test_connect_will_unflagged_but_willMsg_MQTT_3_1_2_11 {
    NSDictionary *parameters = MQTTTestHelpers.broker;
    
    self.session =  [MQTTTestHelpers session:parameters];
    self.session.willMsg = [@"test_connect_will_unflagged_but_willMsg" dataUsingEncoding:NSUTF8StringEncoding];
    
    [self connect:parameters];
    XCTAssertFalse(self.timedout);
    XCTAssertTrue(self.event ==
                  MQTTSessionEventConnectionClosedByBroker || MQTTSessionEventConnectionClosed,
                  @"Protocol violation not detected by broker");
    
    self.ungraceful = YES;
    [self shutdown:parameters];
}

/*
 * [MQTT-3.1.2-11]
 * If the Will Flag is set to 0 the Will QoS and Will Retain fields in the Connect Flags
 * MUST be set to zero and the Will Topic and Will Message fields MUST NOT be present in the payload.
 */

- (void)test_connect_will_unflagged_but_willTopic_MQTT_3_1_2_11 {
    NSDictionary *parameters = MQTTTestHelpers.broker;
    
    self.session =  [MQTTTestHelpers session:parameters];
    self.session.willTopic = @"MQTTClient";
    
    [self connect:parameters];
    XCTAssertFalse(self.timedout);
    XCTAssertTrue(self.event ==
                  MQTTSessionEventConnectionClosedByBroker || MQTTSessionEventConnectionClosed,
                  @"Protocol violation not detected by broker");
    
    self.ungraceful = YES;
    [self shutdown:parameters];
}

/*
 * [MQTT-3.1.2-11]
 * If the Will Flag is set to 0 the Will QoS and Will Retain fields in the Connect Flags
 * MUST be set to zero and the Will Topic and Will Message fields MUST NOT be present in the payload.
 */

- (void)test_connect_will_unflagged_but_willMsg_and_willTopic_MQTT_3_1_2_11 {
    NSDictionary *parameters = MQTTTestHelpers.broker;
    
    self.session =  [MQTTTestHelpers session:parameters];
    self.session.willTopic = @"MQTTClient";
    self.session.willMsg = [@"test_connect_will_unflagged_but_willMsg_and_willTopic" dataUsingEncoding:NSUTF8StringEncoding];
    
    [self connect:parameters];
    XCTAssertFalse(self.timedout);
    XCTAssertTrue(self.event ==
                  MQTTSessionEventConnectionClosedByBroker || MQTTSessionEventConnectionClosed,
                  @"Protocol violation not detected by broker");
    
    self.ungraceful = YES;
    [self shutdown:parameters];
}

/*
 * [MQTT-3.1.2-9]
 * If the Will Flag is set to 1, the Will QoS and Will Retain fields in the Connect Flags will
 * be used by the Server, and the Will Topic and Will Message fields MUST be present in the payload.
 */
- (void)test_connect_will_flagged_but_no_willTopic_nor_willMsg_MQTT_3_1_2_9 {
    NSDictionary *parameters = MQTTTestHelpers.broker;
    
    self.session =  [MQTTTestHelpers session:parameters];
    self.session.willFlag = TRUE;
    
    [self connect:parameters];
    XCTAssertFalse(self.timedout);
    XCTAssertTrue(self.event ==
                  MQTTSessionEventConnectionClosedByBroker || MQTTSessionEventConnectionClosed,
                  @"Protocol violation not detected by broker");
    
    self.ungraceful = YES;
    [self shutdown:parameters];
}

/*
 * [MQTT-3.1.2-9]
 * If the Will Flag is set to 1, the Will QoS and Will Retain fields in the Connect Flags will
 * be used by the Server, and the Will Topic and Will Message fields MUST be present in the payload.
 */
- (void)test_connect_will_flagged_but_no_willTopic_MQTT_3_1_2_9 {
    NSDictionary *parameters = MQTTTestHelpers.broker;
    
    self.session =  [MQTTTestHelpers session:parameters];
    self.session.willFlag = TRUE;
    self.session.willMsg = [[NSData alloc] init];
    
    [self connect:parameters];
    XCTAssertFalse(self.timedout);
    XCTAssertTrue(self.event ==
                  MQTTSessionEventConnectionClosedByBroker || MQTTSessionEventConnectionClosed,
                  @"Protocol violation not detected by broker");
    
    self.ungraceful = YES;
    [self shutdown:parameters];
    
}

/*
 * [MQTT-3.1.2-9]
 * If the Will Flag is set to 1, the Will QoS and Will Retain fields in the Connect Flags will
 * be used by the Server, and the Will Topic and Will Message fields MUST be present in the payload.
 */
- (void)test_connect_will_flagged_but_no_willMsg_MQTT_3_1_2_9 {
    NSDictionary *parameters = MQTTTestHelpers.broker;
    
    self.session =  [MQTTTestHelpers session:parameters];
    self.session.willFlag = TRUE;
    self.session.willTopic = @"MQTTClient";
    
    [self connect:parameters];
    XCTAssertFalse(self.timedout);
    XCTAssertTrue(self.event ==
                  MQTTSessionEventConnectionClosedByBroker || MQTTSessionEventConnectionClosed,
                  @"Protocol violation not detected by broker");
    
    self.ungraceful = YES;
    [self shutdown:parameters];
    
}

/*
 * [MQTT-3.1.4-2]
 * If the ClientId represents a Client already connected to the Server then the Server MUST disconnect the existing Client.
 */

- (void)SLOWtest_disconnect_when_same_clientID_connects_MQTT_3_1_4_2 {
    NSDictionary *parameters = MQTTTestHelpers.broker;
    
    self.session = [MQTTTestHelpers session:parameters];
    self.session.clientId = @"MQTTClient";
    
    [self connect:parameters];
    XCTAssertFalse(self.timedout);
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
    
    
    MQTTSession *sameSession = [MQTTTestHelpers session:parameters];
    sameSession.clientId = @"MQTTClient";
    
    XCTestExpectation *expectation = [self expectationWithDescription:@""];
    [sameSession connectWithConnectHandler:^(NSError *error) {
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:[parameters[@"timeout"] unsignedIntValue] handler:nil];
    
    [self shutdown:parameters];
    
    XCTestExpectation *closeExpectation = [self expectationWithDescription:@""];
    [sameSession closeWithDisconnectHandler:^(NSError *error) {
        [closeExpectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:[parameters[@"timeout"] unsignedIntValue] handler:nil];
}

/*
 * [MQTT-3.1.3-1]
 * These fields, if present, MUST appear in the order Client Identifier, Will Topic, Will Message, User Name, Password.
 */
- (void)test_connect_all_fields_MQTT_3_1_3_1 {
    NSDictionary *parameters = MQTTTestHelpers.broker;
    
    self.session = [MQTTTestHelpers session:parameters];
    self.session.clientId = @"ClientID";
    self.session.willFlag = TRUE;
    self.session.willTopic = @"MQTTClient/will-qos0";
    self.session.willMsg = [@"will-qos0" dataUsingEncoding:NSUTF8StringEncoding];
    
    [self connect:parameters];
    XCTAssertFalse(self.timedout);
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
    
    self.ungraceful = TRUE;
    [self shutdown:parameters];
    
}

/*
 * [MQTT-3.1.2-1]
 * If the protocol name is incorrect the Server MAY disconnect the Client, or it MAY
 * continue processing the CONNECT packet in accordance with some other specification.
 * In the latter case, the Server MUST NOT continue to process the CONNECT packet in line with this specification.
 */
- (void)test_connect_protocollevel3__MQTT_3_1_2_1 {
    NSDictionary *parameters = MQTTTestHelpers.broker;
    
    self.session = [MQTTTestHelpers session:parameters];
    self.session.protocolLevel = MQTTProtocolVersion31;
    
    [self connect:parameters];
    XCTAssertFalse(self.timedout);
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"No MQTTSessionEventConnected %@", self.error);
    
    [self shutdown:parameters];
    
}
/*
 * [MQTT-3.1.2-1]
 * If the protocol name is incorrect the Server MAY disconnect the Client, or it MAY
 * continue processing the CONNECT packet in accordance with some other specification.
 * In the latter case, the Server MUST NOT continue to process the CONNECT packet in line with this specification.
 */
- (void)test_connect_protocollevel4__MQTT_3_1_2_1 {
    NSDictionary *parameters = MQTTTestHelpers.broker;
    
    self.session = [MQTTTestHelpers session:parameters];
    self.session.protocolLevel = MQTTProtocolVersion311;
    
    [self connect:parameters];
    XCTAssertFalse(self.timedout);
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"No MQTTSessionEventConnected %@", self.error);
    
    [self shutdown:parameters];
    
}
/*
 * [MQTT-3.1.2-1]
 * If the protocol name is incorrect the Server MAY disconnect the Client, or it MAY
 * continue processing the CONNECT packet in accordance with some other specification.
 * In the latter case, the Server MUST NOT continue to process the CONNECT packet in line with this specification.
 */
- (void)SLOWtest_connect_protocollevel5__MQTT_3_1_2_1 {
    NSDictionary *parameters = MQTTTestHelpers.broker;
    
    self.session = [MQTTTestHelpers session:parameters];
    self.session.protocolLevel = MQTTProtocolVersion50;
    
    [self connect:parameters];
    XCTAssertFalse(self.timedout);
    XCTAssertEqual(self.event, MQTTSessionEventConnectionClosedByBroker, @"session not closed %@", self.error);
    
    [self shutdown:parameters];
    
}

/*
 * [MQTT-3.1.2-2]
 * The Server MUST respond to the CONNECT Packet with a CONNACK return code
 * 0x01 (unacceptable protocol level) and then disconnect the Client if the Protocol
 * Level is not supported by the Server.
 * [MQTT-3.2.2-5]
 * If a server sends a CONNACK packet containing a non-zero return code it MUST then close the Network Connection.
 */
- (void)test_connect_illegal_protocollevel88_MQTT_3_1_2_2_MQTT_3_2_2_5 {
    NSDictionary *parameters = MQTTTestHelpers.broker;
    
    self.session = [MQTTTestHelpers session:parameters];
    self.session.protocolLevel = 88;
    
    [self connect:parameters];
    
    XCTAssertFalse(self.timedout);
    XCTAssertNotNil(self.error);
    
    [self shutdown:parameters];
}

/*
 * [MQTT-3.1.2-2]
 * The Server MUST respond to the CONNECT Packet with a CONNACK return code
 * 0x01 (unacceptable protocol level) and then disconnect the Client if the Protocol
 * Level is not supported by the Server.
 * [MQTT-3.2.2-5]
 * If a server sends a CONNACK packet containing a non-zero return code it MUST then close the Network Connection.
 */
- (void)test_connect_illegal_protocollevel88_strict {
    MQTTStrict.strict = YES;
    NSDictionary *parameters = MQTTTestHelpers.broker;
    self.session = [MQTTTestHelpers session:parameters];
    self.session.protocolLevel = 88;
    XCTAssertThrows([self.session connect]);
}

/*
 * [MQTT-3.1.2-1]
 * If the protocol name is incorrect the Server MAY disconnect the Client, or it MAY
 * continue processing the CONNECT packet in accordance with some other specification.
 * In the latter case, the Server MUST NOT continue to process the CONNECT packet in line with this specification.
 */
- (void)DISABLEtest_connect_illegal_protocollevel0_and_protocolname_MQTT_3_1_2_1 {
    NSDictionary *parameters = MQTTTestHelpers.broker;
    
    self.session = [MQTTTestHelpers session:parameters];
    self.session.protocolLevel = 0;
    
    [self connect:parameters];
    XCTAssertFalse(self.timedout);
    if (self.event == MQTTSessionEventConnectionClosedByBroker ||
        self.event == MQTTSessionEventConnectionError ||
        (self.event == MQTTSessionEventConnectionRefused && self.error && self.error.code == 0x01)) {
        // Success, although week definition
    } else {
        XCTFail(@"connect returned event:%d, error:%@", self.event, self.error);
    }
    [self shutdown:parameters];
    
}

/*
 * [MQTT-3.1.0-1]
 * After a Network Connection is established by a Client to a Server, the first Packet sent from the
 * Client to the Server MUST be a CONNECT Packet.
 */
- (void)test_first_packet_MQTT_3_1_0_1 {
    DDLogVerbose(@"can't test [MQTT-3.1.0-1]");
}

- (void)testPing {
    NSDictionary *parameters = MQTTTestHelpers.broker;
    
    self.session = [MQTTTestHelpers session:parameters];
    self.session.keepAliveInterval = 2;
    
    [self connect:parameters];
    XCTAssertFalse(self.timedout);
    XCTAssertEqual(self.event, MQTTSessionEventConnected);
    XCTKVOExpectation *expectation = [[XCTKVOExpectation alloc] initWithKeyPath:@"type" object:self expectedValue:@(MQTTPingresp)];
    
    [self waitForExpectations:@[expectation] timeout:[parameters[@"timeout"] intValue]];
    
    [self shutdown:parameters];
}

/*
 * [MQTT-3.1.4-5]
 * If the Server rejects the CONNECT, it MUST NOT process any data sent by the Client after the CONNECT Packet.
 */
- (void)DISABLEtest_dont_process_after_reject_MQTT_3_1_4_5 {
    NSDictionary *parameters = MQTTTestHelpers.broker;
    
    self.session = [MQTTTestHelpers session:parameters];
    self.session.protocolLevel = 88;
    
    [self connect:parameters];
    
    [self.session unsubscribeTopic:TOPIC];
    [self.session publishData:[@"Data" dataUsingEncoding:NSUTF8StringEncoding] onTopic:TOPIC retain:FALSE qos:MQTTQosLevelAtMostOnce];
    
    XCTAssertFalse(self.timedout);
    XCTAssertEqual(self.event, MQTTSessionEventConnectionRefused, @"MQTTSessionEventConnectionRefused %@", self.error);
    XCTAssert(self.error.code == 0x01, @"error = %@", self.error);
    [self shutdown:parameters];
    
}

#define PROCESSING_NUMBER 20
#define PROCESSING_TIMEOUT 30

- (void)DISABLEtestThrottlingIncomingAtLeastOnce {
    NSDictionary *parameters = MQTTTestHelpers.broker;
    self.session = [MQTTTestHelpers session:parameters];
    [self connect:parameters];
    
    XCTAssertFalse(self.timedout);
    XCTAssertEqual(self.event, MQTTSessionEventConnected);
    
    self.received = 0;
    
    [self.session subscribeToTopic:TOPIC atLevel:MQTTQosLevelAtLeastOnce];
    
    for (int i = 0; i < PROCESSING_NUMBER; i++) {
        NSString *payload = [NSString stringWithFormat:@"Data %d", i];
        [self.session publishData:[payload dataUsingEncoding:NSUTF8StringEncoding]
                          onTopic:TOPIC
                           retain:false
                              qos:MQTTQosLevelAtLeastOnce];
    }
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id  _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        return self.received == PROCESSING_NUMBER;
    }];
    XCTNSPredicateExpectation *expectation = [[XCTNSPredicateExpectation alloc] initWithPredicate:predicate object:self];
    [self waitForExpectations:@[expectation] timeout:PROCESSING_TIMEOUT];
    [self shutdown:parameters];
}

- (void)testThrottlingIncomingExactlyOnce {
    NSDictionary *parameters = MQTTTestHelpers.broker;
    
    self.session = [MQTTTestHelpers session:parameters];
    
    [self connect:parameters];
    XCTAssertFalse(self.timedout);
    XCTAssertEqual(self.event, MQTTSessionEventConnected);
    
    self.received = 0;
    
    [self.session subscribeToTopic:TOPIC atLevel:MQTTQosLevelExactlyOnce];
    
    for (int i = 0; i < PROCESSING_NUMBER; i++) {
        NSString *payload = [NSString stringWithFormat:@"Data %d", i];
        [self.session publishData:[payload dataUsingEncoding:NSUTF8StringEncoding]
                          onTopic:TOPIC
                           retain:false
                              qos:MQTTQosLevelExactlyOnce];
    }
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id  _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        return self.received == PROCESSING_NUMBER;
    }];
    XCTNSPredicateExpectation *expectation = [[XCTNSPredicateExpectation alloc] initWithPredicate:predicate object:self];
    [self waitForExpectations:@[expectation] timeout:PROCESSING_TIMEOUT];
    [self shutdown:parameters];
}

#pragma mark helpers

- (BOOL)newMessageWithFeedback:(MQTTSession *)session data:(NSData *)data onTopic:(NSString *)topic qos:(MQTTQosLevel)qos retained:(BOOL)retained mid:(unsigned int)mid {
    DDLogVerbose(@"newMessageWithFeedback:%@ onTopic:%@ qos:%d retained:%d mid:%d", data, topic, qos, retained, mid);
    // Randomly reject messages to simulate throttling
    int r = arc4random_uniform(1);
    if (r == 0) {
        if (!retained && [topic isEqualToString:TOPIC]) {
            self.received++;
        }
        return true;
    } else {
        return false;
    }
}

- (void)connect:(NSDictionary *)parameters {
    self.session.delegate = self;
    self.event = -1;
    self.timedout = NO;
    XCTestExpectation *expectation = [self expectationWithDescription:@"Connect expectation"];
    [self.session connectWithConnectHandler:^(NSError *error) {
        self.error = error;
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:[parameters[@"timeout"] intValue] handler:^(NSError * _Nullable error) {
        self.timedout = (error != nil);
    }];
}

- (void)shutdown:(NSDictionary *)parameters {
    if (!self.ungraceful) {
        self.event = -1;
        self.timedout = NO;
        XCTestExpectation *expectation = [self expectationWithDescription:@"Cose Expectation"];
        [self.session closeWithDisconnectHandler:^(NSError *error) {
            [expectation fulfill];
        }];
        [self waitForExpectationsWithTimeout:[parameters[@"timeout"] intValue] handler:^(NSError * _Nullable error) {
            self.timedout = (error != nil);
        }];
        XCTAssertFalse(self.timedout);
        
        self.session.delegate = nil;
        self.session = nil;
    }
}

@end
