// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Message.h instead.

#import <CoreData/CoreData.h>


extern const struct MessageAttributes {
	__unsafe_unretained NSString *date;
	__unsafe_unretained NSString *text;
} MessageAttributes;

extern const struct MessageRelationships {
	__unsafe_unretained NSString *user;
} MessageRelationships;

extern const struct MessageFetchedProperties {
} MessageFetchedProperties;

@class User;




@interface MessageID : NSManagedObjectID {}
@end

@interface _Message : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (MessageID*)objectID;




@property (nonatomic, strong) NSDate *date;


//- (BOOL)validateDate:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString *text;


//- (BOOL)validateText:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) User* user;

//- (BOOL)validateUser:(id*)value_ error:(NSError**)error_;




@end

@interface _Message (CoreDataGeneratedAccessors)

@end

@interface _Message (CoreDataGeneratedPrimitiveAccessors)


- (NSDate*)primitiveDate;
- (void)setPrimitiveDate:(NSDate*)value;




- (NSString*)primitiveText;
- (void)setPrimitiveText:(NSString*)value;





- (User*)primitiveUser;
- (void)setPrimitiveUser:(User*)value;


@end
