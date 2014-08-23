//
//  DCTCoreDataStackTests.m
//  DCTCoreDataStackTests
//
//  Created by Daniel Tull on 14.06.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import "DCTCoreDataStackTests.h"
#import <DCTCoreDataStack/DCTCoreDataStack.h>

@implementation DCTCoreDataStackTests

- (void)testThreadedAccess {

	DCTCoreDataStack *stack = [[DCTCoreDataStack alloc] initWithStoreFilename:@"name"];

	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		[stack managedObjectContext];
	});

	[stack managedObjectContext];

	XCTAssertTrue(YES, @"We've passed as it's not crashed!");
}

@end
