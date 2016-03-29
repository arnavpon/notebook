//  Module.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/7/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Superclass containing basic behavior common to all modules. Each variable will be an object of the module class to which they are attached. This module will store the variable name & all associated behaviors. The module should also contain ALL information needed to create the custom TV cell for reporting data. 
// Each Module object should have a designated 'Behaviors' array & a 'Computations' array that will be used as the data sources for the ConfigureModuleVC. The Custom Module also displays a unique 'options' array containing user defined options for data collection. If either the behaviors or computations arrays are empty, then the VC will not display that section in the TV.
// Note about a module's 'Behaviors' - all functionality should be described w/in the class itself. Externally, all the VC should be doing is determining which option was selected, setting the selected option for the module object, & then executing the returned function defined in the module object. This function will tell the VC how to lay out the interface, what information to store, etc. There should be no class-specific logic being executed in the View Controllers - the VC should describe a SINGLE method that knows what information to send & what info it will receive (always in consistent form) from the Module object! We might need to make an enum for each Module's behaviors & then construct the behaviors upon selection. Based on the 'selectedBehavior', the app will communicate w/ the VC during configuration.

import Foundation
import UIKit

class Module {
    //Defines the behaviors that are common to all modules - all modules should include a timeStamp variable (every time a measurement is taken for any kind of module, the current date & time of the recording should be noted down).
    static let modules: [Modules] = [Modules.CustomModule, Modules.EnvironmentModule, Modules.FoodIntakeModule, Modules.ExerciseModule, Modules.BiometricModule, Modules.CarbonEmissionsModule] //list of available modules, update whenever a new one is added
    
    internal var moduleTitle: String = "" //overwrite w/ <> Module enum raw value in each class
    internal let variableName: String //the name given to the variable attached to this module
    internal var sectionsToDisplay: [String] = [] //sections to display in ConfigureModuleVC
    
    //This entire variable may be extraneous!!! Determine @ some point whether to keep or remove (may serve as a model for the configuration options). Migrate the useful behaviors over -> the variable that handles the visual layout for Custom Configuration TV Cells.
    internal var configureModuleLayoutObject: Dictionary<String, AnyObject> { //dataObject for laying out the TV in the ConfigureModuleVC: for each variable to be displayed in ConfigureModuleVC, it needs to know - the # of sections to display, the titles for these sections, the number of rows for each section, the title for each row, & whether each section's rows should be selectable. Additionally, if a given set of rows can be selected, the VC needs to know what behavior to execute if those rows are selected by the user. Any interactive behaviors - e.g. if there are any user created options for the Custom Module, the user can't select a behavior - should also be defined. This 'layout' object should contain all of this information.
        var tempObject = Dictionary<String, AnyObject>()
        
        var viewForSection = Dictionary<String, CustomTableViewHeader>()
        for section in sectionsToDisplay { //assign rows to their respective sections
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
        for section in sectionsToDisplay { //assign rows to their respective sections
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
        
        var selectable = Dictionary<String, Bool>()
        for section in sectionsToDisplay { //dict indicating whether rows in a section can be SELECTED
            switch section {
            case BMNBehaviorsKey:
                selectable[section] = true
            case BMNComputationsKey:
                selectable[section] = true
            default:
                print("[Module - TVLayout] error: default switch")
            }
        }
        tempObject[BMNCellIsSelectableKey] = selectable
        
        var deletable = Dictionary<String, Bool>()
        for section in sectionsToDisplay { //dict indicating whether rows in a section can be DELETED
            switch section {
            case BMNBehaviorsKey:
                deletable[section] = false
            case BMNComputationsKey:
                deletable[section] = false
            default:
                print("[Module - TVLayout] error: default switch")
            }
        }
        tempObject[BMNCellIsDeletableKey] = deletable
        
        return tempObject
    }
    
    internal var configurationOptionsLayoutObject: Dictionary<String, [String]> { //object that handles layout of the ConfigurationOptionsVC (including all custom TV cells)
        //
    }
    
    internal var behaviors: [String] { //override w/ behaviors for each module
        get { //can only get, not set
            return []
        }
    }
    
    internal var computations: [String] { //override w/ computations for each module
        get { //can only get, not set
            return []
        }
    }
    
    //Provide configuration options when Behavior/Computation is selected:
    internal var configurationRequired: Bool = false //indicates if further config is needed for selection
    internal var showTopBar: Bool = false //controls display of topBar (w/ + button) in ConfigOptions (only needed when configuration required is set to TRUE)
    internal var selectedFunctionality: String? { //the behavior OR computation (picked from the enums defined in each module object) that the user selected for this variable (used to communicate w/ Configuration VC).
        didSet { //perform some behavior when set
            if (selectedFunctionality != nil) {
                print("User selected behavior: '\(selectedFunctionality!)'.")
            }
        }
    }
    
    internal var dataReportingCell: BaseTableViewCell? //handles visual layout in Data Entry mode; custom class is assigned based on the selected Behavior/Computation; **make sure that this variable is only set prior to data reporting (when the project is pulled from the CoreData store)
    
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
    
    internal func getDateAndTimeAtMeasurement() -> DateTime { //returns date & time @ measurement
        return DateTime()
    }
}
