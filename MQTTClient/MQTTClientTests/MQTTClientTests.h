//
//  MQTTClientTests.h
//  MQTTClient
//
//  Created by Christoph Krey on 25.03.14.
//  Copyright (c) 2014 Christoph Krey. All rights reserved.
//

#ifndef MQTTClient_MQTTClientTests_h
#define MQTTClient_MQTTClientTests_h

/**
 * Test Coverage MQTT Brokers
 */

#define TOPIC @"MQTTClient"
#define MULTI 15  // some test servers are limited in concurrent sessions
#define BULK 99
#define ALOT 1024
#define PERSISTENT false

//#define BROKERLIST @[@"local", @"mosquitto", @"mosquittoTls", @"mosquittoTlsCerts", @"eclipse", @"paho", @"hivemq", @"m2m", @"rabbitmq"]
#define BROKERLIST @[@"local"]

#define BROKERS @{ \
\
@"local": @{ \
@"host": @"localhost",  \
@"port": @1883,  \
@"tls": @NO, \
@"protocollevel": @4, \
@"timeout": @10 \
}, \
\
@"mosquittoTls": @{ \
@"host": @"test.mosquitto.org",  \
@"port": @8883,  \
@"tls": @YES, \
@"protocollevel": @4, \
@"timeout": @10, \
@"serverCER": @"mosquitto.org" \
}, \
\
@"mosquittoTlsCerts": @{ \
@"host": @"test.mosquitto.org",  \
@"port": @8884,  \
@"tls": @YES, \
@"protocollevel": @4, \
@"timeout": @10, \
@"serverCER": @"mosquitto.org", \
@"clientp12": @"KreyChristoph", \
@"clientp12pass": @"abcde" \
}, \
\
@"mosquitto": @{ \
@"host": @"test.mosquitto.org",  \
@"port": @1883,  \
@"tls": @NO, \
@"protocollevel": @4, \
@"timeout": @10 \
}, \
\
@"eclipse": @{ \
@"host": @"m2m.eclipse.org",  \
@"port": @1883,  \
@"tls": @NO, \
@"protocollevel": @4, \
@"timeout": @10 \
}, \
\
@"paho": @{ \
@"host": @"iot.eclipse.org",  \
@"port": @1883,  \
@"tls": @NO, \
@"protocollevel": @4, \
@"timeout": @10 \
}, \
\
@"m2m": @{ \
@"host": @"q.m2m.io",  \
@"port": @1883,  \
@"tls": @NO, \
@"protocollevel": @4, \
@"timeout": @10 \
}, \
\
@"hivemq": @{ \
@"host": @"broker.mqtt-dashboard.com",  \
@"port": @1883,  \
@"tls": @NO, \
@"protocollevel": @4, \
@"timeout": @30 \
}, \
\
@"rabbitmq": @{ \
@"host": @"dev.rabbitmq.com",  \
@"port": @1883,  \
@"tls": @NO, \
@"protocollevel": @3, \
@"timeout": @10 \
} \
\
}

#endif
