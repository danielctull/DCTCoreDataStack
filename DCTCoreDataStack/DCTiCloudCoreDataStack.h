//
//  DCTiCloudCoreDataStack.h
//  DCTCoreDataStack
//
//  Created by Daniel Tull on 06.08.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import "DCTCoreDataStack.h"

@interface DCTiCloudCoreDataStack : DCTCoreDataStack

- (id)initWithStoreFilename:(NSString *)storeFilename
				  storeType:(NSString *)storeType
			   storeOptions:(NSDictionary *)storeOptions
		 modelConfiguration:(NSString *)modelConfiguration
				   modelURL:(NSURL *)modelURL
ubiquityContainerIdentifier:(NSString *)ubiquityContainerIdentifier;

@property (nonatomic, readonly, copy) NSString *storeFilename;
@property (nonatomic, readonly, copy) NSString *ubiquityContainerIdentifier;

@property (nonatomic, readonly, getter = isiCloudAvailable) BOOL iCloudAvailable;

@property (nonatomic, copy) void (^iCloudAccountDidChangeHandler)();

@end
