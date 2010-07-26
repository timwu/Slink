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
   if([self length] < ETHERNET_HEADER+IP_HEADER+UDP_HEADER)
   {
      NSLog(@"Packet smaller than header size!");
      return INVALID;
   }
   const uint16_t * packetData = self.bytes;
   uint32_t srcIp = ntohl((packetData[13] << 16) | packetData[14]);
   //if(!((packetData[13] == 0x0000) && (packetData[14] == 0x0001)))
   if(!(srcIp == 0x00000001))
   {
      NSLog(@"Packet src IP not 0.0.0.1! Packet src IP: %@", srcIp);
      return INVALID;
   }
   uint32_t dstIp = ntohl((packetData[15] << 16) | packetData[16]);
   //if(!((packetData[15] == 0xFFFF) && (packetData[16] == 0xFFFF)))
   if(!(dstIp == 0xFFFFFFFF))
   {
      NSLog(@"Packet dst IP not 255.255.255.255! Packet dst IP: %@", dstIp);
      return INVALID;
   }
   uint16_t srcPort = ntohl(packetData[17]);
   uint16_t dstPort = ntohl(packetData[18]);
   //if(!((packetData[17] == 0x0C02) && (packetData[18] == 0x0C02)))
   if(!((srcPort == 0x0C02) && (dstPort == 0x0C02)))
   {
      NSLog(@"Packet src and dst ports not for xbox (3074)! Src port: %@, Dst port: %@", srcPort, dstPort);
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
