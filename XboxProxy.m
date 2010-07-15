//
//  xboxproxy.m
//  Slink
//
//  Created by Tim Wu on 7/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "XboxProxy.h"
#import "PortMapper.h"

@implementation XboxProxy
//////////////////////////////////////////////////////////////
#pragma mark initializers
//////////////////////////////////////////////////////////////
- (id) initWithPort:(UInt16) port
{
	if (self = [super init]) {
		myExternalIp = [PortMapper findPublicAddress];
		macDestinationAddrMap = [NSMutableDictionary dictionaryWithObject:[NSMutableArray arrayWithCapacity:5] forKey:BROADCAST_MAC];
		self.myPort = [NSNumber numberWithInt:port];
	}
	return self;
}

- (void) connectTo:(NSString *)host port:(UInt16)port
{
	// List proxies from remote
	[self send:LIST_PROXIES_PACKET toHost:host port:port];
	// Greet remote with "introduce:port" packet
	[self send:self.introducePacket toHost:host port:port];
}

- (BOOL) send:(id) data toHost:(NSString *) host port:(UInt16) port
{
	NSError * serializationError = nil;
	NSData * serializedPacket = [NSPropertyListSerialization dataWithPropertyList:data format:NSPropertyListBinaryFormat_v1_0 options:0 error:&serializationError];
	if (serializationError) {
		NSLog(@"Error serializing introduce packet. %@", serializationError);
		return NO;
	}
	return [serverSocket sendData:serializedPacket toHost:host port:port withTimeout:SEND_TIMEOUT tag:0];
}
//////////////////////////////////////////////////////////////
#pragma mark getters/setters
//////////////////////////////////////////////////////////////
@synthesize myPort;
- (void) setMyPort:(NSNumber *) port
{
	NSError * bindError = nil;
	if (serverSocket) {
		[serverSocket close];
	}
	serverSocket = [[AsyncUdpSocket alloc] initWithDelegate:self];
	if([serverSocket bindToPort:[port intValue] error:&bindError] == NO) {
		NSLog(@"Error binding to port %@. %@", port, bindError);
		return;
	}
	[serverSocket receiveWithTimeout:RECV_TIMEOUT tag:0];
}

@synthesize dev;
- (void) setDev:(NSString *)_dev
{
	if ([_dev isEqual:dev]) {
		return;
	}
	if (sniffer) {
		[sniffer close];
	}
	sniffer = [[PcapListener alloc] initWithInterface:_dev withDelegate:self AndFilter:filter];
	dev = _dev;
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
	return [macDestinationAddrMap objectForKey:BROADCAST_MAC];
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
	id dstMacAddress = [self getSrcMacAddress:packet];
	NSArray * destinationServer = [macDestinationAddrMap objectForKey:dstMacAddress];
	NSString * host = [destinationServer objectAtIndex:0];
	NSNumber * port = [destinationServer objectAtIndex:1];
	if (host == nil || port == nil) {
		NSLog(@"Got a packet to nowhere...");
	} else {
		[serverSocket sendData:packet toHost:host port:[port intValue] withTimeout:SEND_TIMEOUT tag:0];
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
		[macDestinationAddrMap setObject:[NSArray arrayWithObjects:host, [NSNumber numberWithInt:port]] forKey:srcMacAddress];
	}
	[sniffer inject:packet];
}

- (void) handleIntroduce:(NSString *) host port:(UInt16) port
{
	NSArray * candidateProxy = [NSArray arrayWithObjects:host, [NSNumber numberWithInt:port]];
	[self updateBroadcastArray:candidateProxy];
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
	NSLog(@"Failed to receieve packet.");
	if ([error code] != AsyncUdpSocketReceiveTimeoutError) {
		NSLog(@"Failed to receive packet due to :%@", error);
	}
	[sock receiveWithTimeout:RECV_TIMEOUT tag:tag];
}
@end
