//
//  NSString+MacAddress.h
//  Slink
//
//  Created by Tim Wu on 7/18/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
typedef NSString MacAddress;

@interface NSString (MacAddress)

+ (MacAddress *) macAddressWithBytes:(const unsigned char *) bytes;

@end
