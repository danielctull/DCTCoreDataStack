
import Foundation

public struct ModelInfo {

	let URL: NSURL
	let configuration: String?

	public init(URL: NSURL, configuration: String? = nil) {
		self.URL = URL
		self.configuration = configuration
	}
}
