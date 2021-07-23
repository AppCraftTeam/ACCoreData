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
    
    // MARK: - Props
    private var mainContext: NSManagedObjectContext
    private var privateContext: NSManagedObjectContext
    
    // MARK: - Initialization
    public init(modelName: String) {
        guard let objectModelUrl = Bundle.main.url(forResource: modelName, withExtension: "momd") else {
            NSLog("[LocalWorker] - Error: Could not load model from bundle")
            
            fatalError("[LocalWorker] - Error: Could not load model from bundle")
        }
        
        guard let objectModel = NSManagedObjectModel(contentsOf: objectModelUrl) else {
            NSLog("[LocalWorker] - Error: Could not init model from \(objectModelUrl)")
            
            fatalError("[LocalWorker] - Error: Could not init model from \(objectModelUrl)")
        }
        
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: objectModel)
        
        self.mainContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        self.mainContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        self.mainContext.persistentStoreCoordinator = coordinator
        
        let fileManagerUrls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentUrl = fileManagerUrls[fileManagerUrls.endIndex - 1]
        
        let storeUrl = documentUrl.appendingPathComponent("\(modelName).sqlite")
        let options = [NSMigratePersistentStoresAutomaticallyOption: true,
                       NSInferMappingModelAutomaticallyOption: true]
        do {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeUrl, options: options)
        } catch let error {
            NSLog("[LocalWorker] - Error: Could not migrate store: \(error.localizedDescription)")
            
            fatalError("[LocalWorker] - Error: Could not migrate store: \(error.localizedDescription)")
        }
        
        self.privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        self.privateContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        self.privateContext.parent = self.mainContext
    }
    
    deinit {
        self.saveMainContext()
    }
    
    // MARK: - LocalWorkerInterface
    public func create(entityName: String) -> NSManagedObject {
        return NSEntityDescription.insertNewObject(forEntityName: entityName, into: self.privateContext)
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
