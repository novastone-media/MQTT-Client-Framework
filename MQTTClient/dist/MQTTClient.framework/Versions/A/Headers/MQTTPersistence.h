//
//  MQTTPersistence.h
//  MQTTClient
//
//  Created by Christoph Krey on 22.03.15.
//  Copyright (c) 2015 Christoph Krey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MQTTMessage.h"

@interface MQTTFlow : NSManagedObject
@property (strong, nonatomic) NSString *clientId;
@property (strong, nonatomic) NSNumber *incomingFlag;
@property (strong, nonatomic) NSNumber *retainedFlag;
@property (strong, nonatomic) NSNumber *commandType;
@property (strong, nonatomic) NSNumber *qosLevel;
@property (strong, nonatomic) NSNumber *messageId;
@property (strong, nonatomic) NSString *topic;
@property (strong, nonatomic) NSData *data;
@property (strong, nonatomic) NSDate *deadline;

@end

@interface MQTTPersistence : NSObject
@property (nonatomic) BOOL persistent;
@property (nonatomic) NSUInteger maxWindowSize;
@property (nonatomic) NSUInteger maxMessages;
@property (nonatomic) NSUInteger maxSize;

- (NSUInteger)windowSize:(NSString *)clientId;
- (MQTTFlow *)storeMessageForClientId:(NSString *)clientId
                                topic:(NSString *)topic
                                 data:(NSData *)data
                           retainFlag:(BOOL)retainFlag
                                  qos:(MQTTQosLevel)qos
                                msgId:(UInt16)msgId
                         incomingFlag:(BOOL)incomingFlag
                          commandType:(UInt8)commandType
                             deadline:(NSDate *)deadline;

- (void)deleteFlow:(MQTTFlow *)flow;
- (void)deleteAllFlowsForClientId:(NSString *)clientId;
- (NSArray *)allFlowsforClientId:(NSString *)clientId
                    incomingFlag:(BOOL)incomingFlag;
- (MQTTFlow *)flowforClientId:(NSString *)clientId
                 incomingFlag:(BOOL)incomingFlag
                    messageId:(UInt16)messageId;

- (MQTTFlow *)createFlowforClientId:(NSString *)clientId
                       incomingFlag:(BOOL)incomingFlag
                          messageId:(UInt16)messageId;
- (void)sync;

@end
