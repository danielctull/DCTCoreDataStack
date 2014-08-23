//
//  AppDelegate.m
//  Demo
//
//  Created by Daniel Tull on 24.07.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

@import DCTCoreDataStack;
#import "AppDelegate.h"
#import "Event.h"
#import "ViewController.h"

@interface AppDelegate ()
@property (nonatomic) DCTCoreDataStack *coreDataStack;
@end

@implementation AppDelegate

@synthesize window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	
	self.coreDataStack = [[DCTCoreDataStack alloc] initWithStoreFilename:@"DCTCoreDataStack"];

	NSManagedObjectContext *context = self.coreDataStack.managedObjectContext;
	ViewController *viewController = [[ViewController alloc] initWithManagedObjectContext:context];
	
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:viewController];
    [self.window makeKeyAndVisible];
    return YES;
}

@end
