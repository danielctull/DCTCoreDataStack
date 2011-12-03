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
#import "NSManagedObjectContext+DCTCoreDataStack.h"
#import <objc/runtime.h>

typedef void (^DCTInternalCoreDataStackSaveBlock) (NSManagedObjectContext *managedObjectContext, 
												   dispatch_queue_t callbackQueue,
												   DCTManagedObjectContextSaveErrorBlock failureHandler);

@interface DCTCoreDataStack ()
- (NSURL *)dctInternal_applicationDocumentsDirectory;

- (void)dctInternal_iOS5mainContextDidSave:(NSNotification *)notification;

- (void)dctInternal_applicationDidEnterBackgroundNotification:(NSNotification *)notification;

- (void)dctInternal_loadModelURL;
- (void)dctInternal_loadStoreURL;
- (void)dctInternal_loadManagedObjectContext;
- (void)dctInternal_loadPersistentStoreCoordinator;
- (void)dctInternal_loadManagedObjectModel;
@end

@implementation DCTCoreDataStack {
	__strong NSManagedObjectContext *managedObjectContext;
	__strong NSManagedObjectModel *managedObjectModel;
	__strong NSPersistentStoreCoordinator *persistentStoreCoordinator;
	__strong NSString *modelName;
	
	__strong NSManagedObjectContext *backgroundSavingContext;
	
	__strong DCTInternalCoreDataStackSaveBlock saveBlock;
}

@synthesize persistentStoreType;
@synthesize persistentStoreOptions;
@synthesize modelConfiguration;
@synthesize modelURL;
@synthesize storeURL;

#pragma mark - NSObject

- (void)dealloc {
	if (backgroundSavingContext != nil)
		[[NSNotificationCenter defaultCenter] removeObserver:self 
														name:NSManagedObjectContextDidSaveNotification
													  object:managedObjectContext];
}

- (id)init {
	
	if (!(self = [super init])) return nil;
	
	self.persistentStoreType = NSSQLiteStoreType;
	
	if(UIApplicationDidEnterBackgroundNotification != NULL)
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(dctInternal_applicationDidEnterBackgroundNotification:) 
													 name:UIApplicationDidEnterBackgroundNotification 
												   object:nil];
	
	saveBlock = ^(NSManagedObjectContext *context, dispatch_queue_t callbackQueue, DCTManagedObjectContextSaveErrorBlock failureHandler) {
		NSError *error = nil;
		if (![context save:&error] && failureHandler != NULL) {
			dispatch_async(callbackQueue, ^{
				failureHandler(error);
			});
		}
	};
	
	if ([[NSManagedObjectContext class] instancesRespondToSelector:@selector(performBlock:)]) {
		
		DCTInternalCoreDataStackSaveBlock oldSaveBlock = [saveBlock copy];
		
		saveBlock = ^(NSManagedObjectContext *context, dispatch_queue_t callbackQueue, DCTManagedObjectContextSaveErrorBlock failureHandler) {
			[context performBlock:^{
				oldSaveBlock(context, callbackQueue, failureHandler);
			}];
		};
	}
	
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
    
	if (managedObjectContext == nil)
		[self dctInternal_loadManagedObjectContext];
	
    return managedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel {
		
	if (managedObjectModel == nil)
		[self dctInternal_loadManagedObjectModel];
	
	return managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
	
    if (persistentStoreCoordinator == nil)
		[self dctInternal_loadPersistentStoreCoordinator];
	
	return persistentStoreCoordinator;
}

- (NSURL *)modelURL {
	
	if (modelURL == nil)
		[self dctInternal_loadModelURL];
	
	return modelURL;
}

- (NSURL *)storeURL {
	
	if (storeURL == nil)
		[self dctInternal_loadStoreURL];
	
	return storeURL;
}

#pragma mark - Internal Loading

- (void)dctInternal_loadManagedObjectContext {
	
	NSPersistentStoreCoordinator *psc = self.persistentStoreCoordinator;
	
	if (psc == nil) return;
	
	if ([NSManagedObjectContext instancesRespondToSelector:@selector(initWithConcurrencyType:)]) {
		
		backgroundSavingContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
		[backgroundSavingContext setPersistentStoreCoordinator:psc];
		backgroundSavingContext.dct_name = @"DCTCoreDataStack.backgroundSavingContext";
		
		managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
		[managedObjectContext setParentContext:backgroundSavingContext];
		managedObjectContext.dct_name = @"DCTCoreDataStack.managedObjectContext";
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(dctInternal_iOS5mainContextDidSave:)
													 name:NSManagedObjectContextDidSaveNotification
												   object:managedObjectContext];
	} else {
		
		managedObjectContext = [[NSManagedObjectContext alloc] init];
		[managedObjectContext setPersistentStoreCoordinator:psc];
		managedObjectContext.dct_name = @"DCTCoreDataStack.managedObjectContext";
	}
}

- (void)dctInternal_loadManagedObjectModel {
	managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:self.modelURL];
}

- (void)dctInternal_loadPersistentStoreCoordinator {
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

- (void)dctInternal_loadModelURL {
	modelURL = [[NSBundle mainBundle] URLForResource:modelName withExtension:@"momd"];
}

- (void)dctInternal_loadStoreURL {
	NSString *pathComponent = nil;
	
	if ([self.persistentStoreType isEqualToString:NSBinaryStoreType])
		pathComponent = [NSString stringWithFormat:@"%@.sqlite", modelName];
	
	else if ([self.persistentStoreType isEqualToString:NSSQLiteStoreType])
		pathComponent = [NSString stringWithFormat:@"%@.sqlite", modelName];
	
	if (pathComponent) 
		storeURL = [[self dctInternal_applicationDocumentsDirectory] URLByAppendingPathComponent:pathComponent];
}

#pragma mark - Other Internal

- (void)dctInternal_iOS5mainContextDidSave:(NSNotification *)notification; {
	
	NSManagedObjectContext *moc = [notification object];
	DCTManagedObjectContextSaveErrorBlock handler = objc_getAssociatedObject(moc, @selector(dct_saveWithErrorHandler:));
	
	saveBlock(backgroundSavingContext, dispatch_get_current_queue(), handler);
}

- (NSURL *)dctInternal_applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (void)dctInternal_applicationDidEnterBackgroundNotification:(NSNotification *)notification {
	saveBlock(self.managedObjectContext, dispatch_get_current_queue(), NULL);
}

@end
