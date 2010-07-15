//
//  SlinkAppDelegate.m
//  Slink
//
//  Created by Tim Wu on 7/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "SlinkAppDelegate.h"

@implementation SlinkAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	NSLog(@"Launching");
	xboxProxy = [[XboxProxy alloc] initWithPort:5000];
	[xboxProxy setDev:@"en2"];
	[xboxProxy connectTo:@"192.168.1.110" port:5000];
}

@end
