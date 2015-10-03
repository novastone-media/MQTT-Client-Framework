//
//  SwiftTests.swift
//  MQTTClient
//
//  Created by Christoph Krey on 14.01.15.
//  Copyright (c) 2015 Christoph Krey. All rights reserved.
//

import Foundation

class SwiftTests : XCTestCase, MQTTSessionDelegate {
    var session: MQTTSession?;
    var sessionConnected = false;
    var sessionError = false;
    var sessionReceived = false;
    var sessionSubAcked = false;
    
    override func setUp() {
        session = MQTTSession(
            clientId: "swift",
            userName: nil,
            password: nil,
            keepAlive: 60,
            cleanSession: true,
            will: false,
            willTopic: nil,
            willMsg: nil,
            willQoS: MQTTQosLevel.AtMostOnce,
            willRetainFlag: false,
            protocolLevel: 4,
            runLoop: nil,
            forMode: nil
        )
        session!.delegate = self;
        session!.persistence.persistent = true;
        
        session!.connectToHost("localhost",
            port: 1883,
            usingSSL: false)
        while !sessionConnected && !sessionError {
            NSRunLoop.currentRunLoop().runUntilDate(NSDate(timeIntervalSinceNow: 1))
        }
    }
    
    override func tearDown() {
        session!.close()
    }
    
    func testSubscribe() {
        session!.subscribeToTopic("#", atLevel: MQTTQosLevel.AtMostOnce)
        while sessionConnected && !sessionError && !sessionSubAcked {
            NSRunLoop.currentRunLoop().runUntilDate(NSDate(timeIntervalSinceNow: 1))
        }
    }
    
    func testPublish() {
        session!.subscribeToTopic("#", atLevel: MQTTQosLevel.AtMostOnce)
        
        while sessionConnected && !sessionError && !sessionSubAcked {
            NSRunLoop.currentRunLoop().runUntilDate(NSDate(timeIntervalSinceNow: 1))
        }
        
        session!.publishData("sent from Xcode 6.0 using Swift".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false),
            onTopic: "mqtt/swift/framework",
            retain: false,
            qos: MQTTQosLevel.AtMostOnce)
        
        while sessionConnected && !sessionError && !sessionReceived {
            NSRunLoop.currentRunLoop().runUntilDate(NSDate(timeIntervalSinceNow: 1))
        }
        
    }
    
    func handleEvent(session: MQTTSession!, event eventCode: MQTTSessionEvent, error: NSError!) {
        switch eventCode {
        case .Connected:
            sessionConnected = true
        case .ConnectionClosed:
            sessionConnected = false
        default:
            sessionError = true
        }
    }
    
    func newMessage(session: MQTTSession!, data: NSData!, onTopic topic: String!, qos: MQTTQosLevel, retained: Bool, mid: UInt32) {
        print("Received \(data) on:\(topic) q\(qos) r\(retained) m\(mid)")
        sessionReceived = true;
    }
    
    func subAckReceived(session: MQTTSession!, msgID: UInt16, grantedQoss qoss: [AnyObject]!) {
        sessionSubAcked = true;
    }
    
}
