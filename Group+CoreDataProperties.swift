//  Group+CoreDataProperties.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 4/13/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Contains all necessary info for persisting a Project's experimental group's variables & action.

import Foundation
import CoreData

extension Group {

    @NSManaged var project: Project //relationship -> 'Project' entity (one-to-one b/c each group can only have 1 parent project)
    
    @NSManaged var groupType: String //type of group (rawValue of 'GroupTypes' enum - control vs. comp)
    @NSManaged var afterActionVariables: Dictionary<String, [String: AnyObject]> //input vars
    @NSManaged var action: String //action separating input variables from output variables
    @NSManaged var beforeActionVariables: Dictionary<String, [String: AnyObject]> //output vars
    
    convenience init(type: GroupTypes, project: Project, action: String, beforeVariables: [String: [String: AnyObject]], afterVariables: [String: [String: AnyObject]], insertIntoManagedObjectContext context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Group", inManagedObjectContext: context)
        self.init(entity: entity!, insertIntoManagedObjectContext: context)
        
        //Configure before & afterActionVars - dictionary format = ["VAR_NAME": ["VARIABLE_PROPERTY": CONFIGURATION_OBJECT]]:
        self.beforeActionVariables = beforeVariables
        self.action = action //store the raw value (which is a string)
        self.afterActionVariables = afterVariables
        self.groupType = type.rawValue
        self.project = project //set parent project (note - this AUTOMATICALLY sets the Project's groups object due to the inverse relationship!)
        
        //After the object has been inserted, simply save the MOC to make it persist.
    }
    
}