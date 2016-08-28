//  Datastream+CoreDataProperties.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 8/24/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Datastream Superclass - defines common behaviors to all objects that utilize datastreams (e.g. FoodIntake & Workout behaviors).

import Foundation
import CoreData

extension Datastream {

    @NSManaged var streamID: String //used to match stream -> subclass objects
    @NSManaged var temporaryStorageObject: [String: AnyObject]? //holds data while stream is open
    @NSManaged var cachedData: [NSDate: AnyObject]? //stores data from last [X] closed datastreams, depending on subclass type; KEY = date when entry was cached
    
    convenience init(streamID: String, insertIntoManagedObjectContext context: NSManagedObjectContext) { //default init
        let entity = NSEntityDescription.entityForName("Datastream", inManagedObjectContext: context)
        self.init(entity: entity!, insertIntoManagedObjectContext: context)
        
        self.streamID = streamID //set ID
        self.temporaryStorageObject = nil //*do NOT delete - required for protocol conformance*
        
        //After the object has been inserted, simply save the MOC to make it persist.
    }

}