//
//  AppDelegate.m
//  Demo
//
//  Created by Daniel Tull on 24.07.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import "AppDelegate.h"
#import <DCTCoreDataStack/DCTCoreDataStack.h>
#import "Event.h"

@implementation AppDelegate {
	__strong DCTCoreDataStack *coreDataStack;
	__strong NSManagedObjectContext *threadedContext;
}

@synthesize window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	
	coreDataStack = [[DCTCoreDataStack alloc] initWithStoreFilename:@"DCTCoreDataStack"];
	NSManagedObjectContext *context = coreDataStack.managedObjectContext;
	
	NSLog(@"%@:%@ ", self, NSStringFromSelector(_cmd));
	Event *event = [Event insertInManagedObjectContext:context];
	event.name = @"Some name";
	NSError *error = nil;
	BOOL success = [context save:&error];
	NSLog(@"%@:%@ %@\n %@ \n\n", self, NSStringFromSelector(_cmd), (success?@"success":@"failure"), [context dct_detailedDescriptionFromValidationError:error]);
	
	
	
	
	threadedContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
	threadedContext.parentContext = context;
	
	NSString *mainLabel = [NSString stringWithCString:dispatch_queue_get_label(dispatch_get_current_queue())
											 encoding:NSUTF8StringEncoding];
	
	[threadedContext performBlock:^{
		
		Event *event = [Event insertInManagedObjectContext:threadedContext];
		event.name = @"Some name";
		
		NSString *threadLabel = [NSString stringWithCString:dispatch_queue_get_label(dispatch_get_current_queue())
												   encoding:NSUTF8StringEncoding];
		
		void (^completion)(BOOL, NSError*) = ^(BOOL success, NSError *error) {
			
			NSString *currentLabel = [NSString stringWithCString:dispatch_queue_get_label(dispatch_get_current_queue())
														encoding:NSUTF8StringEncoding];
			
			NSLog(@"%@ 1 Completion with %@: main:%@, current:%@", (success?@"success":@"failure"), threadedContext, threadLabel, currentLabel);
			
			if (!success) {
				NSLog(@"%@", [context dct_detailedDescriptionFromValidationError:error]);
				return;
			}
			
			[context performBlock:^{
				
				[context dct_saveWithCompletionHandler:^(BOOL success, NSError *error) {
					
					NSString *currentLabel = [NSString stringWithCString:dispatch_queue_get_label(dispatch_get_current_queue())
																encoding:NSUTF8StringEncoding];
					
					NSLog(@"%@ 2 Completion with %@: main:%@, current:%@", (success?@"success":@"failure"), context, mainLabel, currentLabel);
					
					if (!success) NSLog(@"%@", [context dct_detailedDescriptionFromValidationError:error]);
					
				}];
			}];
		};
		
		
		[threadedContext dct_saveWithCompletionHandler:completion];
		
		
		[Event insertInManagedObjectContext:threadedContext];
		[threadedContext dct_saveWithCompletionHandler:completion];
	}];
	
	
	
	
	
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    return YES;
}

@end
