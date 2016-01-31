//  Actions.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/7/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Enumeration containing a list of possible actions.

import Foundation

enum Actions: String { //assign raw values (string representations) to each enum case
    
    case Sleep = "Sleep"
    case Exercise = "Exercise"
    case Eat = "Eat"
    case Custom = "Custom"
    
}

struct Action { //used to create the project action from & store the project action to CoreData
    
    let action: Actions
    var customAction: String? //should only be set if custom action is set
    
    init(action: Actions, actionName: String?) { //initializer for user selection & CoreData object
        self.action = action
        
        if (self.action == Actions.Custom) { //set name for custom action
            customAction = actionName
        }
    }

}