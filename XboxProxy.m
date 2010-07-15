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
- (id) init
{
	if (self = [super init]) {
		myExternalIp = [PortMapper findPublicAddress];
		macDestinationAddrMap = [NSMutableDictionary dictionaryWithObject:[NSMutableArray arrayWithCapacity:5] forKey:BROADCAST_MAC];
		queue = [[NSOperationQueue alloc] init];
	}
	return self;
}

- (void) connectTo:(NSString *)host port:(UInt16)port
{
	// List proxies from remote
	// Greet remote with "introduce:port" packet
}

//////////////////////////////////////////////////////////////
#pragma mark getters/setters
//////////////////////////////////////////////////////////////
- (id) introducePacket
{
	return [NSArray arrayWithObjects:INTRODUCE, myExternalIp, myExternalPort];
}
- (id) proxyList
{
	return [macDestinationAddrMap objectForKey:BROADCAST_MAC];
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

- (void) updateBroadcastArray:(id) newAddresses
{
	// Do something
}

//////////////////////////////////////////////////////////////
#pragma mark HandlePcapPacket
//////////////////////////////////////////////////////////////
- (void) handleSniffedPacket:(NSData *) packet
{
	const unsigned char * packetData = [packet bytes];
	NSString * dstMacAddress = [NSString stringWithFormat:@"%02x:%02x:%02x:%02x:%02x:%02x", 
							 packetData[0], packetData[1], packetData[2],
							 packetData[3], packetData[4], packetData[5]];
	NSArray * destinationServer = [macDestinationAddrMap objectForKey:dstMacAddress];
	NSString * host = [destinationServer objectAtIndex:0];
	NSNumber * port = [destinationServer objectAtIndex:1];
	if (host == nil || port == nil) {
		NSLog(@"Got a packet to nowhere...");
	} else {
		[serverSocket sendData:packet toHost:host port:[port intValue] withTimeout:SEND_TIMEOUT tag:0];
	}
}

- (void) handleReceivedPacket:(NSData *)packet fromHost:(NSString *) host port:(UInt16) port
{
	// check if this host needs to be added to the list
	[sniffer inject:packet];
}

//////////////////////////////////////////////////////////////
#pragma mark Udp Socket Receive Delegate
//////////////////////////////////////////////////////////////
- (BOOL)onUdpSocket:(AsyncUdpSocket *)sock didReceiveData:(NSData *)data withTag:(long)tag fromHost:(NSString *)host port:(UInt16)port
{
	NSError * decodingError;
	NSPropertyListFormat format;
	id decodedPacket = [NSPropertyListSerialization propertyListWithData:data options:0 format:&format error:&decodingError];
	if ([decodedPacket isKindOfClass:[NSData class]]) {
		[self handleReceivedPacket:decodedPacket fromHost:host port:port];
	} else if([decodedPacket isKindOfClass:[NSArray class]]) {
		[self updateBroadcastArray:decodedPacket];
	} else if ([decodedPacket isEqual:LIST_PROXIES_PACKET]) {
		NSError * serializationError;
		NSData * sendPacket = [NSPropertyListSerialization dataWithPropertyList:self.proxyList 
																		 format:NSPropertyListBinaryFormat_v1_0 
																		options:0 
																		  error:&serializationError];
		if (serializationError) {
			NSLog(@"Failed to serialize broadcast array.");
		} else {
			[sock sendData:sendPacket toHost:host port:port withTimeout:SEND_TIMEOUT tag:tag+1];
		}
	} else {
		NSLog(@"Got an unknown packet!");
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
@end
