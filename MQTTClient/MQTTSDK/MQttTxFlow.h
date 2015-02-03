//
// MQttTxFlow.h
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

#import <Foundation/Foundation.h>
#import "MQTTMessage.h"

@interface MQttTxFlow : NSObject 

+ (id)flowWithMsg:(MQTTMessage*)aMsg
         deadline:(unsigned int)aDeadline;
- (id)initWithMsg:(MQTTMessage*)aMsg deadline:(unsigned int)aDeadline;

@property (strong) MQTTMessage* msg;
@property (assign) unsigned int deadline;

@end

