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
#define LIST_PROXIES_PACKET @"list-proxies"
#define INTRODUCE @"Introduce"

typedef NSData MacAddress;

@interface XboxProxy : NSObject {
	// Sniffer variables
	PcapListener * sniffer;
	NSString * dev;
	NSString * filter;
	
	NSString * myExternalIp;
	NSNumber * myPort;
	NSMutableDictionary * macDestinationAddrMap;
	AsyncUdpSocket * serverSocket;
	NSOperationQueue * queue;
}
@property (assign) NSString * dev;
@property (assign) NSString	 * filter;
@property (assign) NSNumber * myPort;

- (id) initWithPort:(UInt16)port;

- (void) connectTo:(NSString *) host port:(UInt16) port;
- (BOOL) send:(id) data toHost:(NSString *) host port:(UInt16) port;

- (BOOL) isInjectPacket:(id) decodedPacket;
- (BOOL) isListProxiesPacket:(id) decodedPacket;
- (BOOL) isIntroducePacket:(id) decodedPacket;
- (BOOL) isProxyListPacket:(id) decodedPacket;
- (id) introducePacket;
- (id) proxyList;
- (id) getDstMacAddress:(NSData *) packet;
- (id) getSrcMacAddress:(NSData *) packet;

- (void) updateBroadcastArray:(NSArray *)newAddresses;
- (void) handleReceivedPacket:(NSData *) packet fromHost:(NSString *) host port:(UInt16) port;
- (void) handleIntroduce:(NSString *)host port:(UInt16)port;
@end
