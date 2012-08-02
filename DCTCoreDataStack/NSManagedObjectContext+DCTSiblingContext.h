//
//  NSManagedObjectContext+DCTSiblingContext.h
//  DCTCoreDataStack
//
//  Created by Daniel Tull on 02.08.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObjectContext (DCTSiblingContext)

- (NSManagedObjectContext *)dct_newSiblingContextWithConcurrencyType:(NSManagedObjectContextConcurrencyType)concurrencyType;

@end
