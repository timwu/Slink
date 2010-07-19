//
//  ProxyInfo.m
//  Slink
//
//  Created by Tim Wu on 7/18/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ProxyInfo.h"

@implementation NSString(IpAddress)

+ (NSString *) stringWithIp:(uint32_t) ip
{
	return [NSString stringWithFormat:@"%d.%d.%d.%d",
			(ip & 0xFF000000) >> 24,
			(ip & 0x00FF0000) >> 16,
			(ip & 0x0000FF00) >> 8,
			(ip & 0x000000FF)];
}

- (uint32_t) ipValue 
{
	uint32_t ip = 0;
	NSArray * ipOctets = [self componentsSeparatedByString:@"."];
	for(NSString * octet in ipOctets) {
		ip <<= 8;
		ip |= [octet intValue];
	}
	return ip;
}
@end


@implementation ProxyInfo
@synthesize ip, port, pingTime, ipAsString;

+ (ProxyInfo *) proxyInfoWithPacketData:(const uint8_t *) _packetData
{
	const uint32_t * packetData = (const uint32_t *) _packetData;
	ProxyInfo * proxyInfo = [ProxyInfo new];
	proxyInfo.ip = ntohl(packetData[0]);
	proxyInfo.port = ntohl(packetData[1]);
	return proxyInfo;
}

+ (ProxyInfo *) proxyInfoWithHost:(NSString *) _ip port:(UInt16) _port
{
	ProxyInfo * proxyInfo = [ProxyInfo new];
	proxyInfo.ip = [_ip ipValue];
	proxyInfo.port = 0;
	proxyInfo.pingTime = 0;
	return proxyInfo;
}

- (void) setIp:(uint32_t) _ip
{
	ip = _ip;
	ipAsString = [NSString stringWithIp:_ip];
}

- (NSSet *) keyPathsForValuesAffectingIpAsString
{
	return [NSSet setWithObjects:@"ip", nil];
}

- (void) setIpAsString:(NSString *) _ip
{
	ipAsString = _ip;
	ip = [_ip ipValue];
}

- (NSSet *) keyPathsForValuesAffectingIp
{
	return [NSSet setWithObjects:@"ipAsString", nil];
}

- (NSString *) description
{
	return [NSString stringWithFormat:@"%@:%d", self.ipAsString, self.port];
}

- (void) writeToPacketData:(uint8_t *) _packetData
{
	uint32_t * packetData = (uint32_t *) _packetData;
	packetData[0] = htonl(self.ip);
	packetData[1] = htonl(self.port);
}

- (BOOL) isEqual:(id) other
{
	return [other isKindOfClass:[ProxyInfo class]] && [other ip] == self.ip && [other port] == self.port;
}
@end
