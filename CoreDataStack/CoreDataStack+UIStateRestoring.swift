
import UIKit

extension CoreDataStack: UIStateRestoring {

	struct Keys {
		static let StoreType = "StoreType"
		static let StoreURL = "StoreURL"
		static let StoreOptions = "StoreOptions"
		static let ModelURL = "ModelURL"
		static let ModelConfiguration = "ModelConfiguration"
	}

	public var objectRestorationClass: AnyObject.Type? {
		return classForCoder
	}

	public func encodeRestorableStateWithCoder(coder: NSCoder) {
		coder.encodeObject(modelInfo.URL, forKey: Keys.ModelURL)
		coder.encodeObject(modelInfo.configuration, forKey: Keys.ModelConfiguration)
		coder.encodeObject(storeInfo.type, forKey: Keys.StoreType)
		coder.encodeObject(storeInfo.options, forKey: Keys.StoreOptions)
		coder.encodeObject(storeInfo.URL, forKey: Keys.StoreURL)
	}
}

extension Stack: UIObjectRestoration {

	public static func objectWithRestorationIdentifierPath(identifierComponents: [String], coder: NSCoder) -> UIStateRestoring? {

		guard
			let identifier = identifierComponents.last,
			let modelURL = coder.decodeObjectOfClass(NSURL.self, forKey: Keys.ModelURL),
			let storeType = coder.decodeObjectOfClass(NSString.self, forKey: Keys.StoreType) as? String
		else {
			return nil
		}

//		let storeOptions = coder.decodeObjectOfClass(, forKey: Keys.StoreOptions

//		let storeInfo: StoreInfo
//		switch storeType {
//		case NSInMemoryStoreType:
//			storeInfo = StoreInfo.Memory(options: [:])
//
//		case NSSQLiteStoreType:
//			storeInfo = StoreInfo.SQL(options: <#T##Options#>, URL: <#T##NSURL#>)
//		case NSBinaryStoreType:
//
//
//
//		}

//
//
//		let stack = Stack(modelInfo: ModelInfo(URL:, storeInfo: <#T##StoreInfo#>)
//
//
//
//		UIApplication.registerObjectForStateRestoration(<#T##object: UIStateRestoring##UIStateRestoring#>, restorationIdentifier: identifier)


	}
}



//
//
//
//
//
//#pragma mark - UIStateRestoring
//
//- (Class<UIObjectRestoration>)objectRestorationClass {
//	return [self class];
//	}
//
//	- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
//		[coder encodeObject:self.storeURL forKey:DCTCoreDataStackProperties.storeURL];
//		[coder encodeObject:self.storeType forKey:DCTCoreDataStackProperties.storeType];
//		[coder encodeObject:self.storeOptions forKey:DCTCoreDataStackProperties.storeOptions];
//		[coder encodeObject:self.modelConfiguration forKey:DCTCoreDataStackProperties.modelConfiguration];
//		[coder encodeObject:self.modelURL forKey:DCTCoreDataStackProperties.modelURL];
//}
//
//#pragma mark - UIObjectRestoration
//
//+ (id<UIStateRestoring>) objectWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder {
//
//	NSURL *storeURL = [coder decodeObjectOfClass:[NSURL class] forKey:DCTCoreDataStackProperties.storeURL];
//	NSString *storeType = [coder decodeObjectOfClass:[NSString class] forKey:DCTCoreDataStackProperties.storeType];
//	NSDictionary *storeOptions = [coder decodeObjectOfClass:[NSDictionary class] forKey:DCTCoreDataStackProperties.storeOptions];
//	NSString *modelConfiguration = [coder decodeObjectOfClass:[NSString class] forKey:DCTCoreDataStackProperties.modelConfiguration];
//	NSURL *modelURL = [coder decodeObjectOfClass:[NSURL class] forKey:DCTCoreDataStackProperties.modelURL];
//
//	DCTCoreDataStack *coreDataStack = [[self alloc] initWithStoreURL:storeURL
//		storeType:storeType
//		storeOptions:storeOptions
//		modelConfiguration:modelConfiguration
//		modelURL:modelURL];
//
//	NSString *identifier = [identifierComponents lastObject];
//	[UIApplication registerObjectForStateRestoration:coreDataStack restorationIdentifier:identifier];
//
//	return coreDataStack;
//}
