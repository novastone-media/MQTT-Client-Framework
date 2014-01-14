MQTT-Client-Framework

Re: MQTT 1.3.1

Spec review:
	Distinquish between transient and non-transient error -> disconnect

Client:
	Complete Checks
	Implement UTF Check [MQTT-1.4.0-1]
	Implement NULL Check [MQTT-1.4.0-2]
	ZERO￼WIDTH NO-BREAK SPACE implement [MQTT-1.4.0-3]
	Disconnect if headers not correct [MQTT-2.0.0-1]
	Disconnect if flags not correct [MQTT-2.1.2-1]
x	Implement new connect header and fallback [MQTT-3.1.2-2]
	Discard after CleanSession [MQTT-3.1.2-6]
x	no plausi checks
	different set of functions with plausi checks
x	new protocol

Server-Test:
	Send invalid UTF [MQTT-1.4.0-1]
	Send NULL [MQTT-1.4.0-2]
	ZERO￼WIDTH NO-BREAK SPACE send [MQTT-1.4.0-3]
	

