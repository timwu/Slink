//
//  xboxproxy.h
//  Slink
//
//  Created by Tim Wu on 7/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PcapListener.h"
#import "AsyncUdpSocket.h"

#define RECV_TIMEOUT 10
#define SEND_TIMEOUT 10
#define BROADCAST_MAC @"ff:ff:ff:ff:ff:ff"
#define HELLO_PACKET @"Hello"

@interface XboxProxy : NSObject {
	// Sniffer variables
	PcapListener * sniffer;
	NSString * dev;
	NSString * filter;
	
	NSString * myExternalIp;
	NSMutableDictionary * macDestinationAddrMap;
	AsyncUdpSocket * serverSocket;
	NSOperationQueue * queue;
}

- (void) connectTo:(NSString *) host port:(UInt16) port;

- (void) setDev:(NSString *) _dev;
- (void) setFilter:(NSString *) _filter;
- (void) updateBroadcastArray:(NSArray *)newAddresses;
- (void) handleReceivedPacket:(NSData *) packet fromHost:(NSString *) host port:(UInt16) port;
@end
