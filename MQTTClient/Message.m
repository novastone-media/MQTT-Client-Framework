//
//  Message.m
//  MQTTClient
//
//  Created by Christoph Krey on 23.03.14.
//  Copyright (c) 2014 Christoph Krey. All rights reserved.
//

#import "Message.h"
#import "User.h"


@implementation Message

@dynamic acknowledged;
@dynamic content;
@dynamic contenttype;
@dynamic delivered;
@dynamic msgid;
@dynamic outgoing;
@dynamic seen;
@dynamic timestamp;
@dynamic belongsTo;

@end
