//
//  _DCTSiblingManagedObjectContext.m
//  DCTManagedObjectContextSibling
//
//  Created by Daniel Tull on 02.08.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import "_DCTSiblingManagedObjectContext.h"
#import "NSManagedObjectContext+DCTCoreDataStack.h"

@interface _DCTSiblingManagedObjectContext ()
@property (nonatomic, weak) NSManagedObjectContext *originalContext;
@end

@implementation _DCTSiblingManagedObjectContext

- (id)initWithConcurrencyType:(NSManagedObjectContextConcurrencyType)concurrencyType
		 managedObjectContext:(NSManagedObjectContext *)context {

	self = [super initWithConcurrencyType:concurrencyType];
	if (!self) return nil;

	_originalContext = context;
	self.parentContext = _originalContext.parentContext;

	return self;
}

- (void)dct_saveWithCompletionHandler:(void (^)(BOOL, NSError *))completionHandler {

	NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
	[defaultCenter addObserver:self
					  selector:@selector(contextDidSaveNotification:)
						  name:NSManagedObjectContextDidSaveNotification
						object:self];

	[super dct_saveWithCompletionHandler:^(BOOL success, NSError *error) {

		[defaultCenter removeObserver:self
								 name:NSManagedObjectContextDidSaveNotification
							   object:self];

		if (completionHandler != NULL) completionHandler(success, error);
	}];
}

- (void)contextDidSaveNotification:(NSNotification *)notification {
	[self.originalContext performBlock:^{
		self.originalContext.mergePolicy = NSOverwriteMergePolicy;
		[self.originalContext mergeChangesFromContextDidSaveNotification:notification];
	}];
}

@end
