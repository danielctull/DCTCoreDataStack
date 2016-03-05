
import XCTest
import CoreDataStack

class CoreDataStackTests: XCTestCase {

	var modelURL: NSURL {
		return NSBundle(forClass: CoreDataStackTests.self).URLForResource("Model", withExtension: "momd")!
	}

	func testMemoryStack() {
		let storeInfo = StoreInfo.Memory(options: nil)
		let modelInfo = ModelInfo(URL: modelURL)
		let stack = CoreDataStack(modelInfo: modelInfo, storeInfo: storeInfo)

		let model = try! stack.managedObjectModel()
		XCTAssertNotNil(model)

		let coordinator = try! stack.persistentStoreCoordinator()
		XCTAssertNotNil(coordinator)

		let context = try! stack.managedObjectContext()
		XCTAssertNotNil(context)

		// All these properties should provide the same objects back
		XCTAssertEqual(try! stack.managedObjectModel(), model)
		XCTAssertEqual(try! stack.persistentStoreCoordinator(), coordinator)
		XCTAssertEqual(try! stack.managedObjectContext(), context)


		try! stack.destroyStore()

		// Destroying the store resets the stack
		XCTAssertNotEqual(try! stack.persistentStoreCoordinator(), coordinator)
		XCTAssertNotEqual(try! stack.managedObjectContext(), context)
	}
}
