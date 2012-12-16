//
//  ViewController.h
//  DCTCoreDataStack
//
//  Created by Daniel Tull on 24.07.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <DCTCoreDataStack/DCTCoreDataStack.h>
#import "Event.h"

@interface ViewController : UITableViewController

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;
@property (nonatomic, readonly, strong) NSManagedObjectContext *managedObjectContext;

@end
