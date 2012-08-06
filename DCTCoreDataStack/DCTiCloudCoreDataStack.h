//
//  DCTiCloudCoreDataStack.h
//  DCTCoreDataStack
//
//  Created by Daniel Tull on 06.08.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import "DCTCoreDataStack.h"

@interface DCTiCloudCoreDataStack : DCTCoreDataStack

+ (void)setUbiquityContainerIdentifier:(NSString *)string;

@property (nonatomic, readonly, getter = isiCloudAvailable) BOOL iCloudAvailable;

@property (nonatomic, copy) void (^iCloudAccountDidChangeHandler)();

@end
