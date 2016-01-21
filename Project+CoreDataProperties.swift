//  Project+CoreDataProperties.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/18/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

import Foundation
import CoreData

extension Project {
    
    @NSManaged var inputVariableDataHasBeenEntered: Bool //tracker to check whether input variable data has been input for this project @ the current time (used to determine whether to display IV or OM in the DataEntryTV). **Need to check if saving the MOC on a reconstructed object will be saved the next time the app is opened. 
    
    @NSManaged var title: String //project title
    @NSManaged var question: String //question being investigated in the project
    @NSManaged var endPoint: NSNumber? //duration of project in # of days
    @NSManaged var beforeActionVars: Dictionary<String, [String: AnyObject]> //must have at least 1
    @NSManaged var action: String //action separating input variables from outcome variables
    @NSManaged var afterActionVars: Dictionary<String, [String: AnyObject]> //must have at least 1
    
    convenience init(title: String, question: String, endPoint: NSNumber?, action: String, beforeVariables: [String: [String: AnyObject]], afterVariables: [String: [String: AnyObject]], insertIntoManagedObjectContext context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Project", inManagedObjectContext: context)
        self.init(entity: entity!, insertIntoManagedObjectContext: context)
        self.title = title
        self.question = question
        self.endPoint = endPoint
        self.action = action //store the raw value (which is a string)
        self.beforeActionVars = beforeVariables
        self.afterActionVars = afterVariables
        
        //After the object has been inserted, simply save the MOC to make it persist.
    }

    
}
