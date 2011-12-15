// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to User.h instead.

#import <CoreData/CoreData.h>


extern const struct UserAttributes {
	__unsafe_unretained NSString *name;
} UserAttributes;

extern const struct UserRelationships {
	__unsafe_unretained NSString *followers;
	__unsafe_unretained NSString *following;
	__unsafe_unretained NSString *messages;
} UserRelationships;

extern const struct UserFetchedProperties {
} UserFetchedProperties;

@class User;
@class User;
@class Message;



@interface UserID : NSManagedObjectID {}
@end

@interface _User : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (UserID*)objectID;




@property (nonatomic, strong) NSString *name;


//- (BOOL)validateName:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSSet* followers;

- (NSMutableSet*)followersSet;




@property (nonatomic, strong) NSSet* following;

- (NSMutableSet*)followingSet;




@property (nonatomic, strong) NSSet* messages;

- (NSMutableSet*)messagesSet;




@end

@interface _User (CoreDataGeneratedAccessors)

- (void)addFollowers:(NSSet*)value_;
- (void)removeFollowers:(NSSet*)value_;
- (void)addFollowersObject:(User*)value_;
- (void)removeFollowersObject:(User*)value_;

- (void)addFollowing:(NSSet*)value_;
- (void)removeFollowing:(NSSet*)value_;
- (void)addFollowingObject:(User*)value_;
- (void)removeFollowingObject:(User*)value_;

- (void)addMessages:(NSSet*)value_;
- (void)removeMessages:(NSSet*)value_;
- (void)addMessagesObject:(Message*)value_;
- (void)removeMessagesObject:(Message*)value_;

@end

@interface _User (CoreDataGeneratedPrimitiveAccessors)


- (NSString*)primitiveName;
- (void)setPrimitiveName:(NSString*)value;





- (NSMutableSet*)primitiveFollowers;
- (void)setPrimitiveFollowers:(NSMutableSet*)value;



- (NSMutableSet*)primitiveFollowing;
- (void)setPrimitiveFollowing:(NSMutableSet*)value;



- (NSMutableSet*)primitiveMessages;
- (void)setPrimitiveMessages:(NSMutableSet*)value;


@end
