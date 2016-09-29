//
//  MQTTSwift.swift
//  MQTTSwift
//
//  Created by Christoph Krey on 23.05.16.
//  Copyright © 2016 OwnTracks. All rights reserved.
//

import MQTTClient
import Foundation

class MQTTSwift: NSObject, MQTTSessionDelegate  {
    
    var sessionConnected = false
    var sessionError = false
    var sessionReceived = false
    var sessionSubAcked = false
    var session: MQTTSession?
    
    func testSwiftSubscribe() {
        guard let newSession = MQTTSession() else {
            fatalError("Could not create MQTTSession")
        }
        session = newSession
        
        newSession.delegate = self
        
        newSession.connect(toHost: "localhost", port: 1883, usingSSL: false)
        while !sessionConnected && !sessionError {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 1))
        }
        
        newSession.subscribe(toTopic: "#", at: .atMostOnce)
        
        while sessionConnected && !sessionError && !sessionSubAcked {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 1))
        }
        
        newSession.publishData("sent from Xcode using Swift".data(using: String.Encoding.utf8, allowLossyConversion: false),
                               onTopic: "MQTTSwift",
                               retain: false,
                               qos: .atMostOnce)
        
        while sessionConnected && !sessionError && !sessionReceived {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 1))
        }
        
        newSession.close()
    }
    
    func handleEvent(_ session: MQTTSession!, event eventCode: MQTTSessionEvent, error: Error!) {
        switch eventCode {
        case .connected:
            sessionConnected = true
        case .connectionClosed:
            sessionConnected = false
        default:
            sessionError = true
        }
    }
    
    func newMessage(_ session: MQTTSession!, data: Data!, onTopic topic: String!, qos: MQTTQosLevel, retained: Bool, mid: UInt32) {
        print("Received \(data) on:\(topic) q\(qos) r\(retained) m\(mid)")
        sessionReceived = true;
    }
    
    func subAckReceived(_ session: MQTTSession!, msgID: UInt16, grantedQoss qoss: [NSNumber]!) {
        sessionSubAcked = true;
    }
    
}
