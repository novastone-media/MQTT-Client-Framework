//
//  FlowTests.m
//  MQTTClient
//
//  Created by Christoph Krey on 08.07.14.
//  Copyright © 2014-2017 Christoph Krey. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "MQTTLog.h"
#import "MQTTTestHelpers.h"

@interface ATest : NSObject <MQTTSessionDelegate>

@property (nonatomic) NSInteger maxMessages;
@property (nonatomic) NSInteger processingBuffer;
@property (nonatomic) NSTimeInterval processingTime;

@property (strong, nonatomic) MQTTSession *session;
@property (nonatomic) NSInteger publishedCounter;
@property (nonatomic) NSInteger deliveredCounter;
@property (nonatomic) NSInteger receivedCounter;
@property (nonatomic) NSInteger processedCounter;
@property (strong, nonatomic) NSTimer *processingSimulationTimer;
@property (strong, nonatomic) NSError *error;
@property (strong, nonatomic) NSDictionary *parameters;
@property (nonatomic) BOOL connected;
@property (nonatomic) BOOL closed;
@property (nonatomic) BOOL subscribed;

@end

#define COUNT 100

@implementation ATest

- (id)setup:(NSDictionary *)parameters
{
    self.parameters = parameters;
    
    self.session = [MQTTTestHelpers session:parameters];    
    self.session.delegate = self;
    
    self.publishedCounter = 0;
    self.deliveredCounter = 0;
    self.receivedCounter = 0;
    self.processedCounter = 0;
    
    return self;
}

- (void)start:(NSInteger)processingBuffer processingTime:(NSTimeInterval)processingTime maxMessages:(NSInteger)maxMessages{
    self.processingBuffer = processingBuffer;
    self.processingTime = processingTime;
    self.maxMessages = maxMessages;
    self.session.persistence.maxMessages = maxMessages;
    
    if (self.processingTime > 0) {
        self.processingSimulationTimer = [NSTimer scheduledTimerWithTimeInterval:self.processingTime
                                                                          target:self
                                                                        selector:@selector(processingSimulation:)
                                                                        userInfo:nil
                                                                         repeats:true];
    }
    [self connect];
}

- (void)connect {
    [self.session connect];
    DDLogVerbose(@"%@ connecting", self.session.clientId);
}

- (void)sub:(MQTTQosLevel)qos {
    [self.session subscribeToTopic:@"MQTTClient/#" atLevel:qos];
}

- (void)pub:(MQTTQosLevel)qos count:(NSInteger)count {
    NSString *message = [NSString stringWithFormat:@"data %5ld", (long)count];
    UInt16 msgID = [self.session publishData:[message dataUsingEncoding:NSUTF8StringEncoding] onTopic:@"MQTTClient" retain:NO qos:qos];
    if (qos == MQTTQosLevelAtMostOnce || msgID > 0) {
        self.publishedCounter++;
        DDLogVerbose(@"published(%ld): msgID:%d", (long)self.publishedCounter, msgID);
    }
    if (qos == MQTTQosLevelAtMostOnce) {
        self.deliveredCounter++;
    }
}

- (void)close {
    [self.session closeWithReturnCode:MQTTSuccess
                sessionExpiryInterval:nil
                         reasonString:nil
                         userProperty:nil
                    disconnectHandler:nil];
}

- (void)stop {
    [self.processingSimulationTimer invalidate];
    self.session.delegate = nil;
    self.session = nil;
}

- (void)connected:(MQTTSession *)session sessionPresent:(BOOL)sessionPresent {
    self.connected = true;
}

- (void)subAckReceived:(MQTTSession *)session msgID:(UInt16)msgID grantedQoss:(NSArray *)qoss {
    self.subscribed = true;
}

- (void)messageDelivered:(MQTTSession *)session msgID:(UInt16)msgID {
    self.deliveredCounter++;
    DDLogInfo(@"messageDelivered(%ld): msgID:%d", (long)self.deliveredCounter, msgID);
}

