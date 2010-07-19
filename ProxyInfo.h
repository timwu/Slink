//
//  ProxyInfo.h
//  Slink
//
//  Created by Tim Wu on 7/18/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <arpa/inet.h>

// Constant for the size of a serialized proxy info
#define PROXY_INFO_SZ (sizeof(uint32_t) * 2)

@interface NSString (IpAddress)
+ (NSString *) stringWithIp:(uint32_t) ip;
- (uint32_t) ipValue;
@end

@interface ProxyInfo : NSObject
{
	uint32_t ip;
	NSString * ipAsString;
	uint16_t port;
	uint32_t pingTime;
}
@property (assign) uint32_t ip;
@property (assign) uint16_t port;
@property (assign) uint32_t pingTime;
@property (assign) NSString * ipAsString;
+ (ProxyInfo *) proxyInfoWithPacketData:(const uint8_t *) packetData;
+ (ProxyInfo *) proxyInfoWithHost:(NSString *) _ip port:(UInt16) _port;
- (void) writeToPacketData:(uint8_t *) packetData;
@end
