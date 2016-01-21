MQTT-Client-Framework
=====================

an Objective-C native MQTT Framework http://mqtt.org

### Tested with

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

### Howto

Use the CocoaPod MQTTClient! 

Add this to your Podfile:
```
pod 'MQTTClient'
```

Additionally add this subspec if you want to use MQTT over Websockets:
```
pod 'MQTTClient/Websocket'
```

Or use the dynamic library created in the MQTTFramework target.

Or include the source from here.

[Documentation](MQTTClient/dist/documentation/html/index.html)

### Usage

Create a new client and connect to a broker:

```objective-c

\@interface MyDelegate : ... MQTTSessionDelegate>
...

        MQTTCFSocketTransport *transport = [[MQTTCFSocketTransport alloc] init];
        transport.host = @"localhost";
        transport.port = 1883;

        session = [[MQTTSession alloc] init];
        session.transport = transport;
        
	session.delegate=self;

	[session connectAndWaitTimeout:30];  //this is part of the synchronous API

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

#### docs

Documentation generated with doxygen http://doxygen.org

#### Comparison MQTT Clients for iOS (incomplete)

|Wrapper|---|----|MQTTKit  |Marquette|Moscapsule|Musqueteer|MQTT-Client|MqttSDK|CocoaMQTT|
|-------|---|----|---------|---------|----------|----------|-----------|-------|---------|
|       |   |    |Obj-C    |Obj-C    |Swift     |Obj-C     |Obj-C      |Obj-C  |Swift    |
|Library|IBM|Paho|Mosquitto|Mosquitto|Mosquitto |Mosquitto |native     |native |native   |
