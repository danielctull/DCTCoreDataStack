//
//  NSManagedObjectContext+DCTSiblingContext.m
//  DCTCoreDataStack
//
//  Created by Daniel Tull on 02.08.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import "NSManagedObjectContext+DCTSiblingContext.h"
#import "_DCTSiblingManagedObjectContext.h"
@implementation NSManagedObjectContext (DCTSiblingContext)

- (NSManagedObjectContext *)dct_newSiblingContextWithConcurrencyType:(NSManagedObjectContextConcurrencyType)concurrencyType {
	return [[_DCTSiblingManagedObjectContext alloc] initWithConcurrencyType:concurrencyType
													   managedObjectContext:self];
}

@end
