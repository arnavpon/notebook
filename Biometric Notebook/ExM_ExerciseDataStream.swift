//  ExM_ExerciseDataStream.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 8/24/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Exercise Module > defines behaviors for the exercise data stream that enables the input of workout-related data.

import UIKit

class ExM_ExerciseDataStream: Datastream {
    
    // MARK: - Singleton Definition
    
    static let sharedInstance: ExM_ExerciseDataStream = {
        let instance: ExM_ExerciseDataStream
        let context = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
        let existingInstances = fetchObjectsFromCoreDataStore("Datastream", filterProperty: "streamID", filterValue: [DatastreamIdentifiers.ExM_Workout.rawValue]) as! [Datastream] //fetch instances
        if (existingInstances.isEmpty) { //NO instance exists yet (1st run) - create it
            instance = ExM_ExerciseDataStream(streamID: DatastreamIdentifiers.ExM_Workout.rawValue, insertIntoManagedObjectContext: context)
            let id = instance.objectID.description
            print("Shared Instance ID = [\(id)]")
        } else if (existingInstances.count == 1) { //single sharedInstance exists
            if let exerciseDataStream = existingInstances.first as? ExM_ExerciseDataStream {
                instance = exerciseDataStream
                let id = instance.objectID.description
                print("Shared Instance ID = [\(id)]")
            } else {
                print("[ExM_ExerciseDataStream sharedInstance] Fatal Error!")
                abort()
            }
        } else { //fatal error, more than 1 instance
            print("[ExM_ExerciseDataStream sharedInstance] Fatal Error! > 1 instance found in store!")
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