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

//#define BROKERLIST @[@"local", @"mosquitto", @"eclipse", @"paho", @"pahotest", @"rabbitmq", @"hivemq", @"rsmb", @"mosca", @"m2m", @"vernemq", @"emqttd"]
#define BROKERLIST @[@"local", @"mosquitto"]

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
@"localTls": @{ \
@"host": @"localhost",  \
@"port": @8883,  \
@"tls": @YES, \
@"protocollevel": @4, \
@"timeout": @10 \
}, \
\
@"localTlsCerts": @{ \
@"host": @"localhost",  \
@"port": @8884,  \
@"tls": @YES, \
@"protocollevel": @4, \
@"timeout": @10, \
@"clientp12": @"info@owntracks.org", \
@"clientp12pass": @"12345678" \
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
}, \
\
@"pahotest": @{ \
@"host": @"localhost",  \
@"port": @1884,  \
@"tls": @NO, \
@"protocollevel": @4, \
@"timeout": @10 \
}, \
\
@"rsmb": @{ \
@"host": @"192.168.178.38",  \
@"port": @1884,  \
@"tls": @NO, \
@"protocollevel": @3, \
@"timeout": @10 \
}, \
\
@"mosca": @{ \
@"host": @"localhost",  \
@"port": @1885,  \
@"tls": @NO, \
@"protocollevel": @4, \
@"timeout": @10 \
}, \
\
@"vernemq": @{ \
@"host": @"localhost",  \
@"port": @1886,  \
@"tls": @NO, \
@"protocollevel": @4, \
@"timeout": @10 \
}, \
\
@"emqttd": @{ \
@"host": @"localhost",  \
@"port": @1887,  \
@"tls": @NO, \
@"protocollevel": @4, \
@"timeout": @10 \
} \
\
}

// IBM Websphere MQ Telemetry not tested
// IBM MessageSight not tested
// IBM Integration Bus not tested
// Cloudmqtt not tested
// Eurotech Everywhere Device Cloud not tested
// Xively not tested
// eMQTT not tested
// Apache ActiveMQ not tested
// Apache Apollo not tested
// Moquette not tested
// Litmus Automation Loop not tested
// webMethods Nirvana Messaging not tested



#endif
