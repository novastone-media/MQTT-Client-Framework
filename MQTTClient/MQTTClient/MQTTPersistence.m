//
//  MQTTPersistence.m
//  MQTTClient
//
//  Created by Christoph Krey on 22.03.15.
//  Copyright (c) 2015 Christoph Krey. All rights reserved.
//

#import "MQTTPersistence.h"

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

#ifdef DEBUG
#define DEBUGPERSIST FALSE
#else
#define DEBUGPERSIST FALSE
#endif

#define PERSISTENT NO
#define MAX_SIZE 64*1024*1024
#define MAX_WINDOW_SIZE 16
#define MAX_MESSAGES 1024


@interface MQTTPersistence()
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@end

static NSRecursiveLock *lock;
static NSManagedObjectContext *parentManagedObjectContext;
static NSManagedObjectModel *managedObjectModel;
static NSPersistentStoreCoordinator *persistentStoreCoordinator;
static unsigned long long fileSize;
static unsigned long long fileSystemFreeSize;

@implementation MQTTPersistence

- (MQTTPersistence *)init {
    self = [super init];
    self.persistent = PERSISTENT;
    self.maxSize = MAX_SIZE;
    self.maxMessages = MAX_MESSAGES;
    self.maxWindowSize = MAX_WINDOW_SIZE;
    if (!lock) {
        lock = [[NSRecursiveLock alloc] init];
    }
    return self;
}


- (NSUInteger)windowSize:(NSString *)clientId {
    NSUInteger windowSize = 0;
    NSArray *flows = [self allFlowsforClientId:clientId
                                  incomingFlag:NO];
    for (MQTTFlow *flow in flows) {
        if ([flow.commandType intValue] != 0) {
            windowSize++;
        }
    }
    return windowSize;
}

- (MQTTFlow *)storeMessageForClientId:(NSString *)clientId
                                topic:(NSString *)topic
                                 data:(NSData *)data
                           retainFlag:(BOOL)retainFlag
                                  qos:(MQTTQosLevel)qos
                                msgId:(UInt16)msgId
                         incomingFlag:(BOOL)incomingFlag {
    if (([self allFlowsforClientId:clientId incomingFlag:incomingFlag].count <= self.maxMessages) &&
        (fileSize <= self.maxSize)) {
        MQTTFlow *flow = [self createFlowforClientId:clientId
                                        incomingFlag:incomingFlag
                                           messageId:msgId];
        flow.topic = topic;
        flow.data = data;
        flow.retainedFlag = @(retainFlag);
        flow.qosLevel = @(qos);
        if ([self windowSize:clientId] > self.maxWindowSize) {
            flow.commandType = @(0);
        } else {
            flow.commandType = @(MQTTPublish);
        }
        flow.deadline = [NSDate dateWithTimeIntervalSinceNow:0];
        [self sync];
        return flow;
    } else {
        return nil;
    }
}

- (void)deleteFlow:(MQTTFlow *)flow {
    [self.managedObjectContext performBlockAndWait:^{
        [self.managedObjectContext deleteObject:flow];
    }];
}

- (void)deleteAllFlowsForClientId:(NSString *)clientId {
    [self.managedObjectContext performBlockAndWait:^{
        for (MQTTFlow *flow in [self allFlowsforClientId:clientId incomingFlag:TRUE]) {
            [self.managedObjectContext deleteObject:flow];
        }
        for (MQTTFlow *flow in [self allFlowsforClientId:clientId incomingFlag:FALSE]) {
            [self.managedObjectContext deleteObject:flow];
        }
        [self sync];
    }];
}

- (void)sync {
    [self.managedObjectContext performBlockAndWait:^{
        if (self.managedObjectContext.hasChanges) {
            if (DEBUGPERSIST) NSLog(@"sync: i%lu u%lu d%lu",
                                    (unsigned long)self.managedObjectContext.insertedObjects.count,
                                    (unsigned long)self.managedObjectContext.updatedObjects.count,
                                    (unsigned long)self.managedObjectContext.deletedObjects.count
                                    );
            NSError *error = nil;
            if (![self.managedObjectContext save:&error]) {
                if (DEBUGPERSIST) NSLog(@"sync %@", error);
            }
            [self sizes];
        }
    }];
}

- (NSArray *)allFlowsforClientId:(NSString *)clientId
                    incomingFlag:(BOOL)incomingFlag {
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"MQTTFlow"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:
                              @"clientId = %@ and incomingFlag = %@",
                              clientId,
                              @(incomingFlag)
                              ];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"deadline" ascending:YES]];
    __block NSArray *flows;
    [self.managedObjectContext performBlockAndWait:^{
        NSError *error = nil;
        flows = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        if (!flows) {
            if (DEBUGPERSIST) NSLog(@"allFlowsforClientId %@", error);
        }
    }];
    return flows;
}

- (MQTTFlow *)flowforClientId:(NSString *)clientId
                 incomingFlag:(BOOL)incomingFlag
                    messageId:(UInt16)messageId {
    MQTTFlow *flow = nil;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"MQTTFlow"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:
                              @"clientId = %@ and incomingFlag = %@ and messageId = %@",
                              clientId,
                              @(incomingFlag),
                              @(messageId)
                              ];
    __block NSArray *flows;
    __block NSError *error = nil;
    [self.managedObjectContext performBlockAndWait:^{
        flows = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    }];
    if (!flows) {
        if (DEBUGPERSIST) NSLog(@"flowForClientId %@", error);
    } else {
        if ([flows count]) {
            flow = [flows lastObject];
        }
    }
    return flow;
}

- (MQTTFlow *)createFlowforClientId:(NSString *)clientId
                       incomingFlag:(BOOL)incomingFlag
                          messageId:(UInt16)messageId {
    MQTTFlow *flow = [self flowforClientId:clientId incomingFlag:incomingFlag messageId:messageId];
    
    if (!flow) {
        flow = [NSEntityDescription insertNewObjectForEntityForName:@"MQTTFlow"
                                             inManagedObjectContext:self.managedObjectContext];
        
        flow.clientId = clientId;
        flow.incomingFlag = @(incomingFlag);
        flow.messageId = @(messageId);
        
    }
    return flow;
}

#pragma mark - Core Data stack

- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    @synchronized (lock) {
        if (parentManagedObjectContext == nil) {
            NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
            if (coordinator != nil) {
                parentManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
                [parentManagedObjectContext setPersistentStoreCoordinator:coordinator];
            }
        }
        
        _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [_managedObjectContext setParentContext:parentManagedObjectContext];
        
        return _managedObjectContext;
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
        if (DEBUGPERSIST) NSLog(@"Persistent store: %@", persistentStoreURL.path);
        
        
        NSError *error = nil;
        persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc]
                                      initWithManagedObjectModel:[self managedObjectModel]];
        NSDictionary *options = @{NSMigratePersistentStoresAutomaticallyOption: @YES,
                                  NSInferMappingModelAutomaticallyOption: @YES,
                                  NSSQLiteAnalyzeOption: @YES,
                                  NSSQLiteManualVacuumOption: @YES};
        
        if (![persistentStoreCoordinator addPersistentStoreWithType:self.persistent ? NSSQLiteStoreType : NSInMemoryStoreType
                                                      configuration:nil
                                                                URL:self.persistent ? persistentStoreURL : nil
                                                            options:options
                                                              error:&error]) {
            if (DEBUGPERSIST) NSLog(@"managedObjectContext save: %@", error);
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
    if (DEBUGPERSIST) NSLog(@"sizes %llu/%llu", fileSize, fileSystemFreeSize);
}
@end
