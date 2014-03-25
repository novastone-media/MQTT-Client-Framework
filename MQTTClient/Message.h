//
//  Message.h
//  MQTTClient
//
//  Created by Christoph Krey on 23.03.14.
//  Copyright (c) 2014 Christoph Krey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class User;

@interface Message : NSManagedObject

@property (nonatomic, retain) NSNumber * acknowledged;
@property (nonatomic, retain) NSData * content;
@property (nonatomic, retain) NSString * contenttype;
@property (nonatomic, retain) NSNumber * delivered;
@property (nonatomic, retain) NSNumber * msgid;
@property (nonatomic, retain) NSNumber * outgoing;
@property (nonatomic, retain) NSNumber * seen;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) User *belongsTo;

@end
