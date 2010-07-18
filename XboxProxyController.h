//
//  XboxProxyController.h
//  Slink
//
//  Created by Tim Wu on 7/15/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "XboxProxy.h"
#import "PortMapper.h"
#import "PcapListener.h"

#define DEFAULT_PORT 30000

@interface RemoteProxyEntry : NSObject
{
	NSString * proxyEntry;
	int connectionState;
	
}
@property (assign) NSString * proxyEntry;
@property (assign) int connectionState;
@end

@interface XboxProxyController : NSObject {
	XboxProxy * xboxProxy;
#pragma mark Connect to window
	IBOutlet NSTextField * connectToIp;
	IBOutlet NSTextField * connectToPort;
	
#pragma mark Preference settings.
	IBOutlet NSTextField * externalPortField;
	IBOutlet NSPopUpButton * deviceSelection;
#define mark Main window settings
	NSMutableArray * proxyEntries;
}

@property (assign) NSMutableArray * proxyEntries;
@property (assign) XboxProxy * xboxProxy;

- (void) startup;
- (void) shutdown;

- (IBAction) toggleProxyState:(id) sender;
- (IBAction) connectToProxy:(id) sender;
- (IBAction) deviceSelector:(id) sender;

#pragma mark Notification Handlers
- (void) connectedToProxy:(NSNotification *) notification;

#pragma mark Proxy Entries KVO methods
- (void) insertObject:(RemoteProxyEntry *)proxyEntry inProxyEntriesAtIndex:(NSUInteger)index;
- (void) removeObjectFromProxyEntriesAtIndex:(NSUInteger)index;
@end
