//  CustomModule.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/7/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Module used to capture text based information based on a variable & its options. When we store this information to CoreData, we create a dictionary containing all necessary information & pass this to the managed object. When the app is reopened, this dictionary is broken down to produce individual components, which will be used for data capture.
// In a custom module, the user can either enter a prompt (to replace the variable name as a section title), their own options, or select a behavior from a pre-built list.

import Foundation
import UIKit

class CustomModule: Module {
    
    override var configureModuleLayoutObject: Dictionary<String, AnyObject> {
        get {
            //This whole viewLayout object needs to be reworked since we are only laying out the options in the ConfigurationOptionsVC. Remove extraneous stuff!
            var tempObject = Dictionary<String, AnyObject>()
            
            var viewForSection = Dictionary<String, CustomTableViewHeader>()
            for section in sectionsToDisplay { //assign rows to their respective sections
                switch section { //use the lowercare string for the dict key
                case BMNBehaviorsKey:
                    viewForSection[section] = CustomTableViewHeader(frame: CGRect(x: 0, y: 0, width: 0, height: 24), text: "Available Behaviors")
                case BMNComputationsKey:
                    viewForSection[section] = CustomTableViewHeader(frame: CGRect(x: 0, y: 0, width: 0, height: 24), text: "Available Computations")
                default:
                    print("[Custom - TVLayout] error: default switch [viewForSection]")
                }
            }
            tempObject[BMNViewForSectionKey] = viewForSection
            
            var rowsForSection = Dictionary<String, [String]>()
            for section in sectionsToDisplay { //assign rows to their respective sections
                switch section {
                case BMNCustomModuleOptionsKey:
                    rowsForSection[section] = options
                case BMNBehaviorsKey:
                    rowsForSection[section] = behaviors
                case BMNComputationsKey:
                    rowsForSection[section] = computations
                default:
                    print("[Custom - TVLayout] error: default switch")
                }
            }
            tempObject[BMNRowsForSectionKey] = rowsForSection
            
            var selectable = Dictionary<String, Bool>() //**may be obsolete now (all rows should be selectable in ConfigModuleVC)
            for section in sectionsToDisplay { //dict indicating whether rows in a section can be selected
                switch section {
                case BMNCustomModuleOptionsKey:
                    selectable[section] = false
                case BMNBehaviorsKey:
                    selectable[section] = true
                case BMNComputationsKey:
                    selectable[section] = true
                default:
                    print("Custom - TVLayout] error: default switch")
                }
            }
            tempObject[BMNCellIsSelectableKey] = selectable
            
            var alertMessage = Dictionary<String, [String: String]>() //1st key is section name, 2nd key is behavior/computation name, value is a message for the alertController
            var messageForBehavior = Dictionary<String, String>()
            for behavior in behaviors {
                messageForBehavior[behavior] = CustomModuleBehaviors(rawValue: behavior)?.getAlertMessageForBehavior()
            }
            alertMessage[BMNBehaviorsKey] = messageForBehavior
            var messageForComputation = Dictionary<String, String>()
            for computation in computations {
                messageForComputation[computation] = CustomModuleComputations(rawValue: computation)?.getAlertMessageForComputation()
            }
            alertMessage[BMNComputationsKey] = messageForComputation
            tempObject[BMNAlertMessageKey] = alertMessage //merge dictionaries
            
            var deletable = Dictionary<String, Bool>()
            for section in sectionsToDisplay { //dict indicating whether rows in a section can be deleted
                switch section { 
                case BMNCustomModuleOptionsKey:
                    deletable[section] = true
                case BMNBehaviorsKey:
                    deletable[section] = false
                case BMNComputationsKey:
                    deletable[section] = false
                default:
                    print("Custom - TVLayout] error: default switch")
                }
            }
            tempObject[BMNCellIsDeletableKey] = deletable
            
            //**This stuff may be extraneous:
            tempObject["buttons"] = ["add", "prompt"] //indicate if there are any buttons that need to be added to the view (CustomMod needs a + button for adding options & a 'prompt' button for adding an options prompt). 
            //Custom view creation paradigm: create the view object in the Module class declaration & then add it to the superview (applying any view resizing/formatting) in the VC.
            
            return tempObject
        }
    }
    
    override var configurationOptionsLayoutObject: Dictionary<String, [String]> {
        //
    }
    
    private let customModuleBehaviors: [CustomModuleBehaviors] = [CustomModuleBehaviors.CustomOptions, CustomModuleBehaviors.Binary, CustomModuleBehaviors.Counter, CustomModuleBehaviors.Scale]
    override var behaviors: [String] { //'behaviors' = instance variables containing pre-defined behaviors that the module can adopt in place of the standard user-created options
        var behaviorTitles: [String] = []
        for behavior in customModuleBehaviors {
            behaviorTitles.append(behavior.rawValue)
        }
        return behaviorTitles
    } //HIDE these options if the user creates any of their own choices!
    
