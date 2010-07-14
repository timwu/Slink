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
#define LIST_MACS_REQ @"LIST-MACS"
#define LIST_PROXIES_REQ @"LIST-PROXIES"

enum PACKET_KEYS {
	PACKET_TYPE,
	PACKET_PORT,
	PACKET_MACS,
	PACKET_PROXIES
};

enum PACKET_TYPE {
	PROXY_LIST_RESPONSE,
	MAC_LIST_RESPONSE
};

@interface RemoteXboxProxy : NSObject
{
	NSArray * macAddresses;
	AsyncUdpSocket * clientSocket;
}
@property (assign) NSArray * macAddresses;
- (id) initWithHost:(NSString *) host port:(int) port andSocketDelegate:(id) delegate;
- (id) initWithHost:(NSString *) host port:(int) port socketDelegate:(id) delegate andMacAddresses:(NSArray *) _macAddresses;
- (BOOL) send:(id) packetContents;
- (NSString *) host;
- (UInt16) port;
@end


@interface XboxProxy : NSObject {
	// Sniffer variables
	PcapListener * sniffer;
	NSString * dev;
	NSString * filter;
	
	NSString * myExternalIp;
	NSMutableArray * localMacAddresses;
	NSMutableArray * remoteXboxProxies;
	AsyncUdpSocket * serverSocket;
	NSOperationQueue * queue;
}

- (void) setDev:(NSString *) _dev;
- (void) setFilter:(NSString *) _filter;
- (void) updateRemoteProxy:(NSString *) proxy withUpdateDictionary:(NSDictionary *) updateDict;
@end
