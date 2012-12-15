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
	__strong DCTCoreDataStack *_coreDataStack;
}

@synthesize window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	
	_coreDataStack = [[DCTCoreDataStack alloc] initWithStoreFilename:@"DCTCoreDataStack"];

	NSManagedObjectContext *context = _coreDataStack.managedObjectContext;
	ViewController *viewController = [[ViewController alloc] initWithManagedObjectContext:context];
	
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:viewController];
    [self.window makeKeyAndVisible];
    return YES;
}

@end
