//
//  XboxProxyController.m
//  Slink
//
//  Created by Tim Wu on 7/15/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "XboxProxyController.h"

@implementation XboxProxyController

- (void) startup
{
	NSLog(@"Starting up");
	[externalPortField setIntValue:DEFAULT_PORT];
	[deviceSelection removeAllItems];
	[deviceSelection addItemsWithTitles:[PcapListener getAvailableInterfaces]];
	
	// Register for some notifications
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateExternalIp:) name:XPUpdatedExternalIp object:nil];
}

- (void) shutdown
{
	[xboxProxy close];
}

#pragma mark Interface builder actions
- (IBAction) toggleProxyState:(id) sender
{
	// If it's running, shut it down
	if (xboxProxy && [xboxProxy isRunning]) {
		[xboxProxy close];
		xboxProxy = nil;
		[toggleButton setTitle:@"Start"];
		[connectButton setEnabled:NO];
		return;
	}
	//NSLog(@"tasked with starting the proxy.");
	int port = [externalPortField intValue];
	NSString * dev = [[deviceSelection selectedItem] title];
	NSLog(@"Device: %@, port %d", dev, port);
	if (port == 0 || [dev isEqual:@""]) {
		NSLog(@"Missing port or device.");
		return;
	}
	xboxProxy = [[XboxProxy alloc] initWithPort:port listenDevice:dev];
	if ([xboxProxy start]) {
		[connectButton setEnabled:YES];
		[toggleButton setTitle:@"Stop"];
	}
}

- (IBAction) connectToProxy:(id) sender
{
	NSString * host = [connectIp stringValue];
	int port = [connectPort intValue];
	if ([host isEqual:@""] || port == 0) {
		NSLog(@"Invalid connect info: %@:%d", host, port);
		return;
	}
	[xboxProxy connectTo:host port:port];
	[connectIp setStringValue:@""];
	[connectPort setStringValue:@""];
}

- (IBAction) deviceSelector:(id) sender
{
	if (xboxProxy && [xboxProxy isRunning]) {
		[xboxProxy setDev:[sender titleOfSelectedItem]];
	}
}

#pragma mark Notification Handlers
- (void) updateExternalIp:(NSNotification *)notification
{
	[externalIpField setStringValue:[[notification object] myExternalIp]];
}

@end
