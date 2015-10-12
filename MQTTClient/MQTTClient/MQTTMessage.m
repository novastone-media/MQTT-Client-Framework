//
// MQTTMessage.m
// MQTTClient.framework
//
// Copyright (c) 2013-2015, Christoph Krey
//
// based on
//
// Copyright (c) 2011, 2013, 2lemetry LLC
// 
// All rights reserved. This program and the accompanying materials
// are made available under the terms of the Eclipse Public License v1.0
// which accompanies this distribution, and is available at
// http://www.eclipse.org/legal/epl-v10.html
// 
// Contributors:
//    Kyle Roche - initial API and implementation and/or initial documentation
// 

#import "MQTTMessage.h"

#ifdef DEBUG
#define DEBUGMSG FALSE
#else
#define DEBUGMSG FALSE
#endif

@implementation MQTTMessage

+ (id)connectMessageWithClientId:(NSString*)clientId
                        userName:(NSString*)userName
                        password:(NSString*)password
                       keepAlive:(NSInteger)keepAlive
                    cleanSession:(BOOL)cleanSessionFlag
                            will:(BOOL)will
                       willTopic:(NSString*)willTopic
                         willMsg:(NSData*)willMsg
                         willQoS:(MQTTQosLevel)willQoS
                      willRetain:(BOOL)willRetainFlag
                   protocolLevel:(UInt8)protocolLevel
{
    /*
     * setup flags w/o basic plausibility checks
     *
     */
    UInt8 flags = 0x00;

    if (cleanSessionFlag) {
        flags |= 0x02;
    }
    
    if (userName) {
        flags |= 0x80;
    }
    if (password) {
        flags |= 0x40;
    }
    
    if (will) {
        flags |= 0x04;
    }
    
    flags |= ((willQoS & 0x03) << 3);

    if (willRetainFlag) {
        flags |= 0x20;
    }
    
    NSMutableData* data = [NSMutableData data];
    
    switch (protocolLevel) {
        case 4:
            [data appendMQTTString:@"MQTT"];
            [data appendByte:4];
            break;
        case 3:
            [data appendMQTTString:@"MQIsdp"];
            [data appendByte:3];
            break;
        case 0:
            [data appendMQTTString:@""];
            [data appendByte:protocolLevel];
            break;
        default:
            [data appendMQTTString:@"MQTT"];
            [data appendByte:protocolLevel];
            break;
    }
    [data appendByte:flags];
    [data appendUInt16BigEndian:keepAlive];
    [data appendMQTTString:clientId];
    if (willTopic) {
        [data appendMQTTString:willTopic];
    }
    if (willMsg) {
        [data appendUInt16BigEndian:[willMsg length]];
        [data appendData:willMsg];
    }
    if (userName) {
        [data appendMQTTString:userName];
    }
    if (password) {
        [data appendMQTTString:password];
    }

    MQTTMessage *msg = [[MQTTMessage alloc] initWithType:MQTTConnect
                                                    data:data];
    return msg;
}

+ (id)pingreqMessage
{
    return [[MQTTMessage alloc] initWithType:MQTTPingreq];
}

+ (id)disconnectMessage
{
    return [[MQTTMessage alloc] initWithType:MQTTDisconnect];
}

+ (id)subscribeMessageWithMessageId:(UInt16)msgId
                              topics:(NSDictionary *)topics
{
    NSMutableData* data = [NSMutableData data];
    [data appendUInt16BigEndian:msgId];
    for (NSString *topic in topics.allKeys) {
        [data appendMQTTString:topic];
        [data appendByte:[topics[topic] intValue]];
    }
    MQTTMessage* msg = [[MQTTMessage alloc] initWithType:MQTTSubscribe
                                                     qos:1
                                                    data:data];
    msg.mid = msgId;
    return msg;
}

+ (id)unsubscribeMessageWithMessageId:(UInt16)msgId
                                topics:(NSArray *)topics
{
    NSMutableData* data = [NSMutableData data];
    [data appendUInt16BigEndian:msgId];
    for (NSString *topic in topics) {
        [data appendMQTTString:topic];
    }
    MQTTMessage* msg = [[MQTTMessage alloc] initWithType:MQTTUnsubscribe
                                                     qos:1
                                                    data:data];
    msg.mid = msgId;
    return msg;
}

