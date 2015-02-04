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
#define MULTI 99
#define BULK 99

// rabbitmq does not support MQTT3.1.1
// hivemq currently down
// m2m requires non-anonymous

#define BROKERLIST @[@"local", @"mosquitto", @"eclipse", @"paho"]

#define BROKERS @{ \
\
@"local": @{ \
@"host": @"localhost",  \
@"port": @1883,  \
@"tls": @NO, \
@"timeout": @10 \
}, \
\
@"mosquitto": @{ \
@"host": @"test.mosquitto.org",  \
@"port": @1883,  \
@"tls": @NO, \
@"timeout": @10 \
}, \
\
@"eclipse": @{ \
@"host": @"m2m.eclipse.org",  \
@"port": @1883,  \
@"tls": @NO, \
@"timeout": @10 \
}, \
\
@"paho": @{ \
@"host": @"iot.eclipse.org",  \
@"port": @1883,  \
@"tls": @NO, \
@"timeout": @10 \
}, \
\
@"m2m": @{ \
@"host": @"q.m2m.io",  \
@"port": @1883,  \
@"tls": @NO, \
@"timeout": @10 \
}, \
\
@"hivemq": @{ \
@"host": @"broker.mqtt-dashboard.com",  \
@"port": @1883,  \
@"tls": @NO, \
@"timeout": @10 \
}, \
\
@"rabbitmq": @{ \
@"host": @"dev.rabbitmq.com",  \
@"port": @1883,  \
@"tls": @NO, \
@"timeout": @10 \
} \
}

// MQTT 3.1.1 Paho Test Broker
// git.eclipse.org/gitroot/paho/org.eclipse.paho.mqtt.testing.git
// #define PARAMETERS @{ \
//                      @"host": @"192.168.178.38",  \
//                      @"port": @1883,  \
//                      @"tls": @NO, \
//                      @"protocollevel": @3, \
//                      @"timeout": @10 \
//                      }


// Mosca
//#define PARAMETERS @{ \
//                    @"host": @"192.168.178.39",  \
//                    @"port": @1883,  \
//                    @"tls": @NO, \
//                    @"protocollevel": @4, \
//                    @"timeout": @10 \
//                    }

// RSMB
// git.eclipse.org/gitroot/mosquitto/org.eclipse.mosquitto.rsmb.git
//#define PARAMETERS @{ \
//                    @"host": @"192.168.178.38",  \
//                    @"port": @1883,  \
//                    @"tls": @NO, \
//                    @"protocollevel": @3, \
//                    @"timeout": @10 \
//                    }

// IBM Websphere MQ Telemetry not tested
// IBM MessageSight not tested
// IBM Integration Bus not tested
// Cloudmqtt not tested
// Eurotech Everywhere Device Cloud not tested
// Xivelynot tested
// eMQTT not tested
// Apache ActiveMQ not tested
// Apache Apollo not tested
// Moquette not tested
// Litmus Automation Loop not tested
// webMethods Nirvana Messaging not tested



#endif
