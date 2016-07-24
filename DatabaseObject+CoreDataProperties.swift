//  DatabaseObject+CoreDataProperties.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 7/2/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// DatabaseObject stores data until it is ready to be pushed to online DB. This data can be reported information from the user, a system-created project backup, etc.

import Foundation
import CoreData

extension DatabaseObject {
    
    @NSManaged var projectTitle: String //indicates Project being affected by DB operation
    @NSManaged var dataDictionary: [String: AnyObject] //data to push to DB
    @NSManaged var dataTypeRaw: NSNumber //rawValue for DBConnDataTypes enum (indicates type of data)
    
    convenience init(title: String, data: [String: AnyObject], dataType: DatabaseConnectionDataTypes, insertIntoManagedObjectContext context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("DatabaseObject", inManagedObjectContext: context)
        self.init(entity: entity!, insertIntoManagedObjectContext: context)
        self.projectTitle = title
        self.dataDictionary = data
        self.dataTypeRaw = dataType.rawValue
        
        //After the object has been inserted, simply save the MOC to make it persist.
    }
    
}