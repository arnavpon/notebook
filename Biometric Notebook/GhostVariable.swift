//  GhostVariable.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 5/25/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Structure used to create & hold ghost variables during project setup.

import Foundation

struct GhostVariable {
    
    let groupType: CCProjectNavigationState?
    let locationInFlow: VariableLocations
    let computation: String
    let name: String
    let settings: [String: AnyObject]
    
    init(groupType: CCProjectNavigationState?, location: VariableLocations, computation: String, name: String, settings: [String: AnyObject]) {
        self.groupType = groupType
        self.locationInFlow = location
        self.computation = computation
        self.name = name
        self.settings = settings
    }
    
}