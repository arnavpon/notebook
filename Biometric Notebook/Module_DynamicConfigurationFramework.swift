//  Module_DynamicConfigurationFramework.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 5/26/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Class that controls the visual presentation of variables to the user during project setup.

import Foundation

class Module_DynamicConfigurationFramework {
    
    var currentLocationInFlow: VariableLocations? //before or afterAction; set by VC
    private var existingVariables: [String: [String: Int]] = [BMN_Blocker_BeforeActionVariablesKey: Dictionary<String, Int>(), BMN_Blocker_AfterActionVariablesKey: Dictionary<String, Int>()] {
        didSet {
            for (keyO, dict) in existingVariables {
                for (keyI, value) in dict {
                    print("\n[existingVars] OUTER KEY = \(keyO). INNER KEY = [\(keyI)]. VALUE = [\(value)].")
                }
            }
        }
    }
//    private lazy var existingVariables: [String: [String: Int]] = [BMN_Blocker_BeforeActionVariablesKey: Dictionary<String, Int>(), BMN_Blocker_AfterActionVariablesKey: Dictionary<String, Int>()]
    private var allVariables: Set<(String)> {
        get {
            var temp = Set<String>()
            for (_, type) in existingVariables {
                for (typeName, _) in type {
                    temp.insert(typeName)
                }
            }
            return temp
        }
    }
    private var ccProjectCache: Dictionary<String, Int>? //for CC project - temporarily stores variables for control or comparison (whichever state the user is NOT currently on)
    
    // MARK: - Initializers
    
    init() { }
    
    // MARK: - View Controller Interface
    
    private func getKeyForLocation(location: VariableLocations) -> String { //assigns a key for location
        switch location {
        case .BeforeAction:
            return BMN_Blocker_BeforeActionVariablesKey
        case .AfterAction:
            return BMN_Blocker_AfterActionVariablesKey
        }
    }
    
    func variableWasCreated(location: VariableLocations, typeName: String) {
        let key = getKeyForLocation(location)
        if let typesWithCount = existingVariables[key] {
            var temp = typesWithCount //create temp obj for updating
            if let count = typesWithCount[typeName] { //variable already exists
                let newCount = count + 1 //increment count
                temp[typeName] = newCount //update count for the existing typeName
                print("[\(typeName)] Var EXISTS! New Count: \(newCount).")
            } else { //new variable name
                temp[typeName] = 1 //make new entry for typeName
                print("Creating NEW entry for variable type: [\(typeName)] @ LOCATION = [\(key)]...")
            }
            existingVariables[key] = temp //update real dictionary w/ temp
        }
    }
    
    func variableWasDeleted(location: VariableLocations, typeName: String) {
        let key = getKeyForLocation(location)
        if let typesWithCount = existingVariables[key] {
            var temp = typesWithCount //create temp obj for updating
            if let count = typesWithCount[typeName] { //variable already exists
                let newCount = count - 1 //increment count
                if !(newCount == 0) { //some other variables are still present
                    temp[typeName] = newCount //update count for the typeName
                    print("[\(typeName)] Var Deleted! New Count: \(newCount).")
                } else { //count is 0, remove entry from dict
                    temp[typeName] = nil //remove entry for that typeName
                    print("[\(typeName)] now has a count of 0! Removing type from dict...")
                }
                existingVariables[key] = temp //update real dictionary w/ temp
            } else { //error - deleted variable is not present in dictionary
                print("Error! Variable to be deleted does not exist in dictionary!!!")
            }
        }
    }
    
    func ccProjectWillSwitchState() { //for CC project - this method remembers which input variables were set for both the control & comparison group
        //(1) If there are existing values in the cache, store them to a temp object:
        var temp = Dictionary<String, Int>()
        if let cache = ccProjectCache {
            temp = cache
        }
        
        //(2) Save the current flow's values to the cache:
        if let existingInputVars = existingVariables[BMN_Blocker_BeforeActionVariablesKey] {
            ccProjectCache = existingInputVars //set the IV -> the cache
            
            //(3) Move the temp object's (beforeAction) values -> the existingVars' before_action key:
            existingVariables[BMN_Blocker_BeforeActionVariablesKey] = temp //afterActionVars stay SAME
        }
    }
    
    // MARK: - Module Interface
    
    private func doesSetupContainVariableType(typeName type: String, atLocation: VariableLocations?) -> Bool {
        //Called by self, checks if setup contains a variable of the given typeName @ the given location (optional - if nil check for existence @ EITHER location):
        if let location = atLocation { //location was set
            let key = getKeyForLocation(location)
            if let existingTypes = existingVariables[key] {
                for (existingType, _) in existingTypes {
                    if (existingType == type) { //check if variable matches any existingType
                        return true
                    }
                }
            }
        } else { //no location set, check in allVariables
            if (self.allVariables.contains(type)) {
                return true
            }
        }
        return false //default is NO match
    }
    
