//
//  MQTTCoreDataPersistence.m
//  MQTTClient
//
//  Created by Christoph Krey on 22.03.15.
//  Copyright © 2015-2016 Christoph Krey. All rights reserved.
//

#import "MQTTCoreDataPersistence.h"

#ifdef LUMBERJACK
#define LOG_LEVEL_DEF ddLogLevel
#import <CocoaLumberjack/CocoaLumberjack.h>
#ifdef DEBUG
static const DDLogLevel ddLogLevel = DDLogLevelWarning;
#else
static const DDLogLevel ddLogLevel = DDLogLevelWarning;
#endif
#else
#define DDLogVerbose NSLog
#define DDLogWarn NSLog
#define DDLogInfo NSLog
#define DDLogError NSLog
#endif

static NSRecursiveLock *lock;
static NSManagedObjectContext *parentManagedObjectContext;
static NSManagedObjectModel *managedObjectModel;
static NSPersistentStoreCoordinator *persistentStoreCoordinator;
static unsigned long long fileSize;
static unsigned long long fileSystemFreeSize;

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
    for (MQTTFlow *flow in flows) {
        if ([flow.commandType unsignedIntegerValue] != MQTT_None) {
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
                                 incomingFlag:(BOOL)incomingFlag
                                  commandType:(UInt8)commandType
                                     deadline:(NSDate *)deadline {
    if (([self allFlowsforClientId:clientId incomingFlag:incomingFlag].count <= self.maxMessages) &&
        (fileSize <= self.maxSize)) {
        MQTTFlow *flow = (MQTTFlow *)[self createFlowforClientId:clientId
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

- (void)deleteFlow:(MQTTFlow *)flow {
    [self.managedObjectContext performBlockAndWait:^{
        [self.managedObjectContext deleteObject:flow];
        [self sync];
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
    __block NSArray *flows = nil;
    [self.managedObjectContext performBlockAndWait:^{
        
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"MQTTFlow"];
        fetchRequest.predicate = [NSPredicate predicateWithFormat:
                                  @"clientId = %@ and incomingFlag = %@",
                                  clientId,
                                  @(incomingFlag)
                                  ];
        fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"deadline" ascending:YES]];
        NSError *error = nil;
        flows = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        if (!flows) {
            DDLogError(@"[MQTTPersistence] allFlowsforClientId %@", error);
        }
    }];
    return flows;
}

- (MQTTFlow *)flowforClientId:(NSString *)clientId
                         incomingFlag:(BOOL)incomingFlag
                            messageId:(UInt16)messageId {
    __block MQTTFlow *flow = nil;
    
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
        NSArray *flows;
        NSError *error = nil;
        flows = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        if (!flows) {
            DDLogError(@"[MQTTPersistence] flowForClientId %@", error);
        } else {
            if ([flows count]) {
                flow = [flows lastObject];
            }
        }
    }];
    DDLogVerbose(@"flowforClientId performed");
    return flow;
}

- (MQTTFlow *)createFlowforClientId:(NSString *)clientId
                               incomingFlag:(BOOL)incomingFlag
                                  messageId:(UInt16)messageId {
    __block MQTTFlow *flow = (MQTTFlow *)[self flowforClientId:clientId
                                                                  incomingFlag:incomingFlag
                                                                     messageId:messageId];
    if (!flow) {
        [self.managedObjectContext performBlockAndWait:^{
            flow = [NSEntityDescription insertNewObjectForEntityForName:@"MQTTFlow"
                                                 inManagedObjectContext:self.managedObjectContext];
            
            flow.clientId = clientId;
            flow.incomingFlag = @(incomingFlag);
            flow.messageId = @(messageId);
        }];
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
                                  NSSQLiteManualVacuumOption: @YES};
        
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
