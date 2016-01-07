//  Project+CoreDataProperties.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/7/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.

import Foundation
import CoreData

extension Project {
    
    @NSManaged var title: String //project title
    @NSManaged var question: String //question being investigated in the project
    @NSManaged var endPoint: NSTimeInterval //duration of project
    @NSManaged var action: String //action separating input variables from outcome variables
    @NSManaged var beforeActionVars: Dictionary<String, AnyObject> //must have at least 1
    @NSManaged var afterActionVars: Dictionary<String, AnyObject> //must have at least 1
    
    convenience init(title: String, question: String, endPoint: NSTimeInterval, action: Actions, inputVars: Dictionary<String, AnyObject>, outcomeVars: Dictionary<String, AnyObject>, insertIntoManagedObjectContext context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Project", inManagedObjectContext: context)
        self.init(entity: entity!, insertIntoManagedObjectContext: context)
        self.title = title
        self.question = question
        self.endPoint = endPoint
        self.action = action.rawValue //store the raw value (which is a string)
        self.beforeActionVars = inputVars
        self.afterActionVars = outcomeVars
        
        //After the object has been inserted, simply save to make it persist.
    }

}
