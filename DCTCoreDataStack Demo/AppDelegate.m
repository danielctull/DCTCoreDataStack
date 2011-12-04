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
	
	NSString *mainLabel = [NSString stringWithCString:dispatch_queue_get_label(dispatch_get_current_queue())
											 encoding:NSUTF8StringEncoding];
	
	DCTManagedObjectContextSaveCompletionBlock completion = ^(BOOL success, NSError *error) {
		
		NSString *currentLabel = [NSString stringWithCString:dispatch_queue_get_label(dispatch_get_current_queue())
													encoding:NSUTF8StringEncoding];
		
		NSLog(@"Completion with %@: main:%@, current:%@", (success?@"success":@"failure"), mainLabel, currentLabel);
		
		if (!success) NSLog(@"%@", [context dct_detailedDescriptionFromValidationError:error]);
	};
	
	Event *event = [Event insertInManagedObjectContext:context];
	event.name = @"Some name";
	[context dct_saveWithCompletionHandler:completion];
	
	[Event insertInManagedObjectContext:context];
	[context dct_saveWithCompletionHandler:completion];
	
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    return YES;
}

@end
