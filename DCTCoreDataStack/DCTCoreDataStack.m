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

#import "DCTCoreDataStack+Private.h"
#import "_DCTCDSManagedObjectContext.h"
#import <objc/runtime.h>
#include <sys/xattr.h>

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

NSString *const DCTCoreDataStackExcludeFromBackupStoreOption = @"DCTCoreDataStackExcludeFromBackupStoreOption";

@interface DCTCoreDataStack ()
@property (nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, strong) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong) NSManagedObjectContext *rootContext;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@end

@implementation DCTCoreDataStack

#pragma mark - NSObject

#if TARGET_OS_IPHONE

- (void)dealloc {
	NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
	UIApplication *app = [UIApplication sharedApplication];
	[defaultCenter removeObserver:self
							 name:UIApplicationDidEnterBackgroundNotification
						   object:app];
	[defaultCenter removeObserver:self
							 name:UIApplicationWillTerminateNotification
						   object:app];
}

#endif

#pragma mark - Initialization

- (id)initWithStoreURL:(NSURL *)storeURL
			 storeType:(NSString *)storeType
		  storeOptions:(NSDictionary *)storeOptions
	modelConfiguration:(NSString *)modelConfiguration
			  modelURL:(NSURL *)modelURL {
	
	NSParameterAssert(storeType);

	self = [self init];
	if (!self) return nil;
	
	_storeURL = [storeURL copy];
	_storeType = [storeType copy];
	_storeOptions = [storeOptions copy];
	_modelURL = [modelURL copy];
	_modelConfiguration = [modelConfiguration copy];
	
	self.didResolvePersistentStoreErrorHandler = ^(NSError *error) {
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		abort();
		return NO;
	};
	
#if TARGET_OS_IPHONE
	
	UIApplication *app = [UIApplication sharedApplication];
	NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
	
	[defaultCenter addObserver:self
					  selector:@selector(applicationDidEnterBackgroundNotification:)
						  name:UIApplicationDidEnterBackgroundNotification
						object:app];
	
	[defaultCenter addObserver:self
					  selector:@selector(applicationWillTerminateNotification:)
						  name:UIApplicationWillTerminateNotification
						object:app];

#endif
	
	return self;
}

- (id)initWithStoreFilename:(NSString *)filename {
	NSURL *storeURL = [[[self class] applicationDocumentsDirectory] URLByAppendingPathComponent:filename];
	return [self initWithStoreURL:storeURL
						storeType:NSSQLiteStoreType
					 storeOptions:nil
			   modelConfiguration:nil
						 modelURL:nil];
}

#pragma mark - Getters

- (NSManagedObjectContext *)rootContext {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdirect-ivar-access"

	if (_rootContext == nil)
		[self loadRootContext];

	return _rootContext;
	
#pragma clang diagnostic pop
}

- (void)loadRootContext {
	NSManagedObjectContext *rootContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
	[rootContext setPersistentStoreCoordinator:self.persistentStoreCoordinator];
	rootContext.dct_name = @"DCTCoreDataStack.internal_rootContext";
	self.rootContext = rootContext;
}

- (NSManagedObjectContext *)managedObjectContext {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdirect-ivar-access"
	
	if (_managedObjectContext == nil)
		[self loadManagedObjectContext];

	return _managedObjectContext;
	
#pragma clang diagnostic pop
}

