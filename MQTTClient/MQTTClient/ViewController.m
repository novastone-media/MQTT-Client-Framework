//
//  ViewController.m
//  MQTTClient
//
//  Created by Christoph Krey on 07.08.16.
//  Copyright © 2016 Christoph Krey. All rights reserved.
//

#import "ViewController.h"
#import "MQTTClient.h"

@interface ViewController () <MQTTSessionDelegate>
@property (weak, nonatomic) IBOutlet UILabel *label;

@property (strong, nonatomic) NSMutableArray <MQTTSession *> *sessions;
@property (strong, nonatomic) NSTimer *delayTimer;
@property (nonatomic) unsigned long received;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.sessions = [[NSMutableArray alloc] init];
    self.label.text = [NSString stringWithFormat:@"Starting"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.label.text = [NSString stringWithFormat:@"viewDidDisappear %ld", (unsigned long)self.sessions.count];

    self.delayTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                       target:self
                                                     selector:@selector(addOne:)
                                                     userInfo:nil
                                                      repeats:true];

}

- (void)addOne:(NSTimer *)timer {
    self.label.text = [NSString stringWithFormat:@"addOne %ld", (unsigned long)self.sessions.count];

    MQTTSession *session = [[MQTTSession alloc] initWithClientId:[NSString stringWithFormat:@"MQTTClient-%ld", (unsigned long)self.sessions.count]
                                                        userName:nil
                                                        password:nil
                                                       keepAlive:60
                                                    cleanSession:TRUE
                                                            will:FALSE
                                                       willTopic:nil
                                                         willMsg:nil
                                                         willQoS:0
                                                  willRetainFlag:FALSE
                                                   protocolLevel:4
                                                         runLoop:nil
                                                         forMode:nil];

    self.label.text = [NSString stringWithFormat:@"Created %@", [NSString stringWithFormat:@"MQTTClient-%ld", (unsigned long)self.sessions.count]];
    session.delegate = self;
    [self.sessions addObject:session];
    [session connectToHost:@"mqtt.localdomain" port:1883];
}

- (void)connected:(MQTTSession *)session {
    self.label.text = [NSString stringWithFormat:@"connected %@", session.clientId];
    [session subscribeTopic:@"$SYS/#"];
}

- (void)newMessage:(MQTTSession *)session data:(NSData *)data onTopic:(NSString *)topic qos:(MQTTQosLevel)qos retained:(BOOL)retained mid:(unsigned int)mid {
    self.received++;
    self.label.text = [NSString stringWithFormat:@"newMessage %ld", self.received];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    self.label.text = [NSString stringWithFormat:@"didReceiveMemoryWarning %ld", (unsigned long)self.sessions.count];

    for (MQTTSession *session in self.sessions) {
        self.label.text = [NSString stringWithFormat:@"Closing %@", session.clientId];
        [session disconnect];
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    }
}

@end
