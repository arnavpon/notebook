//  Project+CoreDataProperties.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/18/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

import Foundation
import CoreData

extension Project {
    
    @NSManaged var groups: NSSet //relationship -> 'Group' entity (one-to-many b/c each project contains multiple groups); INVERSE of 'project' relationship in Group class (modifying one automatically adjusts the other); *one-to-many objects must be of NSSet type*
    //Each group in the project's 'groups' relationship must have a unique identifier so that it can be told apart during data entry from other groups. 
    @NSManaged var counters: NSSet //relationship -> 'Counter' entity (one-to-many)
    
    @NSManaged var temporaryStorageObject: [String: [String: AnyObject]]? //temporarily holds the inputsVariables data during a single measurement cycle (e.g. while the action is being performed). After the action, this temporarily held data + outputVariables are sent -> DB. || tracker to check whether input variable data has been input for this project @ the current time (used to determine whether to display IV or OM in the DataEntryTV).
    
    @NSManaged var projectType: String //string representation for ExperimentTypes enum
    @NSManaged var title: String //project title
    @NSManaged var question: String //question being investigated in the project
    @NSManaged var hypothesis: String? //(optional) hypothesis for the project
    @NSManaged var startDate: NSDate //date on which project was created
    @NSManaged var endDate: NSDate? //end date for project (start date + endpoint)
    @NSManaged var isActive: Bool //var indicating if project is Active (TRUE) or Expired (FALSE)
    
    convenience init(type: ExperimentTypes, title: String, question: String, hypothesis: String?, endPoint: NSTimeInterval?, insertIntoManagedObjectContext context: NSManagedObjectContext) { //application init
        let entity = NSEntityDescription.entityForName("Project", inManagedObjectContext: context)
        self.init(entity: entity!, insertIntoManagedObjectContext: context)
        
        self.projectType = type.rawValue
        self.title = title
        self.question = question
        self.hypothesis = hypothesis
        self.isActive = true //project starts as ACTIVE
        
        //Use the entered 'endPoint' to configure the start & end date properties:
        self.startDate = NSDate() //get the current date
        let start = DateTime(date: startDate).getFullTimeStamp()
        print("Formatted Start: '\(start)'.")
        if let end = endPoint { //project w/ defined endpoint
            self.endDate = startDate.dateByAddingTimeInterval(end)
            let ending = DateTime(date: endDate!) //**remove after stable
            print("Formatted End: '\(ending.getFullTimeStamp())'.")
        } else { //project w/ undefined endpoint
            self.endDate = nil //set endDate -> nil
        }
        
        //After the object has been inserted, simply save the MOC to make it persist.
    }
    
    convenience init(type: ExperimentTypes, title: String, question: String, hypothesis: String?, startDate: Double, endpoint: Double?, insertIntoManagedObjectContext context: NSManagedObjectContext) { //CLOUD init
        let entity = NSEntityDescription.entityForName("Project", inManagedObjectContext: context)
        self.init(entity: entity!, insertIntoManagedObjectContext: context)
        
        self.projectType = type.rawValue
        self.title = title
        self.question = question
        self.hypothesis = hypothesis
        self.startDate = NSDate(timeIntervalSinceReferenceDate: startDate)
        if let end = endpoint {
            self.endDate = NSDate(timeInterval: end, sinceDate: self.startDate)
            print("Project END DATE = \(DateTime(date: endDate!).getFullTimeStamp()).")
            let currentDate = NSDate()
            let difference = currentDate.timeIntervalSinceDate(endDate!)
            if (difference >= 0) { //current date > end date (INACTIVE)
                self.isActive = false
            } else { //end date > current date (ACTIVE)
                self.isActive = true
            }
        } else {
            self.isActive = true //no endpoint => ACTIVE project
        }
        
        //After the object has been inserted, simply save the MOC to make it persist.
    }
    
}