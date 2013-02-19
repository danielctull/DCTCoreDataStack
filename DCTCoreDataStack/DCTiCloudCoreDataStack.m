//
//  DCTiCloudCoreDataStack.m
//  DCTCoreDataStack
//
//  Created by Daniel Tull on 06.08.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import "DCTiCloudCoreDataStack.h"
#import "DCTCoreDataStack+Private.h"

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

@interface DCTiCloudCoreDataStack ()
@property (nonatomic, strong) id ubiquityIdentityToken;
@property (nonatomic, strong) NSPersistentStore *persistentStore;
@property (nonatomic, strong) NSMutableArray *ubiquitousContentChangesNotifications;
@end

@implementation DCTiCloudCoreDataStack

#pragma mark - DCTCoreDataStack

- (void)dealloc {
	NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
	[defaultCenter removeObserver:self
							 name:NSUbiquityIdentityDidChangeNotification
						   object:nil];
	[defaultCenter removeObserver:self
							 name:NSPersistentStoreDidImportUbiquitousContentChangesNotification
						   object:nil];

#if TARGET_OS_IPHONE
	[defaultCenter removeObserver:self
							 name:UIApplicationDidBecomeActiveNotification
						   object:[UIApplication sharedApplication]];
#endif
}

- (id)initWithStoreURL:(NSURL *)storeURL
			 storeType:(NSString *)storeType
		  storeOptions:(NSDictionary *)storeOptions
	modelConfiguration:(NSString *)modelConfiguration
			  modelURL:(NSURL *)modelURL {
	
	return [self initWithStoreFilename:[storeURL lastPathComponent]
							 storeType:NSSQLiteStoreType
						  storeOptions:storeOptions
					modelConfiguration:modelConfiguration
							  modelURL:modelURL
		   ubiquityContainerIdentifier:nil];
}

- (id)initWithStoreFilename:(NSString *)filename {
	return [self initWithStoreFilename:filename
							 storeType:NSSQLiteStoreType
						  storeOptions:nil
					modelConfiguration:nil
							  modelURL:nil
		   ubiquityContainerIdentifier:nil];
}

- (NSURL *)storeURL {
	NSURL *ubiquityContainerURL = [self ubiquityContainerURL];
	if (ubiquityContainerURL) {
		NSString *storeFilename = [NSString stringWithFormat:@"%@.nosync", self.storeFilename];
		return [ubiquityContainerURL URLByAppendingPathComponent:storeFilename];
	}

	return [[[self class] applicationDocumentsDirectory] URLByAppendingPathComponent:self.storeFilename];
}

- (NSDictionary *)storeOptions {

	if (!self.iCloudAvailable) return [super storeOptions];

	NSMutableDictionary *storeOptions = [[super storeOptions] mutableCopy];
	if (!storeOptions) storeOptions = [NSMutableDictionary new];
	[storeOptions setObject:self.storeFilename forKey:NSPersistentStoreUbiquitousContentNameKey];
	NSURL *URL = [[self ubiquityContainerURL] URLByAppendingPathComponent:self.storeFilename];
	[storeOptions setObject:URL forKey:NSPersistentStoreUbiquitousContentURLKey];
	return [storeOptions copy];
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
	_ubiquitousContentChangesNotifications = [NSMutableArray new];
	
	NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
	[defaultCenter addObserver:self
					  selector:@selector(ubiquityIdentityDidChangeNotification:)
						  name:NSUbiquityIdentityDidChangeNotification
						object:nil];
	[defaultCenter addObserver:self
					  selector:@selector(persistentStoreDidImportUbiquitousContentChangesNotification:)
						  name:NSPersistentStoreDidImportUbiquitousContentChangesNotification
						object:nil];
	
#if TARGET_OS_IPHONE
	[defaultCenter addObserver:self
					  selector:@selector(applicationDidBecomeActiveNotification:)
						  name:UIApplicationDidBecomeActiveNotification
						object:[UIApplication sharedApplication]];
#endif

	return self;
}

- (BOOL)isiCloudAvailable {
	return (self.ubiquityIdentityToken != nil);
}

#pragma mark - Internal

- (void)setUbiquityIdentityToken:(id)ubiquityIdentityToken {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdirect-ivar-access"
	if (_ubiquityIdentityToken == nil && ubiquityIdentityToken == nil) return;
	if ([_ubiquityIdentityToken isEqual:ubiquityIdentityToken]) return;
	_ubiquityIdentityToken = ubiquityIdentityToken;
	if (self.persistentStore) {
		[self removePersistentStore];
		[self loadPersistentStore:NULL];
	}
#pragma clang diagnostic pop
}

- (void)removePersistentStore {
	if (!self.persistentStore) return;
	NSPersistentStoreCoordinator *persistentStoreCoordinator = self.managedObjectContext.persistentStoreCoordinator;
	[persistentStoreCoordinator lock];
	[persistentStoreCoordinator removePersistentStore:self.persistentStore error:NULL];
	[persistentStoreCoordinator unlock];
}