- (BOOL)newMessageWithFeedback:(MQTTSession *)session data:(NSData *)data onTopic:(NSString *)topic qos:(MQTTQosLevel)qos retained:(BOOL)retained mid:(unsigned int)mid {
    NSString *message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    if (self.processedCounter > self.receivedCounter - self.processingBuffer) {
        DDLogInfo(@"newMessageWithFeedback(%ld/%ld/%ld) accepted:%@ onTopic:%@ qos:%d retained:%d mid:%d",
                  (long)self.processedCounter,
                  (long)self.receivedCounter,
                  (long)self.processingBuffer,
                  message, topic, qos, retained, mid);
        self.receivedCounter++;
        return true;
    } else {
        DDLogInfo(@"newMessageWithFeedback(%ld/%ld/%ld) rejected:%@ onTopic:%@ qos:%d retained:%d mid:%d",
                  (long)self.processedCounter,
                  (long)self.receivedCounter,
                  (long)self.processingBuffer,
                  message, topic, qos, retained, mid);
        return false;
    }
}

- (void)handleEvent:(MQTTSession *)session event:(MQTTSessionEvent)eventCode error:(NSError *)error {
    DDLogVerbose(@"handleEvent:%ld error:%@", (long)eventCode, error);
    if (eventCode == MQTTSessionEventConnectionClosed || eventCode == MQTTSessionEventConnectionClosedByBroker) {
        self.closed = true;
    }
    self.error = error;
}

- (void)processingSimulation:(NSTimer *)timer {
    if (self.receivedCounter > self.processedCounter) {
        self.processedCounter++;
        DDLogInfo(@"processed %ld/%ld", (long)self.processedCounter, (long)self.receivedCounter);
    }
}



@end

@interface MQTTTestFlows : MQTTTestHelpers

@property (nonatomic) BOOL subscriberReady;
@property (strong, nonatomic) NSDictionary *parameters;

@property (nonatomic) MQTTQosLevel subscriberQos;
@property (nonatomic) NSInteger subscriberWindow;
@property (nonatomic) MQTTQosLevel publisherQos;
@property (nonatomic) NSInteger publisherWindow;
@property (nonatomic) MQTTQosLevel secondPublisherQos;
@property (nonatomic) NSInteger secondPublisherWindow;
@property (nonatomic) NSInteger count;
@property (nonatomic) NSInteger processingBuffer;
@property (nonatomic) NSTimeInterval processingTime;
@property (nonatomic) NSTimeInterval timeout;

@end

@implementation MQTTTestFlows

- (void)SLOWtestFlow0 {
    [self testAnyFlow:COUNT
        subscriberQos:MQTTQosLevelAtMostOnce
         publisherQos:MQTTQosLevelAtMostOnce
   secondPublisherQos:MQTTQosLevelAtMostOnce
     subscriberWindow:32
      publisherWindow:32
secondPublisherWindow:32
     processingBuffer:2000
       processingTime:0.001
              timeout:300];
}

- (void)testFlow1 {
    [self testAnyFlow:COUNT
        subscriberQos:MQTTQosLevelAtLeastOnce
         publisherQos:MQTTQosLevelAtLeastOnce
   secondPublisherQos:MQTTQosLevelAtLeastOnce
     subscriberWindow:512
      publisherWindow:512
secondPublisherWindow:512
     processingBuffer:512
       processingTime:0.01
              timeout:300];
}

- (void)SLOWtestFlow2 {
    [self testAnyFlow:COUNT
        subscriberQos:MQTTQosLevelExactlyOnce
         publisherQos:MQTTQosLevelExactlyOnce
   secondPublisherQos:MQTTQosLevelExactlyOnce
     subscriberWindow:32
      publisherWindow:32
secondPublisherWindow:32
     processingBuffer:128
       processingTime:0.1
              timeout:300];
}

- (void)testFlowFastSubscriber {
    [self testAnyFlow:COUNT
        subscriberQos:MQTTQosLevelExactlyOnce
         publisherQos:MQTTQosLevelExactlyOnce
   secondPublisherQos:MQTTQosLevelExactlyOnce
     subscriberWindow:512
      publisherWindow:128
secondPublisherWindow:64
     processingBuffer:1000
       processingTime:0.001
              timeout:120];
    
}

