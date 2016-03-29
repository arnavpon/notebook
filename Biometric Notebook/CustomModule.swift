//  CustomModule.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/7/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Module used to capture text based information based on a variable & its options. When we store this information to CoreData, we create a dictionary containing all necessary information & pass this to the managed object. When the app is reopened, this dictionary is broken down to produce individual components, which will be used for data capture.

import Foundation
import UIKit

class CustomModule: Module {
    
    override var configureModuleLayoutObject: Dictionary<String, AnyObject> {
        get {
            var tempObject = super.configureModuleLayoutObject //obtain super's dict & ADD TO IT
            
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
            
            return tempObject
        }
    }
    
    private let customModuleBehaviors: [CustomModuleBehaviors] = [CustomModuleBehaviors.CustomOptions, CustomModuleBehaviors.Binary, CustomModuleBehaviors.Counter, CustomModuleBehaviors.Scale]
    override var behaviors: [String] {
        var behaviorTitles: [String] = []
        for behavior in customModuleBehaviors {
            behaviorTitles.append(behavior.rawValue)
        }
        return behaviorTitles
    }
    
    private let customModuleComputations: [CustomModuleComputations] = [CustomModuleComputations.TimeDifference]
    override var computations: [String] {
        var computationTitles: [String] = []
        for computation in customModuleComputations {
            computationTitles.append(computation.rawValue)
        }
        return computationTitles
    }
    
    private var prompt: String? //the (optional) prompt attached to the variable (replaces the variable's name as the section header in Data Entry mode)
    private var options: [String] = [] //array of user-created options associated w/ the variable/prompt
    
    override init(name: String) {
        super.init(name: name)
        self.moduleTitle = Modules.CustomModule.rawValue //title specific to this class
    }
    
    // MARK: - Configuration Options
    
    internal override func setConfigurationOptionsForSelection() { //handles ALL configuration for ConfigOptionsVC - (1) Sets the topBar visibility; (2) Sets the 'options' value as needed; (3) Constructs the configuration TV cells.
        if let selection = selectedFunctionality { //make sure behavior/computation was selected & only set the configOptionsObject if further configuration is required
            var array: [(ConfigurationOptionCellTypes, Dictionary<String, AnyObject>)] = []
            switch selection {
            case CustomModuleBehaviors.CustomOptions.rawValue:
                
                topBarPrompt = "Add Custom Options"
                //Only 1 config cell is needed (to set the PROMPT if the user desires):
                array.append((ConfigurationOptionCellTypes.SimpleText, [BMNInstructionsLabelKey: "If you want, set a prompt:"]))
                configurationOptionsLayoutObject = array
                
            case CustomModuleBehaviors.Binary.rawValue:
                
                options = ["Yes", "No"]
                topBarPrompt = nil
                configurationOptionsLayoutObject = nil //no further config needed
                
            case CustomModuleBehaviors.Counter.rawValue:
                
                topBarPrompt = nil
                options = [] //clear options
                configurationOptionsLayoutObject = nil //no further config needed
                
            case CustomModuleBehaviors.Scale.rawValue:
                topBarPrompt = nil
                options = [] //clear options
                
                //3 config cells are needed (asking for minimum, maximum, & increment): **need to indicate default values to the TV through the data source
                array.append((ConfigurationOptionCellTypes.SimpleNumber, [BMNInstructionsLabelKey: "Enter a minimum value for your scale (default 0):", BMNDefaultNumberKey: 0]))
                array.append((ConfigurationOptionCellTypes.SimpleNumber, [BMNInstructionsLabelKey: "Enter a maximum value for your scale (default 10):", BMNDefaultNumberKey: 10]))
                array.append((ConfigurationOptionCellTypes.SimpleNumber, [BMNInstructionsLabelKey: "Enter an increment value for your scale (default 1):", BMNDefaultNumberKey: 1]))
                configurationOptionsLayoutObject = array
                
            case CustomModuleComputations.TimeDifference.rawValue:
                
                topBarPrompt = nil
                options = [] //clear options
                
            default:
                print("[CustomMod: getConfigOptions] Error - default in switch!")
            }
        } else { //no selection, set configOptionsObj -> nil
            configurationOptionsLayoutObject = nil
        }
    }
    
    // MARK: - Data Persistence
    
    internal func createDictionaryForCoreDataStore() -> Dictionary<String, AnyObject> { //generates dictionary to be saved by CoreData (this dict will allow full reconstruction of the object into a Module subclass). Each variable will occupy 1 spot in the overall dictionary, so we need to merge these individual dictionaries for each variable into 1 master dictionary. Each variable's dictionary will be indicated by the variable name, so MAKE SURE THERE ARE NO REPEAT NAMES!
        var persistentDictionary: [String: AnyObject] = [BMNModuleTitleKey: self.moduleTitle, BMNCustomModuleOptionsKey: self.options] //moduleTitle matches switch case in 'Project' > 'createModuleObjectFromModuleName' func
        if let headerTitle = prompt {
            persistentDictionary[BMNCustomModulePromptKey] = headerTitle
        }
        return persistentDictionary
    }
    
    // MARK: - View Layout
    
    internal func getOptionsForVariable() -> [String] { //returns the 'Options' array
        return self.options
    }
    
    internal func setOptionsForVariable(add: Bool, option: String) { //if 'add' is TRUE, append the option; if 'add' is FALSE, delete that option from the array
        if (add) { //append new option
            self.options.append(option)
        } else { //remove option from array
            if let index = self.options.indexOf(option) {
                self.options.removeAtIndex(index)
            }
        }
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