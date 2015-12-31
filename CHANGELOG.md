MQTT-Client-Framework iOS/OSX/tvOS Release Notes
================================================

## MQTT-Client-Framework 0.6.0
> Release date 2015-12-31

[NEW] refactor / cleanup test packages
[NEW] abstraction protocol for persistence closes #74
[NEW] removed .framework in favor of static Xcode library
[FIX] check status of websocket connection before sending
[NEW] unit tested websockets
[NEW] websocket transport closes #62
[NEW] refactor transport layer
[NEW] Split MQTTSession.h/m for better handling closes #80
[NEW] add timeout to ...AndWait methods closes #70

[known bugs]
Websockets not for MQTTSessionmanager (yet)


## MQTT-Client-Framework 0.5.3
>Release date: 2015-12-02

Enhancements

[NEW] add timeout to ...AndWait methods closes #70

## MQTT-Client-Framework 0.5.2
>Release date: 2015-11-28

Added dynamic framework to integrate in Swift libraries

[NEW] MQTTFramework targe added closes #78

## MQTT-Client-Framework 0.5.1
>Release date: 2015-11-18

SessionManager with subscriptions feedback

[NEW] feedback on effective subscription in MQTTSessionManager closes #65

## MQTT-Client-Framework 0.5.0
>Release date: 2015-11-15

API with blocks

[NEW] API with blocks. closes #68
[FIX] Messages queued while off-line are sent after 20 sec only. closes #67

## MQTT-Client-Framework 0.4.0
>Release date: 2015-11-09

Multi Threading support

[FIX] Other crash issue when I publish lots of messages (multithreaded publisher). #64

## MQTT-Client-Framework 0.3.7
>Release date: 2015-11-07

[FIX] wrong target OS preprocessor directives closes #63

## MQTT-Client-Framework 0.3.6
>Release date: 2015-11-06

[FIX] crashes when publishing from different threads closes #61
[PROBABLE FIX] crashes when publishing from different threads #59 #56 #53 #45

## MQTT-Client-Framework 0.3.5
>Release date: 2015-11-04

[NEW] Add testcases for 3.1.2-11 .. 13 (Will flags in connect message)

## MQTT-Client-Framework 0.3.4
>Release date: 2015-10-28

[NEW] extensive flow tests
[FIX] serialization of delegate newMessage* method calls
[FIX] missing msgID for QoS=1 in newMessageWithFeedback

## MQTT-Client-Framework 0.3.3
>Release date: 2015-10-10

[NEW] including tvOS with Cocoapods 0.39
[FIX] test coverage for topics containing 0x0000

## MQTT-Client-Framework 0.3.1/2
>Release date: 2015-10-08

[NEW] comment out tvOS until Cocoapods supports it
[NEW] inbound throttling closes #54

## MQTT-Client-Framework 0.3.0
>Release date: 2015-10-03

[NEW] provide support for tvOS, OSX and iOS closes #50
[NEW] add messageDelivered delegate message in MQTTSessionManager closes #49
[FIX] clarification of changing subscriptions in MQTTSessionManager closes #47

## MQTT-Client-Framework 0.2.6
>Release date: 2015-08-25

[NEW] MQTTSessionManager init with Persistence settings
[NEW] MQTTSessionManager with optional SSL security policy

## MQTT-Client-Framework 0.2.5
>Release date: 2015-08-22

[NEW] Will option on SessionManager closes #44
[NEW] Change SessionManager subscriptions while connected
[FIX] Correct SessionManager subscriptions according to server session present

[NEW] zero message id is accepted on incoming publish closes #42

## MQTT-Client-Framework 0.2.4
>Release date: 2015-08-16

Relaxed check for incoming Publishes (mosca 0.31.1 incompability)

[NEW] zero message id is accepted on incoming publish closes #42

## MQTT-Client-Framework 0.2.3
>Release date: 2015-07-23

Important Bug Fix 

[FIX] File Persistence is not saved to disk closes #41

## MQTT-Client-Framework 0.2.2
>Release date: 2015-07-05

Support TLS Client Certificates

[NEW] Client Certificates

## MQTT-Client-Framework 0.2.1
>Release date: 2015-06-19

Multithreading Violation with NSManagedObjectContext

[NEW] merged PR #37 - thanks
[NEW] elaborated on test cases

## MQTT-Client-Framework 0.2.0
>Release date: 2015-06-03

Add SSL Certificates Pinning and Self-Signed Certificates support

[NEW] merge PR #34

