//
//  SlinkAppDelegate.h
//  Slink
//
//  Created by Tim Wu on 7/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "XboxProxy.h"
#import "XboxProxyController.h"


@interface SlinkAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *window;
	NSArray * deviceList;
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) NSArray * deviceList;
@end
