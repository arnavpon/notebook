//  Datastream+CoreDataProperties.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 8/24/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Datastream Superclass - defines common behaviors to all objects that utilize datastreams (e.g. FoodIntake & Workout behaviors).

import Foundation
import CoreData

extension Datastream {

    @NSManaged var streamID: String //used to match stream -> subclass objects
    @NSManaged var sharedDataObject: [String: AnyObject]
    
    convenience init(streamID: String, insertIntoManagedObjectContext context: NSManagedObjectContext) { //default init
        let entity = NSEntityDescription.entityForName("Datastream", inManagedObjectContext: context)
        self.init(entity: entity!, insertIntoManagedObjectContext: context)
        
        self.streamID = streamID //set ID
        self.sharedDataObject = Dictionary<String, AnyObject>() //initialize dictionary
        
        //After the object has been inserted, simply save the MOC to make it persist.
    }

}