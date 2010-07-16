//
//  xboxproxy.m
//  Slink
//
//  Created by Tim Wu on 7/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "XboxProxy.h"
#import "PortMapper.h"

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
		isRunning = NO;
		serverSocket = nil;
		sniffer = nil;
		myExternalIp = [PortMapper findPublicAddress];
		macDestinationAddrMap = [NSMutableDictionary dictionaryWithCapacity:5];
		allKnownProxies = [NSMutableArray arrayWithCapacity:5];
		self.myPort = [NSNumber numberWithInt:port];
		self.filter = @"(host 0.0.0.1)";
		self.dev = _dev;
		sendTag = 0;
	}
	return self;
}

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
	if (isRunning) {
		NSLog(@"XboxProxy is already running.");
		return YES;
	}
	if ([self startServerSocket] == NO) {
		NSLog(@"Error starting server socket.");
		return NO;
	}
	if ([self startSniffer] == NO) {
		NSLog(@"Error starting packet sniffer.");
		return NO;
	}
	isRunning = YES;
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
	isRunning = NO;
}
	

- (void) connectTo:(NSString *)host port:(UInt16)port
{
	// Add the connected host to the known proxy list
	[self updateBroadcastArray:[self createProxyEntry:host port:port]];
	// List proxies from remote
	[self send:LIST_PROXIES_PACKET toHost:host port:port];
	// Greet remote with "Introduce" packet
	[self send:self.introducePacket toHost:host port:port];
}

- (void) send:(id) data toHost:(NSString *) host port:(UInt16) port
{
	[self performSelector:@selector(doSend:) 
				 onThread:proxyThread 
			   withObject:[XboxProxySendRequest sendRequestWithData:data host:host port:port] 
			waitUntilDone:NO];
}

- (void) send:(id) data toProxy:(id) proxy
{
	[self send:data toHost:[self getProxyEntryHost:proxy] port:[[self getProxyEntryPort:proxy] intValue]];
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
@synthesize myExternalIp;
@synthesize myPort;
- (void) setMyPort:(NSNumber *) port
{
	myPort = port;
	if (isRunning == NO) {
		return;
	}
	[self startServerSocket];
}

@synthesize dev;
- (void) setDev:(NSString *)_dev
{
	if ([_dev isEqual:dev]) {
		return;
	}
	dev = _dev;
	[self startSniffer];
}

@synthesize filter;
- (void) setFilter:(NSString *)_filter
{
	filter = _filter;
	if (sniffer) {
		[sniffer setFilter:filter];
	}
}

- (void) updateBroadcastArray:(id) candidateProxy
{
	for(NSArray * proxy in self.proxyList) {
		if ([proxy isEqualToArray:candidateProxy]) {
			// we already know about this proxy
			return;
		}
	}
	if ([[self createProxyEntry:self.myExternalIp port:[self.myPort intValue]] isEqualToArray:candidateProxy]) {
		return;
	}
	[self.proxyList addObject:candidateProxy];
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
	return [decodedPacket isEqual:INTRODUCE];
}

- (BOOL) isProxyListPacket:(id) decodedPacket
{
	return [decodedPacket isKindOfClass:[NSArray class]];
}

- (id) introducePacket
{
	return INTRODUCE;
}

- (id) proxyList
{
	return allKnownProxies;
}

- (BOOL) isProxyEntry:(id) entry
{
	if ([entry isKindOfClass:[NSArray class]]) {
		return [[entry objectAtIndex:0] isKindOfClass:[NSString class]] && [[entry objectAtIndex:1] isKindOfClass:[NSNumber class]];
	}
	return NO;
}

- (NSString *) getProxyEntryHost:(id) entry
{
	return [entry objectAtIndex:0];
}

- (NSNumber *) getProxyEntryPort:(id) entry
{
	return [entry objectAtIndex:1];
}

- (id) getDstMacAddress:(NSData *)packet
{
	const unsigned char * packetData = [packet bytes];
	return [NSString stringWithFormat:@"%02x:%02x:%02x:%02x:%02x:%02x", 
								packetData[0], packetData[1], packetData[2],
								packetData[3], packetData[4], packetData[5]];
}

- (id) getSrcMacAddress:(NSData *)packet
{
	const unsigned char * packetData = [packet bytes];
	return [NSString stringWithFormat:@"%02x:%02x:%02x:%02x:%02x:%02x", 
								packetData[6], packetData[7], packetData[8],
								packetData[9], packetData[10], packetData[11]];
}

- (void) handleSniffedPacket:(NSData *) packet
{
	[self performSelector:@selector(sendSniffedPacket:) onThread:proxyThread withObject:packet waitUntilDone:NO];
}

- (void) sendSniffedPacket:(NSData *)packet
{
	id dstMacAddress = [self getDstMacAddress:packet];
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
	for(NSArray * proxy in proxyList) {
		[self updateBroadcastArray:proxy];
	}
}

- (void) handleReceivedPacket:(NSData *)packet fromHost:(NSString *) host port:(UInt16) port
{	
	// Check if this mac address is in the map, if not update the map with the new mac, and where it came from
	NSArray * srcMacAddress = [self getSrcMacAddress:packet];
	if ([macDestinationAddrMap objectForKey:srcMacAddress] == nil) {
		[macDestinationAddrMap setObject:[self createProxyEntry:host port:port] forKey:srcMacAddress];
		// Since this is a remote mac address, add it to the pcap filtering so we don't get inject feedback.
		self.filter = [NSString stringWithFormat:@"%@ && !(ether src %@)", self.filter, srcMacAddress];
	}
	[sniffer inject:packet];
}

- (void) handleIntroduce:(NSString *) host port:(UInt16) port
{
	NSArray * candidateProxy = [self createProxyEntry:host port:port];
	[self updateBroadcastArray:candidateProxy];
}

- (id) createProxyEntry:(NSString *) host port:(UInt16) port
{
	return [NSArray arrayWithObjects:host, [NSNumber numberWithInt:port], nil];
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
		[self handleReceivedPacket:decodedPacket fromHost:host port:port];
	} else if([self isProxyListPacket:decodedPacket]) {
		[self handleProxyListPacket:decodedPacket];
	} else if ([self isListProxiesPacket:decodedPacket]) {
		[self send:self.proxyList toHost:host port:port];
	} else if ([self isIntroducePacket:decodedPacket]) {
		[self handleIntroduce:host port:port];
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
