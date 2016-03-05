
import Foundation

public struct ModelInfo {

	public let URL: NSURL
	public let configuration: String?

	public init(URL: NSURL, configuration: String? = nil) {
		self.URL = URL
		self.configuration = configuration
	}
}
