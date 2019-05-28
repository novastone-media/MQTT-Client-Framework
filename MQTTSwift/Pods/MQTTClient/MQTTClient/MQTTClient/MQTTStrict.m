//
//  MQTTStrict.m
//  MQTTClient
//
//  Created by Christoph Krey on 24.07.17.
//  Copyright © 2017 Christoph Krey. All rights reserved.
//

#import "MQTTStrict.h"

@implementation MQTTStrict
static BOOL internalStrict = false;

+ (BOOL)strict {
    return internalStrict;
}

+ (void)setStrict:(BOOL)strict {
    internalStrict = strict;
}

@end
