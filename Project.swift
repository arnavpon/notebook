//  Project.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/7/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// This CoreData object is a representation of the structure of each user-created project. The object is used to store in memory the project framework so that it can be accessed by other portions of the app.

//Each PROJECT contains 1 or more groups. Each group represents a SINGLE control or comparison group. The 'Group' class describes the input & outcome variables + action. The 'Project' class encapsulates all groups & project-specific variables (endpoint, title, question, hypothesis, etc.).

import Foundation
import CoreData

class Project: NSManagedObject {
    
    // MARK: - External Access
    
    func getProjectTypeForDisplay() -> String? { //obtains a display-friendly projectType
        if let type = ExperimentTypes(rawValue: self.projectType) {
            return type.getTypeNameForDisplay()
        }
        return nil
    }
    
    // MARK: - Data Reporting Logic
    
    internal func getInputVariablesForProjectType() {
        //externally facing method - based on some criteria, pulls up the input variables for the section of the project that is CURRENTLY being measured.
    }
    
    // MARK: - Project Endpoint Logic
    
    internal func getPercentageCompleted() -> Double? { //calculates what % of project is complete
        let currentDate = NSDate() //get current time
        let currentTimeElapsed = abs(self.startDate.timeIntervalSinceDate(currentDate)) //proj run length
        print("Current Time Elapsed: \(currentTimeElapsed).")
        if let totalTimeDifference = self.endDate?.timeIntervalSinceDate(self.startDate) { //total length
            let percentCompleted = Double(currentTimeElapsed / abs(totalTimeDifference))
            print("Total Time Difference: \(totalTimeDifference).")
            print("% Complete = \(percentCompleted * 100)%.")
            return percentCompleted
        }
        return nil //indefinite project (NO % value)
    }
    
}