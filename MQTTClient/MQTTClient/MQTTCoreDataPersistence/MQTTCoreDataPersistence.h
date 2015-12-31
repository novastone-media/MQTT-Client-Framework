//
//  MQTTCoreDataPersistence.h
//  MQTTClient
//
//  Created by Christoph Krey on 22.03.15.
//  Copyright (c) 2015 Christoph Krey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MQTTPersistence.h"

@interface MQTTCoreDataPersistence : NSObject <MQTTPersistence>

@end

@interface MQTTCoreDataFlow : NSManagedObject <MQTTFlow>
@end
