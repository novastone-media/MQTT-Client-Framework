//
//  Myself.h
//  MQTTClient
//
//  Created by Christoph Krey on 23.03.14.
//  Copyright (c) 2014 Christoph Krey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class User;

@interface Myself : NSManagedObject

@property (nonatomic, retain) User *myUser;

@end
