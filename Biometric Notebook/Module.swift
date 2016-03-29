//  Module.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/7/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Superclass containing basic behavior common to all modules. Each variable will be an object of the module class to which they are attached. This module will store the variable name & all associated behaviors. The module should also contain ALL information needed to configure the variable's behaviors & create the custom TV cell for reporting data.
// Note about a module's 'Behaviors' - all functionality should be described w/in the class itself. Externally, all the VC should be doing is determining which option was selected, setting the selected option for the module object, & then executing the returned function defined in the module object. This function will tell the VC how to lay out the interface, what information to store, etc. There should be no class-specific logic being executed in the View Controllers - the VC should describe a SINGLE method that knows what information to send & what info it will receive (always in consistent form) from the Module object! We might need to make an enum for each Module's behaviors & then construct the behaviors upon selection. Based on the 'selectedFunctionality', the app will communicate w/ the VC during configuration.

import Foundation
import UIKit

class Module { //defines the behaviors that are common to all modules
    static let modules: [Modules] = [Modules.CustomModule, Modules.EnvironmentModule, Modules.FoodIntakeModule, Modules.ExerciseModule, Modules.BiometricModule, Modules.CarbonEmissionsModule] //list of available modules, update whenever a new one is added
    
    internal var moduleTitle: String = "" //overwrite w/ <> Module enum raw value in each class
    internal let variableName: String //the name given to the variable attached to this module
    internal var sectionsToDisplay: [String] = [] //sections to display in ConfigureModuleVC
    
    //This entire variable may be extraneous!!! Determine @ some point whether to keep or remove (may serve as a model for the configuration options). Migrate the useful behaviors over -> the variable that handles the visual layout for Custom Configuration TV Cells.
    internal var configureModuleLayoutObject: Dictionary<String, AnyObject> { //dataObject for laying out the behaviors & computations in the ConfigureModuleVC
        var tempObject = Dictionary<String, AnyObject>()
        
        var viewForSection = Dictionary<String, CustomTableViewHeader>()
        for section in sectionsToDisplay { //assign headerViews to their respective sections
            switch section { 
            case BMNBehaviorsKey:
                viewForSection[section] = CustomTableViewHeader(frame: CGRect(x: 0, y: 0, width: 0, height: 24), text: "Available Behaviors")
            case BMNComputationsKey:
                viewForSection[section] = CustomTableViewHeader(frame: CGRect(x: 0, y: 0, width: 0, height: 24), text: "Available Computations")
            default:
                print("[Custom - TVLayout viewForSection] error: default switch")
            }
        }
        tempObject[BMNViewForSectionKey] = viewForSection
        
        var rowsForSection = Dictionary<String, [String]>()
        for section in sectionsToDisplay { //assign behaviors & computations to their respective sections
            switch section {
            case BMNBehaviorsKey:
                rowsForSection[section] = behaviors
            case BMNComputationsKey:
                rowsForSection[section] = computations
            default:
                print("[Module - TVLayout] error: default switch")
            }
        }
        tempObject[BMNRowsForSectionKey] = rowsForSection
        
        return tempObject
    }
    
    internal var behaviors: [String] { //override w/ behaviors for each module
        get { //can only GET, not set
            return []
        }
    }
    
    internal var computations: [String] { //override w/ computations for each module
        get { //can only GET, not set
            return []
        }
    }
    
    //Variable's Configuration Options:
    internal var topBarPrompt: String? //text for instructionLabel in topBar
    internal var selectedFunctionality: String? { //the behavior OR computation (picked from the enums defined in each module object) that the user selected for this variable
        didSet { //set configurationOptions based on selection
            print("User selected behavior: '\(selectedFunctionality!)'.")
            setConfigurationOptionsForSelection()
        }
    }
    internal var configurationOptionsLayoutObject: [(ConfigurationOptionCellTypes, Dictionary<String, AnyObject>)]? //obj that handles layout of ConfigurationOptionsVC TV cells
    
    // MARK: - Initializers
    
    init(name: String) {
        self.variableName = name
        
        //Add items to 'sectionsToDisplay' array for ConfigureModuleVC:
        if !(behaviors.isEmpty) { //check if there are behaviors to display
            self.sectionsToDisplay.append(BMNBehaviorsKey)
        }
        if !(computations.isEmpty) { //check if there are computations to display
            self.sectionsToDisplay.append(BMNComputationsKey)
        }
    }
    
    // MARK: - Basic Behaviors
    
    internal func getDateAndTimeAtMeasurement() -> DateTime { //returns date & time @ measurement
        //All modules should include a timeStamp variable (every time a measurement is taken for any kind of module, the current date & time of the recording should be noted down).
        return DateTime()
    }
    
    internal func setConfigurationOptionsForSelection() { //override in subclasses
        //Assigns configurationOptions based on the user's selection of a behavior/computation
        configurationOptionsLayoutObject = nil
    }
}
