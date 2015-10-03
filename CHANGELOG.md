MQTT-Client-Framework iOS Release Notes
=======================================

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

