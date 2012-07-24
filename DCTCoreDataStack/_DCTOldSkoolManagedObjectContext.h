//
//  _DCTOldSkoolManagedObjectContext.h
//  DCTCoreDataStack
//
//  Created by Daniel Tull on 24.07.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface _DCTOldSkoolManagedObjectContext : NSManagedObjectContext
- (id)initWithParentContext:(NSManagedObjectContext *)context;
@end
