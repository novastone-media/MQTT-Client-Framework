//
//  MQTTInMemoryPersistence.m
//  MQTTClient
//
//  Created by Christoph Krey on 22.03.15.
//  Copyright © 2015-2017 Christoph Krey. All rights reserved.
//

#import "MQTTInMemoryPersistence.h"

#import "MQTTLog.h"

@implementation MQTTInMemoryFlow
@synthesize clientId;
@synthesize incomingFlag;
@synthesize retainedFlag;
@synthesize commandType;
@synthesize qosLevel;
@synthesize messageId;
@synthesize topic;
@synthesize data;
@synthesize deadline;

@end

@interface MQTTInMemoryPersistence()
@end

static NSMutableDictionary *clientIds;

@implementation MQTTInMemoryPersistence
@synthesize maxSize;
@synthesize persistent;
@synthesize maxMessages;
@synthesize maxWindowSize;

- (MQTTInMemoryPersistence *)init {
    self = [super init];
    self.maxMessages = MQTT_MAX_MESSAGES;
    self.maxWindowSize = MQTT_MAX_WINDOW_SIZE;
    @synchronized(clientIds) {
        if (!clientIds) {
            clientIds = [[NSMutableDictionary alloc] init];
        }
    }
    return self;
}

- (NSUInteger)windowSize:(NSString *)clientId {
    NSUInteger windowSize = 0;
    NSArray *flows = [self allFlowsforClientId:clientId
                                  incomingFlag:NO];
    for (MQTTInMemoryFlow *flow in flows) {
        if ((flow.commandType).intValue != MQTT_None) {
            windowSize++;
        }
    }
    return windowSize;
}

- (MQTTInMemoryFlow *)storeMessageForClientId:(NSString *)clientId
                                        topic:(NSString *)topic
                                         data:(NSData *)data
                                   retainFlag:(BOOL)retainFlag
                                          qos:(MQTTQosLevel)qos
                                        msgId:(UInt16)msgId
                                 incomingFlag:(BOOL)incomingFlag
                                  commandType:(UInt8)commandType
                                     deadline:(NSDate *)deadline {
    @synchronized(clientIds) {
        
        if (([self allFlowsforClientId:clientId incomingFlag:incomingFlag].count <= self.maxMessages)) {
            MQTTInMemoryFlow *flow = (MQTTInMemoryFlow *)[self createFlowforClientId:clientId
                                                                        incomingFlag:incomingFlag
                                                                           messageId:msgId];
            flow.topic = topic;
            flow.data = data;
            flow.retainedFlag = @(retainFlag);
            flow.qosLevel = @(qos);
            flow.commandType = [NSNumber numberWithUnsignedInteger:commandType];
            flow.deadline = deadline;
            return flow;
        } else {
            return nil;
        }
    }
}

- (void)deleteFlow:(MQTTInMemoryFlow *)flow {
    @synchronized(clientIds) {
        
        NSMutableDictionary *clientIdFlows = clientIds[flow.clientId];
        if (clientIdFlows) {
            NSMutableDictionary *clientIdDirectedFlow = clientIdFlows[flow.incomingFlag];
            if (clientIdDirectedFlow) {
                [clientIdDirectedFlow removeObjectForKey:flow.messageId];
            }
        }
    }
}

- (void)deleteAllFlowsForClientId:(NSString *)clientId {
    @synchronized(clientIds) {
        
        DDLogInfo(@"[MQTTInMemoryPersistence] deleteAllFlowsForClientId %@", clientId);
        [clientIds removeObjectForKey:clientId];
    }
}

- (void)sync {
    //
}

- (NSArray *)allFlowsforClientId:(NSString *)clientId
                    incomingFlag:(BOOL)incomingFlag {
    @synchronized(clientIds) {
        
        NSMutableArray *flows = nil;
        NSMutableDictionary *clientIdFlows = clientIds[clientId];
        if (clientIdFlows) {
            NSMutableDictionary *clientIdDirectedFlow = clientIdFlows[@(incomingFlag)];
            if (clientIdDirectedFlow) {
                flows = [NSMutableArray array];
                NSArray *keys = [clientIdDirectedFlow.allKeys sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES]]];
                for (id key in keys) {
                    [flows addObject:clientIdDirectedFlow[key]];
                }
            }
        }
        return flows;
    }
}

- (MQTTInMemoryFlow *)flowforClientId:(NSString *)clientId
                         incomingFlag:(BOOL)incomingFlag
                            messageId:(UInt16)messageId {
    @synchronized(clientIds) {
        
        MQTTInMemoryFlow *flow = nil;
        
        NSMutableDictionary *clientIdFlows = clientIds[clientId];
        if (clientIdFlows) {
            NSMutableDictionary *clientIdDirectedFlow = clientIdFlows[@(incomingFlag)];
            if (clientIdDirectedFlow) {
                flow = clientIdDirectedFlow[[NSNumber numberWithUnsignedInteger:messageId]];
            }
        }
        
        return flow;
    }
}

- (MQTTInMemoryFlow *)createFlowforClientId:(NSString *)clientId
                               incomingFlag:(BOOL)incomingFlag
                                  messageId:(UInt16)messageId {
    @synchronized(clientIds) {
        NSMutableDictionary *clientIdFlows = clientIds[clientId];
        if (!clientIdFlows) {
            clientIdFlows = [[NSMutableDictionary alloc] init];
            clientIds[clientId] = clientIdFlows;
        }
        
        NSMutableDictionary *clientIdDirectedFlow = clientIdFlows[@(incomingFlag)];
        if (!clientIdDirectedFlow) {
            clientIdDirectedFlow = [[NSMutableDictionary alloc] init];
            clientIdFlows[@(incomingFlag)] = clientIdDirectedFlow;
        }
        
        MQTTInMemoryFlow *flow = [[MQTTInMemoryFlow alloc] init];
        flow.clientId = clientId;
        flow.incomingFlag = @(incomingFlag);
        flow.messageId = [NSNumber numberWithUnsignedInteger:messageId];
        
        clientIdDirectedFlow[[NSNumber numberWithUnsignedInteger:messageId]] = flow;
        
        return flow;
    }
}

@end
