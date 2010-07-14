//
//  xboxproxy.m
//  Slink
//
//  Created by Tim Wu on 7/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "XboxProxy.h"
#import "PortMapper.h"

@implementation RemoteXboxProxy

@synthesize macAddresses;
- (id) initWithHost:(NSString *)host port:(int)port andSocketDelegate:(id) delegate
{
	if (self = [super init]) {
		NSError * connectError;
		clientSocket = [[AsyncUdpSocket alloc] initWithDelegate:delegate];
		if ([clientSocket connectToHost:host onPort:port error:&connectError] == NO) {
			self = nil;
		}
		[self send:LIST_MACS_REQ];
	}
	return self;
}
- (id) initWithHost:(NSString *)host port:(int)port socketDelegate:(id)delegate andMacAddresses:(NSArray *) _macAddresses
{
	if (self = [self initWithHost:host port:port andSocketDelegate:delegate]) {
		macAddresses = _macAddresses;
	}
	return self;
}
- (BOOL) send:(id) packetContents
{
	NSError * serializationError = nil;
	NSData * packet = [NSPropertyListSerialization dataWithPropertyList:packetContents 
																 format:NSPropertyListBinaryFormat_v1_0 
																options:0 
																  error:&serializationError];
	if (serializationError) {
		NSLog(@"Data packet serialization error: %@", serializationError);
		return NO;
	} else {
		[clientSocket sendData:packet withTimeout:SEND_TIMEOUT tag:0];
	}
	return YES;
}
- (NSString *) host
{
	return [clientSocket connectedHost];
}
- (UInt16) port
{
	return [clientSocket connectedPort];
}
- (NSString *) description
{
	return [NSString stringWithFormat:@"RemoteXboxProxy @ %@:%d [%@]", self.host, self.port, self.macAddresses];
}
@end


@implementation XboxProxy

//////////////////////////////////////////////////////////////
#pragma mark initializers
//////////////////////////////////////////////////////////////
- (id) init
{
	if (self = [super init]) {
		myExternalIp = [PortMapper findPublicAddress];
		queue = [[NSOperationQueue alloc] init];
		localMacAddresses = [NSMutableArray arrayWithCapacity:5];
		[localMacAddresses addObject:BROADCAST_MAC];
		remoteXboxProxies = [NSMutableArray arrayWithCapacity:5];
	}
	return self;
}

//////////////////////////////////////////////////////////////
#pragma mark getters/setters
//////////////////////////////////////////////////////////////
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

- (void) setFilter:(NSString *)_filter
{
	filter = _filter;
	if (sniffer) {
		[sniffer setFilter:filter];
	}
}
- (void) updateRemoteProxy:(NSString *)proxy withUpdateDictionary:(NSDictionary *) updateDict
{
	NSNumber * portNumber = [updateDict objectForKey:[NSNumber numberWithInt:PACKET_PORT]];
	NSArray * macAddresses = [updateDict objectForKey:[NSNumber numberWithInt:PACKET_MACS]];
	if (portNumber == nil || macAddresses == nil) {
		NSLog(@"Malformed proxy update packet: %@", updateDict);
		return;
	}
	for(RemoteXboxProxy * remoteXboxProxy in remoteXboxProxies) {
		if ([remoteXboxProxy.host isEqual:proxy] && remoteXboxProxy.port == [portNumber intValue]) {
			[remoteXboxProxy setMacAddresses:macAddresses];
			NSLog(@"Updated proxy: %@", remoteXboxProxy);
			return;
		}
	}
	// Not found, so add it
	RemoteXboxProxy * remoteXboxProxy = [[RemoteXboxProxy alloc] initWithHost:proxy 
																		 port:[portNumber intValue] 
															   socketDelegate:self 
															  andMacAddresses:macAddresses];
	[remoteXboxProxies addObject:remoteXboxProxy];
	NSLog(@"Added proxy: %@", remoteXboxProxy);
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
	NSString * srcMacAddress = [NSString stringWithFormat:@"%02x:%02x:%02x:%02x:%02x:%02x", 
								packetData[6], packetData[7], packetData[8],
								packetData[9], packetData[10], packetData[11]];
	BOOL updatedMacAddressList = NO;
	if ([localMacAddresses containsObject:srcMacAddress] == NO) {
		[localMacAddresses addObject:srcMacAddress];
		updatedMacAddressList = YES;
	}
	for(RemoteXboxProxy * remoteXboxProxy in remoteXboxProxies) {
		if ([remoteXboxProxy.macAddresses containsObject:dstMacAddress]) {
			[remoteXboxProxy send:packet];
		}
		if (updatedMacAddressList) {
			[remoteXboxProxy send:localMacAddresses];
		}
	}
}

//////////////////////////////////////////////////////////////
#pragma mark Udp Socket Receive Delegate
//////////////////////////////////////////////////////////////
- (BOOL)onUdpSocket:(AsyncUdpSocket *)sock didReceiveData:(NSData *)data withTag:(long)tag fromHost:(NSString *)host port:(UInt16)port
{
	NSError * decodingError;
	NSDictionary * decodedPacket = [NSPropertyListSerialization propertyListWithData:data options:0 format:NSPropertyListBinaryFormat_v1_0 error:&decodingError];
	if ([decodedPacket isKindOfClass:[NSData class]]) {
		[sniffer inject:decodedPacket];
	} else if ([decodedPacket isKindOfClass:[NSDictionary class]]) {
		if ([[decodedPacket objectForKey:[NSNumber numberWithInt:PACKET_TYPE]] intValue] == MAC_LIST_RESPONSE) {
			[self updateRemoteProxy:host withUpdateDictionary:decodedPacket];
		} else if ([[decodedPacket objectForKey:[NSNumber numberWithInt:PACKET_TYPE]] intValue] == PROXY_LIST_RESPONSE) {
			
		}	
	} else if ([decodedPacket isKindOfClass:[NSNumber class]]) {
		
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
