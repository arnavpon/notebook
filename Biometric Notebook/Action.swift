//  Actions.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/7/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Enumeration containing a list of possible actions. Is there a way, each time the action pickerView is revealed, to generate an array containing all possible raw values in the enumeration & use this to populate the picker (same goes for the modules TV).

import Foundation

enum Actions: String { //assign raw values (string representations) to each enum case
    
    case Sleep = "Sleep"
    case Exercise = "Exercise"
    case Eat = "Eat"
    
    func generateActionsList() -> [String] { //generate an array containing all possible actions
        let arrayOfEnumItems = ["Sleep", "Exercise", "Eat"]
        return arrayOfEnumItems
    }
    
}

struct Action { //used to create the project action from & store the project action to CoreData
    
    let action: Actions
    
    init(action: String) { //initializer for user selection & CoreData object
        self.action = Actions(rawValue: action)!
    }

}