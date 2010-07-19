//
//  NSArray+ProxyList.m
//  Slink
//
//  Created by Tim Wu on 7/18/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "NSArray+ProxyList.h"

@implementation NSArray (ProxyList)

+ (ProxyList *) proxyListWithPacket:(ProxyPacket *) packet
{
	const uint8_t * packetData = packet.packetData;
	int numberOfProxies = (packet.length / PROXY_INFO_SZ) - 1;
	if (numberOfProxies <= 0) {
		return nil;
	}
	NSMutableArray * proxyList = [NSMutableArray arrayWithCapacity:numberOfProxies];
	for(int i = PACKET_HEADER_SZ; i < packet.length; i += PROXY_INFO_SZ) {
		[proxyList addObject:[ProxyInfo proxyInfoWithPacketData:packetData + i]];
	}
	return proxyList;
}

- (id) filteredProxyListForHost:(NSString *)host port:(UInt16)port
{
	NSPredicate * filterOutHost = [NSPredicate predicateWithFormat:@"(host != %@) AND (port != %@)",
								   host, [NSNumber numberWithInt:port]];
	return [self filteredArrayUsingPredicate:filterOutHost];
}

- (ProxyPacket *) proxyListPacket
{
	uint32_t length = [self count] * PROXY_INFO_SZ;
	MutableProxyPacket * proxyPacket = [MutableProxyPacket proxyPacketWithType:PROXY_LIST andLength:length];
	uint8_t * packetData = proxyPacket.mutablePacketData;
	for(int i = 0; i < [self count]; i++) {
		[[self objectAtIndex:i] writeToPacketData:packetData + (i * PROXY_INFO_SZ)];
	}
	return proxyPacket;
}	
@end

