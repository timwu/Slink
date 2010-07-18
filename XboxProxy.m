//
//  xboxproxy.m
//  Slink
//
//  Created by Tim Wu on 7/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "XboxProxy.h"

#pragma mark Packet Types
@implementation NSDictionary (XboxPacketTypes)
+ (id) proxyEntryWithHost:(NSString *) host port:(UInt16) port
{
	return [NSDictionary dictionaryWithObjectsAndKeys:host, @"host",
			[NSNumber numberWithInt:port], @"port", nil];
}

+ (id) introduceAckWithHost:(NSString *) host port:(UInt16) port
{
	return [NSDictionary dictionaryWithObjectsAndKeys:INTRODUCE_ACK, @"type",
			host, @"host", [NSNumber numberWithInt:port], @"port", nil];
}

+ (id) introduceWithHost:(NSString *)host port:(UInt16)port
{
	return [NSDictionary dictionaryWithObjectsAndKeys:INTRODUCE, @"type",
			host, @"host", [NSNumber numberWithInt:port], @"port", nil];
}
@end

@implementation NSArray (XboxProxyList)
- (id) filteredProxyListForHost:(NSString *)host port:(UInt16)port
{
	NSPredicate * filterOutHost = [NSPredicate predicateWithFormat:@"(host != %@) AND (port != %@)",
								   host, [NSNumber numberWithInt:port]];
	return [self filteredArrayUsingPredicate:filterOutHost];
}
@end

#pragma mark Util Methods
id getDstMacAddress(NSData * packet)
{
	const unsigned char * packetData = [packet bytes];
	return [NSString stringWithFormat:@"%02x:%02x:%02x:%02x:%02x:%02x", 
			packetData[0], packetData[1], packetData[2],
			packetData[3], packetData[4], packetData[5]];
}

id getSrcMacAddress(NSData * packet)
{
	const unsigned char * packetData = [packet bytes];
	return [NSString stringWithFormat:@"%02x:%02x:%02x:%02x:%02x:%02x", 
			packetData[6], packetData[7], packetData[8],
			packetData[9], packetData[10], packetData[11]];
}

@implementation XboxProxySendRequest
@synthesize data, host, port;
- (id) initWithData:(id)_data host:(NSString *)_host port:(UInt16)_port
{
	if (self = [super init]) {
		self.data = _data;
		self.host = _host;
		self.port = _port;
	}
	return self;
}

+ (id) sendRequestWithData:(id)_data host:(NSString *)_host port:(UInt16)_port
{
	return [[self alloc] initWithData:_data host:_host port:_port];
}
@end

@implementation XboxProxy
//////////////////////////////////////////////////////////////
#pragma mark initializers
//////////////////////////////////////////////////////////////
- (id) initWithPort:(UInt16) port listenDevice:(NSString *) _dev
{
	if (self = [super init]) {
		self.running = NO;
		serverSocket = nil;
		sniffer = nil;
		myExternalIp = nil;
		macDestinationAddrMap = [NSMutableDictionary dictionaryWithCapacity:5];
		allKnownProxies = [NSMutableArray arrayWithCapacity:5];
		self.myPort = [NSNumber numberWithInt:port];
		self.filter = @"(host 0.0.0.1)";
		self.dev = _dev;
		sendTag = 0;
	}
	return self;
}

# pragma mark Status KVO methods.
- (NSString *) status
{
	if (!self.running) {
		return @"Slink is stopped.";
	} else {
		NSString * ipStatus = self.myExternalIp == nil ? @"Unknown" : self.myExternalIp;
		return [NSString stringWithFormat:@"Slink is running @ %@:%@", ipStatus, self.myPort];
	}
}

+ (NSSet *) keyPathsForValuesAffectingStatus
{
	return [NSSet setWithObjects:@"running",@"myExternalIp", @"myPort", nil];
}

#pragma mark Lifecycle methods.
- (BOOL) startServerSocket
{
	// Kill the previous server if it's there.
	if (serverSocket) {
		[serverSocket close];
	}
	// The thread the server socket is running on will be xboxproxy's main thread.
	proxyThread = [NSThread currentThread];
	NSError * bindError = nil;
	serverSocket = [[AsyncUdpSocket alloc] initWithDelegate:self];
	if([serverSocket bindToPort:[self.myPort intValue] error:&bindError] == NO) {
		NSLog(@"Error binding to port %@. %@", self.myPort, bindError);
		return NO;
	}
	[serverSocket receiveWithTimeout:RECV_TIMEOUT tag:0];
	return YES;
}

- (BOOL) startSniffer
{
	if (sniffer) {
		[sniffer close];
	}
	sniffer = [[PcapListener alloc] initWithInterface:self.dev withDelegate:self AndFilter:filter];
	return sniffer != nil;
}

