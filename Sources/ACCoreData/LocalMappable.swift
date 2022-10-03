//
//  LocalMappable.swift
//  ACCoreData
//
//  Created by AppCraft LLC on 8/23/21.
//

import CoreData
import Foundation

public protocol LocalMappable {
    func mapEntityToDomain() -> AnyObject
    func mapEntityFromDomain(data: AnyObject)
}

public extension LocalMappable {
    
    func mapEntityToDomain() -> AnyObject {
        NSLog("[\(self)] - Error: Entity to domain mapper not implemented")
        
        return self as AnyObject
    }
    
    func mapEntityFromDomain(data: AnyObject) {
        NSLog("[\(self)] - Error: Domain to entity mapper not implemented")
    }
}
