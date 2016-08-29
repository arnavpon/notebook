//  ExM_ExerciseDatastream+CoreDataProperties.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 8/28/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

import Foundation
import CoreData

extension ExM_ExerciseDatastream {
    
    convenience init(insertIntoManagedObjectContext context: NSManagedObjectContext) { //default init
        let entity = NSEntityDescription.entityForName("Datastream_Workout", inManagedObjectContext: context)
        self.init(entity: entity!, insertIntoManagedObjectContext: context)
        
        self.streamID = DatastreamIdentifiers.ExM_Workout.rawValue //set Workout streamID
        self.temporaryStorageObject = nil //*do NOT delete - required for protocol conformance*
        
        //After the object has been inserted, simply save the MOC to make it persist.
    }

}