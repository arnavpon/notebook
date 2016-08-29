//  FIM_FoodIntakeDataStream.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 8/28/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Food Intake Module > defines behaviors for the food intake data stream.

// For FI vars - if stream is NOT open, it allows the user to either open a new stream or to use cached data from the last completed stream. New streams CANNOT be opened until the existing stream is closed. FIV CANNOT use data from outside the current stream if data has been collected already for the locations that were selected during configuration - e.g. if breakfast has already been consumed & data reported, ONLY the existing breakfast data for the current stream can be used for the variable.

import UIKit
import CoreData

class FIM_FoodIntakeDatastream: Datastream {

    // MARK: - Singleton Definition
    
    static let sharedInstance: FIM_FoodIntakeDatastream = {
        let instance: FIM_FoodIntakeDatastream
        let context = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
        let existingInstances = fetchObjectsFromCoreDataStore("Datastream_FoodIntake", filterProperty: "streamID", filterValue: [DatastreamIdentifiers.FIM_FoodIntake.rawValue]) as! [FIM_FoodIntakeDatastream]
        if (existingInstances.isEmpty) { //NO instance exists yet (1st run) - create it
            instance = FIM_FoodIntakeDatastream(insertIntoManagedObjectContext: context)
            let id = instance.objectID.description
            print("Shared Instance ID = [\(id)]")
        } else if (existingInstances.count == 1) { //SINGLE sharedInstance exists
            instance = existingInstances.first!
        } else { //fatal error - more than 1 instance
            print("[FIM_FoodIntakeDataStream sharedInstance] Fatal Error! > 1 instance found in store!")
            abort()
        }
        return instance
    }()
    
    // MARK: - Stream Logic
    
    func writeToDatastream(data: [String : AnyObject]) {
        //
    }
    
    func readFromDatastream() {
        //
    }
    
    // MARK: - Protocol Logic
    
    override func getVariablesForSelectedGroup(selection: Int?) -> [Module]? { //return 1 dummy variable
        let foodIntakeVariable = FoodIntakeModule() //use Datastream init
        return [foodIntakeVariable]
    }
    
    override func repopulateDataObjectForSubscribedVariables(erroredService service: ServiceTypes) {
        //requires Internet service - repopulate when internet is provided???
    }

}