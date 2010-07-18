//
//  XboxProxyController.m
//  Slink
//
//  Created by Tim Wu on 7/15/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "XboxProxyController.h"

@implementation RemoteProxyEntry
@synthesize proxyEntry;
@synthesize connectionState;
@end


@implementation XboxProxyController
@synthesize xboxProxy;

- (void) startup
{
	NSLog(@"Starting up");
	[externalPortField setIntValue:DEFAULT_PORT];
	[deviceSelection removeAllItems];
	[deviceSelection addItemsWithTitles:[PcapListener getAvailableInterfaces]];
	[self setProxyEntries:[NSMutableArray arrayWithCapacity:5]];
	// Register for some notifications
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectedToProxy:) name:XPConnectedToProxy object:nil];
}

- (void) shutdown
{
	[xboxProxy close];
}

#pragma mark Interface builder actions
- (IBAction) toggleProxyState:(id) sender
{
	// If it's running, shut it down
	if (self.xboxProxy && self.xboxProxy.running) {
		[self.xboxProxy close];
		return;
	}
	int port = [externalPortField intValue];
	NSString * dev = [[deviceSelection selectedItem] title];
	if (port == 0 || [dev isEqual:@""]) {
		[[NSAlert alertWithMessageText:nil 
						defaultButton:nil 
					  alternateButton:nil 
						  otherButton:nil 
			 informativeTextWithFormat:@"Set port and listen device in preferences."] runModal];
		return;
	}
	self.xboxProxy = [[XboxProxy alloc] initWithPort:port listenDevice:dev];
	if (![self.xboxProxy start] || !self.xboxProxy.running) {
		[[NSAlert alertWithMessageText:nil
						defaultButton:nil 
					  alternateButton:nil 
						  otherButton:nil 
			 informativeTextWithFormat:@"Failed to start xbox proxy, check console for errors."] runModal];
	}
}
- (IBAction) connectToProxy:(id) sender
{
	[[sender window] close];
	if (self.xboxProxy && self.xboxProxy.running) {
		[self.xboxProxy connectTo:[connectToIp stringValue] port:[connectToPort intValue]];
	}
}

- (IBAction) deviceSelector:(id) sender
{
	self.xboxProxy.dev = [sender titleOfSelectedItem];
}

#pragma mark Notification Handlers
- (void) connectedToProxy:(NSNotification *) notification
{
	NSDictionary * addedProxy = [notification userInfo];
	RemoteProxyEntry * newProxyEntry = [RemoteProxyEntry new];
	newProxyEntry.proxyEntry = [NSString stringWithFormat:@"%@:%@",[addedProxy objectForKey:@"host"], [addedProxy objectForKey:@"port"]];
	newProxyEntry.connectionState = 3;
	[self insertObject:newProxyEntry inProxyEntriesAtIndex:0];
}

#pragma mark Array Controller KVO methods
- (void) insertObject:(RemoteProxyEntry *)proxyEntry inProxyEntriesAtIndex:(NSUInteger)index 
{
    [proxyEntries insertObject:proxyEntry atIndex:index];
}

- (void) removeObjectFromProxyEntriesAtIndex:(NSUInteger)index 
{
    [proxyEntries removeObjectAtIndex:index];
}
@synthesize proxyEntries;
@end