    func getFilteredTypesForModule(sender: Modules) -> Set<String> { //called by every module class before constructing the behaviors & computations arrays - based on the module type, current location in flow, & existing variables, this method sends back the items to filter out of the array. Since these variables are strings, they will need to be converted to the module-specific enum type before being used (handled inside module class).
        var filteredTypes = Set<String>()
        
        switch sender { //for each Module subclass, define the rules for displaying the variableTypes (based on uniqueness & position in flow)
        case .CustomModule:
            
            //(1) Block variables based on location in flow:
            if (currentLocationInFlow == VariableLocations.BeforeAction) { //block vars that are ONLY allowed to come AFTER the action
                filteredTypes.insert(CustomModuleVariableTypes.Computation_TimeDifference.rawValue)
            } else if (currentLocationInFlow == VariableLocations.AfterAction) { //block vars that are ONLY allowed to come BEFORE the action
                //
            }
            
            //(2) Block variables based on presence in project (i.e. check for uniqueness);
            if (doesSetupContainVariableType(typeName: CustomModuleVariableTypes.Computation_TimeDifference.rawValue, atLocation: nil)) { //TD must be unique
                filteredTypes.insert(CustomModuleVariableTypes.Computation_TimeDifference.rawValue)
            }
            
        case .BiometricModule:
            
            //(1) Block variables based on location in flow:
            if (currentLocationInFlow == VariableLocations.BeforeAction) { //block vars that are ONLY allowed to come AFTER the action
                filteredTypes.insert(BiometricModule_HeartRateOptions.AverageOverAction.rawValue) //**
            } else if (currentLocationInFlow == VariableLocations.AfterAction) { //block vars that are ONLY allowed to come BEFORE the action
                //
            }
            
            //(2) Block variables based on presence in project (i.e. check for uniqueness);
            if (doesSetupContainVariableType(typeName: BiometricModuleVariableTypes.Computation_Age.rawValue, atLocation: nil)) { //AGE is unique @ any location
                filteredTypes.insert(BiometricModuleVariableTypes.Computation_Age.rawValue)
            }
            if (doesSetupContainVariableType(typeName: BiometricModuleVariableTypes.Computation_BiologicalSex.rawValue, atLocation: nil)) { //SEX is unique @ any location
                filteredTypes.insert(BiometricModuleVariableTypes.Computation_BiologicalSex.rawValue)
            }
            
            //The following are unique to IV/OM (i.e. there can only be 1 per inputs, 1 per outcomes):
            if (doesSetupContainVariableType(typeName: BiometricModuleVariableTypes.Behavior_Height.rawValue, atLocation: currentLocationInFlow)) { //unique @ current location
                filteredTypes.insert(BiometricModuleVariableTypes.Behavior_Height.rawValue)
            }
            if (doesSetupContainVariableType(typeName: BiometricModuleVariableTypes.Behavior_Weight.rawValue, atLocation: currentLocationInFlow)) { //unique @ current location
                filteredTypes.insert(BiometricModuleVariableTypes.Behavior_Weight.rawValue)
            }
            if (doesSetupContainVariableType(typeName: BiometricModuleVariableTypes.Computation_BMI.rawValue, atLocation: currentLocationInFlow)) { //unique @ current location
                filteredTypes.insert(BiometricModuleVariableTypes.Computation_BMI.rawValue)
            }
            
            
        case .EnvironmentModule:
            
            //(1) Block variables based on location in flow:
            if (currentLocationInFlow == VariableLocations.BeforeAction) { //block vars that are ONLY allowed to come AFTER the action
                //
            } else if (currentLocationInFlow == VariableLocations.AfterAction) { //block vars that are ONLY allowed to come BEFORE the action
                //
            }
            
            //(2) Block variables based on presence in project (i.e. check for uniqueness):
            //**
            
        case .FoodIntakeModule:
            
            //(1) Block variables based on location in flow:
            if (currentLocationInFlow == VariableLocations.BeforeAction) { //block vars that are ONLY allowed to come AFTER the action
                //
            } else if (currentLocationInFlow == VariableLocations.AfterAction) { //block vars that are ONLY allowed to come BEFORE the action
                //
            }
            
            //(2) Block variables based on presence in project (i.e. check for uniqueness):
            //**
            
        case .ExerciseModule:
            
            //(1) Block variables based on location in flow:
            if (currentLocationInFlow == VariableLocations.BeforeAction) { //block vars that are ONLY allowed to come AFTER the action
                //
            } else if (currentLocationInFlow == VariableLocations.AfterAction) { //block vars that are ONLY allowed to come BEFORE the action
                //
            }
            
            //(2) Block variables based on presence in project (i.e. check for uniqueness):
            //**
            
        case .CarbonEmissionsModule:
            
            //(1) Block variables based on location in flow:
            if (currentLocationInFlow == VariableLocations.BeforeAction) { //block vars that are ONLY allowed to come AFTER the action
                //
            } else if (currentLocationInFlow == VariableLocations.AfterAction) { //block vars that are ONLY allowed to come BEFORE the action
                //
            }
            
            //(2) Block variables based on presence in project (i.e. check for uniqueness):
            //**
            
        default: //Recipe Module - no dynamic config needed
            break
        }
        
        return filteredTypes
    }
    
}