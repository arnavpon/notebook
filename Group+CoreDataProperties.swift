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
    @NSManaged var groupName: String //UNIQUE name used for Project w/ multiple groups
    @NSManaged var action: [String: AnyObject] //dict containing Action configuration info
    @NSManaged var variables: Dictionary<String, [String: AnyObject]> //variables contained in group
    @NSManaged var measurementCycleLength: NSNumber //defines total # of reports for this Group
    @NSManaged var timeDifferenceVars: Dictionary<String, [String: AnyObject]>? //list of default TD vars
    
    convenience init(groupName: String, groupType: GroupTypes, project: Project, action: Action, variables: [String: [String: AnyObject]], cycleLength: Int, timeDifferenceVars: Dictionary<String, [String: AnyObject]>?, insertIntoManagedObjectContext context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Group", inManagedObjectContext: context)
        self.init(entity: entity!, insertIntoManagedObjectContext: context)
        
        self.groupName = groupName //unique ID
        self.groupType = groupType.rawValue
        self.action = action.constructCoreDataObjectForAction() //store the CoreData dict
        self.variables = variables //'variables' dictionary format = ["VAR_NAME": ["VARIABLE_PROPERTY": CONFIGURATION_OBJECT]]
        self.measurementCycleLength = cycleLength
        self.timeDifferenceVars = timeDifferenceVars //store TD vars if any exist
        
        self.project = project //set parent Project (note - this AUTOMATICALLY sets the Project's groups object due to the inverse relationship!)
        
        //After the object has been inserted, simply save the MOC to make it persist.
    }
    
}