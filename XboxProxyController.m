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
	NSString * publicIp = [PortMapper findPublicAddress];
	if(publicIp == nil) {
		[externalIpField setEditable:YES];
		[[externalIpField cell] setPlaceholderString:@"Please enter your internet ip."];
	} else {
		[externalIpField setStringValue:[PortMapper findPublicAddress]];
	}
	[externalPortField setIntValue:DEFAULT_PORT];
	[deviceSelection addItemsWithTitles:[PcapListener getAvailableInterfaces]];
}

- (void) shutdown
{
	[xboxProxy close];
}

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
	xboxProxy.myExternalIp = [externalIpField stringValue];
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
	[sender setTitle:[sender titleOfSelectedItem]];
	if (xboxProxy && [xboxProxy isRunning]) {
		[xboxProxy setDev:[sender titleOfSelectedItem]];
	}
}
@end
