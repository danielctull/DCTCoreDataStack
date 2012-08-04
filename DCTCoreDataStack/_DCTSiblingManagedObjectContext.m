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

	NSSet *deletedObjectIDs = [self _objectIDsFromManagedObjects:[self deletedObjects]];
	NSSet *insertedObjectIDs = [self _objectIDsFromManagedObjects:[self insertedObjects]];
	NSSet *updatedObjectIDs = [self _objectIDsFromManagedObjects:[self updatedObjects]];

	[super dct_saveWithCompletionHandler:^(BOOL success, NSError *error) {

		[_originalContext performBlock:^{

			[deletedObjectIDs enumerateObjectsUsingBlock:^(NSManagedObjectID *objectID, BOOL *stop) {
				[_originalContext deleteObject:[_originalContext objectWithID:objectID]];
			}];

			[updatedObjectIDs enumerateObjectsUsingBlock:^(NSManagedObjectID *objectID, BOOL *stop) {
				NSManagedObject *managedObject = [_originalContext objectWithID:objectID];
				[managedObject willAccessValueForKey:nil];
				[_originalContext refreshObject:managedObject mergeChanges:YES];

			}];

			[insertedObjectIDs enumerateObjectsUsingBlock:^(NSManagedObjectID *objectID, BOOL *stop) {
				NSManagedObject *managedObject = [_originalContext objectWithID:objectID];
				[managedObject willAccessValueForKey:nil];
				[_originalContext insertObject:managedObject];
			}];

			if (completionHandler != NULL)
				completionHandler(success, error);
		}];
	}];
}

- (NSSet *)_objectIDsFromManagedObjects:(NSSet *)managedObjects {
	NSMutableSet *objectIDs = [[NSMutableSet alloc] initWithCapacity:[managedObjects count]];
	[managedObjects enumerateObjectsUsingBlock:^(NSManagedObject *managedObject, BOOL *stop) {
		[objectIDs addObject:[managedObject objectID]];
	}];
	return [objectIDs copy];
}

@end
