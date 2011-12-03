/*
 NSManagedObjectContext+DCTName.m
 DCTCoreDataStack
 
 Created by Daniel Tull on 03.12.2011.
 
 
 
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

#import "NSManagedObjectContext+DCTName.h"
#import <objc/runtime.h>

@implementation NSManagedObjectContext (DCTName)

- (void)setDct_name:(NSString *)name {
	objc_setAssociatedObject(self, @selector(dct_name), [name copy], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)dct_name {
	return objc_getAssociatedObject(self, _cmd);
}

- (void)dct_saveWithErrorHandler:(DCTManagedObjectContextSaveFailureBlock)handler {
	
	if (handler != NULL)
		objc_setAssociatedObject(self, _cmd, [handler copy], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	
	NSError *error = nil;
	if (![self save:&error] && handler != NULL)
		handler(error);
	
	objc_setAssociatedObject(self, _cmd, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