- (void)SLOWtestFlowUnreliableSubscriber {
    [self testAnyFlow:COUNT
        subscriberQos:MQTTQosLevelExactlyOnce
         publisherQos:MQTTQosLevelExactlyOnce
   secondPublisherQos:MQTTQosLevelExactlyOnce
     subscriberWindow:32
      publisherWindow:32
secondPublisherWindow:32
     processingBuffer:256
       processingTime:0.1
              timeout:500];
}

- (void)SLOWtestFlowUnreliableSubscriberQos1and2 {
    [self testAnyFlow:COUNT
        subscriberQos:MQTTQosLevelExactlyOnce
         publisherQos:MQTTQosLevelExactlyOnce
   secondPublisherQos:MQTTQosLevelAtLeastOnce
     subscriberWindow:32
      publisherWindow:32
secondPublisherWindow:32
     processingBuffer:256
       processingTime:0.1
              timeout:500];
}

- (void)SLOWtestFlowSlowSubscriberQos1and2 {
    [self testAnyFlow:COUNT
        subscriberQos:MQTTQosLevelExactlyOnce
         publisherQos:MQTTQosLevelExactlyOnce
   secondPublisherQos:MQTTQosLevelAtLeastOnce
     subscriberWindow:1000
      publisherWindow:2000
secondPublisherWindow:2000
     processingBuffer:1
       processingTime:0.001
              timeout:600];
}


- (void)testFlowSharedSession0 {
    [self testAnyFlowSharedSession:COUNT
                     subscriberQos:MQTTQosLevelAtMostOnce
                      publisherQos:MQTTQosLevelAtMostOnce
                secondPublisherQos:MQTTQosLevelAtMostOnce
                            window:20
                  processingBuffer:1000
                    processingTime:0.001
                           timeout:600];
}

- (void)testFlowSharedSession1 {
    [self testAnyFlowSharedSession:COUNT
                     subscriberQos:MQTTQosLevelAtLeastOnce
                      publisherQos:MQTTQosLevelAtLeastOnce
                secondPublisherQos:MQTTQosLevelAtLeastOnce
                            window:1000
                  processingBuffer:1000
                    processingTime:0.001
                           timeout:600];
}

- (void)testFlowSharedSession1small {
    [self testAnyFlowSharedSession:COUNT
                     subscriberQos:MQTTQosLevelAtLeastOnce
                      publisherQos:MQTTQosLevelAtLeastOnce
                secondPublisherQos:MQTTQosLevelAtLeastOnce
                            window:20
                  processingBuffer:1000
                    processingTime:0.001
                           timeout:600];
}

- (void)SLOWtestFlowSharedSession2 {
    [self testAnyFlowSharedSession:COUNT
                     subscriberQos:MQTTQosLevelExactlyOnce
                      publisherQos:MQTTQosLevelExactlyOnce
                secondPublisherQos:MQTTQosLevelExactlyOnce
                            window:20
                  processingBuffer:1000
                    processingTime:0.001
                           timeout:600];
}

- (void)SLOWtestFlowSharedSession12 {
    [self testAnyFlowSharedSession:COUNT
                     subscriberQos:MQTTQosLevelAtLeastOnce
                      publisherQos:MQTTQosLevelExactlyOnce
                secondPublisherQos:MQTTQosLevelAtLeastOnce
                            window:NSIntegerMax
                  processingBuffer:1000
                    processingTime:0.001
                           timeout:600];
}


- (void)testAnyFlow:(NSInteger)count
      subscriberQos:(MQTTQosLevel)subscriberQos
       publisherQos:(MQTTQosLevel)publisherQos
 secondPublisherQos:(MQTTQosLevel)secondPublisherQos
   subscriberWindow:(NSInteger)subscriberWindow
    publisherWindow:(NSInteger)publisherWindow
