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
		
	if (completionHandler == NULL)
		completionHandler = ^(BOOL success, NSError *error){};
		
	BOOL hasParentContext = (self.parentContext != nil);
	
	NSManagedObjectContext *notifyContext = self.parentContext;
	if (!hasParentContext) notifyContext = self;
	
	NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
	[defaultCenter addObserver:self
					  selector:@selector(_contextDidSaveNotification:)
						  name:NSManagedObjectContextDidSaveNotification
						object:notifyContext];
	
	void (^removeObserver)() = ^{
		[defaultCenter removeObserver:self
								 name:NSManagedObjectContextDidSaveNotification
							   object:notifyContext];
	};
	
	[super dct_saveWithCompletionHandler:^(BOOL success, NSError *error) {
		
		if (!success || !hasParentContext) {
			completionHandler(success, error);
			removeObserver();
			return;
		}
		
		[self.parentContext performBlock:^{
			[self.parentContext dct_saveWithCompletionHandler:^(BOOL success, NSError *error) {
				completionHandler(success, error);
				removeObserver();
			}];
		}];
	}];
}

- (void)_contextDidSaveNotification:(NSNotification *)notification {
	[_originalContext performBlock:^{
		[_originalContext mergeChangesFromContextDidSaveNotification:notification];
	}];
}

@end
