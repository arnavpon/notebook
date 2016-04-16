//  Project.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/7/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// This CoreData object is a representation of the structure of each user-created project. The object is used to store in memory the project framework so that it can be accessed by other portions of the app.

//Each PROJECT contains 1 or more groups. Each group represents a SINGLE control or comparison group. The 'Group' class describes the input & outcome variables + action. The 'Project' class encapsulates all groups & project-specific variables (endpoint, title, question, hypothesis, etc.).

import Foundation
import CoreData

class Project: NSManagedObject {
    
    private var experimentType: ExperimentTypes? { //get projectType as an enum object
        return ExperimentTypes(rawValue: self.projectType)
    }
    
    // MARK: - External Access
    
    func getProjectTypeForDisplay() -> String? { //obtains a display-friendly projectType for VC
        return experimentType?.getTypeNameForDisplay()
    }
    
    func checkProjectCompletionStatus() { //checks if project is ACTIVE or INACTIVE
        if (self.isActive) { //ONLY perform check if project is currently active
            let currentDate = NSDate()
            if let end = endDate { //check if project has expiry date
                print("[CURRENT] \(DateTime(date: currentDate).getFullTimeStamp())")
                print("[END] \(DateTime(date: end).getFullTimeStamp())")
                if (currentDate.timeIntervalSinceReferenceDate >= end.timeIntervalSinceReferenceDate) {
                    //Project has expired - perform cleanup (delete all associated counter objects, block data reporting, etc.):
                    print("'\(self.title)' Project has expired!.")
                    self.isActive = false
                    for object in self.counters { //delete any associated Counter objects
                        if let counter = object as? Counter {
                            deleteManagedObject(counter)
                        }
                    }
                    saveManagedObjectContext() //persist all changes
                }
            }
        }
    }
    
    func refreshMeasurementCycle() { //refreshes counters & tempStorage obj (called automatically @ end of measurement cycle or manually by user)
        self.temporaryStorageObject = nil //clear temp object
        for object in self.counters { //refresh each counter
            if let counter = object as? Counter {
                counter.refreshCounter()
            }
        }
        saveManagedObjectContext() //persist all changes
    }
    
    // MARK: - Project Endpoint Logic
    
    internal func getPercentageCompleted() -> Double? { //calculates what % of project is complete
        let currentDate = NSDate() //get current time
        let currentTimeElapsed = abs(self.startDate.timeIntervalSinceDate(currentDate)) //proj run length
//        print("Current Time Elapsed: \(currentTimeElapsed).")
        if let totalTimeDifference = self.endDate?.timeIntervalSinceDate(self.startDate) { //total length
            let percentCompleted = Double(currentTimeElapsed / abs(totalTimeDifference))
//            print("Total Time Difference: \(totalTimeDifference).")
//            print("% Complete = \(percentCompleted * 100)%.")
            return percentCompleted
        }
        return nil //indefinite project (NO % value)
    }
    
}