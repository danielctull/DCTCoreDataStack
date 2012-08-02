//
//  NSManagedObjectContext+DCTSiblingContext.h
//  DCTCoreDataStack
//
//  Created by Daniel Tull on 02.08.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObjectContext (DCTSiblingContext)

/** Generates a new private context to do background work on.
 
 This is a sibling to the managedObjectContext and saves to this context will merge across
 to the managedObjectContext. Changes to the managedObjectContext will not merge across
 to the context given from this method, and should be handled by the user if desired.
 
 @param concurrencyType The concurrency type to use, which is almost defintely going to be NSPrivateQueueConcurrencyType.
 */
- (NSManagedObjectContext *)dct_newSiblingContextWithConcurrencyType:(NSManagedObjectContextConcurrencyType)concurrencyType;

@end
