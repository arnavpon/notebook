//  DatabaseObject+CoreDataProperties.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 7/2/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// DatabaseObject stores data until it is ready to be pushed to online DB.

import Foundation
import CoreData

extension DatabaseObject {

    @NSManaged var projectTitle: String
    @NSManaged var dataDictionary: [String: [String: AnyObject]]
    @NSManaged var groupType: String
    
    convenience init(title: String, data: [String: [String: AnyObject]], groupType: String, insertIntoManagedObjectContext context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("DatabaseObject", inManagedObjectContext: context)
        self.init(entity: entity!, insertIntoManagedObjectContext: context)
        
        self.projectTitle = title
        self.dataDictionary = data
        self.groupType = groupType
        
        //After the object has been inserted, simply save the MOC to make it persist.
    }

}