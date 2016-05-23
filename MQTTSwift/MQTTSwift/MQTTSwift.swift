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
    var sessionConnected = false;
    var sessionError = false;
    var sessionReceived = false;
    var sessionSubAcked = false;
    var session : MQTTSession?;

    func testSwiftSubscribe() {
        session = MQTTSession();
        session!.delegate = self;

        session!.connectToHost("localhost",
                               port:1883,
                               usingSSL: false);
        while !sessionConnected && !sessionError {
            NSRunLoop.currentRunLoop().runUntilDate(NSDate(timeIntervalSinceNow: 1))
        }

        session!.subscribeToTopic("#", atLevel: .AtMostOnce)

        while sessionConnected && !sessionError && !sessionSubAcked {
            NSRunLoop.currentRunLoop().runUntilDate(NSDate(timeIntervalSinceNow: 1))
        }

        session!.publishData("sent from Xcode using Swift".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false),
                             onTopic: "MQTTSwift",
                             retain: false,
                             qos: .AtMostOnce)

        while sessionConnected && !sessionError && !sessionReceived {
            NSRunLoop.currentRunLoop().runUntilDate(NSDate(timeIntervalSinceNow: 1))
        }

        session!.close()
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

func subAckReceived(session: MQTTSession!, msgID: UInt16, grantedQoss qoss: [NSNumber]!) {
        sessionSubAcked = true;
    }

}
