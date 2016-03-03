//
//  MQTTCoreDataPersistence.m
//  MQTTClient
//
//  Created by Christoph Krey on 22.03.15.
//  Copyright © 2015-2016 Christoph Krey. All rights reserved.
//

#import "MQTTCoreDataPersistence.h"

#import "MQTTLog.h"

static NSRecursiveLock *lock;
static NSManagedObjectContext *parentManagedObjectContext;
static NSManagedObjectModel *managedObjectModel;
static NSPersistentStoreCoordinator *persistentStoreCoordinator;
static unsigned long long fileSize;
static unsigned long long fileSystemFreeSize;

@implementation MQTTFlow
@dynamic clientId;
@dynamic incomingFlag;
@dynamic retainedFlag;
@dynamic commandType;
@dynamic qosLevel;
@dynamic messageId;
@dynamic topic;
@dynamic data;
@dynamic deadline;

@end

@interface MQTTCoreDataFlow ()

- (MQTTCoreDataFlow *)initWithContext:(NSManagedObjectContext *)context andObject:(id<MQTTFlow>)object;
@property NSManagedObjectContext *context;
@property id<MQTTFlow> object;

@end

@implementation MQTTCoreDataFlow

@synthesize context;
@synthesize object;

- (MQTTCoreDataFlow *)initWithContext:(NSManagedObjectContext *)c andObject:(id<MQTTFlow>)o
{
    self = [super init];
    self.context = c;
    self.object = o;
    return self;
}

- (NSString *)clientId {
    __block NSString *_clientId;
    [context performBlockAndWait:^{
        _clientId = object.clientId;
    }];
    return _clientId;
}
- (void)setClientId:(NSString *)clientId {
    [context performBlockAndWait:^{
        object.clientId = clientId;
    }];
}
- (NSNumber *)incomingFlag {
    __block NSNumber *_incomingFlag;
    [context performBlockAndWait:^{
        _incomingFlag = object.incomingFlag;
    }];
    return _incomingFlag;
}
- (void)setIncomingFlag:(NSNumber *)incomingFlag {
    [context performBlockAndWait:^{
        object.incomingFlag = incomingFlag;
    }];
}
- (NSNumber *)retainedFlag {
    __block NSNumber *_retainedFlag;
    [context performBlockAndWait:^{
        _retainedFlag = object.retainedFlag;
    }];
    return _retainedFlag;
}
- (void)setRetainedFlag:(NSNumber *)retainedFlag {
    [context performBlockAndWait:^{
        object.retainedFlag = retainedFlag;
    }];
}
- (NSNumber *)commandType {
    __block NSNumber *_commandType;
    [context performBlockAndWait:^{
        _commandType = object.commandType;
    }];
    return _commandType;
}
- (void)setCommandType:(NSNumber *)commandType {
    [context performBlockAndWait:^{
        object.commandType = commandType;
    }];
}
- (NSNumber *)qosLevel {
    __block NSNumber *_qosLevel;
    [context performBlockAndWait:^{
        _qosLevel = object.qosLevel;
    }];
    return _qosLevel;
}
- (void)setQosLevel:(NSNumber *)qosLevel {
    [context performBlockAndWait:^{
        object.qosLevel = qosLevel;
    }];
}
- (NSNumber *)messageId {
    __block NSNumber *_messageId;
    [context performBlockAndWait:^{
        _messageId = object.messageId;
    }];
    return _messageId;
}
- (void)setMessageId:(NSNumber *)messageId {
    [context performBlockAndWait:^{
        object.messageId = messageId;
    }];
}
- (NSString *)topic {
    __block NSString *_topic;
    [context performBlockAndWait:^{
        _topic = object.topic;
    }];
    return _topic;
}
- (void)setTopic:(NSString *)topic {
    [context performBlockAndWait:^{
        object.topic = topic;
    }];
}
- (NSData *)data {
    __block NSData *_data;
    [context performBlockAndWait:^{
        _data = object.data;
    }];
    return _data;
}
- (void)setData:(NSData *)data {
    [context performBlockAndWait:^{
        object.data = data;
    }];
}
- (NSDate *)deadline {
    __block NSDate *_deadline;
    [context performBlockAndWait:^{
        _deadline = object.deadline;
    }];
    return _deadline;
}
- (void)setDeadline:(NSDate *)deadline {
    [context performBlockAndWait:^{
        object.deadline = deadline;
    }];
}

@end

