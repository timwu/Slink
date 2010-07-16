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
	[xboxProxyController startup];
}

- (NSApplicationTerminateReply) applicationShouldTerminate:(NSApplication *)sender
{
	NSLog(@"Going down....");
	[xboxProxyController shutdown];
	return NSTerminateNow;
}

@end
