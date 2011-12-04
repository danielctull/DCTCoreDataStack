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
	[Event insertInManagedObjectContext:context];
	[context dct_save];
	
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    return YES;
}

@end
