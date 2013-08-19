//
//  _DCTCDSManagedObjectContext.m
//  DCTCoreDataStack
//
//  Created by Daniel Tull on 24.07.2012.
//
//  Created by Daniel Tull on 24.07.2012.
//
//  Copyright (c) 2011 Daniel Tull. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  * Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
//
//  * Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
//  * Neither the name of the author nor the names of its contributors may be used
//    to endorse or promote products derived from this software without specific
//    prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
//  FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
//  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
//  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
//  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
//  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
//  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//


#import "_DCTCDSManagedObjectContext.h"
#import "NSManagedObjectContext+DCTCoreDataStack.h"
#import <objc/runtime.h>
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

@implementation _DCTCDSManagedObjectContext

- (BOOL)save:(NSError **)error {
		
	id object = objc_getAssociatedObject(self, @selector(dct_saveWithCompletionHandler:));
	
	if (object) return [super save:error];
	
	__block BOOL success = [super save:error];
	
	if (success) {
		
		NSManagedObjectContext *parent = self.parentContext;
		
		[parent performBlockAndWait:^{
			success = [parent save:error];
		}];
	}
	
	return success;
}

- (void)dct_saveWithCompletionHandler:(void(^)(BOOL success, NSError *error))completion {

	if (completion == NULL) completion = ^(BOOL success, NSError *error) {};

#if TARGET_OS_IPHONE
	
	UIBackgroundTaskIdentifier backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:NULL];
	
	void(^iphoneCompletion)(BOOL, NSError *) = ^(BOOL success, NSError *error) {
		completion(success, error);
		[[UIApplication sharedApplication] endBackgroundTask:backgroundTaskIdentifier];
	};
	
	completion = iphoneCompletion;
	
#endif
	
	NSManagedObjectContext *parent = self.parentContext;
	
	// Put anything in this association to switch on save:
	objc_setAssociatedObject(self, _cmd, [NSNull null], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	
	[super dct_saveWithCompletionHandler:^(BOOL success, NSError *error) {
		
		// Clear the association after the save
		objc_setAssociatedObject(self, _cmd, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
		
		if (!success) {
			completion(success, error);
			return;
		}
		
		[parent performBlock:^{
			[parent dct_saveWithCompletionHandler:^(BOOL success, NSError *error) {
				[self performBlock:^{
					completion(success, error);
				}];
			}];
		}];
	}];
}

@end
