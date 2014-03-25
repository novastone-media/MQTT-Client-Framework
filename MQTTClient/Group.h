//
//  Group.h
//  MQTTClient
//
//  Created by Christoph Krey on 23.03.14.
//  Copyright (c) 2014 Christoph Krey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class User, UserGroup;

@interface Group : NSManagedObject

@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) User *belongsTo;
@property (nonatomic, retain) NSSet *hasUsers;
@property (nonatomic, retain) User *isUser;
@end

@interface Group (CoreDataGeneratedAccessors)

- (void)addHasUsersObject:(UserGroup *)value;
- (void)removeHasUsersObject:(UserGroup *)value;
- (void)addHasUsers:(NSSet *)values;
- (void)removeHasUsers:(NSSet *)values;

@end
