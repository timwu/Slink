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

@interface XboxProxyController : NSObject {
	XboxProxy * xboxProxy;
#pragma mark Connect to window
	IBOutlet NSTextField * connectToIp;
	IBOutlet NSTextField * connectToPort;
	
#pragma mark Preference settings.
	IBOutlet NSTextField * externalPortField;
	IBOutlet NSPopUpButton * deviceSelection;
#define mark Main window settings
}

@property (assign) XboxProxy * xboxProxy;

- (void) startup;
- (void) shutdown;

- (IBAction) toggleProxyState:(id) sender;
- (IBAction) connectToProxy:(id) sender;
- (IBAction) deviceSelector:(id) sender;
@end
