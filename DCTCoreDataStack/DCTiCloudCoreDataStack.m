//
//  DCTiCloudCoreDataStack.m
//  DCTCoreDataStack
//
//  Created by Daniel Tull on 06.08.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import "DCTiCloudCoreDataStack.h"
#import "_DCTCoreDataStack.h"

@interface DCTiCloudCoreDataStack ()
@property (nonatomic, strong) id ubiquityIdentityToken;
@end

@implementation DCTiCloudCoreDataStack {
	__strong DCTCoreDataStack *_coreDataStack;
	__strong NSURL *_storeName;
}

#pragma mark - DCTCoreDataStack

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:NSUbiquityIdentityDidChangeNotification
												  object:nil];
}

- (id)initWithStoreURL:(NSURL *)storeURL
			 storeType:(NSString *)storeType
		  storeOptions:(NSDictionary *)storeOptions
	modelConfiguration:(NSString *)modelConfiguration
			  modelURL:(NSURL *)modelURL {
	return nil;
}

- (id)initWithStoreFilename:(NSString *)filename {
	return [self initWithStoreFilename:filename
							 storeType:NSSQLiteStoreType
						  storeOptions:nil
					modelConfiguration:nil
							  modelURL:nil
		   ubiquityContainerIdentifier:nil];
}

#pragma mark - DCTiCloudCoreDataStack

- (id)initWithStoreFilename:(NSString *)storeFilename
				  storeType:(NSString *)storeType
			   storeOptions:(NSDictionary *)storeOptions
		 modelConfiguration:(NSString *)modelConfiguration
				   modelURL:(NSURL *)modelURL
ubiquityContainerIdentifier:(NSString *)ubiquityContainerIdentifier {

	self = [super initWithStoreURL:nil
						 storeType:storeType
					  storeOptions:storeOptions
				modelConfiguration:modelConfiguration
						  modelURL:modelURL];
	if (!self) return nil;

	_storeFilename = [storeFilename copy];
	_ubiquityContainerIdentifier = [ubiquityContainerIdentifier copy];
	_ubiquityIdentityToken = [[NSFileManager defaultManager] ubiquityIdentityToken];

	[self _loadCoreDataStack];

	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_ubiquityIdentityDidChangeNotification:)
                                                 name:NSUbiquityIdentityDidChangeNotification
                                               object:nil];

	return self;
}

- (void)setUbiquityIdentityToken:(id)ubiquityIdentityToken {
	if (_ubiquityIdentityToken == nil && ubiquityIdentityToken == nil) return;
	if ([_ubiquityIdentityToken isEqual:ubiquityIdentityToken]) return;
	_ubiquityIdentityToken = ubiquityIdentityToken;
	[self _loadCoreDataStack];
	if (self.iCloudAccountDidChangeHandler) self.iCloudAccountDidChangeHandler();
}

- (BOOL)isiCloudAvailable {
	return (self.ubiquityIdentityToken != nil);
}

#pragma mark - Internal

- (void)_loadCoreDataStack {

	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSURL *ubiquityContainerURL = [fileManager URLForUbiquityContainerIdentifier:self.ubiquityContainerIdentifier];
	NSMutableDictionary *storeOptions = [self.storeOptions mutableCopy];
	[storeOptions setObject:self.storeFilename forKey:NSPersistentStoreUbiquitousContentNameKey];
	[storeOptions setObject:ubiquityContainerURL forKey:NSPersistentStoreUbiquitousContentURLKey];

	NSString *storeFilename = [NSString stringWithFormat:@"%@.nosync", self.storeFilename];
	NSURL *storeURL = [ubiquityContainerURL URLByAppendingPathComponent:storeFilename];

	_coreDataStack = [[DCTCoreDataStack alloc] initWithStoreURL:storeURL
													  storeType:self.storeType
												   storeOptions:storeOptions
											 modelConfiguration:self.modelConfiguration
													   modelURL:self.modelURL];
	_coreDataStack.didResolvePersistentStoreErrorHandler = self.didResolvePersistentStoreErrorHandler;
	_coreDataStack.automaticSaveCompletionHandler = self.automaticSaveCompletionHandler;
}

- (void)_ubiquityIdentityDidChangeNotification:(NSNotification *)notification {
	self.ubiquityIdentityToken = [[NSFileManager defaultManager] ubiquityIdentityToken];
}

- (void)_applicationDidBecomeActiveNotification:(NSNotification *)notification {
	[super _applicationDidBecomeActiveNotification:notification];
	self.ubiquityIdentityToken = [[NSFileManager defaultManager] ubiquityIdentityToken];
}

#pragma mark - DCTCoreDataStack getters and setters

- (NSManagedObjectContext *)managedObjectContext {
	return _coreDataStack.managedObjectContext;
}

- (void)setAutomaticSaveCompletionHandler:(void (^)(BOOL, NSError *))automaticSaveCompletionHandler {
	[super setAutomaticSaveCompletionHandler:automaticSaveCompletionHandler];
	_coreDataStack.automaticSaveCompletionHandler = automaticSaveCompletionHandler;
}

- (void)setDidResolvePersistentStoreErrorHandler:(BOOL (^)(NSError *))didResolvePersistentStoreErrorHandler {
	[super setDidResolvePersistentStoreErrorHandler:didResolvePersistentStoreErrorHandler];
	_coreDataStack.didResolvePersistentStoreErrorHandler = didResolvePersistentStoreErrorHandler;
}

@end
