
import Foundation
import CoreData

public class CoreDataStack {

	public let storeInfo: StoreInfo
	public let modelInfo: ModelInfo

	public init(modelInfo: ModelInfo, storeInfo: StoreInfo) {
		self.storeInfo = storeInfo
		self.modelInfo = modelInfo
	}

	public func destroyStore() throws {

		if let URL = storeInfo.URL {
			try _coordinator?.destroyPersistentStoreAtURL(URL, withType: storeInfo.type, options: storeInfo.options)
		}

		_coordinator = nil
		_context = nil
	}

	// MARK: Managed Object Model

	private var _model: NSManagedObjectModel?
	public func managedObjectModel() throws -> NSManagedObjectModel {

		if let model = _model {
			return model
		}

		guard let model = NSManagedObjectModel(contentsOfURL: modelInfo.URL) else {
			throw Error.InvalidModelURL
		}

		_model = model
		return model
	}

	// MARK: Persistent Store Coordinator

	private var _coordinator: NSPersistentStoreCoordinator?
	public func persistentStoreCoordinator() throws -> NSPersistentStoreCoordinator {

		if let coordinator = _coordinator {
			return coordinator
		}

		let model = try managedObjectModel()
		let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
		try coordinator.addPersistentStoreWithType(storeInfo.type, configuration: modelInfo.configuration, URL: storeInfo.URL, options: storeInfo.options)

		_coordinator = coordinator
		return coordinator
	}

	// MARK: Managed Object Context

	private var _context: NSManagedObjectContext?
	public func managedObjectContext() throws -> NSManagedObjectContext {

		if let context = _context {
			return context
		}

		let coordinator = try persistentStoreCoordinator()
		let context = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
		context.persistentStoreCoordinator = coordinator

		_context = context
		return context
	}
}
