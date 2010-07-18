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
#define LIST_PROXIES_PACKET @"list-proxies"
#define INTRODUCE @"Introduce"
#define INTRODUCE_ACK @"Introduce-ack"

#define XPStarted @"XPStarted"
#define XPStopped @"XPStopped"
#define XPFilterStringChanged @"XPFilterStringChanged"
#define XPConnectedToProxy @"XPConnectedToProxy"
#define XPUpdatedExternalIp @"XPUpdatedExternalIp"

#pragma mark Packet Types
typedef NSDictionary ProxyEntry;
typedef NSDictionary Introduce;
@interface NSDictionary (XboxPacketTypes)
{
}
+ (id) proxyEntryWithHost:(NSString *) host port:(UInt16) port;
+ (id) introduceAckWithHost:(NSString *) host port:(UInt16) port;
+ (id) introduceWithHost:(NSString *) host port:(UInt16) port;
@end

typedef NSArray ProxyList;
@interface NSArray (XboxProxyList)
{
}
- (id) filteredProxyListForHost:(NSString *) host port:(UInt16) port;
@end



#pragma mark Util Methods
id getSrcMacAddress(NSData * packet);
id getDstMacAddress(NSData * packet);

@interface XboxProxySendRequest : NSObject
{
	id data;
	NSString * host;
	UInt16 port;
}
@property (assign) id data;
@property (assign) NSString * host;
@property (assign) UInt16 port;

- (id) initWithData:(id) _data host:(NSString *) _host port:(UInt16) _port;
+ (id) sendRequestWithData:(id) _data host:(NSString *) _host port:(UInt16) _port;
@end


@interface XboxProxy : NSObject {
	long sendTag;
	BOOL running;
	
	// Sniffer variables
	PcapListener * sniffer;
	NSString * dev;
	NSString * filter;
	
	NSString * myExternalIp;
	NSNumber * myPort;
	NSMutableDictionary * macDestinationAddrMap;
	NSMutableArray * allKnownProxies;
	AsyncUdpSocket * serverSocket;
	NSThread * proxyThread;
}
@property (assign) NSString * dev;
@property (assign) NSString	 * filter;
@property (assign) NSNumber * myPort;
@property (assign) NSString * myExternalIp;
@property (assign) BOOL running;

- (id) initWithPort:(UInt16)port listenDevice:(NSString *) _dev;

- (NSString *) status;
- (void) close;
- (BOOL) start;
- (BOOL) startServerSocket;
- (BOOL) startSniffer;

- (void) connectTo:(NSString *) host port:(UInt16) port;
- (void) send:(id) data toHost:(NSString *) host port:(UInt16) port;
- (void) send:(id) data toProxy:(id) proxy;
- (void) doSend:(XboxProxySendRequest *)sendReq;

- (BOOL) isInjectPacket:(id) decodedPacket;
- (BOOL) isListProxiesPacket:(id) decodedPacket;
- (BOOL) isIntroducePacket:(id) decodedPacket;
- (BOOL) isIntroduceAckPacket:(id) decodedPacket;
- (BOOL) isProxyListPacket:(id) decodedPacket;
- (id) proxyList;

- (void) updateBroadcastArray:(ProxyEntry *)newAddresses;
- (void) handleInject:(NSData *) packet fromHost:(NSString *) host port:(UInt16) port;
- (void) handleIntroduce:(Introduce *) packet fromHost:(NSString *)host port:(UInt16)port;
@end
