//
//  MasterViewController.m
//  BackgroundInsertionTest
//
//  Created by Daniel Tull on 15.12.2011.
//  Copyright (c) 2011 Daniel Tull Limited. All rights reserved.
//

#import "MasterViewController.h"
#import "NSManagedObjectContext+DCTCoreDataStack.h"
#import "User.h"
#import "Message.h"

@interface MasterViewController () <NSFetchedResultsControllerDelegate>
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
- (IBAction)insertNewObject:(id)sender;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *backgroundProcessingContext;
@property (strong, nonatomic) User *me;
@end

@implementation MasterViewController

@synthesize fetchedResultsController;
@synthesize managedObjectContext;
@synthesize backgroundProcessingContext;
@synthesize me;

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
	UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewObject:)];
	self.navigationItem.rightBarButtonItem = addButton;
	
	NSManagedObjectContext *mainContext = self.managedObjectContext;
	
	me = [User insertInManagedObjectContext:mainContext];
	me.name = @"Daniel";
	
	for (NSInteger i = 0; i < 5; i++) {
		User *someoneElse = [User insertInManagedObjectContext:mainContext];
		someoneElse.name = [NSString stringWithFormat:@"Friend %i", i];
		[me addFollowingObject:someoneElse];
	}
		
	[mainContext dct_save];
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    Message *message = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = [NSString stringWithFormat:@"%@: %@", message.user.name, message.text];
}

- (IBAction)insertNewObject:(id)sender {
	
	NSManagedObjectContext *context = self.backgroundProcessingContext;
	NSManagedObjectID *userID = [[me.following anyObject] objectID];
	
	[context performBlock:^{
		
		Message *message = [Message insertInManagedObjectContext:context];
		message.user = (User *)[context objectWithID:userID];
		message.date = [NSDate date];
		message.text = @"Hello";
		
		[context dct_saveWithCompletionHandler:^(BOOL success, NSError *error) {
			[self.managedObjectContext performBlock:^{
				[self.managedObjectContext dct_save];
			}];
		}];
	}];
}

#pragma mark - Getters

- (NSManagedObjectContext *)backgroundProcessingContext {
	
	if (!backgroundProcessingContext) {
		backgroundProcessingContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
		backgroundProcessingContext.parentContext = self.managedObjectContext;
	}
	
	return backgroundProcessingContext;	
}

- (NSFetchedResultsController *)fetchedResultsController {
	
    if (fetchedResultsController != nil)
        return fetchedResultsController;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	
	fetchRequest.entity = [Message entityInManagedObjectContext:self.managedObjectContext];
	
	fetchRequest.predicate = [NSPredicate predicateWithFormat:@"%K.%K contains %@", MessageRelationships.user, UserRelationships.followers, self.me];
	
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:MessageAttributes.date 
																   ascending:NO];
    fetchRequest.sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    
    fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:@"Master"];
    fetchedResultsController.delegate = self;    
	[fetchedResultsController performFetch:nil];
    
    return fetchedResultsController;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
	return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
	
	[self configureCell:cell atIndexPath:indexPath];
	
    return cell;
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller 
  didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
		   atIndex:(NSUInteger)sectionIndex
	 forChangeType:(NSFetchedResultsChangeType)type {
	
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
	   atIndexPath:(NSIndexPath *)indexPath
	 forChangeType:(NSFetchedResultsChangeType)type
	  newIndexPath:(NSIndexPath *)newIndexPath {
	
    UITableView *tableView = self.tableView;
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView endUpdates];
}

@end