    private let customModuleComputations: [CustomModuleComputations] = [CustomModuleComputations.TimeDifference]
    override var computations: [String] {
        var computationTitles: [String] = []
        for computation in customModuleComputations {
            computationTitles.append(computation.rawValue)
        }
        return computationTitles
    }
    
    override var selectedFunctionality: String? { //handle selection of a behavior/computation (by assigning a SPECIFIC class to the TV cell object for data reporting)
        didSet { //when user selects a behavior, set the options accordingly; disable the + button so that user cannot add further items & enable the 'Save' option in the VC
            if let function = selectedFunctionality {
                switch function {
                case CustomModuleBehaviors.CustomOptions.rawValue:
                    configurationRequired = true
                    showTopBar = true
                case CustomModuleBehaviors.Binary.rawValue:
                    options = ["Yes", "No"]
                    configurationRequired = false
                case CustomModuleBehaviors.Counter.rawValue:
                    configurationRequired = false
                    //clear 'options' property
                case CustomModuleBehaviors.Scale.rawValue:
                    configurationRequired = true
                    showTopBar = false
                    //clear 'options' property
                case CustomModuleComputations.TimeDifference.rawValue: 
                    configurationRequired = true
                    showTopBar = false
                    //clear 'options' property
                default:
                    print("[Custom] error: default switch 'selectedBehavior'")
                }
            }
        }
    }
    
    private var prompt: String? //the (optional) prompt attached to the variable (replaces the variable's name as the section header in Data Entry mode)
    var options: [String] = [] //array of user-created options associated w/ the variable/prompt
    
    override init(name: String) {
        super.init(name: name)
        self.moduleTitle = Modules.CustomModule.rawValue //title specific to this class
    }
    
    // MARK: - View Layout
    
    internal func createDictionaryForCoreDataStore() -> Dictionary<String, AnyObject> { //generates dictionary to be saved by CoreData (this dict will allow full reconstruction of the object into a Module subclass). Each variable will occupy 1 spot in the overall dictionary, so we need to merge these individual dictionaries for each variable into 1 master dictionary. Each variable's dictionary will be indicated by the variable name, so MAKE SURE THERE ARE NO REPEAT NAMES!
        var persistentDictionary: [String: AnyObject] = [BMNModuleTitleKey: self.moduleTitle, BMNCustomModuleOptionsKey: self.options] //moduleTitle matches switch case in 'Project' > 'createModuleObjectFromModuleName' func
        if let headerTitle = prompt {
            persistentDictionary[BMNCustomModulePromptKey] = headerTitle
        }
        return persistentDictionary
    }
    
    internal func getOptionsForVariable() -> [String] { //returns the 'Options' array
        return self.options
    }
    
    internal func getPromptForVariable() -> String? { //returns the 'Options' array
        return self.prompt
    }
    
    internal func setPromptForVariable(prompt: String) { //returns the 'Options' array
        self.prompt = prompt
    }
}

enum CustomModuleBehaviors: String {
    case CustomOptions = "Custom Options" //allows user to enter custom options
    case Binary = "Binary" //automatically creates 2 options, 'Yes' & 'No'.
    case Counter = "Counter" //creates an incrementable counter
    case Scale = "<Range Scale>" //gives users the option to select a value on a scale from A - B, where the user selects what the lower & upper limits are when they adopt this behavior; in data entry mode, the user will then select a value from this range using a slider/picker (TBD).
    
    func getAlertMessageForBehavior() -> String { //provides an informative pop-up about the behavior
        var message = ""
        switch self {
        case .CustomOptions:
            message = "Create custom selection options."
        case .Binary:
            message = "A binary configuration offers two options - 'Yes' and 'No'. Useful for variables with only two possibilities."
        case .Counter:
            message = "A counter that allows you to keep track of how many times something has occurred."
        case .Scale:
            message = "A scale allows you to pick an integer value between the minimum and the maximum value that you set."
        }
        return message
    }
}

enum CustomModuleComputations: String {
    case TimeDifference = "Time Difference" //for configuration, need to select variables between which to calculate the time difference (as an animation, have a drag line that triggers when it runs over another variable or the project action, but disappears if placed outside of allowed location)
    
    func getAlertMessageForComputation() -> String { //provides an informative pop-up about the comp
        var message = ""
        switch self {
        case .TimeDifference:
            message = "Calculates a time difference between 2 variables or a variable and the project's action."
        }
        return message
    }
}