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
#import "_DCTCDSManagedObjectContext.h"
@import ObjectiveC.runtime;
#include <sys/xattr.h>

extern const struct DCTCoreDataStackProperties {
	__unsafe_unretained NSString *storeURL;
	__unsafe_unretained NSString *storeType;
	__unsafe_unretained NSString *storeOptions;
	__unsafe_unretained NSString *modelConfiguration;
	__unsafe_unretained NSString *modelURL;
} DCTCoreDataStackProperties;

const struct DCTCoreDataStackProperties DCTCoreDataStackProperties = {
	.storeURL = @"storeURL",
	.storeType = @"storeType",
	.storeOptions = @"storeOptions",
	.modelConfiguration = @"modelConfiguration",
	.modelURL = @"modelURL"
};

NSString *const DCTCoreDataStackExcludeFromBackupStoreOption = @"DCTCoreDataStackExcludeFromBackupStoreOption";

@interface DCTCoreDataStack ()
@property (nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic) NSManagedObjectModel *managedObjectModel;
@property (nonatomic) NSManagedObjectContext *rootContext;
@property (nonatomic) NSManagedObjectContext *managedObjectContext;
@property (nonatomic) dispatch_queue_t queue;
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
	_queue = dispatch_queue_create("DCTCoreDataStack", DISPATCH_QUEUE_SERIAL);
	
#if TARGET_OS_IPHONE

	NSString *identifier = [[NSUUID UUID] UUIDString];
	[UIApplication registerObjectForStateRestoration:self restorationIdentifier:identifier];

	UIApplication *app = [UIApplication sharedApplication];
	NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
	
	[defaultCenter addObserver:self
					  selector:@selector(_applicationDidEnterBackgroundNotification:)
						  name:UIApplicationDidEnterBackgroundNotification
						object:app];
	
	[defaultCenter addObserver:self
					  selector:@selector(_applicationWillTerminateNotification:)
						  name:UIApplicationWillTerminateNotification
						object:app];

#endif
	
	return self;
}

- (id)initWithStoreFilename:(NSString *)filename {
	NSURL *storeURL = [[[self class] _applicationDocumentsDirectory] URLByAppendingPathComponent:filename];
	return [self initWithStoreURL:storeURL
						storeType:NSSQLiteStoreType
					 storeOptions:nil
			   modelConfiguration:nil
						 modelURL:nil];
}

#pragma mark - Getters

