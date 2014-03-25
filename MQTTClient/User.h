//
//  User.h
//  MQTTClient
//
//  Created by Christoph Krey on 23.03.14.
//  Copyright (c) 2014 Christoph Krey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Device, Group, Message, Myself, UserGroup;

@interface User : NSManagedObject

@property (nonatomic, retain) NSNumber * abRecordId;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSData * pubkey;
@property (nonatomic, retain) NSData * seckey;
@property (nonatomic, retain) NSData * sigkey;
@property (nonatomic, retain) NSData * verkey;
@property (nonatomic, retain) NSSet *hasDevices;
@property (nonatomic, retain) NSSet *hasGroups;
@property (nonatomic, retain) NSSet *hasMessages;
@property (nonatomic, retain) Group *isGroup;
@property (nonatomic, retain) Myself *me;
@property (nonatomic, retain) NSSet *ownsGroups;
@end

@interface User (CoreDataGeneratedAccessors)

- (void)addHasDevicesObject:(Device *)value;
- (void)removeHasDevicesObject:(Device *)value;
- (void)addHasDevices:(NSSet *)values;
- (void)removeHasDevices:(NSSet *)values;

- (void)addHasGroupsObject:(UserGroup *)value;
- (void)removeHasGroupsObject:(UserGroup *)value;
- (void)addHasGroups:(NSSet *)values;
- (void)removeHasGroups:(NSSet *)values;

- (void)addHasMessagesObject:(Message *)value;
- (void)removeHasMessagesObject:(Message *)value;
- (void)addHasMessages:(NSSet *)values;
- (void)removeHasMessages:(NSSet *)values;

- (void)addOwnsGroupsObject:(Group *)value;
- (void)removeOwnsGroupsObject:(Group *)value;
- (void)addOwnsGroups:(NSSet *)values;
- (void)removeOwnsGroups:(NSSet *)values;

@end
