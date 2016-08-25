//  UniqueIDs.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 4/15/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// SINGLETON class that keeps track of all counter IDs that are either in use or have been decommissioned. This ensures that only UNIQUE ids will be used for the counters so they can be told apart.

import UIKit
import CoreData

class UniqueIDs: NSManagedObject {
    
    // MARK: - Singleton Definition
    
    static let sharedInstance: UniqueIDs = {
        let instance: UniqueIDs
        let context = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
        let existingInstances = fetchObjectsFromCoreDataStore("UniqueIDs", filterProperty: nil, filterValue: nil) as! [UniqueIDs] //fetch instances
        if (existingInstances.isEmpty) { //NO instance exists yet (1st run)
            instance = UniqueIDs(insertIntoManagedObjectContext: context)
        } else if (existingInstances.count == 1) { //single sharedInstance exists
            instance = existingInstances.first!
        } else { //fatal error, more than 1 instance
            print("[UniqueIDs sharedInstance] Fatal Error! More than 1 instance was found in store!")
            abort()
        }
        return instance
    }()

    // MARK: - Counter ID Logic
    
    func getUniqueIDForNewCounter() -> Int { //returns unique ID for a newly created Counter object
        if (self.deactivatedCounterIDs.isEmpty) { //no deactivated counters
            //Assign the new Counter an ID that is 1 more than the last in the activeIDs array:
            if (self.activeCounterIDs.isEmpty) { //NO existing active counters
                activeCounterIDs.insert(0) //add item -> active IDs
                return 0 //return the 1st available #
            } else { //active counters exist
                if let last = self.activeCounterIDs.sort().last {
                    let next = last + 1 //assign next ID in line
                    activeCounterIDs.insert(next) //add item -> active IDs
                    return next
                }
            }
        } else { //deactivated counters have objects
            //Return the LOWEST available ID # in the array:
            if let first = self.deactivatedCounterIDs.sort().first {
                deactivatedCounterIDs.remove(first) //remove selected ID from deactivated IDs
                activeCounterIDs.insert(first) //insert selected ID into active IDs
                return first
            }
        }
        return -1 //invalid ID # (indicates failure)
    }
    
    func deactivateIDForDeletedCounter(id: Int) { //transfers ID from active -> deactivated object
        self.activeCounterIDs.remove(id)
        self.deactivatedCounterIDs.insert(id)
    }
    
}