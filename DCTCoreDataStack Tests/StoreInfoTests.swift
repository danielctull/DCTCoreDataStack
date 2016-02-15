
import XCTest
import CoreData
@testable import DCTCoreDataStack

class StoreInfoTests: XCTestCase {

	func testMemory() {
		let info = StoreInfo.Memory(options: nil)
		XCTAssertEqual(info.type, NSInMemoryStoreType)
		XCTAssertNil(info.options)
		XCTAssertNil(info.URL)
	}

	func testSQL() {
		let URL = NSURL(string: "http://test.com")!
		let info = StoreInfo.SQL(options: nil, URL: URL)
		XCTAssertEqual(info.type, NSSQLiteStoreType)
		XCTAssertNil(info.options)
		XCTAssertEqual(info.URL, URL)
	}

	func testBinary() {
		let URL = NSURL(string: "http://test.com")!
		let info = StoreInfo.Binary(options: nil, URL: URL)
		XCTAssertEqual(info.type, NSBinaryStoreType)
		XCTAssertNil(info.options)
		XCTAssertEqual(info.URL, URL)
	}



}
