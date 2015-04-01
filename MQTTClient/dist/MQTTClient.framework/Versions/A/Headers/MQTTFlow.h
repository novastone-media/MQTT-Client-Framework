//
//  MQTTFlow.h
//  MQTTClient
//
//  Created by Christoph Krey on 20.03.15.
//  Copyright (c) 2015 Christoph Krey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface MQTTFlow : NSManagedObject

@property (nonatomic, retain) NSData * data;
@property (nonatomic, retain) NSString * topic;
@property (nonatomic, retain) NSNumber * mid;
@property (nonatomic, retain) NSNumber * qos;
@property (nonatomic, retain) NSNumber * retainedFlag;
@property (nonatomic, retain) NSNumber * incoming;
@property (nonatomic, retain) NSDate * deadline;
@property (nonatomic, retain) NSString * clientid;
@property (nonatomic, retain) NSNumber * type;

@end
