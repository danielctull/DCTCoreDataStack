
import Foundation

public enum StoreInfo {

	public typealias Options = [String : AnyObject]

	case Memory(options: Options)
	case SQL(options: Options, URL: NSURL)
	case Binary(options: Options, URL: NSURL)
}

extension StoreInfo {

	var type: String {
		switch self {
			case .Memory: return NSInMemoryStoreType
			case .SQL: return NSSQLiteStoreType
			case .Binary: return NSBinaryStoreType
		}
	}

	var URL: NSURL? {
		switch self {
			case .Memory: return nil
			case .SQL(_, let URL): return URL
			case .Binary(_, let URL): return URL
		}
	}

	var options: Options {
		switch self {
			case .Memory(let options): return options
			case .SQL(let options, _): return options
			case .Binary(let options, _): return options
		}
	}
}
