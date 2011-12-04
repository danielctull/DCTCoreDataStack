//
//  AppDelegate.m
//  DCTCoreDataStack
//
//  Created by Daniel Tull on 04.12.2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "DCTCoreDataStack.h"
#import "Event.h"
#import "NSManagedObjectContext+DCTCoreDataStack.h"

@implementation AppDelegate {
	DCTCoreDataStack *coreDataStack;
}

@synthesize window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	
	coreDataStack = [[DCTCoreDataStack alloc] initWithModelName:@"DCTCoreDataStack"];
	NSManagedObjectContext *context = coreDataStack.managedObjectContext;
	
	dispatch_queue_t queue = dispatch_get_current_queue();
	
	DCTManagedObjectContextSaveCompletionBlock completion = ^(BOOL success) {
		NSString *mainLabel = [NSString stringWithCString:dispatch_queue_get_label(queue)
												 encoding:NSUTF8StringEncoding];
		
		NSString *currentLabel = [NSString stringWithCString:dispatch_queue_get_label(dispatch_get_current_queue())
													encoding:NSUTF8StringEncoding];
		
		NSLog(@"Completion with %@: main:%@, current:%@", (success?@"success":@"failure"), mainLabel, currentLabel);
	};
	
	DCTManagedObjectContextSaveErrorBlock error = ^(NSError *error) {
		NSLog(@"%@", [context dct_detailedDescriptionFromValidationError:error]);
		
		NSString *mainLabel = [NSString stringWithCString:dispatch_queue_get_label(queue)
												 encoding:NSUTF8StringEncoding];
		
		NSString *currentLabel = [NSString stringWithCString:dispatch_queue_get_label(dispatch_get_current_queue())
													encoding:NSUTF8StringEncoding];
		
		NSLog(@"Error: main:%@, current:%@", mainLabel, currentLabel);
	};
	
	Event *event = [Event insertInManagedObjectContext:context];
	event.name = @"Some name";
	[context dct_saveWithErrorHandler:error completionHandler:completion];
	
	[Event insertInManagedObjectContext:context];
	[context dct_saveWithErrorHandler:error completionHandler:completion];
	
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    return YES;
}

@end
