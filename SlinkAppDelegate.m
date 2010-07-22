//
//  SlinkAppDelegate.m
//  Slink
//
//  Created by Tim Wu on 7/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "SlinkAppDelegate.h"
#import "PcapListener.h"

@implementation SlinkAppDelegate

@synthesize window, deviceList;

+ (void) initialize
{
	NSLog(@"initializing.");
	[[NSUserDefaults standardUserDefaults] registerDefaults:
	 [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:DEFAULT_PORT], @"externalPort", 
	  [NSNumber numberWithBool:YES], @"mapExternalPort", nil]];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	NSLog(@"Launching");
	self.deviceList = [PcapListener getAvailableInterfaces];
}

- (NSApplicationTerminateReply) applicationShouldTerminate:(NSApplication *)sender
{
	NSLog(@"Going down....");
	return NSTerminateNow;
}

@end
