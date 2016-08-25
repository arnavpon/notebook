//  FIM_FoodIntakeDataStream.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 8/24/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Food Intake Module > defines behaviors for the food intake data stream.

import UIKit
import CoreData

class FIM_FoodIntakeDataStream: Datastream {
    
    // MARK: - Singleton Definition
    
    static let sharedInstance: FIM_FoodIntakeDataStream = {
        let instance: FIM_FoodIntakeDataStream
        let context = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
        let existingInstances = fetchObjectsFromCoreDataStore("Datastream", filterProperty: "streamID", filterValue: [DatastreamIdentifiers.FIM_FoodIntake.rawValue]) as! [Datastream]
        if (existingInstances.isEmpty) { //NO instance exists yet (1st run) - create it
            instance = FIM_FoodIntakeDataStream(streamID: DatastreamIdentifiers.FIM_FoodIntake.rawValue, insertIntoManagedObjectContext: context)
            let id = instance.objectID.description
            print("Shared Instance ID = [\(id)]")
        } else if (existingInstances.count == 1) { //single sharedInstance exists
            if let foodIntakeDatastreamInstance = existingInstances.first as? FIM_FoodIntakeDataStream {
                instance = foodIntakeDatastreamInstance
                let id = instance.objectID.description
                print("Shared Instance ID = [\(id)]")
            } else {
                print("[FIM_FoodIntakeDataStream sharedInstance] Fatal Error!")
                abort()
            }
        } else { //fatal error, more than 1 instance
            print("[FIM_FoodIntakeDataStream sharedInstance] Fatal Error! > 1 instance found in store!")
            abort()
        }
        return instance
    }()
    
    // MARK: - Stream Logic
    
    override func writeToDatastream() {
        //
    }
    
    override func readFromDatastream() {
        //
    }
    
}