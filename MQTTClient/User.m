//
//  User.m
//  MQTTClient
//
//  Created by Christoph Krey on 23.03.14.
//  Copyright (c) 2014 Christoph Krey. All rights reserved.
//

#import "User.h"
#import "Device.h"
#import "Group.h"
#import "Message.h"
#import "Myself.h"
#import "UserGroup.h"


@implementation User

@dynamic abRecordId;
@dynamic identifier;
@dynamic pubkey;
@dynamic seckey;
@dynamic sigkey;
@dynamic verkey;
@dynamic hasDevices;
@dynamic hasGroups;
@dynamic hasMessages;
@dynamic isGroup;
@dynamic me;
@dynamic ownsGroups;

@end
