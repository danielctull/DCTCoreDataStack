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
#import "ViewController.h"

@implementation AppDelegate {
	__strong DCTCoreDataStack *coreDataStack;
}

@synthesize window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	
	coreDataStack = [[DCTCoreDataStack alloc] initWithStoreFilename:@"DCTCoreDataStack"];
	
	ViewController *viewController = [ViewController new];
	viewController.mainContext = coreDataStack.managedObjectContext;
	viewController.backgroundContext = [coreDataStack newWorkerManagedObjectContext];
	
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:viewController];
    [self.window makeKeyAndVisible];
    return YES;
}

@end