- (BOOL) start
{
	if (self.running) {
		NSLog(@"XboxProxy is already running.");
		return YES;
	}
	if ([self startSniffer] == NO) {
		NSLog(@"Error starting packet sniffer.");
		return NO;
	}
	if ([self startServerSocket] == NO) {
		NSLog(@"Error starting server socket.");
		return NO;
	}
	self.running = YES;
	[[NSNotificationCenter defaultCenter] postNotificationName:XPStarted object:self];
	return YES;
}

- (void) close
{
	[serverSocket close];
	serverSocket = nil;
	self.filter = @"(host 0.0.0.1)";
	[sniffer close];
	sniffer = nil;
	macDestinationAddrMap = [NSMutableDictionary dictionaryWithCapacity:5];
	allKnownProxies = [NSMutableArray arrayWithCapacity:5];
	self.running = NO;
	[[NSNotificationCenter defaultCenter] postNotificationName:XPStopped object:self];
}
	

- (void) connectTo:(NSString *)host port:(UInt16)port
{
	NSLog(@"Connecting to %@:%d", host, port);
	// List proxies from remote
	[self send:LIST_PROXIES_PACKET toHost:host port:port];
	// Greet remote with "Introduce" packet
	[self send:[Introduce introduceWithHost:host port:port] toHost:host port:port];
	// Send your list of proxies
	[self send:[self.proxyList filteredProxyListForHost:host port:port] toHost:host port:port];
}

- (void) send:(id) data toHost:(NSString *) host port:(UInt16) port
{
	[self performSelector:@selector(doSend:) 
				 onThread:proxyThread 
			   withObject:[XboxProxySendRequest sendRequestWithData:data host:host port:port] 
			waitUntilDone:NO];
}

- (void) send:(id) data toProxy:(ProxyEntry *) proxy
{
	[self send:data toHost:[proxy objectForKey:@"host"] port:[[proxy objectForKey:@"port"] intValue]];
}

- (void) doSend:(XboxProxySendRequest *) sendReq
{
	NSError * serializationError = nil;
	NSData * serializedPacket = [NSPropertyListSerialization dataWithPropertyList:sendReq.data format:NSPropertyListBinaryFormat_v1_0 options:0 error:&serializationError];
	if (serializationError) {
		NSLog(@"Error serializing introduce packet. %@", serializationError);
	}
	if ([serverSocket sendData:serializedPacket toHost:sendReq.host port:sendReq.port withTimeout:SEND_TIMEOUT tag:sendTag++] == NO) {
		NSLog(@"Error sending packet.");
	}
}
//////////////////////////////////////////////////////////////
#pragma mark getters/setters
//////////////////////////////////////////////////////////////
@synthesize running;
@synthesize myExternalIp;
@synthesize myPort;
- (void) setMyPort:(NSNumber *) port
{
	myPort = port;
	if (self.running) {
		[self startServerSocket];
	}
}

@synthesize dev;
- (void) setDev:(NSString *)_dev
{
	if ([_dev isEqual:dev]) {
		return;
	}
	dev = _dev;
	if (self.running) {
		[self startSniffer];
	}
}

@synthesize filter;
- (void) setFilter:(NSString *)_filter
{
	filter = _filter;
	NSLog(@"Filter changed to %@", filter);
	if (sniffer) {
		[sniffer setFilter:filter];
	}
}

- (void) updateBroadcastArray:(ProxyEntry *) candidateProxy
{
	for(ProxyEntry * proxy in self.proxyList) {
		if ([proxy isEqualTo:candidateProxy]) {
			// we already know about this proxy
			return;
		}
	}
	[self.proxyList addObject:candidateProxy];
	[[NSNotificationCenter defaultCenter] postNotificationName:XPConnectedToProxy 
														object:self 
													  userInfo:candidateProxy];
}

//////////////////////////////////////////////////////////////
#pragma mark packet handling methods
//////////////////////////////////////////////////////////////
- (BOOL) isInjectPacket:(id) decodedPacket
{
	return [decodedPacket isKindOfClass:[NSData class]];
}

- (BOOL) isListProxiesPacket:(id) decodedPacket
{
	return [decodedPacket isEqual:LIST_PROXIES_PACKET];
}

- (BOOL) isIntroducePacket:(id) decodedPacket
{
	return [[decodedPacket objectForKey:@"type"] isEqualTo:INTRODUCE];
}

- (BOOL) isIntroduceAckPacket:(Introduce *) decodedPacket
{
	return [[decodedPacket objectForKey:@"type"] isEqual:INTRODUCE_ACK];
}

- (BOOL) isProxyListPacket:(id) decodedPacket
{
	return [decodedPacket isKindOfClass:[NSArray class]];;
}

- (id) proxyList
{
	return allKnownProxies;
}

