//
//  NSString+MacAddress.m
//  Slink
//
//  Created by Tim Wu on 7/18/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "NSString+MacAddress.h"

@implementation NSString (MacAddress)
+ (MacAddress *) macAddressWithBytes:(const unsigned char *) bytes
{
	return [MacAddress stringWithFormat:@"%02x:%02x:%02x:%02x:%02x:%02x",
		    bytes[0], bytes[1], bytes[2],
			bytes[3], bytes[4], bytes[5]];
}
@end
