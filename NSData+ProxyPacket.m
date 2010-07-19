//
//  NSData+ProxyPacket.m
//  Slink
//
//  Created by Tim Wu on 7/18/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "NSData+ProxyPacket.h"

@implementation NSData (ProxyPacket)

+ (ProxyPacket *) introducePacketToHost:(NSString *) host port:(UInt16) port
{
	return [ProxyPacket introducePacket:[ProxyInfo proxyInfoWithHost:host port:port]];
}

+ (ProxyPacket *) introduceAckPacketToHost:(NSString *) host port:(UInt16) port
{
	return [ProxyPacket introduceAckPacket:[ProxyInfo proxyInfoWithHost:host port:port]];
}

+ (ProxyPacket *) introducePacket:(ProxyInfo *) receieverInfo
{
	MutableProxyPacket * proxyPacket = [MutableProxyPacket proxyPacketWithType:INTRODUCE andLength:PROXY_INFO_SZ];
	[receieverInfo writeToPacketData:proxyPacket.mutableBytes];
	return proxyPacket;
}

+ (ProxyPacket *) introduceAckPacket:(ProxyInfo *) receieverInfo
{
	MutableProxyPacket * proxyPacket = [MutableProxyPacket proxyPacketWithType:INTRODUCE_ACK andLength:PROXY_INFO_SZ];
	[receieverInfo writeToPacketData:proxyPacket.mutableBytes];
	return proxyPacket;
}

+ (ProxyPacket *) listProxyReqPacket
{
	return [MutableProxyPacket proxyPacketWithType:LIST_PROXY_REQ andLength:0];
}

- (PACKET_TYPE) packetType
{
	const uint32_t * packetHeader = self.bytes;
	return ntohl(packetHeader[0]) == CONTROL_PACKET_MAGIC ? ntohl(packetHeader[1]) : INJECT;
}

- (const void *) packetData;
{
	return self.bytes + (sizeof(uint32_t) * 2);
}

- (MacAddress *) dstMacAddress
{
	const unsigned char * packetData = self.packetData;
	return [MacAddress macAddressWithBytes:packetData];
}

- (MacAddress *) srcMacAddress
{
	const unsigned char * packetData = self.packetData;
	return [MacAddress macAddressWithBytes:packetData + 6];
}

- (ProxyList *) proxyList
{
	return [ProxyList proxyListWithPacket:self];
}

- (ProxyInfo *) receiverProxyInfo
{
	return [ProxyInfo proxyInfoWithPacketData:self.packetData];
}
@end

@implementation NSMutableData (MutableProxyPacket)
+ (MutableProxyPacket *) proxyPacketWithType:(PACKET_TYPE) type andLength:(uint32_t) length
{
	MutableProxyPacket * proxyPacket = [MutableProxyPacket dataWithCapacity:PACKET_HEADER_SZ + length];
	uint32_t * packetHeader = proxyPacket.mutableBytes;
	packetHeader[0] = htonl(CONTROL_PACKET_MAGIC);
	packetHeader[1] = htonl(type);
	return proxyPacket;
}

- (void *) mutablePacketData;
{
	return self.mutableBytes + (sizeof(uint32_t) * 2);
}
@end
