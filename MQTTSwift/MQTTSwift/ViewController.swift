//
//  ViewController.swift
//  MQTTSwift
//
//  Created by Christoph Krey on 23.05.16.
//  Copyright © 2016 OwnTracks. All rights reserved.
//

import UIKit
import MQTTClient

class ViewController: UIViewController, MQTTSessionDelegate {
    private let session = MQTTSession()!
    private var subscribed = false
    @IBOutlet weak var status: UILabel!
    @IBOutlet weak var messages: UITextView!
    @IBOutlet weak var subscriptionStatus: UILabel!
    @IBOutlet weak var publishText: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        session.transport = MQTTCFSocketTransport()
        session.transport.host = "test.mosquitto.org"
        session.transport.port = 1883
        session.delegate = self
    }
    
    func handleEvent(_ session: MQTTSession!, event eventCode: MQTTSessionEvent, error: Error!) {
        switch eventCode {
        case .connected:
            self.status.text = "Connected"
        case .connectionClosed:
            self.status.text = "Closed"
        case .connectionClosedByBroker:
            self.status.text = "Closed by Broker"
        case .connectionError:
            self.status.text = "Error"
        case .connectionRefused:
            self.status.text = "Refused"
        case .protocolError:
            self.status.text = "Protocol Error"
        }
    }
    
    func newMessage(_ session: MQTTSession!, data: Data!, onTopic topic: String!, qos: MQTTQosLevel, retained: Bool, mid: UInt32) {
        var text = self.messages.text ?? ""
        text.append("\n topic - \(topic!) data - \(data!)")
        self.messages.text = text
    }
    
    func subAckReceived(_ session: MQTTSession!, msgID: UInt16, grantedQoss qoss: [NSNumber]!) {
        self.subscribed = true
        self.subscriptionStatus.text = "Subscribed"
    }
    
    func unsubAckReceived(_ session: MQTTSession!, msgID: UInt16) {
        self.subscribed = false
        self.subscriptionStatus.text = "Unsubscribed"
    }
    
    @IBAction func subscribeUnsubscribe(_ sender: Any) {
        if self.subscribed {
            session.unsubscribeTopic("MQTTClient")
        } else {
            session.subscribe(toTopic: "MQTTClient", at: .atMostOnce)
        }
        
    }
    @IBAction func publish(_ sender: Any) {
        self.session.publishData((self.publishText.text ?? "").data(using: String.Encoding.utf8, allowLossyConversion: false),
                                 onTopic: "MQTTClient",
                                 retain: false,
                                 qos: .atMostOnce)
    }
    
    @IBAction func connectDisconnect(_ sender: Any) {
        switch self.session.status {
        case .connected:
            self.session.disconnect()
        case .closed, .created, .error:
            self.session.connect()
        default:
            return
        }
    }
}


