//
//  _DCTSiblingManagedObjectContext.m
//  DCTManagedObjectContextSibling
//
//  Created by Daniel Tull on 02.08.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import "_DCTSiblingManagedObjectContext.h"
#import "NSManagedObjectContext+DCTCoreDataStack.h"

@implementation _DCTSiblingManagedObjectContext {
	__weak NSManagedObjectContext *_originalContext;
}

- (id)initWithConcurrencyType:(NSManagedObjectContextConcurrencyType)concurrencyType
		 managedObjectContext:(NSManagedObjectContext *)context {

	self = [super initWithConcurrencyType:concurrencyType];
	if (!self) return nil;

	_originalContext = context;

	if (_originalContext.parentContext)
		self.parentContext = _originalContext.parentContext;
	else
		self.persistentStoreCoordinator = _originalContext.persistentStoreCoordinator;

	return self;
}

- (void)dct_saveWithCompletionHandler:(void (^)(BOOL, NSError *))completionHandler {

	NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
	[defaultCenter addObserver:self
					  selector:@selector(_contextDidSaveNotification:)
						  name:NSManagedObjectContextDidSaveNotification
						object:self];

	[super dct_saveWithCompletionHandler:^(BOOL success, NSError *error) {

		[defaultCenter removeObserver:self
								 name:NSManagedObjectContextDidSaveNotification
							   object:self];

		if (completionHandler != NULL) completionHandler(success, error);
	}];
}

- (void)_contextDidSaveNotification:(NSNotification *)notification {
	[_originalContext performBlock:^{
		_originalContext.mergePolicy = NSOverwriteMergePolicy;
		[_originalContext mergeChangesFromContextDidSaveNotification:notification];
	}];
}

@end
