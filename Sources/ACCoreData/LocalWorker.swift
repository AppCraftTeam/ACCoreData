//
//  LocalWorker.swift
//  ACCoreData
//
//  Created by AppCraft LLC on 8/23/21.
//

import UIKit
import CoreData

public protocol LocalWorkerInterface: AnyObject {
    func create(entityName: String) -> NSManagedObject
    func save(completion: @escaping(_ result: Bool, _ error: Error?) -> Void)
    
    func fetch(_ request: NSFetchRequest<NSManagedObject>, completion: @escaping(_ result: [NSManagedObject]?, _ error: Error?) -> Void)
    func remove(_ entities: [NSManagedObject], completion: @escaping(_ result: Bool, _ error: Error?) -> Void)
}

open class LocalWorker: LocalWorkerInterface {
    
    // MARK: Props
    private var mainContext: NSManagedObjectContext
    private var privateContext: NSManagedObjectContext
    
    // MARK: - Initialization
    public init(modelName: String) {
        guard let objectModelUrl = Bundle.main.url(forResource: modelName, withExtension: "momd") else {
            fatalError("[LocalWorker] - Error: Could not load model from bundle")
        }
        guard let objectModel = NSManagedObjectModel(contentsOf: objectModelUrl) else {
            fatalError("[LocalWorker] - Error: Could not init model from \(objectModelUrl)")
        }
        
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: objectModel)
        
        self.mainContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        self.mainContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        self.mainContext.persistentStoreCoordinator = coordinator
        
        let storeURL: URL = {
            let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            if urls.indices.contains(urls.endIndex - 1) {
                let docURL = urls[urls.endIndex - 1]
                let storeURL = docURL.appendingPathComponent("\(modelName).sqlite")
                return storeURL
            } else {
                fatalError("[LocalWorker] - Error: Failure loading store")
            }
        }()
        
        let options = [
            NSInferMappingModelAutomaticallyOption: true,
            NSMigratePersistentStoresAutomaticallyOption: true
        ]
        
        do {
            if #available(watchOS 8.0, iOS 15.0, *) {
                _ = try coordinator.addPersistentStore(type: .sqlite, at: storeURL, options: options)
            } else {
                try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: options)
            }
        } catch let error {
            fatalError("[LocalWorker] - Error: Could not migrate store: \(error.localizedDescription)")
        }
        
        self.privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        self.privateContext.parent = mainContext
        self.privateContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    deinit {
        self.saveMainContext()
    }
    
    // MARK: - LocalWorkerInterface
    public func create(entityName: String) -> NSManagedObject {
        NSEntityDescription.insertNewObject(forEntityName: entityName, into: self.privateContext)
    }
    
    public func save(completion: @escaping(_ result: Bool, _ error: Error?) -> Void) {
        self.privateContext.perform {
            self.savePrivateContext(completion: { (result, error) in
                completion(result, error)
            })
        }
    }
    
    public func fetch(_ request: NSFetchRequest<NSManagedObject>, completion: @escaping(_ result: [NSManagedObject]?, _ error: Error?) -> Void) {
        self.privateContext.perform {
            do {
                let results = try self.privateContext.fetch(request)
                
                completion(results, nil)
            } catch let error {
                NSLog("[LocalWorker] - Error: Could not fetch requst \(request): \(error.localizedDescription)")
                
                completion(nil, error)
            }
        }
    }
    
    public func remove(_ entities: [NSManagedObject], completion: @escaping(_ result: Bool, _ error: Error?) -> Void) {
        self.privateContext.perform {
            for entity in entities {
                self.privateContext.delete(entity)
            }
            
            self.savePrivateContext(completion: { (result, error) in
                completion(result, error)
            })
        }
    }
    
    // MARK: - Module functions
    private func saveMainContext() {
        self.mainContext.performAndWait {
            do {
                try self.mainContext.save()
                
                NSLog("[LocalWorker] - Success saving main managed object context")
            } catch let error {
                NSLog("[LocalWorker] - Error: Could not save main managed object context: \(error.localizedDescription)")
                
                fatalError("[LocalWorker] - Error: Could not save main managed object context: \(error.localizedDescription)")
            }
        }
    }
    
    private func savePrivateContext(completion: @escaping(_ result: Bool, _ error: Error?) -> Void) {
        if self.privateContext.hasChanges {
            do {
                try self.privateContext.save()
                
                self.saveMainContext()
                
                completion(true, nil)
            } catch let error {
                NSLog("[LocalWorker] - Error: Could not save context: \(error.localizedDescription)")
                
                completion(false, error)
            }
        } else {
            completion(false, nil)
        }
    }
}
