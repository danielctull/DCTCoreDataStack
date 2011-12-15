// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to User.m instead.

#import "_User.h"

const struct UserAttributes UserAttributes = {
	.name = @"name",
};

const struct UserRelationships UserRelationships = {
	.followers = @"followers",
	.following = @"following",
	.messages = @"messages",
};

const struct UserFetchedProperties UserFetchedProperties = {
};

@implementation UserID
@end

@implementation _User

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"User" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"User";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"User" inManagedObjectContext:moc_];
}

- (UserID*)objectID {
	return (UserID*)[super objectID];
}

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	

	return keyPaths;
}




@dynamic name;






@dynamic followers;

	
- (NSMutableSet*)followersSet {
	[self willAccessValueForKey:@"followers"];
  
	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"followers"];
  
	[self didAccessValueForKey:@"followers"];
	return result;
}
	

@dynamic following;

	
- (NSMutableSet*)followingSet {
	[self willAccessValueForKey:@"following"];
  
	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"following"];
  
	[self didAccessValueForKey:@"following"];
	return result;
}
	

@dynamic messages;

	
- (NSMutableSet*)messagesSet {
	[self willAccessValueForKey:@"messages"];
  
	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"messages"];
  
	[self didAccessValueForKey:@"messages"];
	return result;
}
	





@end
