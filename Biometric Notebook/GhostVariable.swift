//  GhostVariable.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 5/25/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Struct used to create & hold ghost variables during project setup.

import Foundation

struct GhostVariable {
    
    let computation: String //ghost var's parent computation
    let name: String //ghost var's name
    let settings: [String: AnyObject] //config dict for ghost var
    
    init(computation: String, name: String, settings: [String: AnyObject]) {
        self.computation = computation
        self.name = name
        self.settings = settings
    }
    
}