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



@interface DCTCoreDataStack_ManagedObjectContext : NSManagedObjectContext
@end



typedef void (^DCTInternalCoreDataStackSaveBlock) (NSManagedObjectContext *managedObjectContext,
												   DCTManagedObjectContextSaveCompletionBlock completionHandler);

@interface DCTCoreDataStack ()

+ (NSURL *)dctInternal_applicationDocumentsDirectory;

#ifdef TARGET_OS_IPHONE
- (void)dctInternal_applicationDidEnterBackgroundNotification:(NSNotification *)notification;
- (void)dctInternal_applicationWillTerminateNotification:(NSNotification *)notification;
#endif

- (void)dctInternal_loadManagedObjectContext;
- (void)dctInternal_loadManagedObjectModel;
- (void)dctInternal_loadPersistentStoreCoordinator;

@property (nonatomic, readonly) NSPersistentStoreCoordinator *dctInternal_persistentStoreCoordinator;

@end

@implementation DCTCoreDataStack {
	__strong NSManagedObjectContext *managedObjectContext;
	__strong NSManagedObjectModel *managedObjectModel;
	__strong NSPersistentStoreCoordinator *persistentStoreCoordinator;
	__strong NSString *modelName;
	
	__strong NSManagedObjectContext *backgroundSavingContext;
}

@synthesize storeType;
@synthesize storeOptions;
@synthesize modelConfiguration;
@synthesize storeURL;
@synthesize modelName;
@synthesize persistentStoreErrorHandler;

#pragma mark - NSObject

- (void)dealloc {

#ifdef TARGET_OS_IPHONE
	UIApplication *app = [UIApplication sharedApplication];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self 
													name:UIApplicationDidEnterBackgroundNotification
												  object:app];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self 
													name:UIApplicationWillTerminateNotification
												  object:app];
	
#endif
}



#pragma mark - Initialization

- (id)initWithStoreURL:(NSURL *)URL
			 storeType:(NSString *)type
		  storeOptions:(NSDictionary *)options
	modelConfiguration:(NSString *)configuration
			 modelName:(NSString *)name {
	
	NSParameterAssert(URL);
	NSParameterAssert(type);
	
	if (!(self = [self init])) return nil;
	
	storeURL = [URL copy];
	storeType = [type copy];
	storeOptions = [options copy];
	modelName = [name copy];
	modelConfiguration = [configuration copy];
	
	self.persistentStoreErrorHandler = ^(NSError *error) {
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		abort();
	};
		
#ifdef TARGET_OS_IPHONE
	
	UIApplication *app = [UIApplication sharedApplication];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(dctInternal_applicationDidEnterBackgroundNotification:) 
												 name:UIApplicationDidEnterBackgroundNotification 
											   object:app];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(dctInternal_applicationWillTerminateNotification:) 
												 name:UIApplicationWillTerminateNotification
											   object:app];
#endif
	
	return self;
}

- (id)initWithStoreFilename:(NSString *)filename
				  storeType:(NSString *)type
               storeOptions:(NSDictionary *)options
		 modelConfiguration:(NSString *)configuration 
                  modelName:(NSString *)name {
	
	NSURL *URL = [[[self class] dctInternal_applicationDocumentsDirectory] URLByAppendingPathComponent:filename];
	return [self initWithStoreURL:URL storeType:type storeOptions:options modelConfiguration:configuration modelName:name];
}

