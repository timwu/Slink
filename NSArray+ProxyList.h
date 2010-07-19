//
//  NSArray+ProxyList.h
//  Slink
//
//  Created by Tim Wu on 7/18/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef NSArray ProxyList;
typedef NSMutableArray MutableProxyList;

#import "NSData+ProxyPacket.h"
#import "ProxyInfo.h"

@interface NSArray (ProxyList)
+ (ProxyList *) proxyListWithPacket:(ProxyPacket *) packet;
- (id) filteredProxyListForHost:(NSString *) host port:(UInt16) port;
- (ProxyPacket *) proxyListPacket;
@end

@interface NSMutableArray (MutableProxyList)
- (void) addProxyAtHost:(NSString *) host port:(UInt16) port;
@end