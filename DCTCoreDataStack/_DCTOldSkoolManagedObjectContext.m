//
//  _DCTOldSkoolManagedObjectContext.m
//  DCTCoreDataStack
//
//  Created by Daniel Tull on 24.07.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import "_DCTOldSkoolManagedObjectContext.h"

@implementation _DCTOldSkoolManagedObjectContext {
	__strong NSOperationQueue *_queue;
	__weak NSManagedObjectContext *_context;
}

- (void)dealloc {
	if (_context)
		[[NSNotificationCenter defaultCenter] removeObserver:self
														name:NSManagedObjectContextDidSaveNotification
													  object:self];
}

- (id)initWithParentContext:(NSManagedObjectContext *)context {
	self = [self init];
	if (!self) return nil;
	
	_context = context;
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(_didSaveNotification:)
												 name:NSManagedObjectContextDidSaveNotification
											   object:self];
	return self;
}

- (id)init {
	self = [super init];
	if (!self) return nil;
	_queue = [NSOperationQueue new];
	[_queue setMaxConcurrentOperationCount:1];
	return self;
}

- (void)_didSaveNotification:(NSNotification *)notification {
	[_context performBlock:^{
		[_context mergeChangesFromContextDidSaveNotification:notification];
	}];
}

- (void)performBlock:(void (^)())block {
	[_queue addOperationWithBlock:block];
}

@end
