//  FIM_FoodIntakeDataStream+CoreDataProperties.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 8/28/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

import Foundation
import CoreData

extension FIM_FoodIntakeDatastream {

    convenience init(insertIntoManagedObjectContext context: NSManagedObjectContext) { //default init
        let entity = NSEntityDescription.entityForName("Datastream_FoodIntake", inManagedObjectContext: context)
        self.init(entity: entity!, insertIntoManagedObjectContext: context)
        
        self.streamID = DatastreamIdentifiers.FIM_FoodIntake.rawValue //set FoodIntake streamID
        self.temporaryStorageObject = nil //*do NOT delete - required for protocol conformance*
        
        //After the object has been inserted, simply save the MOC to make it persist.
    }

}