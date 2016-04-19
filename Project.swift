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
    
    // MARK: - Auto-Captured Variable Logic
    
    func obtainAutoCaptureData() -> [String: [String: AnyObject]] { //set this as a completion!
        let autoCapturedData = Dictionary<String, [String: AnyObject]>()
        return autoCapturedData //**make completion
    }
    
    //flexible way to obtain data for auto-captured variables: (1) TYPE 1 - variables that are automatically captured 1 time just before the DB object is generated (i.e. when 'Done' button is pressed in VC); (2) TYPE 2 - data captured from sensors (how to handle this is TBD).
    //When variables are going to be reported, we need to check if any of the variables w/in a given set of IV or OM are auto-captured. If so, we need to collect that data @ this time -
    //(1) Need method to check if there are auto-captured variables - needs to introspectively check which of its groups is being reported, whether IV or OM are being reported, & for that group, determine which vars are auto vs. manual.
    //(2) Need flexible method to have all of these variables report their data back before generating the final dict - this is tricky b/c it will require access to HealthKit, Location services, etc. & if these are disabled, we won't be able to collect that info. We must prompt the user to enable that info sooner (e.g. when they open the DataEntryVC, prompt them even before DoneBtn is hit). All of the data will be reported asynchronously, aggregated w/ the manually reported data, & sent -> DB. **We could place a method inside the Module class that ONLY works for auto-cap vars, & is similar to the REPORT DATA fx in TV cells. When called by the Project class or VC, it executes an overriden functionality that sends back the data for that variable in a dictionary against its name [varName: data].
    //When do we obtain the data & how do we handle the fact that data will be returned asynchronously (hence we cannot collect it when the Done btn is pressed [OR CAN WE & just send the data asynchronously?]).
    //For type II variables (sensor data), we will need to create a separate DB table b/c the entries will not be collected @ the same frequency as other data (OR SHOULD WE SET IT SO THE RATES MATCH?).
    
}