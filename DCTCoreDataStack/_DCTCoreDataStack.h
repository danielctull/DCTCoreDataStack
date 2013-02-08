//
//  _DCTCoreDataStack.h
//  DCTCoreDataStack
//
//  Created by Daniel Tull on 15/12/2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import "DCTCoreDataStack.h"

@interface DCTCoreDataStack (Private)

- (void)loadPersistentStore:(void(^)(NSPersistentStore *persistentStore, NSError *error))completion;
+ (NSURL *)_applicationDocumentsDirectory;

#if TARGET_OS_IPHONE
- (void)_applicationDidEnterBackgroundNotification:(NSNotification *)notification;
- (void)_applicationWillTerminateNotification:(NSNotification *)notification;
#endif

@end
