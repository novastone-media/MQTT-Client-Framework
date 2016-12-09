//
// MQTTSessionSynchron.m
// MQTTClient.framework
//
// Copyright © 2013-2016, Christoph Krey
//

/**
 Synchronous API
 
 @author Christoph Krey krey.christoph@gmail.com
 @see http://mqtt.org
 */

#import "MQTTSession.h"
#import "MQTTSessionLegacy.h"
#import "MQTTSessionSynchron.h"

#import "MQTTLog.h"

@interface MQTTSession()
@property (nonatomic) UInt16 synchronPubMid;
@property (nonatomic) UInt16 synchronUnsubMid;
@property (nonatomic) UInt16 synchronSubMid;

- (dispatch_semaphore_t)semaphorePub;
- (dispatch_semaphore_t)semaphoreSub;
- (dispatch_semaphore_t)semaphoreUnsub;
- (dispatch_semaphore_t)semaphoreConnect;
- (dispatch_semaphore_t)semaphoreDisconnect;

@end

@implementation MQTTSession(Synchron)

/** Synchron connect
 *
 */
- (BOOL)connectAndWaitTimeout:(NSTimeInterval)timeout {
    
    [self connect];
    
    dispatch_semaphore_wait(self.semaphoreConnect,
                            dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeout * NSEC_PER_SEC)));
    
    DDLogVerbose(@"[MQTTSessionSynchron] end connect");
    
    return (self.status == MQTTSessionStatusConnected);
}

/**
 * @deprecated
 */
 - (BOOL)connectAndWaitToHost:(NSString*)host port:(UInt32)port usingSSL:(BOOL)usingSSL {
    return [self connectAndWaitToHost:host port:port usingSSL:usingSSL timeout:0];
}

/**
 * @deprecated
 */
- (BOOL)connectAndWaitToHost:(NSString*)host port:(UInt32)port usingSSL:(BOOL)usingSSL timeout:(NSTimeInterval)timeout {
    
    [self connectToHost:host port:port usingSSL:usingSSL];
    
    dispatch_semaphore_wait(self.semaphoreConnect,
                            dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeout * NSEC_PER_SEC)));
    
    DDLogVerbose(@"[MQTTSessionSynchron] end connect");
    
    return (self.status == MQTTSessionStatusConnected);
}

- (BOOL)subscribeAndWaitToTopic:(NSString *)topic atLevel:(MQTTQosLevel)qosLevel {
    return [self subscribeAndWaitToTopic:topic atLevel:qosLevel timeout:0];
}

- (BOOL)subscribeAndWaitToTopic:(NSString *)topic atLevel:(MQTTQosLevel)qosLevel timeout:(NSTimeInterval)timeout {
    
    UInt16 mid = [self subscribeToTopic:topic atLevel:qosLevel];
    self.synchronSubMid = mid;
    
    dispatch_semaphore_wait(self.semaphoreSub,
                            dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeout * NSEC_PER_SEC)));
    
    DDLogVerbose(@"[MQTTSessionSynchron] end subscribe");
    
    if (self.synchronSubMid != mid) {
        return FALSE;
    } else {
        return TRUE;
    }
}

- (BOOL)subscribeAndWaitToTopics:(NSDictionary<NSString *, NSNumber *> *)topics {
    return [self subscribeAndWaitToTopics:topics timeout:0];
}

- (BOOL)subscribeAndWaitToTopics:(NSDictionary<NSString *, NSNumber *> *)topics timeout:(NSTimeInterval)timeout {
    
    UInt16 mid = [self subscribeToTopics:topics];
    self.synchronSubMid = mid;
    
    dispatch_semaphore_wait(self.semaphoreSub,
                            dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeout * NSEC_PER_SEC)));
    
    DDLogVerbose(@"[MQTTSessionSynchron] end subscribe");
    
    if (self.synchronSubMid != mid) {
        return FALSE;
    } else {
        return TRUE;
    }
}

- (BOOL)unsubscribeAndWaitTopic:(NSString *)theTopic {
    return [self unsubscribeAndWaitTopic:theTopic timeout:0];
}

- (BOOL)unsubscribeAndWaitTopic:(NSString *)theTopic timeout:(NSTimeInterval)timeout {
    
    UInt16 mid = [self unsubscribeTopic:theTopic];
    self.synchronUnsubMid = mid;
    
    dispatch_semaphore_wait(self.semaphoreUnsub,
                            dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeout * NSEC_PER_SEC)));
    
    DDLogVerbose(@"[MQTTSessionSynchron] end unsubscribe");
    
    if (self.synchronUnsubMid != mid) {
        return FALSE;
    } else {
        return TRUE;
    }
}

- (BOOL)unsubscribeAndWaitTopics:(NSArray<NSString *> *)topics {
    return [self unsubscribeAndWaitTopics:topics timeout:0];
}

- (BOOL)unsubscribeAndWaitTopics:(NSArray<NSString *> *)topics timeout:(NSTimeInterval)timeout {
    
    UInt16 mid = [self unsubscribeTopics:topics];
    self.synchronUnsubMid = mid;
    
    dispatch_semaphore_wait(self.semaphoreUnsub,
                            dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeout * NSEC_PER_SEC)));
    
    DDLogVerbose(@"[MQTTSessionSynchron] end unsubscribe");
    
    if (self.synchronUnsubMid != mid) {
        return FALSE;
    } else {
        return TRUE;
    }
}

- (BOOL)publishAndWaitData:(NSData*)data
                   onTopic:(NSString*)topic
                    retain:(BOOL)retainFlag
                       qos:(MQTTQosLevel)qos {
    return [self publishAndWaitData:data onTopic:topic retain:retainFlag qos:qos timeout:0];
}

- (BOOL)publishAndWaitData:(NSData*)data
                   onTopic:(NSString*)topic
                    retain:(BOOL)retainFlag
                       qos:(MQTTQosLevel)qos
                   timeout:(NSTimeInterval)timeout {
    
    UInt16 mid = self.synchronPubMid = [self publishData:data onTopic:topic retain:retainFlag qos:qos];
    if (qos == MQTTQosLevelAtMostOnce) {
        return TRUE;
    } else {
        
        dispatch_semaphore_wait(self.semaphorePub,
                                dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeout * NSEC_PER_SEC)));
        
        DDLogVerbose(@"[MQTTSessionSynchron] end publish");
        
        if (self.synchronPubMid != mid) {
            return FALSE;
        } else {
            return TRUE;
        }
    }
}

- (void)closeAndWait {
    [self closeAndWait:0];
}

- (void)closeAndWait:(NSTimeInterval)timeout {
    
    [self close];
    
    dispatch_semaphore_wait(self.semaphoreDisconnect,
                            dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeout * NSEC_PER_SEC)));
    
    DDLogVerbose(@"[MQTTSessionSynchron] end close");
}

@end