- (void)loadPersistentStore:(void (^)(NSPersistentStore *, NSError *))completion {
	// load the new store on a background thread, because it takes an age to setup with a new iCloud container
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		NSPersistentStoreCoordinator *persistentStoreCoordinator = self.managedObjectContext.persistentStoreCoordinator;
		[persistentStoreCoordinator lock];
		[super loadPersistentStore:^(NSPersistentStore *store, NSError *error) {
			dispatch_async(dispatch_get_main_queue(), ^{
				self.persistentStore = store;
				if (self.persistentStoreDidChangeHandler != NULL) self.persistentStoreDidChangeHandler();
				if (completion != NULL) completion(store, error);
			});
		}];
		[persistentStoreCoordinator unlock];
	});
}

- (void)setPersistentStore:(NSPersistentStore *)persistentStore {
	_persistentStore = persistentStore;
	[self processUbiquitousContentChangesNotifications];
}

- (NSURL *)ubiquityContainerURL {
	return [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:self.ubiquityContainerIdentifier];
}

#pragma mark - Notifications

- (void)persistentStoreDidImportUbiquitousContentChangesNotification:(NSNotification *)notification {

	NSLog(@"%@:%@", self, NSStringFromSelector(_cmd));

	[self.managedObjectContext performBlock:^{
		NSLog(@"%@:%@ %@", self, NSStringFromSelector(_cmd), self.managedObjectContext.dct_name);
		[self.managedObjectContext.parentContext performBlock:^{
			NSLog(@"%@:%@ %@", self, NSStringFromSelector(_cmd), self.managedObjectContext.parentContext.dct_name);
		}];
	}];


	dispatch_async(dispatch_get_main_queue(), ^{

		NSLog(@"%@:%@ %@", self, NSStringFromSelector(_cmd), notification);
		if (!self.persistentStore || ![notification.object isEqual:self.managedObjectContext.persistentStoreCoordinator]) {
			NSLog(@"%@:%@ Has persistentStore: %@", self, NSStringFromSelector(_cmd), self.persistentStore);
			[self.ubiquitousContentChangesNotifications addObject:notification];
			return;
		}


		NSManagedObjectContext *context = self.managedObjectContext;
		[context performBlock:^{

			[context mergeChangesFromContextDidSaveNotification:notification];

			NSSet *insertedObjectIDs = [notification.userInfo objectForKey:NSInsertedObjectsKey];
			NSSet *updatedObjectIDs = [notification.userInfo objectForKey:NSUpdatedObjectsKey];
			NSSet *deletedObjectIDs = [notification.userInfo objectForKey:NSDeletedObjectsKey];

			[deletedObjectIDs enumerateObjectsUsingBlock:^(NSManagedObjectID *objectID, BOOL *stop) {
				[context deleteObject:[context objectWithID:objectID]];
			}];

			[updatedObjectIDs enumerateObjectsUsingBlock:^(NSManagedObjectID *objectID, BOOL *stop) {
				NSManagedObject *managedObject = [context objectWithID:objectID];
				[managedObject willAccessValueForKey:nil];
				[context refreshObject:managedObject mergeChanges:YES];

			}];

			[insertedObjectIDs enumerateObjectsUsingBlock:^(NSManagedObjectID *objectID, BOOL *stop) {
				NSManagedObject *managedObject = [context objectWithID:objectID];
				[managedObject willAccessValueForKey:nil];
				[context insertObject:managedObject];
			}];
			[context processPendingChanges];
		}];
	});
}

- (NSSet *)objectsWithObjectIDs:(NSSet *)objectIDs inManagedObjectContext:(NSManagedObjectContext *)context {
	NSMutableSet *objects = [[NSMutableSet alloc] initWithCapacity:[objectIDs count]];
	[objectIDs enumerateObjectsUsingBlock:^(NSManagedObjectID *objectID, BOOL *stop) {
		NSManagedObject *object = [context objectWithID:objectID];
		[objects addObject:object];
	}];
	return [objects copy];
}

- (void)processUbiquitousContentChangesNotifications {
	NSArray *notifications = [self.ubiquitousContentChangesNotifications copy];
	[self.ubiquitousContentChangesNotifications removeAllObjects];
	[notifications enumerateObjectsUsingBlock:^(NSNotification *notification, NSUInteger idx, BOOL *stop) {
		[self persistentStoreDidImportUbiquitousContentChangesNotification:notification];
	}];
}

- (void)ubiquityIdentityDidChangeNotification:(NSNotification *)notification {
	self.ubiquityIdentityToken = [[NSFileManager defaultManager] ubiquityIdentityToken];
}

#if TARGET_OS_IPHONE
- (void)applicationDidBecomeActiveNotification:(NSNotification *)notification {
	self.ubiquityIdentityToken = [[NSFileManager defaultManager] ubiquityIdentityToken];
}
#endif

@end