// Attempt to fix #117
//
//@interface NSManagedObjectContext ( Recursive )
//- (void)recursiveSave;
//@end
//
//@implementation NSManagedObjectContext ( Recursive )
//
//- (void)recursiveSave {
//    if (self.hasChanges) {
//        NSError *error = nil;
//        if (![self save: &error]) {
//            DDLogError(@"[MQTTPersistence] sync error %@", error);
//        }
//        
//        if (self.parentContext) {
//            [self.parentContext recursiveSave];
//        }
//    }
//}
//@end
//
@implementation MQTTCoreDataPersistence
@synthesize persistent;
@synthesize maxSize;
@synthesize maxMessages;
@synthesize maxWindowSize;

- (MQTTCoreDataPersistence *)init {
    self = [super init];
    self.persistent = MQTT_PERSISTENT;
    self.maxSize = MQTT_MAX_SIZE;
    self.maxMessages = MQTT_MAX_MESSAGES;
    self.maxWindowSize = MQTT_MAX_WINDOW_SIZE;
    if (!lock) {
        lock = [[NSRecursiveLock alloc] init];
    }
    return self;
}

- (NSUInteger)windowSize:(NSString *)clientId {
    NSUInteger windowSize = 0;
    NSArray *flows = [self allFlowsforClientId:clientId
                                  incomingFlag:NO];
    for (MQTTCoreDataFlow *flow in flows) {
        if ([flow.commandType unsignedIntegerValue] != MQTT_None) {
            windowSize++;
        }
    }
    return windowSize;
}

- (MQTTCoreDataFlow *)storeMessageForClientId:(NSString *)clientId
                                        topic:(NSString *)topic
                                         data:(NSData *)data
                                   retainFlag:(BOOL)retainFlag
                                          qos:(MQTTQosLevel)qos
                                        msgId:(UInt16)msgId
                                 incomingFlag:(BOOL)incomingFlag
                                  commandType:(UInt8)commandType
                                     deadline:(NSDate *)deadline {
    if (([self allFlowsforClientId:clientId incomingFlag:incomingFlag].count <= self.maxMessages) &&
        (fileSize <= self.maxSize)) {
        MQTTCoreDataFlow *flow = [self createFlowforClientId:clientId
                                                incomingFlag:incomingFlag
                                                    messageId:msgId];
        flow.topic = topic;
        flow.data = data;
        flow.retainedFlag = [NSNumber numberWithBool:retainFlag];
        flow.qosLevel = [NSNumber numberWithUnsignedInteger:qos];
        flow.commandType = [NSNumber numberWithUnsignedInteger:commandType];
        flow.deadline = deadline;
        return flow;
    } else {
        return nil;
    }
}

- (void)deleteFlow:(MQTTCoreDataFlow *)flow {
    [self.managedObjectContext performBlockAndWait:^{
        [self.managedObjectContext deleteObject:(NSManagedObject *)flow.object];
        [self sync];
    }];
}

- (void)deleteAllFlowsForClientId:(NSString *)clientId {
    [self.managedObjectContext performBlockAndWait:^{
        for (MQTTCoreDataFlow *flow in [self allFlowsforClientId:clientId incomingFlag:TRUE]) {
            [self.managedObjectContext deleteObject:(NSManagedObject *)flow.object];
        }
        for (MQTTCoreDataFlow *flow in [self allFlowsforClientId:clientId incomingFlag:FALSE]) {
            [self.managedObjectContext deleteObject:(NSManagedObject *)flow.object];
        }
        [self sync];
    }];
}

- (void)sync {
    [self.managedObjectContext performBlockAndWait:^{
        if (self.managedObjectContext.hasChanges) {
            DDLogVerbose(@"[MQTTPersistence] pre-sync: i%lu u%lu d%lu",
                         (unsigned long)self.managedObjectContext.insertedObjects.count,
                         (unsigned long)self.managedObjectContext.updatedObjects.count,
                         (unsigned long)self.managedObjectContext.deletedObjects.count
                         );
            NSError *error = nil;
            if (![self.managedObjectContext save:&error]) {
                DDLogError(@"[MQTTPersistence] sync error %@", error);
            }
            if (self.managedObjectContext.hasChanges) {
                DDLogError(@"[MQTTPersistence] sync not complete");
            }
            DDLogVerbose(@"[MQTTPersistence] postsync: i%lu u%lu d%lu",
                         (unsigned long)self.managedObjectContext.insertedObjects.count,
                         (unsigned long)self.managedObjectContext.updatedObjects.count,
                         (unsigned long)self.managedObjectContext.deletedObjects.count
                         );
            [self sizes];
        }
    }];
}

