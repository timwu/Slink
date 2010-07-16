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
	IBOutlet NSTextField * externalIpField;
	IBOutlet NSTextField * externalPortField;
	IBOutlet NSTextField * connectIp;
	IBOutlet NSTextField * connectPort;
	IBOutlet NSPopUpButton * deviceSelection;
	IBOutlet NSButton * connectButton;
}

- (void) startup;
- (void) shutdown;

- (IBAction) startProxy:(id) sender;
- (IBAction) connectToProxy:(id) sender;
- (IBAction) deviceSelector:(id) sender;
@end
