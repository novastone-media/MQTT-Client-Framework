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

// IBM Websphere MQ Telemetry
// not tested

// IBM MessageSight
// not tested

// IBM Integration Bus
// not tested

// Mosquitto
//#define PARAMETERS @{ \
//                  @"host": @"test.mosquitto.org",  \
//                  @"port": @1883,  \
//                  @"tls": @NO, \
//                  @"protocollevel": @4, \
//                  @"timeout": @10 \
//                  }

//#define HOST @"m2m.eclipse.org"
//#define PARAMETERS @{ \
//                    @"host": @"m2m.eclipse.org",  \
//                    @"port": @1883,  \
//                    @"tls": @NO, \
//                    @"protocollevel": @4, \
//                    @"timeout": @10 \
//                    }

//#define HOST @"192.168.178.38"
//#define PARAMETERS @{ \
//                    @"host": @"192.168.178.38",  \
//                    @"port": @1883,  \
//                    @"tls": @NO, \
//                    @"protocollevel": @4, \
//                    @"timeout": @10 \
//                    }

//#define HOST @"localhost"
//#define PARAMETERS @{ \
//                    @"host": @"localhost",  \
//                    @"port": @1883,  \
//                    @"tls": @NO, \
//                    @"protocollevel": @4, \
//                    @"timeout": @10 \
//                    }

//#define @"www.cloudmqtt.com"
//#define port 18443, 28443
// not tested

// Eclipse Paho
//#define PARAMETERS @{ \
//                    @"host": @"iot.eclipse.org",  \
//                    @"port": @1883,  \
//                    @"tls": @NO, \
//                    @"protocollevel": @4, \
//                    @"timeout": @10 \
//                    }

// MQTT 3.1.1 Paho Test Broker
// git.eclipse.org/gitroot/paho/org.eclipse.paho.mqtt.testing.git
// #define PARAMETERS @{ \
//                      @"host": @"192.168.178.38",  \
//                      @"port": @1883,  \
//                      @"tls": @NO, \
//                      @"protocollevel": @3, \
//                      @"timeout": @10 \
//                      }


// Eurotech Everywhere Device Cloud
// not tested

// Xively
// not tested

// eMQTT
// not tested

// m2m.io
//#define PARAMETERS @{ \
//                    @"host": @"q.m2m.io",  \
//                    @"port": @1883,  \
//                    @"tls": @NO, \
//                    @"protocollevel": @4, \
//                    @"timeout": @10 \
//                    }
//

// webMethods Nirvana Messaging
// not tested

// RabbitMQ
//#define PARAMETERS @{ \
//                    @"host": @"dev.rabbitmq.com",  \
//                    @"port": @1883,  \
//                    @"tls": @NO, \
//                    @"protocollevel": @3, \
//                    @"timeout": @10 \
//                    }

// RSMB
// git.eclipse.org/gitroot/mosquitto/org.eclipse.mosquitto.rsmb.git
#define PARAMETERS @{ \
                    @"host": @"192.168.178.38",  \
                    @"port": @1883,  \
                    @"tls": @NO, \
                    @"protocollevel": @3, \
                    @"timeout": @10 \
                    }

// Apache ActiveMQ
// not tested

// Apache Apollo
// not tested

// Moquette
// not tested

// HiveMQ
//#define PARAMETERS @{ \
//                    @"host": @"broker.mqtt-dashboard.com",  \
//                    @"port": @1883,  \
//                    @"tls": @NO, \
//                    @"protocollevel": @4, \
//                    @"timeout": @10 \
//                    }

// Mosca
//#define PARAMETERS @{ \
//                    @"host": @"192.168.178.39",  \
//                    @"port": @1883,  \
//                    @"tls": @NO, \
//                    @"protocollevel": @4, \
//                    @"timeout": @10 \
//                    }

// Litmus Automation Loop
// not tested

#define TOPIC @"MQTTClient"

#endif
