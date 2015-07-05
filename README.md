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

### Howto

Add MQTTClient.framework from the dist directory to your IOS project
or use the CocoaPod MQTTClient

[Documentation](MQTTClient/dist/documentation/html/index.html)

### Usage

Create a new client and connect to a broker:

```objective-c
MQTTSession *session = [[MQTTSession alloc]initWithClientId:@"client_id"]

// Set delegate appropriately to receive various events
// See MQTTSession.h for information on various handlers
// you can subscribe to.
[session setDelegate:self];

[session connectAndWaitToHost:@"host" port:1883 usingSSL:NO];

```

Subscribe to a topic:

```objective-c
[session subscribeToTopic:topic atLevel:MQTTQosLevelAtLeastOnce];
```

Publish a message to a topic:

```objective-c
[session publishAndWaitData:data
	                onTopic:@"topic"
	                 retain:NO
				        qos:MQTTQosLevelAtLeastOnce]
```

### License

Copyright (C) 2013-2015 Christoph Krey

Based on and fully API backward compatible with

https://github.com/m2mIO/mqttIO-objC

Copyright © 2011, 2013 2lemetry, LLC

All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that
the following conditions are met:

Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer
in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES|
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


#### Framework

Framework build using instructions and scripts by Jeff Verkoeyen https://github.com/jverkoey/iOS-Framework

#### docs

Documentation generated with doxygen http://doxygen.org

#### Comparison MQTT Clients for iOS (incomplete)

|Wrapper|---|----|MQTTKit  |Marquette|Moscapsule|Musqueteer|MQTT-Client|MqttSDK|CocoaMQTT|
|-------|---|----|---------|---------|----------|----------|-----------|-------|---------|
|       |   |    |Obj-C    |Obj-C    |Swift     |Obj-C     |Obj-C      |Obj-C  |Swift    |
|Library|IBM|Paho|Mosquitto|Mosquitto|Mosquitto |Mosquitto |native     |native |native   |
