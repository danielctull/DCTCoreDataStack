//
//  DCTCoreDataStack+UIKit.m
//  DCTCoreDataStack
//
//  Created by Daniel Tull on 08.12.2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "DCTCoreDataStack+UIKit.h"
#import "NSManagedObjectContext+DCTCoreDataStack.h"

@interface DCTCoreDataStack ()
- (void)dctInternal_applicationDidEnterBackgroundNotification:(NSNotification *)notification;
- (void)dctInternal_applicationWillTerminateNotification:(NSNotification *)notification;
@end

@implementation DCTCoreDataStack (UIKit)

+ (void)load {
	
	UIApplication *app = [UIApplication sharedApplication];
	
	[self addInitBlock:^(DCTCoreDataStack *stack) {
		[[NSNotificationCenter defaultCenter] addObserver:stack
												 selector:@selector(dctInternal_applicationDidEnterBackgroundNotification:) 
													 name:UIApplicationDidEnterBackgroundNotification 
												   object:app];
		
		[[NSNotificationCenter defaultCenter] addObserver:stack
												 selector:@selector(dctInternal_applicationWillTerminateNotification:) 
													 name:UIApplicationWillTerminateNotification
												   object:app];		
	}];
	
	[self addDeallocBlock:^(DCTCoreDataStack *stack) {
		
		[[NSNotificationCenter defaultCenter] removeObserver:stack
														name:UIApplicationDidEnterBackgroundNotification
													  object:app];
		
		[[NSNotificationCenter defaultCenter] removeObserver:stack
														name:UIApplicationWillTerminateNotification
													  object:app];
	}];
}

- (void)dctInternal_applicationDidEnterBackgroundNotification:(NSNotification *)notification {
	
	if (![self.managedObjectContext hasChanges]) return;
	
	if ([self.managedObjectContext respondsToSelector:@selector(performBlock:)]) {
		
		[self.managedObjectContext performBlock:^{
			[self.managedObjectContext dct_saveWithCompletionHandler:NULL];
		}];
		
	} else {
		
		[self.managedObjectContext dct_saveWithCompletionHandler:NULL];
	}
	
	// TODO: what if there was a save error?
}

- (void)dctInternal_applicationWillTerminateNotification:(NSNotification *)notification {
	
	if (![self.managedObjectContext hasChanges]) return;
	
	if ([self.managedObjectContext respondsToSelector:@selector(performBlock:)]) {
		
		[self.managedObjectContext performBlock:^{
			[self.managedObjectContext save:nil];
		}];
		
	} else {
		
		[self.managedObjectContext save:nil];
	}
}


@end
