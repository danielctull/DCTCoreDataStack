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
												   DCTManagedObjectContextSaveCompletionBlock completionHandler);

@interface DCTCoreDataStack ()

- (NSURL *)dctInternal_applicationDocumentsDirectory;

- (void)dctInternal_iOS5mainContextDidSave:(NSNotification *)notification;

- (void)dctInternal_applicationDidEnterBackgroundNotification:(NSNotification *)notification;
- (void)dctInternal_applicationWillTerminateNotification:(NSNotification *)notification;

- (void)dctInternal_loadManagedObjectContext;
- (void)dctInternal_loadManagedObjectModel;
@end

@implementation DCTCoreDataStack {
	__strong NSManagedObjectContext *managedObjectContext;
	__strong NSManagedObjectModel *managedObjectModel;
	__strong NSString *modelName;
	
	__strong NSManagedObjectContext *backgroundSavingContext;
	
	__strong DCTInternalCoreDataStackSaveBlock saveBlock;
}

@synthesize persistentStoreType = persistentStoreType;
@synthesize persistentStoreOptions = persistentStoreOptions;
@synthesize modelConfiguration = modelConfiguration;
@synthesize storeURL;

#pragma mark - NSObject

- (void)dealloc {
	if (backgroundSavingContext != nil)
		[[NSNotificationCenter defaultCenter] removeObserver:self 
														name:NSManagedObjectContextDidSaveNotification
													  object:managedObjectContext];
#ifdef TARGET_OS_IPHONE
	[[NSNotificationCenter defaultCenter] removeObserver:self 
													name:UIApplicationDidEnterBackgroundNotification
												  object:nil];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self 
													name:UIApplicationWillTerminateNotification
												  object:nil];
#endif
}



#pragma mark - Initialization

- (id)initWithStoreFilename:(NSString *)filename
                       type:(NSString *)storeType
         modelConfiguration:(NSString *)configuration
               storeOptions:(NSDictionary *)storeOptions
                  modelName:(NSString *)aModelName;
{
    NSParameterAssert(storeType);
    
    if (!(self = [self init])) return nil;
	
    
	modelName = [aModelName copy];
    persistentStoreType = [storeType copy];
    modelConfiguration = [configuration copy];
    persistentStoreOptions = [storeOptions copy];
    
    
    storeURL = [[self dctInternal_applicationDocumentsDirectory] URLByAppendingPathComponent:filename];
    
	
#ifdef TARGET_OS_IPHONE
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(dctInternal_applicationDidEnterBackgroundNotification:) 
												 name:UIApplicationDidEnterBackgroundNotification 
											   object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(dctInternal_applicationWillTerminateNotification:) 
												 name:UIApplicationWillTerminateNotification
											   object:nil];
#endif
	
	if ([[NSManagedObjectContext class] instancesRespondToSelector:@selector(performBlock:)]) {
		
		saveBlock = ^(NSManagedObjectContext *context,
					  DCTManagedObjectContextSaveCompletionBlock completion) {
			[context performBlock:^{
				[context dct_saveWithCompletionHandler:completion];
			}];
		};
		
	} else{
		
		saveBlock = ^(NSManagedObjectContext *context,
					  DCTManagedObjectContextSaveCompletionBlock completion) {
			[context dct_saveWithCompletionHandler:completion];
		};
		
	}
	
    return self;
}

- (id)initWithStoreFilename:(NSString *)filename {
	return [self initWithStoreFilename:filename type:NSSQLiteStoreType modelConfiguration:nil storeOptions:nil modelName:nil];
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

- (void)dctInternal_loadManagedObjectContext {
	
	NSError *error = nil;
	NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
	if (![psc addPersistentStoreWithType:self.persistentStoreType
												  configuration:self.modelConfiguration
															URL:self.storeURL
														options:self.persistentStoreOptions
														  error:&error]) {
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		abort();
	}
    
	
	if (psc == nil) return; // when would this ever happen?
	
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
	
    if (modelName) {
        NSURL *modelURL = [[NSBundle mainBundle] URLForResource:modelName withExtension:@"momd"];
        managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    } else {
        managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:[NSArray arrayWithObject:[NSBundle mainBundle]]];
    }
}

#pragma mark - Other Internal

- (void)dctInternal_iOS5mainContextDidSave:(NSNotification *)notification; {
	NSManagedObjectContext *moc = [notification object];
	
	DCTManagedObjectContextSaveCompletionBlock completion = objc_getAssociatedObject(moc, @selector(dct_saveWithCompletionHandler:));
	objc_setAssociatedObject(moc, @selector(dct_saveWithCompletionHandler:), nil, OBJC_ASSOCIATION_COPY_NONATOMIC);
	
	saveBlock(backgroundSavingContext, completion);
}

- (NSURL *)dctInternal_applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (void)dctInternal_applicationDidEnterBackgroundNotification:(NSNotification *)notification {
	saveBlock(self.managedObjectContext, NULL);
}

- (void)dctInternal_applicationWillTerminateNotification:(NSNotification *)notification {
	saveBlock(self.managedObjectContext, NULL);
}

@end
