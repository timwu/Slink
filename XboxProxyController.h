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
#define PORT_MAP_TIMEOUT 10

@interface XboxProxyController : NSObject {
	XboxProxy * xboxProxy;
	IBOutlet NSButton * startStopButton;
	IBOutlet NSTextField * connectInfo;
	IBOutlet NSPopUpButton * deviceSelection;
	IBOutlet NSImageView * portMappingError;
	IBOutlet NSProgressIndicator * portMappingSpinner;
	NSNumber * mapExternalPort;
	PortMapper * portMapper;
}

@property (assign) XboxProxy * xboxProxy;
@property (assign) NSNumber * mapExternalPort;
@property (assign) NSNumber * externalPort;

- (void) startup;
- (void) shutdown;

- (IBAction) toggleProxyState:(id) sender;
- (IBAction) connectToProxy:(id) sender;

- (void) openPortMapper;
- (void) handlePortMappingFinished;
@end
