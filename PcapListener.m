//
//  PcapListener.m
//  objcPlayground
//
//  Created by Tim Wu on 7/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PcapListener.h"

static void handlePacket(u_char *_packetHandler, const struct pcap_pkthdr *h, const u_char *packet)
{
	id packetHandler = (id) _packetHandler;
	if ([packetHandler respondsToSelector:@selector(handleSniffedPacket:)])
		[packetHandler handleSniffedPacket:[NSData dataWithBytes:packet length:h->caplen]];
}

@implementation PcapListenerException
@end

@implementation PcapListener

+ (NSArray *) getAvailableInterfaces
{
	char errbuf[PCAP_ERRBUF_SIZE];
	NSMutableArray * interfaces = [NSMutableArray array];
	pcap_if_t *dev;
	
	if (pcap_findalldevs(&dev, errbuf)) {
		[PcapListenerException raise:@"ListInterfaceError" format:@"Failed to list interfaces: %s", errbuf];
	}
	
	for(pcap_if_t *devIter = dev; devIter; devIter = devIter->next) {
		[interfaces addObject:[NSString stringWithUTF8String:devIter->name]];
	}
	return interfaces;
}

- (id) initWithInterface:(NSString *) _interface withDelegate: (id) _delegate
{
	char errbuf[PCAP_ERRBUF_SIZE];
	if (self = [super init]) {
		listenInterface = _interface;
		delegate = _delegate;
		if (pcap_lookupnet([listenInterface UTF8String], &net, &mask, errbuf)) {
			NSLog(@"Failed to lookup interface netmask: %s", errbuf);
			return nil;
		}
		if (!(pcap = pcap_create([listenInterface UTF8String], errbuf))) {
			NSLog(@"Failed to create pcap descriptor: %s", errbuf);
			return nil;
		}
		if (pcap_set_promisc(pcap, 1)) {
			NSLog(@"Failed to set promiscuous mode.");
			return nil;
		}
		if (pcap_set_snaplen(pcap, SNAPLEN)) {
			NSLog(@"Failed to set pcap capture length.");
			return nil;
		}
		if (pcap_set_timeout(pcap, READ_TIMEOUT_MS)) {
			NSLog(@"Failed to set pcap timeout.");
			return nil;
		}
		if (pcap_activate(pcap)) {
			NSLog(@"Failed to activate pcap: %s", errbuf);
			return nil;
		}
		self.filter = @"";
		if (delegate) {
			pollThread = [[NSThread alloc] initWithTarget:self selector:@selector(packetLoop) object:nil];
			[pollThread start];
		}
	}
	return self;
}

- (id) initWithInterface:(NSString *) _interface withDelegate:(id) _delegate
			   AndFilter:(NSString *) _filter
{
	if (self = [self initWithInterface:_interface withDelegate:_delegate]) {
		self.filter = _filter;
	}
	return self;
}

- (int) inject: (NSData *) packet
{
	int bytesWritten = pcap_inject(pcap, [packet bytes], [packet length]);
	if (bytesWritten == -1) {
		[PcapListenerException raise:@"PcapInjectException" format:@"Failed to inject packet: %s", pcap_geterr(pcap)];
	}
	return bytesWritten;
}

@synthesize filter;
- (void) setFilter:(NSString *) _filter
{
	struct bpf_program filterProg;
	filter = _filter;

	if (pcap_compile(pcap, &filterProg, [filter UTF8String], 1, mask)) {
		[PcapListenerException raise:@"PcapCompileException" 
							   format:@"Failed to compile filter program: %@. Error %s", filter, pcap_geterr(pcap)];
	}
	if (pcap_setfilter(pcap, &filterProg)) {
		pcap_freecode(&filterProg);
		[PcapListenerException raise:@"PcapSetFilterException" format:@"Failed to set pcap filter: %s", pcap_geterr(pcap)];
	}
	pcap_freecode(&filterProg);
}

- (NSString *) description
{
	return [NSString stringWithFormat:@"PcapListener(%@) Filter: %@", listenInterface, filter];
}

- (void) close
{
	if (pollThread) {
		[pollThread cancel];
		pollThread = nil;
	}
	if (pcap) {
		pcap_close(pcap);
		pcap = NULL;
	}
}

- (void) finalize
{
	[self close];
	[super finalize];
}

- (void) packetLoop;
{
	while (![[NSThread currentThread] isCancelled]) {
		pcap_loop(pcap, TASK_PACKETS, handlePacket, (u_char *) delegate);
	}
}
@end
