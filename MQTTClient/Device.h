//
//  Device.h
//  MQTTClient
//
//  Created by Christoph Krey on 23.03.14.
//  Copyright (c) 2014 Christoph Krey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class User;

@interface Device : NSManagedObject

@property (nonatomic, retain) NSData * deviceToken;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSNumber * online;
@property (nonatomic, retain) User *belongsTo;

@end
