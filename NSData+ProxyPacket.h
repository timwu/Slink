//
//  NSData+ProxyPacket.h
//  Slink
//
//  Created by Tim Wu on 7/18/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <arpa/inet.h>

typedef NSData ProxyPacket;
typedef NSMutableData MutableProxyPacket;

#import "ProxyInfo.h"
#import "NSString+MacAddress.h"
#import "NSArray+ProxyList.h"

#define CONTROL_PACKET_MAGIC 0x12345678
// Magic number and the type
#define PACKET_HEADER_SZ (sizeof(uint32_t) * 2)

typedef enum {
	INJECT,
	INTRODUCE,
	INTRODUCE_ACK,
	PROXY_LIST,
	LIST_PROXY_REQ,
	INVALID
} PACKET_TYPE;

@interface NSData (ProxyPacket)
+ (ProxyPacket *) introducePacketToHost:(NSString *) host port:(UInt16) port;
+ (ProxyPacket *) introduceAckPacketToHost:(NSString *) host port:(UInt16) port;
+ (ProxyPacket *) introducePacket:(ProxyInfo *) receieverInfo;
+ (ProxyPacket *) introduceAckPacket:(ProxyInfo *) receieverInfo;
+ (ProxyPacket *) listProxyReqPacket;
- (PACKET_TYPE) packetType;
- (const void *) packetData;
- (NSUInteger) packetLength;
- (MacAddress *) srcMacAddress;
- (MacAddress *) dstMacAddress;
- (ProxyList *) proxyList;
- (ProxyInfo *) receiverProxyInfo;
@end

@interface NSMutableData (MutableProxyPacket)
+ (MutableProxyPacket *) proxyPacketWithType:(uint32_t) type andLength:(uint32_t) length;
- (void *) mutablePacketData;
@end