//  Counter+CoreDataProperties.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 4/13/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Counter persistence logic.

import Foundation
import CoreData

extension Counter {
    
    @NSManaged var project: Project //relationship -> 'Project' entity (one-to-one)

    @NSManaged var id: NSNumber //unique ID used to keep track of all active counters
    @NSManaged var variableName: String
    @NSManaged var currentCount: NSNumber
    
    convenience init(linkedVar: CustomModule, project: Project, insertIntoManagedObjectContext context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Counter", inManagedObjectContext: context)
        self.init(entity: entity!, insertIntoManagedObjectContext: context)
        
        //Select unique ID for the counter & insert that ID -> UniqueIDs:
        self.variableName = linkedVar.variableName
        self.project = project //set parent project (note - this AUTOMATICALLY sets the Project's groups object due to the inverse relationship!)
        let newID = UniqueIDs.sharedInstance.getUniqueIDForNewCounter()
        if (newID != -1) { //check for failure indicator
            print("Assigned ID for new counter is: \(newID).")
            for activeID in UniqueIDs.sharedInstance.activeCounterIDs {
                print("[ACTIVE] ID: \(activeID).")
            }
            for deactivatedID in UniqueIDs.sharedInstance.deactivatedCounterIDs {
                print("[INACTIVE] ID: \(deactivatedID).")
            }
            self.id = newID
            linkedVar.counterUniqueID = self.id as Int //match ID -> linkedVar's property!
        } else { //ID request failed
            print("[Counter init()] ERROR - no ID could be obtained for the counter!")
        }
        //After the object has been inserted, simply save the MOC to make it persist.
    }
    
    override func prepareForDeletion() { //when the counter is deleted from the context, transfer its uniqueID -> deactivated counters
        print("[prepareForDeletion] Decommissioning ID #\(self.id as Int)...")
        UniqueIDs.sharedInstance.deactivateIDForDeletedCounter(self.id as Int)
        for activeID in UniqueIDs.sharedInstance.activeCounterIDs {
            print("[ACTIVE] ID: \(activeID).")
        }
        for deactivatedID in UniqueIDs.sharedInstance.deactivatedCounterIDs {
            print("[INACTIVE] ID: \(deactivatedID).")
        }
    }
    
}