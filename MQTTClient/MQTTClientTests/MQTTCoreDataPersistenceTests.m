//
//  MQTTCoreDataPersistenceTests.m
//  MQTTClientiOSTests
//
//  Created by Josip Cavar on 24/04/2018.
//  Copyright © 2018 Christoph Krey. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <MQTTClient/MQTTCoreDataPersistence.h>

@interface MQTTCoreDataPersistenceTests : XCTestCase

@end

@implementation MQTTCoreDataPersistenceTests

- (void)setUp {
    [super setUp];
    // Create Documents directory if it doesn't exist
    NSError *error = nil;
    [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory
                                           inDomain:NSUserDomainMask
                                  appropriateForURL:nil
                                             create:YES
                                              error:&error];
    XCTAssertNil(error);
}

- (void)testSQLiteStoreTypeWhenPersistenceYES {
    MQTTCoreDataPersistence *persistence = [[MQTTCoreDataPersistence alloc] init];
    persistence.persistent = YES;
    NSManagedObjectContext *context = [persistence valueForKey:@"managedObjectContext"];
    NSPersistentStore *store = context.persistentStoreCoordinator.persistentStores.firstObject;
    XCTAssertEqual(store.type, NSSQLiteStoreType);
}

- (void)testInMemoryStoreTypeWhenPersistenceNO {
    MQTTCoreDataPersistence *persistence = [[MQTTCoreDataPersistence alloc] init];
    persistence.persistent = NO;
    NSManagedObjectContext *context = [persistence valueForKey:@"managedObjectContext"];
    NSPersistentStore *store = context.persistentStoreCoordinator.persistentStores.firstObject;
    XCTAssertEqual(store.type, NSInMemoryStoreType);
}

@end
