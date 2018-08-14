# MQTT-Client-Framework 

[![Build Status](https://travis-ci.org/novastone-media/MQTT-Client-Framework.svg?branch=master)](https://travis-ci.org/novastone-media/MQTT-Client-Framework)
[![codecov](https://codecov.io/gh/novastone-media/MQTT-Client-Framework/branch/master/graph/badge.svg)](https://codecov.io/gh/novastone-media/MQTT-Client-Framework)
[![CocoaPods Version](https://img.shields.io/cocoapods/v/MQTTClient.svg)](https://img.shields.io/cocoapods/v/MQTTClient.svg)
[![Platform](https://img.shields.io/cocoapods/p/MQTTClient.svg?style=flat)](https://img.shields.io/cocoapods/p/MQTTClient.svg?style=flat)

**Welcome to MQTT-Client-Framework**

MQTT-Client-Framework is a native Objective-C iOS library. It uses `CFNetwork` for networking and `CoreData` for persistence. It is a complete implementation of MQTT 3.1.1 and supports TLS.

You can read [introduction](http://www.hivemq.com/blog/mqtt-client-library-encyclopedia-mqtt-client-framework) to learn more about framework.

MQTT-Client-Framework is tested with a long list of brokers:

* mosquitto
* paho
* rabbitmq
* hivemq
* rsmb
* mosca
* vernemq
* emqtt
* moquette
* ActiveMQ
* Apollo
* CloudMQTT
* aws
* hbmqtt (MQTTv311 only, limitations)
* [aedes](https://github.com/mcollina/aedes) 
* [flespi](https://flespi.com/mqtt-broker) 

## Usage

Create a new client and connect to a broker:

```objective-c
#import "MQTTClient.h"

MQTTCFSocketTransport *transport = [[MQTTCFSocketTransport alloc] init];
transport.host = @"test.mosquitto.org";
transport.port = 1883;
    
MQTTSession *session = [[MQTTSession alloc] init];
session.transport = transport;
[session connectWithConnectHandler:^(NSError *error) {
	// Do some work
}];
```

Subscribe to a topic:

```objective-c
[session subscribeToTopic:@"example/#" atLevel:MQTTQosLevelExactlyOnce subscribeHandler:^(NSError *error, NSArray<NSNumber *> *gQoss) {
    if (error) {
        NSLog(@"Subscription failed %@", error.localizedDescription);
    } else {
        NSLog(@"Subscription sucessfull! Granted Qos: %@", gQoss);
    }
 }];

```

In your `MQTTSession` delegate, add the following to receive messages for the subscribed topics:

```objective-c
- (void)newMessage:(MQTTSession *)session data:(NSData *)data onTopic:(NSString *)topic qos:(MQTTQosLevel)qos retained:(BOOL)retained mid:(unsigned int)mid {
    // New message received in topic
}
```

Publish a message to a topic:

```objective-c
[session publishData:someData onTopic:@"example/#" retain:NO qos:MQTTQosLevelAtMostOnce publishHandler:^(NSError *error) {
}];
```

If you already have a self signed URL from broker like AWS IoT endpoint, use the `url` property of `MQTTWebsocketTransport`:
```objective-c
MQTTWebsocketTransport *transport = [[MQTTWebsocketTransport alloc] init];
transport.url = @"wss://aws.iot-amazonaws.com/mqtt?expiry='2018-05-01T23:12:32.950Z'"

MQTTSession *session = [[MQTTSession alloc] init];
session.transport = transport;
[session connectWithConnectHandler:^(NSError *error) {
    // Do some work
}];
```

## Installation

### CocoaPods 

Add this to your Podfile:

```
pod 'MQTTClient'
```
which is a short for:

```
pod 'MQTTClient/Min'
pod 'MQTTClient/Manager'
```

The Manager subspec includes the `MQTTSessionManager` class.

If you want to use MQTT over Websockets:

```
pod 'MQTTClient/Websocket'
```

If you want to do your logging with CocoaLumberjack (recommended):

```
pod 'MQTTClient/MinL'
pod 'MQTTClient/ManagerL'
pod 'MQTTClient/WebsocketL'
```

### Carthage

In your Cartfile:

```
github "novastone-media/MQTT-Client-Framework"
```

### Manually

#### Git submodule

1. Add MQTT-Client-Framework as a git submodule into your top-level project directory or simply copy whole folder
2. Find MQTTClient.xcodeproj and drag it into the file navigator of your app project.
3. In Xcode, navigate to the target configuration window by clicking on the blue project icon, and selecting the application target under the "Targets" heading in the sidebar.
4. Under "General" panel go to "Linked Frameworks and Libraries" and add MQTTClient.framework

#### Framework

1. Download MQTT-Client-Framework
2. Build it and you should find MQTTClient.framework under "Products" group.
3. Right click on it and select "Show in Finder" option.
4. Just drag and drop MQTTClient.framework to your project

## Security Disclosure

If you believe you have identified a security vulnerability with MQTT-Client-Framework, please report it to ios@novastonemedia.com and do not post it to a public issue tracker.

## Thanks

This project was originally written by [Christoph Krey](https://github.com/ckrey).
