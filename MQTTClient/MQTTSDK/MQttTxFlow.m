//
// MQtttTxFlow.m
// 
// Copyright (c) 2011, 2013, 2lemetry LLC
// 
// All rights reserved. This program and the accompanying materials
// are made available under the terms of the Eclipse Public License v1.0
// and Eclipse Distribution License v. 1.0 which accompanies this distribution.
// The Eclipse Public License is available at http://www.eclipse.org/legal/epl-v10.html
// and the Eclipse Distribution License is available at
// http://www.eclipse.org/org/documents/edl-v10.php.
// 
// Contributors:
//    Kyle Roche - initial API and implementation and/or initial documentation
// 

#import "MQttTxFlow.h"

@implementation MQttTxFlow

+ (id)flowWithMsg:(MQTTMessage*)msg
         deadline:(unsigned int)deadline {
   return [[MQttTxFlow alloc] initWithMsg:msg deadline:deadline];
}

- (id)initWithMsg:(MQTTMessage*)aMsg
         deadline:(unsigned int)aDeadline {
   _msg = aMsg;
   _deadline = aDeadline;
   return self;
}

@end