- (NSArray *)allFlowsforClientId:(NSString *)clientId
                    incomingFlag:(BOOL)incomingFlag {
    NSMutableArray *flows = [NSMutableArray array];
    __block NSArray *rows;
    [self.managedObjectContext performBlockAndWait:^{
        
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"MQTTFlow"];
        fetchRequest.predicate = [NSPredicate predicateWithFormat:
                                  @"clientId = %@ and incomingFlag = %@",
                                  clientId,
                                  @(incomingFlag)
                                  ];
        fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"deadline" ascending:YES]];
        NSError *error = nil;
        rows = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        if (!rows) {
            DDLogError(@"[MQTTPersistence] allFlowsforClientId %@", error);
        }
    }];
    for (id<MQTTFlow>row in rows) {
        [flows addObject:[[MQTTCoreDataFlow alloc] initWithContext:self.managedObjectContext andObject:row]];
    }
    return flows;
}

- (MQTTCoreDataFlow *)flowforClientId:(NSString *)clientId
                         incomingFlag:(BOOL)incomingFlag
                            messageId:(UInt16)messageId {
    __block MQTTCoreDataFlow *flow = nil;
    
    DDLogVerbose(@"flowforClientId requestingPerform");
    [self.managedObjectContext performBlockAndWait:^{
        DDLogVerbose(@"flowforClientId performing");

        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"MQTTFlow"];
        fetchRequest.predicate = [NSPredicate predicateWithFormat:
                                  @"clientId = %@ and incomingFlag = %@ and messageId = %@",
                                  clientId,
                                  @(incomingFlag),
                                  @(messageId)
                                  ];
        NSArray *rows;
        NSError *error = nil;
        rows = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        if (!rows) {
            DDLogError(@"[MQTTPersistence] flowForClientId %@", error);
        } else {
            if ([rows count]) {
                flow = [[MQTTCoreDataFlow alloc] initWithContext:self.managedObjectContext andObject:[rows lastObject]];
            }
        }
    }];
    DDLogVerbose(@"flowforClientId performed");
    return flow;
}

- (MQTTCoreDataFlow *)createFlowforClientId:(NSString *)clientId
                               incomingFlag:(BOOL)incomingFlag
                                  messageId:(UInt16)messageId {
    MQTTCoreDataFlow *flow = (MQTTCoreDataFlow *)[self flowforClientId:clientId
                                                          incomingFlag:incomingFlag
                                                             messageId:messageId];
    if (!flow) {
        __block id<MQTTFlow> row;
        [self.managedObjectContext performBlockAndWait:^{
            row = [NSEntityDescription insertNewObjectForEntityForName:@"MQTTFlow"
                                                inManagedObjectContext:self.managedObjectContext];
            
            row.clientId = clientId;
            row.incomingFlag = @(incomingFlag);
            row.messageId = @(messageId);
        }];
        flow = [[MQTTCoreDataFlow alloc] initWithContext:self.managedObjectContext andObject:row];
    }
    
    return flow;
}

#pragma mark - Core Data stack

- (NSManagedObjectContext *)managedObjectContext
{
    NSManagedObjectContext *managedObjectContext = [[NSThread currentThread].threadDictionary valueForKey:@"MQTTClient"];
    if (managedObjectContext != nil) {
        return managedObjectContext;
    }
    
    @synchronized (lock) {
        if (parentManagedObjectContext == nil) {
            NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
            if (coordinator != nil) {
                parentManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
                [parentManagedObjectContext setPersistentStoreCoordinator:coordinator];
            }
        }
        
        managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [managedObjectContext setParentContext:parentManagedObjectContext];
        [[NSThread currentThread].threadDictionary setObject:managedObjectContext forKey:@"MQTTClient"];
        
        return managedObjectContext;
    }
}

