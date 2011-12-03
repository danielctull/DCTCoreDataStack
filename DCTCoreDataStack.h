/*
 DCTCoreDataStack.h
 DCTCoreDataStack
 
 Created by Daniel Tull on 01.12.2011.
 
 
 
 Copyright (c) 2011 Daniel Tull. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.
 
 * Neither the name of the author nor the names of its contributors may be used
 to endorse or promote products derived from this software without specific
 prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#if !defined dct_weak && __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_5_0
#define dct_weak weak
#define __dct_weak __weak
#define dct_nil(x)
#elif !defined dct_weak && __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_4_3
#define dct_weak unsafe_unretained
#define __dct_weak __unsafe_unretained
#define dct_nil(x) x = nil
#endif

typedef void (^DCTCoreDataStackErrorBlock) (NSManagedObjectContext *managedObjectContext, NSError *error);

@interface DCTCoreDataStack : NSObject

- (id)init;
- (id)initWithModelName:(NSString *)modelName;

@property (nonatomic, copy) NSURL *modelURL;
@property (nonatomic, copy) NSURL *storeURL;
@property (nonatomic, copy) NSString *persistentStoreType;
@property (nonatomic, copy) NSDictionary *persistentStoreOptions;
@property (nonatomic, copy) NSString *modelConfiguration;

@property (nonatomic, copy) DCTCoreDataStackErrorBlock saveFailureHandler;

@property (nonatomic, strong, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@end
