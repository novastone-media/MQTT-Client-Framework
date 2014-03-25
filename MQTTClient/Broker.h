//
//  Broker.h
//  MQTTClient
//
//  Created by Christoph Krey on 23.03.14.
//  Copyright (c) 2014 Christoph Krey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Broker : NSManagedObject

@property (nonatomic, retain) NSNumber * auth;
@property (nonatomic, retain) NSString * host;
@property (nonatomic, retain) NSString * passwd;
@property (nonatomic, retain) NSNumber * port;
@property (nonatomic, retain) NSNumber * tls;
@property (nonatomic, retain) NSString * user;

@end
