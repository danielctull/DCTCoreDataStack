/*
 NSManagedObjectContext+DCTCoreDataStack.m
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

#import "NSManagedObjectContext+DCTCoreDataStack.h"
#import <objc/runtime.h>

typedef void (^DCTInternalCoreDataStackSaveBlock) (dispatch_queue_t callbackQueue, DCTManagedObjectContextSaveErrorBlock failureHandler);

@implementation NSManagedObjectContext (DCTCoreDataStack)

- (void)setDct_name:(NSString *)name {
	objc_setAssociatedObject(self, @selector(dct_name), [name copy], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)dct_name {
	return objc_getAssociatedObject(self, _cmd);
}

- (void)dct_save {
	[self dct_saveWithErrorHandler:^(NSError *error) {
		NSLog(@"NSManagedObjectContext with name %@ failed to save.\n\n%@", self.dct_name, [self dct_detailedDescriptionFromValidationError:error]);
	}];
}

- (void)dct_saveWithErrorHandler:(DCTManagedObjectContextSaveErrorBlock)errorHandler {
	
	DCTInternalCoreDataStackSaveBlock saveBlock = ^(dispatch_queue_t queue, DCTManagedObjectContextSaveErrorBlock handler) {

		if (handler != NULL)
			objc_setAssociatedObject(self, _cmd, [handler copy], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	
		NSError *error = nil;
		
		if (![self save:&error] && handler != NULL) {
			dispatch_sync(queue, ^{
				handler(error);
			});
		}
	
		if (handler != NULL)
			objc_setAssociatedObject(self, _cmd, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	};
	
	
	
	if ([self respondsToSelector:@selector(performBlock:)]) {
		
		DCTInternalCoreDataStackSaveBlock oldSaveBlock = [saveBlock copy];
		
		saveBlock = ^(dispatch_queue_t queue, DCTManagedObjectContextSaveErrorBlock handler) {
			[self performBlock:^{
				oldSaveBlock(queue, handler);
			}];
		};
	}
	
	
	
	saveBlock(dispatch_get_current_queue(), errorHandler);
}

- (NSString *)dct_detailedDescriptionFromValidationError:(NSError *)anError {
	
    if (anError && [[anError domain] isEqualToString:@"NSCocoaErrorDomain"]) {
        NSArray *errors = nil;
		
        // multiple errors?
        if ([anError code] == NSValidationMultipleErrorsError) {
            errors = [[anError userInfo] objectForKey:NSDetailedErrorsKey];
        } else {
            errors = [NSArray arrayWithObject:anError];
        }
		
        if (errors && [errors count] > 0) {
            NSString *messages = @"Reason(s):\n";
			
            for (NSError * error in errors) {
                NSString *entityName = [[[[error userInfo] objectForKey:@"NSValidationErrorObject"] entity] name];
                NSString *attributeName = [[error userInfo] objectForKey:@"NSValidationErrorKey"];
                NSString *msg;
                switch ([error code]) {
                    case NSManagedObjectValidationError:
                        msg = @"Generic validation error.";
                        break;
                    case NSValidationMissingMandatoryPropertyError:
                        msg = [NSString stringWithFormat:@"The attribute '%@' mustn't be empty.", attributeName];
                        break;
                    case NSValidationRelationshipLacksMinimumCountError:  
                        msg = [NSString stringWithFormat:@"The relationship '%@' doesn't have enough entries.", attributeName];
                        break;
                    case NSValidationRelationshipExceedsMaximumCountError:
                        msg = [NSString stringWithFormat:@"The relationship '%@' has too many entries.", attributeName];
                        break;
                    case NSValidationRelationshipDeniedDeleteError:
                        msg = [NSString stringWithFormat:@"To delete, the relationship '%@' must be empty.", attributeName];
                        break;
                    case NSValidationNumberTooLargeError:                 
                        msg = [NSString stringWithFormat:@"The number of the attribute '%@' is too large.", attributeName];
                        break;
                    case NSValidationNumberTooSmallError:                 
                        msg = [NSString stringWithFormat:@"The number of the attribute '%@' is too small.", attributeName];
                        break;
                    case NSValidationDateTooLateError:                    
                        msg = [NSString stringWithFormat:@"The date of the attribute '%@' is too late.", attributeName];
                        break;
                    case NSValidationDateTooSoonError:                    
                        msg = [NSString stringWithFormat:@"The date of the attribute '%@' is too soon.", attributeName];
                        break;
                    case NSValidationInvalidDateError:                    
                        msg = [NSString stringWithFormat:@"The date of the attribute '%@' is invalid.", attributeName];
                        break;
                    case NSValidationStringTooLongError:      
                        msg = [NSString stringWithFormat:@"The text of the attribute '%@' is too long.", attributeName];
                        break;
                    case NSValidationStringTooShortError:                 
                        msg = [NSString stringWithFormat:@"The text of the attribute '%@' is too short.", attributeName];
                        break;
                    case NSValidationStringPatternMatchingError:          
                        msg = [NSString stringWithFormat:@"The text of the attribute '%@' doesn't match the required pattern.", attributeName];
                        break;
                    default:
                        msg = [NSString stringWithFormat:@"Unknown error (code %i).", [error code]];
                        break;
                }
				
                messages = [messages stringByAppendingFormat:@"%@%@%@\n", (entityName?:@""),(entityName?@": ":@""),msg];
            }
			
			return messages;
			
        }
    }
	
	return nil;
}

@end
