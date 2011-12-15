//
//  AppDelegate.m
//  BackgroundInsertionTest
//
//  Created by Daniel Tull on 15.12.2011.
//  Copyright (c) 2011 Daniel Tull Limited. All rights reserved.
//

#import "AppDelegate.h"
#import "MasterViewController.h"
#import "DCTCoreDataStack.h"

@implementation AppDelegate

@synthesize window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	
	DCTCoreDataStack *stack = [[DCTCoreDataStack alloc] initWithStoreFilename:@"BackgroundInsertionTest"];
	
	self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

	MasterViewController *masterViewController = [[MasterViewController alloc] init];
	masterViewController.managedObjectContext = stack.managedObjectContext;
	
	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:masterViewController];
	
	self.window.rootViewController = navigationController;
    [self.window makeKeyAndVisible];
    return YES;
}

@end
