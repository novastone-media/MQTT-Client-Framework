//
//  MQTTStrict.h
//  MQTTClient
//
//  Created by Christoph Krey on 24.07.17.
//  Copyright © 2017 Christoph Krey. All rights reserved.
//

#import <Foundation/Foundation.h>

/** MQTTStrict controls the behaviour of MQTTClient with regards to parameter checking
 *  If strict is true, all parameters passed by the caller are checked before
 *  the corresponding message is send (CONNECT, PUBLISH, SUBSCRIBE, UNSUBSCRIBE)
 *  and an exception is thrown if any invalid values or inconsistencies are detected
 *
 *  If strict is false, parameters are used as passed by the caller.
 *  Messages will be sent "incorrectly" and
 *  parameter checking will be done on the broker end.
 *
 */
@interface MQTTStrict : NSObject

/** strict returns the current strict flag
 *  @return the strict flag
 */
+ (BOOL)strict;

/** setString sets the global strict flag
 *  @param strict the new strict flag
 */
+ (void)setStrict:(BOOL)strict;

@end
