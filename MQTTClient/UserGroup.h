//
//  UserGroup.h
//  MQTTClient
//
//  Created by Christoph Krey on 23.03.14.
//  Copyright (c) 2014 Christoph Krey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Group, User;

@interface UserGroup : NSManagedObject

@property (nonatomic, retain) NSNumber * confirmed;
@property (nonatomic, retain) Group *group;
@property (nonatomic, retain) User *user;

@end
