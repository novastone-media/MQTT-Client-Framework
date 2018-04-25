# MQTT-Client-Framework 

[![Build Status](https://travis-ci.org/novastone-media/MQTT-Client-Framework.svg?branch=master)](https://travis-ci.org/novastone-media/MQTT-Client-Framework)

**Welcome to MQTT-Client-Framework**

MQTT-Client-Framework is Objective-C native MQTT Framework http://mqtt.org

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
[session subscribeToTopic:@"example/#" atLevel:2 subscribeHandler:^(NSError *error, NSArray<NSNumber *> *gQoss){
    if (error) {
        NSLog(@"Subscription failed %@", error.localizedDescription);
    } else {
        NSLog(@"Subscription sucessfull! Granted Qos: %@", gQoss);
    }
 }]; // this is part of the block API

```

Add the following to receive messages for the subscribed topics
```objective-c
 - (void)newMessage:(MQTTSession *)session
	data:(NSData *)data
	onTopic:(NSString *)topic
	qos:(MQTTQosLevel)qos
	retained:(BOOL)retained
	mid:(unsigned int)mid {
	// this is one of the delegate callbacks
}
```

Publish a message to a topic:

```objective-c
[session publishAndWaitData:data
                    onTopic:@"topic"
                     retain:NO
	                qos:MQTTQosLevelAtLeastOnce]; // this is part of the asynchronous API
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

## Thanks

This project was originally written by [Christoph Krey](https://github.com/ckrey).
