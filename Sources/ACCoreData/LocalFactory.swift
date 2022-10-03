//
//  LocalFactory.swift
//  ACCoreData
//
//  Created by AppCraft LLC on 8/23/21.
//

import CoreData

public enum LocalFactory {
    
    public static func request(_ entityClass: AnyClass, predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]?) -> NSFetchRequest<NSManagedObject> {
        let request: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: String.className(entityClass))
        
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        
        return request
    }
    
    public static func sortDescriptor(key: String, ascending: Bool) -> NSSortDescriptor {
        return NSSortDescriptor(key: key, ascending: ascending)
    }
}

extension String {
    static func className(_ aClass: AnyClass) -> String {
        NSStringFromClass(aClass).components(separatedBy: ".").last ?? ""
    }
}