- (NSManagedObjectContext *)managedObjectContext {
	
	__block NSManagedObjectContext *managedObjectContext;
	dispatch_sync(self.queue, ^{

		if (self->_managedObjectContext == nil) {
			self->_managedObjectContext = [[_DCTCDSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
			[self->_managedObjectContext setParentContext:self.rootContext];
			self->_managedObjectContext.dct_name = @"DCTCoreDataStack.mainContext";
		}

		managedObjectContext = self->_managedObjectContext;
	});

    return managedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel {
	
	if (_managedObjectModel == nil)
		[self _loadManagedObjectModel];
	
	return _managedObjectModel;
}

#pragma mark - Internal Loading

- (NSManagedObjectContext *)rootContext {
	
	if (!_rootContext) {
		_rootContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
		[_rootContext setPersistentStoreCoordinator:self.persistentStoreCoordinator];
		_rootContext.dct_name = @"DCTCoreDataStack.internal_rootContext";
	}
	
	return _rootContext;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
	
	if (_persistentStoreCoordinator != nil)
		return _persistentStoreCoordinator;

	// This forces all threads that reach this
	// code to be processed in an ordered manner on the main thread.  The first
	// one will initialize the data, and the rest will just return with that
	// data.  However, it ensures the creation is not attempted multiple times.
	// from http://stackoverflow.com/questions/10388724/random-exc-bad-access-with-persistentstorecoordinator
	if (![NSThread currentThread].isMainThread) {
		dispatch_sync(dispatch_get_main_queue(), ^{
		(void)[self persistentStoreCoordinator];
	});
	return _persistentStoreCoordinator;
	}

	[self _loadPersistentStoreCoordinator];
	
	return _persistentStoreCoordinator;
}

- (void)_loadManagedObjectModel {

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdirect-ivar-access"

	if (self.modelURL)
		_managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:self.modelURL];
    else
		_managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:[NSArray arrayWithObject:[NSBundle mainBundle]]];

#pragma clang diagnostic pop
}

- (void)_loadPersistentStoreCoordinator {

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdirect-ivar-access"

	_persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
	
	NSError *error = nil;
	NSPersistentStore *persistentStore = [_persistentStoreCoordinator addPersistentStoreWithType:self.storeType
																				   configuration:self.modelConfiguration
																							 URL:self.storeURL
																						 options:self.storeOptions
																						   error:&error];
	
	if (!persistentStore && [self retryAfterPersistentStoreFailure:error])
		[_persistentStoreCoordinator addPersistentStoreWithType:self.storeType
												  configuration:self.modelConfiguration
															URL:self.storeURL
														options:self.storeOptions
														  error:NULL];
	
	[self _setupExcludeFromBackupFlag];

#pragma clang diagnostic pop
}

#pragma mark - Other Internal

- (void)_setupExcludeFromBackupFlag {

	BOOL storeIsReachable = [self.storeURL checkResourceIsReachableAndReturnError:NULL];
	if (!storeIsReachable) return;

	const char *filePath = [[self.storeURL path] fileSystemRepresentation];
	const char *attrName = "com.apple.MobileBackup";

	void (^removeAttribute)() = ^{
		// Remove attribute if it exists
		ssize_t result = getxattr(filePath, attrName, NULL, sizeof(u_int8_t), 0, 0);
		if (result != -1) removexattr(filePath, attrName, 0);
	};
	
	BOOL excludeFromBackup = [[self.storeOptions objectForKey:DCTCoreDataStackExcludeFromBackupStoreOption] boolValue];
	
	if (&NSURLIsExcludedFromBackupKey == NULL) { // iOS 5.0.x / 10.7.x or earlier


#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunreachable-code"
// Warning claims it's unreachable, not sure if that's true.

		if (excludeFromBackup) {
            u_int8_t attrValue = 1;
            setxattr(filePath, attrName, &attrValue, sizeof(attrValue), 0, 0);
        } else {
			removeAttribute();
        }

#pragma clang diagnostic pop
		
	} else { // iOS 5.1 / OS X 10.8 and above

		// Remove attribute if it exists from an upgrade of an older version of iOS
		removeAttribute();

		[self.storeURL setResourceValue:@(excludeFromBackup) forKey:NSURLIsExcludedFromBackupKey error:NULL];
	}
}

+ (NSURL *)_applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

#if TARGET_OS_IPHONE

- (void)_applicationDidEnterBackgroundNotification:(NSNotification *)notification {
	
	NSManagedObjectContext *context = self.managedObjectContext;
	
	if (![context hasChanges]) return;
	    
	[context performBlock:^{
		[context dct_saveWithCompletionHandler:^(BOOL success, NSError *error) {
			[self didAutomaticallySaveWithSuccess:success error:error];
		}];
	}];
	
	// TODO: what if there was a save error?
}

- (void)_applicationWillTerminateNotification:(NSNotification *)notification {
	
	NSManagedObjectContext *context = self.managedObjectContext;
	
	if (![context hasChanges]) return;
	
	__block BOOL success = NO;
	__block NSError *error = nil;
	
	[context performBlock:^{
		success = [context save:&error];
	}];

	[self didAutomaticallySaveWithSuccess:success error:error];
}

- (void)didAutomaticallySaveWithSuccess:(BOOL)success error:(NSError *)error {

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	if (self.automaticSaveCompletionHandler != NULL)
		self.automaticSaveCompletionHandler(success, error);
#pragma clang diagnostic pop

	if ([self.delegate respondsToSelector:@selector(coreDataStack:didAutomaticallySaveWithSuccess:error:)])
		[self.delegate coreDataStack:self didAutomaticallySaveWithSuccess:success error:error];
}

#endif

- (BOOL)retryAfterPersistentStoreFailure:(NSError *)error {

	if ([self.delegate respondsToSelector:@selector(coreDataStack:retryAfterPersistentStoreFailure:)])
		return [self.delegate coreDataStack:self retryAfterPersistentStoreFailure:error];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	if (self.didResolvePersistentStoreErrorHandler)
		return self.didResolvePersistentStoreErrorHandler(error);
#pragma clang diagnostic pop

	NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	abort();
	return NO;
}


#if TARGET_OS_IPHONE

#pragma mark - UIStateRestoring

- (Class<UIObjectRestoration>)objectRestorationClass {
	return [self class];
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
	[coder encodeObject:self.storeURL forKey:DCTCoreDataStackProperties.storeURL];
	[coder encodeObject:self.storeType forKey:DCTCoreDataStackProperties.storeType];
	[coder encodeObject:self.storeOptions forKey:DCTCoreDataStackProperties.storeOptions];
	[coder encodeObject:self.modelConfiguration forKey:DCTCoreDataStackProperties.modelConfiguration];
	[coder encodeObject:self.modelURL forKey:DCTCoreDataStackProperties.modelURL];
}

#pragma mark - UIObjectRestoration

+ (id<UIStateRestoring>) objectWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder {

	NSURL *storeURL = [coder decodeObjectOfClass:[NSURL class] forKey:DCTCoreDataStackProperties.storeURL];
	NSString *storeType = [coder decodeObjectOfClass:[NSString class] forKey:DCTCoreDataStackProperties.storeType];
	NSDictionary *storeOptions = [coder decodeObjectOfClass:[NSDictionary class] forKey:DCTCoreDataStackProperties.storeOptions];
	NSString *modelConfiguration = [coder decodeObjectOfClass:[NSString class] forKey:DCTCoreDataStackProperties.modelConfiguration];
	NSURL *modelURL = [coder decodeObjectOfClass:[NSURL class] forKey:DCTCoreDataStackProperties.modelURL];

	DCTCoreDataStack *coreDataStack = [[self alloc] initWithStoreURL:storeURL
														   storeType:storeType
														storeOptions:storeOptions
												  modelConfiguration:modelConfiguration
															modelURL:modelURL];

	NSString *identifier = [identifierComponents lastObject];
	[UIApplication registerObjectForStateRestoration:coreDataStack restorationIdentifier:identifier];

	return coreDataStack;
}

#endif

@end
