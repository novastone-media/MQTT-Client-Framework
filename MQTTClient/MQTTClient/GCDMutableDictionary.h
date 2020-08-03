//
//  GCDMutableDictionary.h
//  MQTTClient.framework
//
//  Copyright © 2020 Christoph Krey. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface GCDMutableDictionary<__covariant KeyType, __covariant ObjectType> : NSObject

@property (readonly, copy) NSArray<ObjectType> *allValues;

- (nullable ObjectType)objectForKey:(KeyType)aKey;
- (nullable ObjectType)objectForKeyedSubscript:(KeyType)key;

- (void)setObject:(ObjectType)anObject forKey:(KeyType <NSCopying>)aKey;
- (void)setObject:(nullable ObjectType)obj forKeyedSubscript:(KeyType <NSCopying>)key;

- (void)removeAllObjects;
- (void)removeObjectForKey:(KeyType)aKey;

@end

NS_ASSUME_NONNULL_END