secondPublisherWindow:(NSInteger)secondPublisherWindow
   processingBuffer:(NSInteger)processingBuffer
     processingTime:(NSTimeInterval)processingTime
            timeout:(NSTimeInterval)timeout {
    
    
    self.subscriberQos = subscriberQos;
    self.publisherQos = publisherQos;
    self.secondPublisherQos = secondPublisherQos;
    self.subscriberWindow = subscriberWindow;
    self.publisherWindow = publisherWindow;
    self.secondPublisherWindow = secondPublisherWindow;
    self.count = count;
    self.processingBuffer = processingBuffer;
    self.processingTime = processingTime;
    self.timeout = timeout;
    
    self.parameters = MQTTTestHelpers.broker;
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    self.timedout = FALSE;
    [self performSelector:@selector(timedout:) withObject:nil afterDelay:self.timeout];
    
    NSThread *subscriberThread = [[NSThread alloc] initWithTarget:self
                                                         selector:@selector(runSubscriber:) object:self.parameters];
    NSThread *publisherThread  = [[NSThread alloc] initWithTarget:self
                                                         selector:@selector(runPublisher:)
                                  
                                                           object:self.parameters];
    NSThread *secondPublisherThread  = [[NSThread alloc] initWithTarget:self
                                                               selector:@selector(runSecondPublisher:)
                                                                 object:self.parameters];
    
    [subscriberThread start];
    while (!self.subscriberReady)  {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    
    [publisherThread start];
    [secondPublisherThread start];
    
    while ((publisherThread.isExecuting || secondPublisherThread.isExecuting || subscriberThread.isExecuting) && !self.timedout) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    
    [secondPublisherThread cancel];
    [publisherThread cancel];
    [subscriberThread cancel];
    
    XCTAssert(!self.timedout, @"timedout");
}

- (void)testAnyFlowSharedSession:(NSInteger)count
                   subscriberQos:(MQTTQosLevel)subscriberQos
                    publisherQos:(MQTTQosLevel)publisherQos
              secondPublisherQos:(MQTTQosLevel)secondPublisherQos
                          window:(NSInteger)window
                processingBuffer:(NSInteger)processingBuffer
                  processingTime:(NSTimeInterval)processingTime
                         timeout:(NSTimeInterval)timeout {
        
    self.subscriberQos = subscriberQos;
    self.publisherQos = publisherQos;
    self.secondPublisherQos = secondPublisherQos;
    self.subscriberWindow = window;
    self.publisherWindow = window;
    self.secondPublisherWindow = window;
    self.count = count;
    self.processingBuffer = processingBuffer;
    self.processingTime = processingTime;
    self.timeout = timeout;
    
    self.parameters = MQTTTestHelpers.broker;
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    self.timedout = FALSE;
    [self performSelector:@selector(timedout:) withObject:nil afterDelay:self.timeout];
    
    ATest *test = [[ATest alloc] init];
    NSThread *subscriberThread = [[NSThread alloc] initWithTarget:self
                                                         selector:@selector(runSharedSubscriber:)
                                                           object:test];
    NSThread *publisherThread  = [[NSThread alloc] initWithTarget:self
                                                         selector:@selector(runSharedPublisher:)
                                                           object:test];
    NSThread *secondPublisherThread  = [[NSThread alloc] initWithTarget:self
                                                               selector:@selector(runSharedSecondPublisher:)
                                                                 object:test];
    
    [subscriberThread start];
    while (!self.subscriberReady)  {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    
    [publisherThread start];
    [secondPublisherThread start];
    
    while ((publisherThread.isExecuting || secondPublisherThread.isExecuting || subscriberThread.isExecuting) && !self.timedout) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    
    [secondPublisherThread cancel];
    [publisherThread cancel];
    [subscriberThread cancel];
    
    XCTAssert(!self.timedout, @"timedout");
    [test stop];
    
}

- (void)runSubscriber:(NSDictionary *)parameters {
    ATest *test = [[ATest alloc] init];
    [test setup:parameters];
    test.session.clientId = @"MQTTClientS";
    
    [test start:self.processingBuffer processingTime:self.processingTime maxMessages:self.subscriberWindow];
    
    while (!test.connected) {
        DDLogVerbose(@"waiting for connection");
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    
    if (test.session.status == MQTTSessionStatusConnected) {
        
        [test sub:self.subscriberQos];
        while (!test.subscribed) {
            DDLogVerbose(@"%@ waiting for suback", test.session.clientId);
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }
        
        self.subscriberReady = true;
        test.session.cleanSessionFlag = false;
        
        while (test.processedCounter < self.count * 2)  {
            DDLogInfo(@"waiting for processing (%ld)", (long)test.processedCounter);
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }
        
        [test close];
        
        while (!test.closed) {
            DDLogVerbose(@"%@ waiting for close", test.session.clientId);
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }
    }
    
    [test stop];
}

- (void)runPublisher:(NSDictionary *)parameters
{
    ATest *test = [[ATest alloc] init];
    [test setup:parameters];
    test.session.clientId = @"MQTTClientP1";
    
    [test start:0 processingTime:0 maxMessages:self.publisherWindow];
    
    while (!test.connected) {
        DDLogVerbose(@"waiting for connection");
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    
    if (test.session.status == MQTTSessionStatusConnected) {
        test.session.cleanSessionFlag = false;
        
        while (test.publishedCounter < self.count)  {
            [test pub:self.publisherQos count:test.publishedCounter + 100000];
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.0001]];
        }
        
        while (test.deliveredCounter < self.count)  {
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.0001]];
        }
        
        [test close];
        
        while (!test.closed) {
            DDLogVerbose(@"%@ waiting for close", test.session.clientId);
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }
    }
    
    [test stop];
}

