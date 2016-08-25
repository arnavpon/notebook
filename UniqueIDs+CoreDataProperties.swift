//  UniqueIDs+CoreDataProperties.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 4/15/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Stores in memory all active & inactive unique IDs for any behaviors that lie outside of the traditional measurement cycle. When a new behavior object is created, it searches the system for the next available ID - either 1 after the last active ID if there are NO deactivated IDs, or the lowest # deactivated ID if any exist.

import Foundation
import CoreData

extension UniqueIDs {

    @NSManaged var activeCounterIDs: Set<Int>
    @NSManaged var deactivatedCounterIDs: Set<Int> 

    convenience init(insertIntoManagedObjectContext context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("UniqueIDs", inManagedObjectContext: context)
        self.init(entity: entity!, insertIntoManagedObjectContext: context)
    }
    
}