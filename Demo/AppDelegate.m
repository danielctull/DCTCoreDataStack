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

@interface AppDelegate ()
@property (nonatomic, strong) DCTiCloudCoreDataStack *coreDataStack;
@end

@implementation AppDelegate

@synthesize window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	
	self.coreDataStack = [[DCTiCloudCoreDataStack alloc] initWithStoreFilename:@"DCTCoreDataStack"];

	ViewController *viewController = [[ViewController alloc] initWithManagedObjectContext:self.coreDataStack.managedObjectContext];
	self.coreDataStack.persistentStoreDidChangeHandler = ^{
		[viewController reloadData];
	};

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:viewController];
    [self.window makeKeyAndVisible];
    return YES;
}

@end
