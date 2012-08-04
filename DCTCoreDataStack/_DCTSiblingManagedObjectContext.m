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

	
	NSSet *deletedObjects = [self deletedObjects];
	NSSet *insertedObjects = [self insertedObjects];
	NSSet *updatedObjects = [self updatedObjects];
	
	updatedObjects = [updatedObjects setByAddingObjectsFromSet:insertedObjects];
	updatedObjects = [updatedObjects setByAddingObjectsFromSet:deletedObjects];
	
	NSLog(@"insertedObjects: %@", insertedObjects);
	NSLog(@"deletedObjects: %@", deletedObjects);
	NSLog(@"updatedObjects %@", updatedObjects);
	
	NSMutableSet *updatedObjectIDs = [[NSMutableSet alloc] initWithCapacity:[updatedObjects count]];
	[updatedObjects enumerateObjectsUsingBlock:^(NSManagedObject *mo, BOOL *stop) {
		[updatedObjectIDs addObject:[mo objectID]];
	}];
	
	[super dct_saveWithCompletionHandler:^(BOOL success, NSError *error) {
		
		[_originalContext performBlock:^{
			
			[updatedObjectIDs enumerateObjectsUsingBlock:^(NSManagedObjectID *objectID, BOOL *stop) {
				NSManagedObject *object = [_originalContext objectWithID:objectID];
				[_originalContext refreshObject:object mergeChanges:YES];
				[object willAccessValueForKey:nil];
				NSLog(@"refreshing: %@", object);
			}];
			
			[_originalContext mergeChangesFromContextDidSaveNotification:nil];
			
			[_originalContext dct_saveWithCompletionHandler:^(BOOL success, NSError *error) {
				if (completionHandler != NULL)
					completionHandler(success, error);
			}];
		}];
	}];
}

@end
