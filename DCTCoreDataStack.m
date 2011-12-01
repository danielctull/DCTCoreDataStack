//
//  DCTCoreDataStack.m
//  Convene
//
//  Created by Daniel Tull on 01.12.2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "DCTCoreDataStack.h"

@interface DCTCoreDataStack ()
- (NSURL *)dctInternal_applicationDocumentsDirectory;
- (void)dctInternal_mainContextDidSave:(NSNotification *)notification;
- (void)dctInternal_saveManagedObjectContext:(NSManagedObjectContext *)context;
@end

@implementation DCTCoreDataStack {
	__strong NSManagedObjectContext *managedObjectContext;
	__strong NSManagedObjectModel *managedObjectModel;
	__strong NSPersistentStoreCoordinator *persistentStoreCoordinator;
	__strong NSString *modelName;
	__strong NSManagedObjectContext *backgroundSavingContext;
}

@synthesize persistentStoreType;
@synthesize persistentStoreOptions;
@synthesize modelConfiguration;
@synthesize modelURL;
@synthesize storeURL;

#pragma mark - NSObject

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self 
													name:NSManagedObjectContextDidSaveNotification
												  object:managedObjectContext];
}

- (id)init {
	
	if (!(self = [super init])) return nil;
	
	self.persistentStoreType = NSSQLiteStoreType;
	
	return self;
}

#pragma mark - DCTCoreDataStack

- (id)initWithModelName:(NSString *)name {
	
	if (!(self = [self init])) return nil;
	
	modelName = [name copy];
	
	return self;
}

#pragma mark - Getters

- (NSManagedObjectContext *)managedObjectContext {
    
	if (managedObjectContext == nil) {
		
		NSPersistentStoreCoordinator *coordinator = self.persistentStoreCoordinator;
		if (coordinator != nil) {
			
			backgroundSavingContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
			[backgroundSavingContext setPersistentStoreCoordinator:coordinator];
			
			managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
			[managedObjectContext setParentContext:backgroundSavingContext];
			
			[[NSNotificationCenter defaultCenter] addObserver:self 
													 selector:@selector(dctInternal_mainContextDidSave:)
														 name:NSManagedObjectContextDidSaveNotification
													   object:managedObjectContext];
		}
	}
	
    return managedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel {
		
	if (managedObjectModel == nil)
		managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:self.modelURL];
	
	return managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
	
    if (persistentStoreCoordinator == nil) {
		
		NSError *error = nil;
		persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
		if (![persistentStoreCoordinator addPersistentStoreWithType:self.persistentStoreType
													  configuration:self.modelConfiguration
																URL:self.storeURL
															options:self.persistentStoreOptions
															  error:&error]) {
			NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
			abort();
		}
    }
	
	return persistentStoreCoordinator;
}

- (NSURL *)modelURL {
	
	if (!modelURL) modelURL = [[NSBundle mainBundle] URLForResource:modelName withExtension:@"momd"];
	
	return modelURL;
}

- (NSURL *)storeURL {
	
	if (!storeURL) {
		NSString *pathComponent = nil;
		
		if ([self.persistentStoreType isEqualToString:NSBinaryStoreType])
			pathComponent = [NSString stringWithFormat:@"%@.sqlite", modelName];
		
		else if ([self.persistentStoreType isEqualToString:NSSQLiteStoreType])
			pathComponent = [NSString stringWithFormat:@"%@.sqlite", modelName];
		
		if (pathComponent) 
			storeURL = [[self dctInternal_applicationDocumentsDirectory] URLByAppendingPathComponent:pathComponent];
	}
	
	return storeURL;
}

#pragma mark - Internal

- (void)dctInternal_saveManagedObjectContext:(NSManagedObjectContext *)context {
	[context performBlock:^{
		NSError *error = nil;
		if (![context save:&error])
			NSLog(@"%@:%@ %@", self, NSStringFromSelector(_cmd), error);
	}];
}

- (void)dctInternal_mainContextDidSave:(NSNotification *)notification {
	[self dctInternal_saveManagedObjectContext:backgroundSavingContext];
}

- (NSURL *)dctInternal_applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
