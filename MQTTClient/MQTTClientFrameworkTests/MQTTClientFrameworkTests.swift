//
//  MQTTClientFrameworkTests.swift
//  MQTTClient
//
//  Created by Christoph Krey on 10.06.14.
//  Copyright (c) 2014 Christoph Krey. All rights reserved.
//

import Foundation

class MQTTClientFrameworkTests : XCTestCase, MQTTSessionDelegate {
    
    var session = MQTTSession(clientId: "swift", userName: nil, password: nil, keepAlive: 60, cleanSession: true, will: false, willTopic: nil, willMsg: nil, willQoS: 0, willRetainFlag: false, protocolLevel: 4, runLoop: nil, forMode: nil)
    var sessionConnected = false;
    var sessionError = false;
    
    override func setUp() {
        session.delegate = self;
        
        session.connectToHost("localhost", port: 1883, usingSSL: false)
        while !sessionConnected && !sessionError {
            NSRunLoop.currentRunLoop().runUntilDate(NSDate(timeIntervalSinceNow: 1))
        }
        
    }
    
    override func tearDown() {
        session.close()
    }
    
    func testSubscribe() {
        session.subscribeToTopic("#", atLevel: 0)
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
    
    func newMessage(session: MQTTSession!, data: NSData!, onTopic topic: String!, qos: CInt, retained: Bool, mid: CUnsignedInt)
    {
        
    }
    
}
