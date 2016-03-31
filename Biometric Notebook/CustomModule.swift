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
            var tempObject = super.configureModuleLayoutObject //obtain superclass' dict & ADD TO IT
            
            var alertMessage = Dictionary<String, [String: String]>() //1st key is section name, 2nd key is behavior/computation name, value is a message for the alertController
            var messageForBehavior = Dictionary<String, String>()
            for behavior in behaviors {
                messageForBehavior[behavior] = CustomModuleBehaviors(rawValue: behavior)?.getAlertMessageForBehavior()
            }
            alertMessage[BMN_BehaviorsKey] = messageForBehavior
            var messageForComputation = Dictionary<String, String>()
            for computation in computations {
                messageForComputation[computation] = CustomModuleComputations(rawValue: computation)?.getAlertMessageForComputation()
            }
            alertMessage[BMN_ComputationsKey] = messageForComputation
            tempObject[BMN_AlertMessageKey] = alertMessage //merge dictionaries
            
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
    private var options: [String]? //array of user-created options associated w/ the variable/prompt
    private var rangeScaleParameters: (Int, Int, Int)? //(minimum, maximum, increment)
    
    // MARK: - Initializers
    
    override init(name: String) {
        super.init(name: name)
        self.moduleTitle = Modules.CustomModule.rawValue //title specific to this class
    }
    
    // MARK: - Variable Configuration
    
    internal override func setConfigurationOptionsForSelection() { //handles ALL configuration for ConfigOptionsVC - (1) Sets the topBar visibility; (2) Sets the 'options' value as needed; (3) Constructs the configuration TV cells.
        if let selection = selectedFunctionality { //make sure behavior/computation was selected & only set the configOptionsObject if further configuration is required
            var array: [(ConfigurationOptionCellTypes, Dictionary<String, AnyObject>)] = []
            switch selection {
            case CustomModuleBehaviors.CustomOptions.rawValue:
                
                topBarPrompt = "Add Custom Options"
                //Only 1 config cell is needed (to set the PROMPT if the user desires):
                array.append((ConfigurationOptionCellTypes.SimpleText, [BMN_Configuration_CellDescriptorKey: BMN_CustomModule_CustomOptions_PromptID, BMN_Configuration_CellIsOptionalKey: true, BMN_Configuration_InstructionsLabelKey: "If you want, set a prompt:"]))
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
                
                //3 config cells are needed (asking for minimum, maximum, & increment):
                array.append((ConfigurationOptionCellTypes.SimpleNumber, [BMN_Configuration_CellDescriptorKey: BMN_CustomModule_RangeScale_MinimumID, BMN_Configuration_InstructionsLabelKey: "Minimum for scale (default 0):", BMN_Configuration_DefaultNumberKey: 0])) //minimum value
                array.append((ConfigurationOptionCellTypes.SimpleNumber, [BMN_Configuration_CellDescriptorKey: BMN_CustomModule_RangeScale_MaximumID, BMN_Configuration_InstructionsLabelKey: "Maximum for scale (default 10):", BMN_Configuration_DefaultNumberKey: 10])) //maximum value
                array.append((ConfigurationOptionCellTypes.SimpleNumber, [BMN_Configuration_CellDescriptorKey: BMN_CustomModule_RangeScale_IncrementID, BMN_Configuration_InstructionsLabelKey: "Increment for scale (default 1):", BMN_Configuration_DefaultNumberKey: 1])) //increment value
                
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
    
    internal override func matchConfigurationItemsToProperties(configurationData: [String: AnyObject]) {
        //(1) Takes as INPUT the data that was entered into each configuration cell. (2) Given the var's 'selectedFunctionality', matches the configuration data -> properties in the Module object by accessing specific configuration cell identifiers (in 'HelperFx' > 'Dictionary Keys').
        if let selection = selectedFunctionality {
            switch selection { //only needed for sections that require configuration
            case CustomModuleBehaviors.CustomOptions.rawValue:
                
                self.prompt = configurationData[BMN_CustomModule_CustomOptions_PromptID] as? String
                self.options = configurationData[BMN_CustomModule_CustomOptions_OptionsID] as? [String]
                
            case CustomModuleBehaviors.Scale.rawValue: //inc data is INT
                
                if let min = (configurationData[BMN_CustomModule_RangeScale_MinimumID] as? Int), max = (configurationData[BMN_CustomModule_RangeScale_MaximumID] as? Int), increment = (configurationData[BMN_CustomModule_RangeScale_IncrementID] as? Int) {
                    rangeScaleParameters = (min, max, increment)
                }
                
            case CustomModuleComputations.TimeDifference.rawValue:
                print("time difference...")
            default:
                print("[CustomMod: matchConfigToProps] Error! Default in switch!")
            }
        }
    }
    
    // MARK: - Data Persistence
    
    internal func createDictionaryForCoreDataStore() -> Dictionary<String, AnyObject> { //generates dictionary to be saved by CoreData (this dict will allow full reconstruction of the object into a Module subclass). Each variable will occupy 1 spot in the overall dictionary, so we need to merge these individual dictionaries for each variable into 1 master dictionary. Each variable's dictionary will be indicated by the variable name, so MAKE SURE THERE ARE NO REPEAT NAMES!
        
        //**Instead of having to clear all unrelated variables each time we set functionality for the selected variable, we will control that in this section. ONLY set the coreData dictionary depending on the 'selectedFunctionality'. That way, when the object is recreated in data reporting mode, all of the extraneous information will be removed & we will only be left w/ properties pertaining to the selected behavior/computation. As a result, we don't have to worry about nullifying all extraneous variables when we are creating the 'configurationLayoutOptionsObject'!**
        
        var persistentDictionary: [String: AnyObject] = [BMN_ModuleTitleKey: self.moduleTitle] //moduleTitle matches switch case in 'Project' > 'createModuleObjectFromModuleName' func
        if let headerTitle = self.prompt {
            persistentDictionary[BMN_CustomModule_PromptKey] = headerTitle
        }
        if let opts = self.options {
            persistentDictionary[BMN_CustomModule_OptionsKey] = opts
        }
        return persistentDictionary
    }
    
    // MARK: - View Layout
    
    internal func getOptionsForVariable() -> [String]? { //returns the 'Options' array
        return self.options
    }
    
    internal func getPromptForVariable() -> String? { //returns the 'Options' array
        return self.prompt
    }
    
}

enum CustomModuleBehaviors: String {
    case CustomOptions = "Custom Options" //allows user to enter custom options
    case Binary = "Binary" //automatically creates 2 options, 'Yes' & 'No'.
    case Counter = "Counter" //creates an incrementable counter
    case Scale = "<Range Scale>" //gives users the option to select a value on a scale from A - B, where the user selects what the lower & upper limits are when they adopt this behavior; in data entry mode, the user will then select a value from this range using a slider/picker (TBD).
    
    func getAlertMessageForBehavior() -> String { //provides an informative pop-up about the behavior
        var message = ""
        switch self { //**Adjust the raw values so that they are more specific!!!
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
            message = "Calculates a time difference between 2 variables or between a variable and the project's action."
        }
        return message
    }
}