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
	[externalIpField setStringValue:[PortMapper findPublicAddress]];
	[externalPortField setIntValue:DEFAULT_PORT];
	[deviceSelection addItemsWithTitles:[PcapListener getAvailableInterfaces]];
}

- (void) shutdown
{
	[xboxProxy close];
}

- (IBAction) startProxy:(id) sender
{
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
}
@end
