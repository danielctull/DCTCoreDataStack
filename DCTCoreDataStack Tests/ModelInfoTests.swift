
import XCTest
import DCTCoreDataStack

class ModelInfoTests: XCTestCase {

	func testModelInfo() {
		let URL = NSURL(string: "http://test.com")!
		let info = ModelInfo(URL: URL)
		XCTAssertEqual(info.URL, URL)
		XCTAssertNil(info.configuration)
	}

	func testConfiguration() {
		let URL = NSURL(string: "http://test.com")!
		let configuration = "Configuration"
		let info = ModelInfo(URL: URL, configuration: configuration)
		XCTAssertEqual(info.URL, URL)
		XCTAssertEqual(info.configuration, configuration)
	}
}