- (void)runSecondPublisher:(NSDictionary *)parameters
{
    ATest *test = [[ATest alloc] init];
    [test setup:parameters];
    test.session.clientId = @"MQTTClientP2";
    
    [test start:0 processingTime:0 maxMessages:self.secondPublisherWindow];
    
    while (!test.connected) {
        DDLogVerbose(@"waiting for connection");
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    
    if (test.session.status == MQTTSessionStatusConnected) {
        test.session.cleanSessionFlag = false;
        
        while (test.publishedCounter < self.count)  {
            [test pub:self.secondPublisherQos count:test.publishedCounter + 200000];
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.0001]];
        }
        
        while (test.deliveredCounter < self.count)  {
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.0001]];
        }
        
        [test close];
        
        while (!test.closed) {
            DDLogVerbose(@"%@ waiting for close", test.session.clientId);
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }
    }
    
    [test stop];
}

- (void)runSharedSubscriber:(ATest *)test {
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:1
                                                      target:self
                                                    selector:@selector(ticker:)
                                                    userInfo:@"runSharedSubscriber"
                                                     repeats:true];
    
    [test setup:self.parameters];
    test.session.clientId = @"MQTTClientShared";
    
    [test start:self.processingBuffer processingTime:self.processingTime maxMessages:self.subscriberWindow];
    
    while (!test.connected) {
        DDLogVerbose(@"waiting for connection");
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    
    if (test.session.status == MQTTSessionStatusConnected) {
        
        [test sub:self.subscriberQos];
        while (!test.subscribed) {
            DDLogVerbose(@"%@ waiting for suback", test.session.clientId);
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }
        
        self.subscriberReady = true;
        test.session.cleanSessionFlag = false;
        
        while (test.processedCounter < self.count)  {
            DDLogInfo(@"waiting for processing (%ld)", (long)test.processedCounter);
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }
    }
    [timer invalidate];
}

- (void)runSharedPublisher:(ATest *)test {
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:1
                                                      target:self
                                                    selector:@selector(ticker:)
                                                    userInfo:@"runSharedPublisher"
                                                     repeats:true];
    
    
    if (test.session.status == MQTTSessionStatusConnected) {
        
        while (test.publishedCounter < self.count)  {
            @synchronized(test.session) {
                if (test.publishedCounter < self.count) {
                    [test pub:self.publisherQos count:test.publishedCounter + 100000];
                }
            }
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
        }
        
        while (test.deliveredCounter < self.count)  {
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }
    }
    [timer invalidate];
}

- (void)runSharedSecondPublisher:(ATest *)test {
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:1
                                                      target:self
                                                    selector:@selector(ticker:)
                                                    userInfo:@"runSharedSecondPublisher"
                                                     repeats:true];
    
    if (test.session.status == MQTTSessionStatusConnected) {
        
        
        while (test.publishedCounter < self.count)  {
            @synchronized(test.session) {
                if (test.publishedCounter < self.count) {
                    [test pub:self.secondPublisherQos count:test.publishedCounter + 200000];
                }
            }
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
        }
        
        while (test.deliveredCounter < self.count)  {
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }
    }
    [timer invalidate];
}


- (void)ticker:(NSTimer *)timer {
    DDLogVerbose(@"ticker %@", timer.userInfo);
}


@end