- (void) handleSniffedPacket:(NSData *) packet
{
	id dstMacAddress = getDstMacAddress(packet);
	if ([dstMacAddress isEqual:BROADCAST_MAC]) {
		for(id proxyEntry in self.proxyList) {
			[self send:packet toProxy:proxyEntry];
		}
		return;
	}
	id destinationServer = [macDestinationAddrMap objectForKey:dstMacAddress];
	if (destinationServer == nil) {
		NSLog(@"Got an unknown mac: %@", dstMacAddress);
	} else {
		[self send:packet toProxy:destinationServer];
	}
}

- (void) handleProxyListPacket:(NSArray *) proxyList
{
	for(ProxyEntry * proxy in proxyList) {
		NSLog(@"Sending introduction to: %@", proxy);
		[self send:INTRODUCE toHost:[proxy objectForKey:@"host"] port:[[proxy objectForKey:@"port"] intValue]];
	}
}

- (void) handleInject:(NSData *)packet fromHost:(NSString *) host port:(UInt16) port
{	
	// Check if this mac address is in the map, if not update the map with the new mac, and where it came from
	NSArray * srcMacAddress = getSrcMacAddress(packet);
	if ([macDestinationAddrMap objectForKey:srcMacAddress] == nil) {
		NSLog(@"Updating mac -> destination map with entry [%@ -> %@:%d]", srcMacAddress, host, port);
		[macDestinationAddrMap setObject:[ProxyEntry proxyEntryWithHost:host port:port] forKey:srcMacAddress];
		// Since this is a remote mac address, add it to the pcap filtering so we don't get inject feedback.
		self.filter = [NSString stringWithFormat:@"%@ && !(ether src %@)", self.filter, srcMacAddress];
	}
	[sniffer inject:packet];
}

- (void) handleIntroduce:(Introduce *) packet fromHost:(NSString *) host port:(UInt16) port
{
	id candidateProxy = [ProxyEntry proxyEntryWithHost:host port:port];
	[self updateBroadcastArray:candidateProxy];
	// Also acknowledge the introduction
	[self send:[Introduce introduceAckWithHost:host port:port] toHost:host port:port];
	if (self.myExternalIp == nil) {
		NSLog(@"Updating external ip with %@", [packet objectForKey:@"host"]);
		self.myExternalIp = [packet objectForKey:@"host"];
	}
}

- (void) handleIntroduceAck:(Introduce *) packet fromHost:(NSString *) host port:(UInt16) port
{
	NSLog(@"Got introduce ack.");
	[self updateBroadcastArray:[ProxyEntry proxyEntryWithHost:host port:port]];
	if (self.myExternalIp == nil) {
		NSLog(@"Updating external ip with %@", [packet objectForKey:@"host"]);
		self.myExternalIp = [packet objectForKey:@"host"];
	}
}

//////////////////////////////////////////////////////////////
#pragma mark Udp Socket Receive Delegate
//////////////////////////////////////////////////////////////
- (BOOL)onUdpSocket:(AsyncUdpSocket *)sock didReceiveData:(NSData *)data withTag:(long)tag fromHost:(NSString *)host port:(UInt16)port
{
	NSError * decodingError = nil;
	NSPropertyListFormat format;
	id decodedPacket = [NSPropertyListSerialization propertyListWithData:data options:0 format:&format error:&decodingError];
	if ([self isInjectPacket:decodedPacket]) {
		[self handleInject:decodedPacket fromHost:host port:port];
	} else if([self isProxyListPacket:decodedPacket]) {
		[self handleProxyListPacket:decodedPacket];
	} else if ([self isListProxiesPacket:decodedPacket]) {
		[self send:[self.proxyList filteredProxyListForHost:host port: port] toHost:host port:port];
	} else if ([self isIntroducePacket:decodedPacket]) {
		[self handleIntroduce:decodedPacket fromHost:host port:port];
	} else if ([self isIntroduceAckPacket:decodedPacket]) {
		[self handleIntroduceAck:decodedPacket fromHost:host port:port];
	} else {
		NSLog(@"Got an unknown packet!");
	}
	if (decodingError) {
		NSLog(@"Error decoding packet: %@", decodingError);
	}
	[sock receiveWithTimeout:RECV_TIMEOUT tag:tag+1];
	return YES;
}

- (void)onUdpSocket:(AsyncUdpSocket *)sock didNotReceiveDataWithTag:(long)tag dueToError:(NSError *)error
{
	if ([error code] != AsyncUdpSocketReceiveTimeoutError) {
		NSLog(@"Failed to receive packet due to :%@", error);
	}
	[sock receiveWithTimeout:RECV_TIMEOUT tag:tag];
}

- (void)onUdpSocket:(AsyncUdpSocket *)sock didSendDataWithTag:(long)tag
{
}

- (void)onUdpSocket:(AsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error
{
	NSLog(@"Error sending: %@", error);
}
@end
