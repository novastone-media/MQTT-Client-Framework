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
    var broker: NSDictionary = NSDictionary();
    
    
    override func setUp() {
        super.setUp();
    }
    
    override func tearDown() {
        super.tearDown();
    }
    
    func testSwiftSubscribe() {
        print("testSwiftSubscribe \(brokers)")
        
        for brokerName in brokers.allKeys {
            print("testSwiftSubscribe \(brokerName)")
            
            broker = brokers.value(forKey: brokerName as! String) as! NSDictionary;
            print("testSwiftSubscribe \(broker)")
            
            if ((broker.value(forKey: "websocket")) as AnyObject).boolValue != true {
                
                session = MQTTSession();
                session!.delegate = self;
                
                session!.connect(toHost: broker.value(forKey: "host") as! String,
                                 port: UInt32(broker.value(forKey: "port") as! Int),
                                 usingSSL: broker.value(forKey: "tls") as! Bool)
                while !sessionConnected && !sessionError {
                    RunLoop.current.run(until: Date(timeIntervalSinceNow: 1))
                }
                
                session!.subscribe(toTopic: "#", at: .atMostOnce)
                
                while sessionConnected && !sessionError && !sessionSubAcked {
                    RunLoop.current.run(until: Date(timeIntervalSinceNow: 1))
                }
                
                session!.publishData("sent from Xcode 8.0 using Swift".data(using: String.Encoding.utf8, allowLossyConversion: false),
                                     onTopic: TOPIC,
                                     retain: false,
                                     qos: .atMostOnce)
                
                while sessionConnected && !sessionError && !sessionReceived {
                    RunLoop.current.run(until: Date(timeIntervalSinceNow: 1))
                }
                
                session!.close()
            }
        }
    }
    
    func testSessionManager() {
        for brokerName in brokers.allKeys {
            broker = brokers.value(forKey: brokerName as! String) as! NSDictionary;

            if let websocket = broker.value(forKey: "websocket") as? Bool, websocket == true {
                continue
            }
            
            let m = MQTTSessionManager()
            m.delegate = self
            
            m.connect(to: broker.value(forKey: "host") as! String,
                      port: broker.value(forKey: "port") as! Int,
                      tls:  broker.value(forKey: "tls") as! Bool,
                      keepalive: 60,
                      clean: true,
                      auth: false,
                      user: nil,
                      pass: nil,
                      will: false,
                      willTopic: nil,
                      willMsg: nil,
                      willQos: .atMostOnce,
                      willRetainFlag: false,
                      withClientId: nil,
                      securityPolicy: MQTTTestHelpers.securityPolicy(broker as! [AnyHashable: Any]),
                      certificates: MQTTTestHelpers.clientCerts(broker as! [AnyHashable: Any])
            )
            
            while (m.state != .connected) {
                print("waiting for connect %d", m.state);
                RunLoop.current.run(until: Date(timeIntervalSinceNow: 1))
            }
            
        }
    }
    
    override func handleEvent(_ session: MQTTSession!, event eventCode: MQTTSessionEvent, error: Error!) {
        switch eventCode {
        case .connected:
            sessionConnected = true
        case .connectionClosed:
            sessionConnected = false
        default:
            sessionError = true
        }
    }
    
    override func newMessage(_ session: MQTTSession!, data: Data!, onTopic topic: String!, qos: MQTTQosLevel, retained: Bool, mid: UInt32) {
        print("Received \(data) on:\(topic) q\(qos) r\(retained) m\(mid)")
        sessionReceived = true;
    }
    
    override func subAckReceived(_ session: MQTTSession!, msgID: UInt16, grantedQoss qoss: [NSNumber]!) {
        sessionSubAcked = true;
    }
    
}
