/*
 NSManagedObjectContext+FRCCoreDataStack.m
 FRCCoreDataStack
 
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

#import "NSManagedObjectContext+FRCCoreDataStack.h"
#import <objc/runtime.h>

@implementation NSManagedObjectContext (FRCCoreDataStack)

- (void)setFrc_name:(NSString *)name {
	objc_setAssociatedObject(self, @selector(frc_name), name, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)frc_name {
	return objc_getAssociatedObject(self, @selector(frc_name));
}

- (void)frc_save {
	[self frc_saveWithCompletionHandler:^(BOOL success, NSError *error) {
		if (!success) NSLog(@"%@", [self frc_detailedDescriptionFromValidationError:error]);
	}];
}

- (void)frc_saveWithCompletionHandler:(FRCManagedObjectContextSaveCompletionBlock)passedCompletionHandler {
	
	dispatch_queue_t queue = dispatch_get_current_queue();
	
	FRCManagedObjectContextSaveCompletionBlock completionHandler = NULL;
	
	if (passedCompletionHandler != NULL) {
		
		completionHandler = ^(BOOL success, NSError *error){
			dispatch_async(queue, ^{
				passedCompletionHandler(success, error);
			});
		};
	}
	
	NSError *error = nil;
	BOOL success = [self save:&error];
	
	if (completionHandler != NULL)
		completionHandler(success, error);
}

- (NSString *)frc_detailedDescriptionFromValidationError:(NSError *)anError {
	
    if (![[anError domain] isEqualToString:@"NSCocoaErrorDomain"]) return nil;
	
	NSArray *errors = nil;
	
	if ([anError code] == NSValidationMultipleErrorsError)
		errors = [[anError userInfo] objectForKey:NSDetailedErrorsKey];
	else
		errors = [NSArray arrayWithObject:anError];
	
	if ([errors count] == 0) return nil;
	
	NSMutableString *messages = [[NSMutableString alloc] initWithFormat:@"NSManagedObjectContext with name %@ failed to save with the following reason%@:", 
								 self.frc_name,
								 (([errors count] > 1)?@"s":@"")];
	
	for (NSError *error in errors) {
		
		NSString *entityName = [[[[error userInfo] objectForKey:@"NSValidationErrorObject"] entity] name];
		NSString *attributeName = [[error userInfo] objectForKey:@"NSValidationErrorKey"];
		
		NSString *message = nil;
		
		switch ([error code]) {
			case NSManagedObjectValidationError:
				message = @"Generic validation error.";
				break;
			case NSValidationMissingMandatoryPropertyError:
				message = [NSString stringWithFormat:@"The attribute '%@' must not be empty.", attributeName];
				break;
			case NSValidationRelationshipLacksMinimumCountError:  
				message = [NSString stringWithFormat:@"The relationship '%@' doesn't have enough entries.", attributeName];
				break;
			case NSValidationRelationshipExceedsMaximumCountError:
				message = [NSString stringWithFormat:@"The relationship '%@' has too many entries.", attributeName];
				break;
			case NSValidationRelationshipDeniedDeleteError:
				message = [NSString stringWithFormat:@"To delete, the relationship '%@' must be empty.", attributeName];
				break;
			case NSValidationNumberTooLargeError:                 
				message = [NSString stringWithFormat:@"The number of the attribute '%@' is too large.", attributeName];
				break;
			case NSValidationNumberTooSmallError:                 
				message = [NSString stringWithFormat:@"The number of the attribute '%@' is too small.", attributeName];
				break;
			case NSValidationDateTooLateError:                    
				message = [NSString stringWithFormat:@"The date of the attribute '%@' is too late.", attributeName];
				break;
			case NSValidationDateTooSoonError:                    
				message = [NSString stringWithFormat:@"The date of the attribute '%@' is too soon.", attributeName];
				break;
			case NSValidationInvalidDateError:                    
				message = [NSString stringWithFormat:@"The date of the attribute '%@' is invalid.", attributeName];
				break;
			case NSValidationStringTooLongError:      
				message = [NSString stringWithFormat:@"The text of the attribute '%@' is too long.", attributeName];
				break;
			case NSValidationStringTooShortError:                 
				message = [NSString stringWithFormat:@"The text of the attribute '%@' is too short.", attributeName];
				break;
			case NSValidationStringPatternMatchingError:          
				message = [NSString stringWithFormat:@"The text of the attribute '%@' doesn't match the required pattern.", attributeName];
				break;
			default:
				message = [NSString stringWithFormat:@"Unknown error (code %i).", [error code]];
				break;
		}
		
		[messages appendFormat:@"\n    %@%@%@%@%@", (entityName?:@""), (attributeName?@".":@""), (attributeName?:@""), (entityName?@": ":@""), message];
	}
	
	return messages;
}

@end