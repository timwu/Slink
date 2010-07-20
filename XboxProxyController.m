//
//  XboxProxyController.m
//  Slink
//
//  Created by Tim Wu on 7/15/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "XboxProxyController.h"

@implementation XboxProxyController
@synthesize xboxProxy;

- (void) startup
{
	NSUserDefaultsController * userDefaultsController = [NSUserDefaultsController sharedUserDefaultsController];
	NSLog(@"Starting up");
	[deviceSelection removeAllItems];
	[deviceSelection addItemsWithTitles:[PcapListener getAvailableInterfaces]];
	[deviceSelection selectItemWithTitle:[[NSUserDefaults standardUserDefaults] objectForKey:@"listenDevice"]];
	
	self.xboxProxy = [XboxProxy new];
	[self.xboxProxy bind:@"dev" toObject:userDefaultsController withKeyPath:@"values.listenDevice" options:nil];
	
	NSString * externalIp = [PortMapper findPublicAddress];
	if(externalIp)
		self.xboxProxy.ip = externalIp;
	[self bind:@"externalPort" toObject:userDefaultsController withKeyPath:@"values.externalPort" options:nil];
	[self bind:@"mapExternalPort" toObject:userDefaultsController withKeyPath:@"values.mapExternalPort" options:nil];
	portMapper = [[PortMapper alloc] initWithPort:[self.externalPort intValue]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePortMappingFinished) 
												 name:PortMapperChangedNotification object:portMapper];
	portMapper.mapUDP = YES;
	portMapper.mapTCP = NO;
	//[portMappingError setHidden:YES];
	if([self.mapExternalPort boolValue]) {
		[self openPortMapper];
	}
}

- (void) shutdown
{
	[xboxProxy close];
	[portMapper close];
}

#pragma mark Interface builder actions
- (IBAction) toggleProxyState:(id) sender
{
	// If it's running, shut it down
	if (self.xboxProxy.running) {
		[self.xboxProxy close];
		return;
	}
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
	if(self.xboxProxy == nil || self.xboxProxy.running == NO) {
		[self toggleProxyState:sender];
	}
	[self.xboxProxy connectTo:[connectToIp stringValue] port:[connectToPort intValue]];
}

- (NSNumber *) externalPort
{
	return self.xboxProxy.port;
}

- (void) setExternalPort:(NSNumber *) port
{
	self.xboxProxy.port = port;
	portMapper.desiredPublicPort = [port intValue];
	if([self.mapExternalPort boolValue]) {
		[portMapper close];
		[portMapper open];
	}
}

- (NSNumber *) mapExternalPort
{
	return mapExternalPort;
}

- (void) setMapExternalPort:(NSNumber *) map
{
	if(self.mapExternalPort != nil && [map isEqualToNumber:self.mapExternalPort]) return;
	[portMappingError setHidden:YES];
	mapExternalPort = map;
	if([self.mapExternalPort boolValue]) {
		[self openPortMapper];
	} else {
		[portMapper close];
	}
}

- (void) openPortMapper
{
	[portMappingError setHidden:YES];
	[portMappingSpinner setHidden:NO];
	if(portMapper.isMapped == NO)
		[portMapper open];
}

- (void) handlePortMappingFinished
{
	[portMappingSpinner setHidden:YES];
	[portMappingError setHidden:portMapper.isMapped];
}
@end