- (NSManagedObjectModel *)managedObjectModel
{
    @synchronized (lock) {
        if (managedObjectModel != nil) {
            return managedObjectModel;
        }
        
        managedObjectModel = [[NSManagedObjectModel alloc] init];
        NSMutableArray *entities = [[NSMutableArray alloc] init];
        NSMutableArray *properties = [[NSMutableArray alloc] init];
        
        NSAttributeDescription *attributeDescription;
        
        attributeDescription = [[NSAttributeDescription alloc] init];
        attributeDescription.name = @"clientId";
        attributeDescription.attributeType = NSStringAttributeType;
        attributeDescription.attributeValueClassName = @"NSString";
        [properties addObject:attributeDescription];
        
        attributeDescription = [[NSAttributeDescription alloc] init];
        attributeDescription.name = @"incomingFlag";
        attributeDescription.attributeType = NSBooleanAttributeType;
        attributeDescription.attributeValueClassName = @"NSNumber";
        [properties addObject:attributeDescription];
        
        attributeDescription = [[NSAttributeDescription alloc] init];
        attributeDescription.name = @"retainedFlag";
        attributeDescription.attributeType = NSBooleanAttributeType;
        attributeDescription.attributeValueClassName = @"NSNumber";
        [properties addObject:attributeDescription];
        
        attributeDescription = [[NSAttributeDescription alloc] init];
        attributeDescription.name = @"commandType";
        attributeDescription.attributeType = NSInteger16AttributeType;
        attributeDescription.attributeValueClassName = @"NSNumber";
        [properties addObject:attributeDescription];
        
        attributeDescription = [[NSAttributeDescription alloc] init];
        attributeDescription.name = @"qosLevel";
        attributeDescription.attributeType = NSInteger16AttributeType;
        attributeDescription.attributeValueClassName = @"NSNumber";
        [properties addObject:attributeDescription];
        
        attributeDescription = [[NSAttributeDescription alloc] init];
        attributeDescription.name = @"messageId";
        attributeDescription.attributeType = NSInteger32AttributeType;
        attributeDescription.attributeValueClassName = @"NSNumber";
        [properties addObject:attributeDescription];
        
        attributeDescription = [[NSAttributeDescription alloc] init];
        attributeDescription.name = @"topic";
        attributeDescription.attributeType = NSStringAttributeType;
        attributeDescription.attributeValueClassName = @"NSString";
        [properties addObject:attributeDescription];
        
        attributeDescription = [[NSAttributeDescription alloc] init];
        attributeDescription.name = @"data";
        attributeDescription.attributeType = NSBinaryDataAttributeType;
        attributeDescription.attributeValueClassName = @"NSData";
        [properties addObject:attributeDescription];
        
        attributeDescription = [[NSAttributeDescription alloc] init];
        attributeDescription.name = @"deadline";
        attributeDescription.attributeType = NSDateAttributeType;
        attributeDescription.attributeValueClassName = @"NSDate";
        [properties addObject:attributeDescription];
        
        NSEntityDescription *entityDescription = [[NSEntityDescription alloc] init];
        entityDescription.name = @"MQTTFlow";
        entityDescription.managedObjectClassName = @"MQTTFlow";
        entityDescription.abstract = FALSE;
        entityDescription.properties = properties;
        
        [entities addObject:entityDescription];
        [managedObjectModel setEntities:entities];
        
        return managedObjectModel;
    }
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    @synchronized (lock) {
        if (persistentStoreCoordinator != nil) {
            return persistentStoreCoordinator;
        }
        
        NSURL *persistentStoreURL = [[self applicationDocumentsDirectory]
                                     URLByAppendingPathComponent:@"MQTTClient"];
        DDLogInfo(@"[MQTTPersistence] Persistent store: %@", persistentStoreURL.path);
        
        
        NSError *error = nil;
        persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc]
                                      initWithManagedObjectModel:[self managedObjectModel]];
        NSDictionary *options = @{NSMigratePersistentStoresAutomaticallyOption: @YES,
                                  NSInferMappingModelAutomaticallyOption: @YES,
                                  NSSQLiteAnalyzeOption: @YES,
                                  NSSQLiteManualVacuumOption: @YES
                                  };
        
        if (![persistentStoreCoordinator addPersistentStoreWithType:self.persistent ? NSSQLiteStoreType : NSInMemoryStoreType
                                                      configuration:nil
                                                                URL:self.persistent ? persistentStoreURL : nil
                                                            options:options
                                                              error:&error]) {
            DDLogError(@"[MQTTPersistence] managedObjectContext save: %@", error);
            persistentStoreCoordinator = nil;
        }
        
        return persistentStoreCoordinator;
    }
}

#pragma mark - Application's Documents directory

- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (void)sizes {
    if (self.persistent) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *persistentStorePath = [documentsDirectory stringByAppendingPathComponent:@"MQTTClient"];
        
        NSError *error = nil;
        NSDictionary *fileAttributes = [[NSFileManager defaultManager]
                                        attributesOfItemAtPath:persistentStorePath error:&error];
        NSDictionary *fileSystemAttributes = [[NSFileManager defaultManager]
                                              attributesOfFileSystemForPath:persistentStorePath
                                              error:&error];
        fileSize = [[fileAttributes objectForKey:NSFileSize] unsignedLongLongValue];
        fileSystemFreeSize = [[fileSystemAttributes objectForKey:NSFileSystemFreeSize] unsignedLongLongValue];
    } else {
        fileSize = 0;
        fileSystemFreeSize = 0;
    }
    DDLogVerbose(@"[MQTTPersistence] sizes %llu/%llu", fileSize, fileSystemFreeSize);
}
@end
