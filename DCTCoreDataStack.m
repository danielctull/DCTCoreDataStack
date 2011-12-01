/*
 DCTCoreDataStack.m
 DCTCoreDataStack
 
 Created by Daniel Tull on 01.12.2011.
 
 
 
 Copyright (c) 2011 Daniel Tull. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.
 
 * Neither the name of the author nor the names of its contributors may be used
 to endorse or promote products derived from this software without specific
 prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

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
