//
//  SwiftTests.swift
//  MQTTClient
//
//  Created by Christoph Krey on 14.01.15.
//  Copyright © 2015-2016 Christoph Krey. All rights reserved.
//

import Foundation

class SwiftTests : MQTTTestHelpers {
    var sessionConnected = false;
    var sessionError = false;
    var sessionReceived = false;
    var sessionSubAcked = false;
    
    override func setUp() {
        super.setUp();
    }
    
    override func tearDown() {
        super.tearDown();
    }
    
    func testSwiftSubscribe() {
        for brokerName in brokers.allKeys {
            var broker: NSDictionary;
            broker = brokers.valueForKey(brokerName as! String) as! NSDictionary;
            if (broker.valueForKey("websocket"))?.boolValue != true {
                
                session = MQTTSession();
                session!.delegate = self;
                
                session!.connectToHost(broker.valueForKey("host") as! String,
                    port:(broker.valueForKey("port")?.unsignedIntValue)!,
                    usingSSL: (broker.valueForKey("tls")?.boolValue)!);
                while !sessionConnected && !sessionError {
                    NSRunLoop.currentRunLoop().runUntilDate(NSDate(timeIntervalSinceNow: 1))
                }
                
                session!.subscribeToTopic("#", atLevel: MQTTQosLevel.AtMostOnce)
                
                while sessionConnected && !sessionError && !sessionSubAcked {
                    NSRunLoop.currentRunLoop().runUntilDate(NSDate(timeIntervalSinceNow: 1))
                }
                
                session!.publishData("sent from Xcode 6.0 using Swift".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false),
                    onTopic: TOPIC,
                    retain: false,
                    qos: MQTTQosLevel.AtMostOnce)
                
                while sessionConnected && !sessionError && !sessionReceived {
                    NSRunLoop.currentRunLoop().runUntilDate(NSDate(timeIntervalSinceNow: 1))
                }
                
                session!.close()
            }
        }
    }
    
    func testSessionManager() {
        for brokerName in brokers.allKeys {
            var broker: NSDictionary;
            broker = brokers.valueForKey(brokerName as! String) as! NSDictionary;
            if (broker.valueForKey("websocket"))?.boolValue != true {
                
                let m = MQTTSessionManager()
                m.delegate = self
                
                m.connectTo(broker.valueForKey("host") as! String,
                    port: (broker.valueForKey("port")?.integerValue)!,
                    tls:  (broker.valueForKey("tls")?.boolValue)!,
                    keepalive: 60,
                    clean: true,
                    auth: false,
                    user: nil,
                    pass: nil,
                    will: false,
                    willTopic: nil,
                    willMsg: nil,
                    willQos: MQTTQosLevel.AtMostOnce,
                    willRetainFlag: false,
                    withClientId: nil)
                
                while (m.state != MQTTSessionManagerState.Connected) {
                    print("waiting for connect %d", m.state);
                    NSRunLoop.currentRunLoop().runUntilDate(NSDate(timeIntervalSinceNow: 1))
                }

            }
        }
    }
    
    override func handleEvent(session: MQTTSession!, event eventCode: MQTTSessionEvent, error: NSError!) {
        switch eventCode {
        case .Connected:
            sessionConnected = true
        case .ConnectionClosed:
            sessionConnected = false
        default:
            sessionError = true
        }
    }
    
    override func newMessage(session: MQTTSession!, data: NSData!, onTopic topic: String!, qos: MQTTQosLevel, retained: Bool, mid: UInt32) {
        print("Received \(data) on:\(topic) q\(qos) r\(retained) m\(mid)")
        sessionReceived = true;
    }
    
    override func subAckReceived(session: MQTTSession!, msgID: UInt16, grantedQoss qoss: [NSNumber]!) {
        sessionSubAcked = true;
    }
    
}
