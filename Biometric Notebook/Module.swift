//  Module.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/7/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Superclass containing basic behavior common to all modules. Each variable will be an object of the module class to which they are attached. This module will store the variable name & all associated behaviors.

import Foundation

class Module {
    //what kinds of behavior are common to all modules? All modules should include a timeStamp variable (every time a measurement is taken for any kind of module, the current date & time of the recording should be noted down as well).
    internal var moduleTitle: String = "" //overwrite w/ specific module name in each class
    internal let variableName: String //the name given to the variable attached to this module
    
    init(name: String) {
        self.variableName = name
    }
    
    internal func getDateAndTimeAtMeasurement() -> DateTime { //returns date & time @ measurement
        return DateTime()
    }
}