- (id)initWithStoreFilename:(NSString *)filename {
	return [self initWithStoreFilename:filename storeType:NSSQLiteStoreType storeOptions:nil modelConfiguration:nil modelName:nil];
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

#pragma mark - Internal Loading

- (NSPersistentStoreCoordinator *)dctInternal_persistentStoreCoordinator {
	
	if (persistentStoreCoordinator == nil)
		[self dctInternal_loadPersistentStoreCoordinator];
	
	return persistentStoreCoordinator;
}

- (void)dctInternal_loadManagedObjectContext {
	
    NSPersistentStoreCoordinator *psc = self.dctInternal_persistentStoreCoordinator;
	
	if (psc == nil) return; // when would this ever happen?
	
	if ([NSManagedObjectContext instancesRespondToSelector:@selector(initWithConcurrencyType:)]) {
		
		backgroundSavingContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
		[backgroundSavingContext setPersistentStoreCoordinator:psc];
		backgroundSavingContext.dct_name = @"DCTCoreDataStack.backgroundSavingContext";
		
		managedObjectContext = [[DCTCoreDataStack_ManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
		[managedObjectContext setParentContext:backgroundSavingContext];
		managedObjectContext.dct_name = @"DCTCoreDataStack.managedObjectContext";
		
	} else {
		
		managedObjectContext = [[NSManagedObjectContext alloc] init];
		[managedObjectContext setPersistentStoreCoordinator:psc];
		managedObjectContext.dct_name = @"DCTCoreDataStack.managedObjectContext";
	}
}

- (void)dctInternal_loadManagedObjectModel {
	
    if (modelName) {
        NSURL *modelURL = [[NSBundle mainBundle] URLForResource:modelName withExtension:@"momd"];
        managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    } else {
        managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:[NSArray arrayWithObject:[NSBundle mainBundle]]];
    }
}

- (void)dctInternal_loadPersistentStoreCoordinator {
	
	persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
	
	NSError *error = nil;
	NSPersistentStore *persistentStore = [persistentStoreCoordinator addPersistentStoreWithType:self.storeType
																				  configuration:self.modelConfiguration
																							URL:self.storeURL
																						options:self.storeOptions
																						  error:&error];
	
	if (!persistentStore && self.persistentStoreErrorHandler) {
		self.persistentStoreErrorHandler(error);
		
		// Call again, because the failure block may have resolved the failure so we should try again
		[persistentStoreCoordinator addPersistentStoreWithType:self.storeType
												 configuration:self.modelConfiguration
														   URL:self.storeURL
													   options:self.storeOptions
														 error:NULL];
	}
}

#pragma mark - Other Internal

+ (NSURL *)dctInternal_applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

#ifdef TARGET_OS_IPHONE
- (void)dctInternal_applicationDidEnterBackgroundNotification:(NSNotification *)notification {
	
	if (![self.managedObjectContext hasChanges]) return;
	
	if ([self.managedObjectContext respondsToSelector:@selector(performBlock:)]) {
	
		[self.managedObjectContext performBlock:^{
			[self.managedObjectContext dct_saveWithCompletionHandler:NULL];
		}];

	} else {
		
		[self.managedObjectContext dct_saveWithCompletionHandler:NULL];
	}
	
	// TODO: what if there was a save error?
}

- (void)dctInternal_applicationWillTerminateNotification:(NSNotification *)notification {
	
	if (![self.managedObjectContext hasChanges]) return;
	
	if ([self.managedObjectContext respondsToSelector:@selector(performBlock:)]) {
		
		[self.managedObjectContext performBlock:^{
			[self.managedObjectContext save:nil];
		}];
		
	} else {
		
		[self.managedObjectContext save:nil];
	}
}
#endif

@end

@implementation DCTCoreDataStack_ManagedObjectContext

- (BOOL)save:(NSError **)error {
	
	id object = objc_getAssociatedObject(self, @selector(dct_saveWithCompletionHandler:));
	
	if (object) return [super save:error];
	
	__block BOOL success = [super save:error];
	
	if (success) {
		
		NSManagedObjectContext *parent = self.parentContext;
		
		[parent performBlockAndWait:^{
			success = [parent save:error];
		}];
	}
	
	return success;
}

- (void)dct_saveWithCompletionHandler:(DCTManagedObjectContextSaveCompletionBlock)clientCompletion {
	
	dispatch_queue_t queue = dispatch_get_current_queue();
	
	NSManagedObjectContext *parent = self.parentContext;
	
#ifdef TARGET_OS_IPHONE
	UIBackgroundTaskIdentifier backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:NULL];
#endif
	
	DCTManagedObjectContextSaveCompletionBlock completion = ^(BOOL success, NSError *error) {
		
		dispatch_async(queue, ^{
			
			if (clientCompletion != NULL)
				clientCompletion(success, error);

#ifdef TARGET_OS_IPHONE
			[[UIApplication sharedApplication] endBackgroundTask:backgroundTaskIdentifier];
#endif
			
		});
	};
	
	// Put anything in this association to switch on save:
	objc_setAssociatedObject(self, _cmd, [NSNull null], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	
	[super dct_saveWithCompletionHandler:^(BOOL success, NSError *error) {
		
		// Clear the association after the save
		objc_setAssociatedObject(self, _cmd, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
		
		if (!success) {
			completion(success, error);
			return;
		}
		
		[parent performBlock:^{
			[parent dct_saveWithCompletionHandler:completion];
		}];
		
	}];
}

@end
