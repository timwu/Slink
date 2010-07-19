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

#define XPStarted @"XPStarted"
#define XPStopped @"XPStopped"
#define XPFilterStringChanged @"XPFilterStringChanged"
#define XPConnectedToProxy @"XPConnectedToProxy"
#define XPUpdatedExternalIp @"XPUpdatedExternalIp"

@interface XboxProxySendRequest : NSObject
{
	ProxyPacket * packet;
	NSString * host;
	UInt16 port;
}
@property (assign) ProxyPacket * packet;
@property (assign) NSString * host;
@property (assign) UInt16 port;

- (id) initWithPacket:(ProxyPacket *) _packet host:(NSString *) _host port:(UInt16) _port;
+ (id) sendRequestWithPacket:(ProxyPacket *) _packet host:(NSString *) _host port:(UInt16) _port;
@end


@interface XboxProxy : NSObject {
	long sendTag;
	BOOL running;
	
	// Sniffer variables
	PcapListener * sniffer;
	NSString * dev;
	NSString * filter;
	ProxyInfo * localProxyInfo;
	
	NSMutableDictionary * routingTable;
	MutableProxyList * allKnownProxies;
	AsyncUdpSocket * serverSocket;
	NSThread * proxyThread;
}
@property (assign) NSString * dev;
@property (assign) NSString	 * filter;
@property (assign) BOOL running;
@property (readonly) ProxyInfo * localProxyInfo;

- (id) initWithPort:(UInt16)port listenDevice:(NSString *) _dev;

- (void) removeObjectFromAllKnownProxiesAtIndex:(NSUInteger) index;
- (void) insertObject:(ProxyInfo *) proxyInfo inAllKnownProxiesAtIndex:(NSUInteger) index;
- (id) objectInAllKnownProxiesAtIndex:(NSUInteger) index;
- (NSUInteger) countOfAllKnownProxies;

- (NSString *) status;
- (void) close;
- (BOOL) start;
- (BOOL) startServerSocket;
- (BOOL) startSniffer;

- (void) connectTo:(NSString *) host port:(UInt16) port;
- (void) send:(id) data toHost:(NSString *) host port:(UInt16) port;
- (void) send:(id) data toProxy:(ProxyInfo *) proxy;
- (void) doSend:(XboxProxySendRequest *)sendReq;

- (void) updateBroadcastArray:(ProxyInfo *)newAddresses;
- (void) handleInject:(ProxyPacket *) packet fromHost:(NSString *) host port:(UInt16) port;
- (void) handleIntroduce:(ProxyPacket *) packet fromHost:(NSString *)host port:(UInt16)port;
- (void) handleIntroduceAck:(ProxyPacket *) packet fromHost:(NSString *) host port:(UInt16) port;
- (void) handleProxyListReqFromHost:(NSString *) host port:(UInt16) port;
@end