+ (id)publishMessageWithData:(NSData*)payload
                     onTopic:(NSString*)topic
                         qos:(MQTTQosLevel)qosLevel
                       msgId:(UInt16)msgId
                  retainFlag:(BOOL)retain
                     dupFlag:(BOOL)dup
{
    NSMutableData* data = [NSMutableData data];
    [data appendMQTTString:topic];
    if (msgId) [data appendUInt16BigEndian:msgId];
    [data appendData:payload];
    MQTTMessage *msg = [[MQTTMessage alloc] initWithType:MQTTPublish
                                                     qos:qosLevel
                                              retainFlag:retain
                                                 dupFlag:dup
                                                    data:data];
    msg.mid = msgId;
    return msg;
}

+ (id)pubackMessageWithMessageId:(UInt16)msgId
{
    NSMutableData* data = [NSMutableData data];
    [data appendUInt16BigEndian:msgId];
    MQTTMessage *msg = [[MQTTMessage alloc] initWithType:MQTTPuback
                                                    data:data];
    msg.mid = msgId;
    return msg;
}

+ (id)pubrecMessageWithMessageId:(UInt16)msgId
{
    NSMutableData* data = [NSMutableData data];
    [data appendUInt16BigEndian:msgId];
    MQTTMessage *msg = [[MQTTMessage alloc] initWithType:MQTTPubrec
                                                    data:data];
    msg.mid = msgId;
    return msg;
}

+ (id)pubrelMessageWithMessageId:(UInt16)msgId
{
    NSMutableData* data = [NSMutableData data];
    [data appendUInt16BigEndian:msgId];
    MQTTMessage *msg = [[MQTTMessage alloc] initWithType:MQTTPubrel
                                                     qos:1
                                                    data:data];
    msg.mid = msgId;
    return msg;
}

+ (id)pubcompMessageWithMessageId:(UInt16)msgId
{
    NSMutableData* data = [NSMutableData data];
    [data appendUInt16BigEndian:msgId];
    MQTTMessage *msg = [[MQTTMessage alloc] initWithType:MQTTPubcomp
                                                    data:data];
    msg.mid = msgId;
    return msg;
}

- (id)initWithType:(UInt8)aType {
    _type = aType;
    _data = nil;
    return self;
}

- (id)initWithType:(UInt8)aType data:(NSData*)aData {
    _type = aType;
    self.data = aData;
    return self;
}

- (id)initWithType:(UInt8)aType
               qos:(MQTTQosLevel)aQos
              data:(NSData*)aData {
    _type = aType;
    _qos = aQos;
    _data = aData;
    return self;
}

- (id)initWithType:(UInt8)aType
               qos:(MQTTQosLevel)aQos
        retainFlag:(BOOL)aRetainFlag
           dupFlag:(BOOL)aDupFlag
              data:(NSData*)aData {
    _type = aType;
    _qos = aQos;
    _retainFlag = aRetainFlag;
    _dupFlag = aDupFlag;
    _data = aData;
    return self;
}

@end

@implementation NSMutableData (MQTT)

- (void)appendByte:(UInt8)byte
{
    [self appendBytes:&byte length:1];
}

- (void)appendUInt16BigEndian:(UInt16)val
{
    [self appendByte:val / 256];
    [self appendByte:val % 256];
}

- (void)appendMQTTString:(NSString *)string
{
    if (string) {
//        UInt8 buf[2];
//        if (DEBUGMSG) NSLog(@"String=%@", string);
//        const char* utf8String = [string UTF8String];
//        if (DEBUGMSG) NSLog(@"UTF8=%s", utf8String);
//
//        size_t strLen = strlen(utf8String);
//        buf[0] = strLen / 256;
//        buf[1] = strLen % 256;
//        [self appendBytes:buf length:2];
//        [self appendBytes:utf8String length:strLen];
        
// This updated code allows for all kind or UTF characters including 0x0000
        NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
        UInt8 buf[2];
        UInt16 len = data.length;
        buf[0] = len / 256;
        buf[1] = len % 256;

        [self appendBytes:buf length:2];
        [self appendData:data];
    }
}

@end

