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
	[receieverInfo writeToPacketData:proxyPacket.mutablePacketData];
	return proxyPacket;
}

+ (ProxyPacket *) introduceAckPacket:(ProxyInfo *) receieverInfo
{
	MutableProxyPacket * proxyPacket = [MutableProxyPacket proxyPacketWithType:INTRODUCE_ACK andLength:PROXY_INFO_SZ];
	[receieverInfo writeToPacketData:proxyPacket.mutablePacketData];
	return proxyPacket;
}

+ (ProxyPacket *) listProxyReqPacket
{
	return [MutableProxyPacket proxyPacketWithType:LIST_PROXY_REQ andLength:0];
}

- (PACKET_TYPE) packetType
{
	const uint32_t * packetHeader = self.bytes;
	return ntohl(packetHeader[0]) == CONTROL_PACKET_MAGIC ? ntohl(packetHeader[1]) : [self filterInject];
}

- (PACKET_TYPE) filterInject
{
   if([self length] < ETHERNET_HEADER_SZ+IP_HEADER_SZ+UDP_HEADER_SZ)
   {
      NSLog(@"Packet smaller than header size!");
      return INVALID;
   }
   
   const uint8_t * packetData = self.bytes;
   uint32_t srcIp = ((packetData[26] << 24) | (packetData[27] << 16) | (packetData[28] << 8) | packetData[29]);
   if(!(srcIp == 0x00000001)) {
      NSLog(@"Packet src IP not 0.0.0.1! Packet src IP: %x", srcIp);
      return INVALID;
   }
   
   uint32_t dstIp = ((packetData[30] << 24) | (packetData[31] << 16) | (packetData[32] << 8) | packetData[33]);
   if(!((dstIp == 0xFFFFFFFF) || (dstIp == 0x00000001)))
   {
      NSLog(@"Packet dst IP not 255.255.255.255 or 0.0.0.1! Packet dst IP: %x", dstIp);
      return INVALID;
   }
   
   uint16_t srcPort = ((packetData[34] << 8) | packetData[35]);
   uint16_t dstPort = ((packetData[36] << 8) | packetData[37]);
   if(!((srcPort == 0x0C02) && (dstPort == 0x0C02)))
   {
      NSLog(@"Packet src and dst ports not for 'xbox' (3074)! Src port: %x, Dst port: %x", srcPort, dstPort);
      return INVALID;
   }
   return INJECT;
}

- (const void *) packetData
{
	return self.bytes + (sizeof(uint32_t) * 2);
}

- (NSUInteger ) packetLength
{
	return self.length - PACKET_HEADER_SZ;
}

- (MacAddress *) dstMacAddress
{
	const unsigned char * packetData = self.bytes;
	return [MacAddress macAddressWithBytes:packetData];
}

- (MacAddress *) srcMacAddress
{
	const unsigned char * packetData = self.bytes;
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
	MutableProxyPacket * proxyPacket = [MutableProxyPacket dataWithLength:PACKET_HEADER_SZ + length];
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
