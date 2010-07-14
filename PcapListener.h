//
//  PcapListener.h
//  objcPlayground
//
//  Created by Tim Wu on 7/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <pcap.h>

#define READ_TIMEOUT_MS 10
#define SNAPLEN 64 * 1024
#define TASK_PACKETS 1

@interface NSObject (HandlePcapPacket)
- (void) handleSniffedPacket:(NSData *) packet;
@end

@interface PcapListenerException : NSException
{
}
@end

/*!
    @class
    @abstract    Simple class to listen on an interface for packets.
*/
@interface PcapListener : NSObject {
	pcap_t * pcap;
	bpf_u_int32 net, mask;
	NSString * listenInterface;
	NSString * filter;
	NSThread * pollThread;
	id delegate;
}

+ (NSArray *) getAvailableInterfaces;
// Initializers
- (id) initWithInterface:(NSString *) _interface withDelegate:(id) _delegate;
- (id) initWithInterface:(NSString *) _interface withDelegate:(id) _delegate
			   AndFilter:(NSString *) _filter;

- (int) inject: (NSData *) packet;

// Getters and setters
- (void) setFilter:(NSString *) _filter;

// Lifecyle methods
- (void) close;

// Internal methods
- (void) packetLoop;
@end
