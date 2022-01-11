//
//  MQTTCoreDataPersistence.h
//  MQTTClient
//
//  Created by Christoph Krey on 22.03.15.
//  Copyright © 2015-2017 Christoph Krey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MQTTPersistence.h"

@interface MQTTCoreDataFlow : NSObject <MQTTFlow>
- (MQTTCoreDataFlow *)initWithContext:(NSManagedObjectContext *)context andObject:(id<MQTTFlow>)object;
@property NSManagedObjectContext *context;
@property id<MQTTFlow> object;
@end

@interface MQTTCoreDataPersistence : NSObject <MQTTPersistence>
- (NSPersistentStoreCoordinator *)createPersistentStoreCoordinator;
- (NSManagedObjectContext *)managedObjectContext;
- (NSArray *)allFlowsforClientId:(NSString *)clientId;
- (void)sync;
- (void)deleteAllFlowsForClientId:(NSString *)clientId;
- (void)deleteFlow:(MQTTCoreDataFlow *)flow;
- (MQTTCoreDataFlow *)createFlowforClientId:(NSString *)clientId
                               incomingFlag:(BOOL)incomingFlag
                                  messageId:(UInt16)messageId;
- (MQTTCoreDataFlow *)internalFlowForClientId:(NSString *)clientId
                                 incomingFlag:(BOOL)incomingFlag
                                    messageId:(UInt16)messageId;

- (MQTTCoreDataFlow *)flowforClientId:(NSString *)clientId  incomingFlag:(BOOL)incomingFlag messageId:(UInt16)messageId;
- (void)internalSync;
@end

@interface MQTTFlow : NSManagedObject <MQTTFlow>
@end

