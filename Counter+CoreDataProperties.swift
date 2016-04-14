//  Counter+CoreDataProperties.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 4/13/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Counter persistence logic.

import Foundation
import CoreData

extension Counter {

    @NSManaged var id: NSNumber //unique ID used to keep track of all active counters
    @NSManaged var variableName: String
    @NSManaged var currentCount: NSNumber
    
    convenience init(name: String, insertIntoManagedObjectContext context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Group", inManagedObjectContext: context)
        self.init(entity: entity!, insertIntoManagedObjectContext: context)
        
        //Select unique ID for the counter:
        self.variableName = name
        
        //After the object has been inserted, simply save the MOC to make it persist.
    }

}
