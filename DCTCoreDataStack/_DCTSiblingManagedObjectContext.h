//
//  _DCTSiblingManagedObjectContext.h
//  DCTManagedObjectContextSibling
//
//  Created by Daniel Tull on 02.08.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "_DCTCDSManagedObjectContext.h"

@interface _DCTSiblingManagedObjectContext : _DCTCDSManagedObjectContext

- (id)initWithConcurrencyType:(NSManagedObjectContextConcurrencyType)concurrencyType
		 managedObjectContext:(NSManagedObjectContext *)context;

@end
