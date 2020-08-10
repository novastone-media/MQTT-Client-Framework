//
//  GCDMutableDictionary.m
//  MQTTClient.framework
//
//  Copyright © 2020 Christoph Krey. All rights reserved.
//

#import "GCDMutableDictionary.h"

@interface GCDMutableDictionary<KeyType, ObjectType> ()

@property (nonatomic, strong) dispatch_queue_t accessQueue;
@property (nonatomic, strong) NSMutableDictionary<KeyType, ObjectType> *storage;

@end

@implementation GCDMutableDictionary

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSString *label = [NSString stringWithFormat:@"<%@: %p>", NSStringFromClass([self class]), self];
        self.accessQueue = dispatch_queue_create([label cStringUsingEncoding:NSUTF8StringEncoding], DISPATCH_QUEUE_CONCURRENT);
        self.storage = [NSMutableDictionary new];
    }
    return self;
}

- (NSArray *)allValues
{
    __block NSArray *obj;
    dispatch_sync(self.accessQueue, ^{
        obj = self.storage.allValues;
    });
    return obj;
}

- (id)objectForKey:(id)aKey
{
    __block id obj;
    dispatch_sync(self.accessQueue, ^{
        obj = [self.storage objectForKey:aKey];
    });
    return obj;
}

- (id)objectForKeyedSubscript:(id)key
{
    __block id obj;
    dispatch_sync(self.accessQueue, ^{
        obj = [self.storage objectForKeyedSubscript:key];
    });
    return obj;
}

- (void)setObject:(id)anObject forKey:(id<NSCopying>)aKey
{
    dispatch_barrier_async(self.accessQueue, ^{
        [self.storage setObject:anObject forKey:aKey];
    });
}

- (void)setObject:(id)obj forKeyedSubscript:(id<NSCopying>)key
{
    dispatch_barrier_async(self.accessQueue, ^{
        [self.storage setObject:obj forKeyedSubscript:key];
    });
}

- (void)removeAllObjects
{
    dispatch_barrier_async(self.accessQueue, ^{
        [self.storage removeAllObjects];
    });
}

- (void)removeObjectForKey:(id)aKey
{
    dispatch_barrier_async(self.accessQueue, ^{
        [self.storage removeObjectForKey:aKey];
    });
}

@end
