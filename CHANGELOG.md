MQTT-Client-Framework iOS/OSX/tvOS Release Notes
================================================

## MQTT-Client-Framework 0.8.5
> Release date 2016-09-29

[FIX] CocoaLumberjack dependency resolved see #199 and README.md

## MQTT-Client-Framework 0.8.4
> Release date 2016-09-??

[FIX] MQTTSessionManager lastErrorCode set too late? #203

## MQTT-Client-Framework 0.8.3
> Release date 2016-09-23

[FIX] Cannot build after CocoaLumberjack new release #199
[FIX] Xcode8 / Swift3 compatibility

## MQTT-Client-Framework 0.8.1
> Release date 2016-08-10

[FIX] MQTTClient.h in podspec

## MQTT-Client-Framework 0.8.0
> Release date 2016-08-08

[FIX] Application extensions is not supported closes #188
[FIX] Update MQTTCoreDataPersistence.m pull request  #174

## MQTT-Client-Framework 0.7.9
> Release date 2016-06-21

[FIX] Legacy connect method does not honor Client Certificates with default transport #160
[FIX] CFNetwork SSLHandshake failed (-9807) #149

## MQTT-Client-Framework 0.7.8
> Release date 2016-05-23

[FIX] Fix unread and unused variables pull reques #143
[FIX] Call connect handler when connection is closed by broker without sending a CONNACK and consistent error reporting pull request #142
[NEW] Adding method for MQTTSessionManager to include protocolLevel variable pull request #140
[FIX] Fixes an issue where calling open twice on MQTTCFSocketTransport crashes pull request #131
[NEW] Add Swift test project to check #119

## MQTT-Client-Framework 0.7.4
> Release date 2016-03-17

[NEW] include Websockets for tvOS closes #123

## MQTT-Client-Framework 0.7.3
> Release date 2016-03-15

[FIX] Synchronous API timeout closes #121
[FIX] Random crash subscribing to topics closes #113

## MQTT-Client-Framework 0.7.2
> Release date 2016-03-03

[REVERT] Persistent store not saved to disk closes #117

## MQTT-Client-Framework 0.7.0/1
> Release date 2016-03-02

[FIX] Persistent store not saved to disk closes #117

## MQTT-Client-Framework 0.6.8/9
> Release date 2016-02-11

[FIX] Client-side certificate validations issues closes #96

## MQTT-Client-Framework 0.6.7
> Release date 2016-02-10

[FIX] Logs and CocoaLumberjack dependency closes #107

## MQTT-Client-Framework 0.6.6
> Release date 2016-02-05

[FIX] MQTTCoreDataPersistence is crashing closes #104 closes #105
[FIX] CoreData: warning: Unable to load class named 'MQTTFlow' closes #102

## MQTT-Client-Framework 0.6.5
> Release date 2016-01-21

[FIX] turn off verbose logging by default closes #97
[FIX] MQTTFramework.h includes all necessary files now #62

## MQTT-Client-Framework 0.6.4
> Release date 2016-01-17

[FIX] incorrect length checking for SUBACK #95
[FIX] incorrect length checking  for UNSUBSCRIBE

## MQTT-Client-Framework 0.6.3
> Release date 2016-01-17

[FIX] Ignore incoming non-UTF8 topic string closes #94
[FIX] Crash b/c input stream not closed in timeout situation closes #93

## MQTT-Client-Framework 0.6.2
> Release date 2016-01-05

[FIX] MQTTDecoder runLoop no longer configurable closes #87
[FIX] other smaller bugs

## MQTT-Client-Framework 0.6.1
> Release date 2015-12-31

[FIX] CocoaPods packaging

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