- (void)loadManagedObjectContext {
	_DCTCDSManagedObjectContext *managedObjectContext = [[_DCTCDSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
	[managedObjectContext setParentContext:self.rootContext];
	managedObjectContext.dct_name = @"DCTCoreDataStack.mainContext";
	self.managedObjectContext = managedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdirect-ivar-access"
	
	if (_managedObjectModel == nil)
		[self loadManagedObjectModel];
	
	return _managedObjectModel;
	
#pragma clang diagnostic pop
}

- (void)loadManagedObjectModel {

	NSManagedObjectModel *model;
    if (self.modelURL)
		model = [[NSManagedObjectModel alloc] initWithContentsOfURL:self.modelURL];
    else
		model = [NSManagedObjectModel mergedModelFromBundles:[NSArray arrayWithObject:[NSBundle mainBundle]]];

	self.managedObjectModel = model;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdirect-ivar-access"
	
	if (_persistentStoreCoordinator == nil)
		[self loadPersistentStoreCoordinator];
	
	return _persistentStoreCoordinator;
	
#pragma clang diagnostic pop
}

- (void)loadPersistentStoreCoordinator {
	self.persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
	[self loadPersistentStore:NULL];
}

@end

@implementation DCTCoreDataStack (Private)

- (void)loadPersistentStore:(void(^)(NSPersistentStore *persistentStore, NSError *error))completion {

	if (completion == NULL) {
		void(^wrapper)(NSPersistentStore *, NSError *) = ^(NSPersistentStore *store, NSError *error) {};
		completion = wrapper;
	}

	NSError *error;
	NSPersistentStore *persistentStore = [self.persistentStoreCoordinator addPersistentStoreWithType:self.storeType
																					   configuration:self.modelConfiguration
																								 URL:self.storeURL
																							 options:self.storeOptions
																							   error:&error];

	if (!persistentStore && self.didResolvePersistentStoreErrorHandler != NULL) {

		if (!self.didResolvePersistentStoreErrorHandler(error)) {
			completion(nil, error);
			return;
		}

		NSError *error2;
		persistentStore = [self.persistentStoreCoordinator addPersistentStoreWithType:self.storeType
																		configuration:self.modelConfiguration
																				  URL:self.storeURL
																			  options:self.storeOptions
																				error:&error2];
		if (!persistentStore) {
			completion(nil, error2);
			return;
		}
	}

	[self setupExcludeFromBackupFlag];
	completion(persistentStore, nil);
}

- (void)setupExcludeFromBackupFlag {

	BOOL storeIsReachable = [self.storeURL checkResourceIsReachableAndReturnError:NULL];
	if (!storeIsReachable) return;

	const char *filePath = [[self.storeURL path] fileSystemRepresentation];
	const char *attrName = "com.apple.MobileBackup";

	void (^removeAttribute)() = ^{
		// Remove attribute if it exists
		int result = getxattr(filePath, attrName, NULL, sizeof(u_int8_t), 0, 0);
		if (result != -1) removexattr(filePath, attrName, 0);
	};

	void (^addAttribute)() = ^{
		u_int8_t attrValue = 1;
		setxattr(filePath, attrName, &attrValue, sizeof(attrValue), 0, 0);
	};

	BOOL excludeFromBackup = [[self.storeOptions objectForKey:DCTCoreDataStackExcludeFromBackupStoreOption] boolValue];

	if (&NSURLIsExcludedFromBackupKey == NULL) { // iOS 5.0.x / 10.7.x or earlier

		if (excludeFromBackup)
			addAttribute();
		else
			removeAttribute();

	} else { // iOS 5.1 / OS X 10.8 and above

		// Remove attribute if it exists from an upgrade of an older version of iOS
		removeAttribute();

		[self.storeURL setResourceValue:@(excludeFromBackup) forKey:NSURLIsExcludedFromBackupKey error:NULL];
	}
}

+ (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

#pragma mark - Notifications

#if TARGET_OS_IPHONE

- (void)applicationDidEnterBackgroundNotification:(NSNotification *)notification {
	
	NSManagedObjectContext *context = self.managedObjectContext;
	
	if (![context hasChanges]) return;
	    
	[context performBlock:^{
		[context dct_saveWithCompletionHandler:self.automaticSaveCompletionHandler];
	}];
	
	// TODO: what if there was a save error?
}

- (void)applicationWillTerminateNotification:(NSNotification *)notification {
	
	NSManagedObjectContext *context = self.managedObjectContext;
	
	if (![context hasChanges]) return;
	
	__block BOOL success = NO;
	__block NSError *error = nil;
	
	[context performBlock:^{
		success = [context save:&error];
	}];
	
	if (self.automaticSaveCompletionHandler != NULL)
		self.automaticSaveCompletionHandler(success, error);
}

#endif

@end
