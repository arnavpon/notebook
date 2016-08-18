//  Module_DynamicConfigurationFramework.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 5/26/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Class that controls the visual presentation of variables to the user during project setup.

import UIKit

class Module_DynamicConfigurationFramework {
    
    var currentVarConfigType: ModuleConfigurationTypes? //set by VC
    private var existingVariables: [String: [String: Int]] = [BMN_DynamicConfig_InputVariablesKey: Dictionary<String, Int>(), BMN_DynamicConfig_OutcomeMeasuresKey: Dictionary<String, Int>()] //sorts variableTypes according to IV vs. OM
    private var allVariables: Set<(String)> { //master list of ALL variable types in Project
        get {
            var temp = Set<String>() //unique set of all var functionalities in project
            for (_, functionalityDict) in existingVariables {
                for (functionality, _) in functionalityDict {
                    temp.insert(functionality)
                }
            }
            return temp
        }
    }
    
    // MARK: - Initializers
    
    init() { }
    
    // MARK: - View Controller Interface
    
    private func getKeyForConfigType(type: ModuleConfigurationTypes) -> String { //assigns key -> location
        switch type {
        case .InputVariable:
            return BMN_DynamicConfig_InputVariablesKey
        case .OutcomeMeasure:
            return BMN_DynamicConfig_OutcomeMeasuresKey
        default:
            return "" //AQ has no location in dict (DCF is used to block certain variables from appearing)
        }
    }
    
    func variableWasCreated(type: ModuleConfigurationTypes, selectedFunctionality: String) {
        let key = getKeyForConfigType(type)
        if let typesWithCount = existingVariables[key] {
            var temp = typesWithCount //create temp obj for updating
            if let count = typesWithCount[selectedFunctionality] { //variable already exists
                let newCount = count + 1 //increment count
                temp[selectedFunctionality] = newCount //update count for the existing typeName
                print("[\(selectedFunctionality)] Var EXISTS! New Count: \(newCount).")
            } else { //new variable name
                temp[selectedFunctionality] = 1 //make new entry for typeName
                print("Creating NEW entry for variable type: [\(selectedFunctionality)] @ LOCATION = [\(key)]...")
            }
            existingVariables[key] = temp //update real dictionary w/ temp
        }
    }
    
    func variableWasDeleted(type: ModuleConfigurationTypes, selectedFunctionality: String) {
        let key = getKeyForConfigType(type)
        if let typesWithCount = existingVariables[key] {
            var temp = typesWithCount //create temp obj for updating
            if let count = typesWithCount[selectedFunctionality] { //variable already exists
                let newCount = count - 1 //increment count
                if !(newCount == 0) { //some other variables are still present
                    temp[selectedFunctionality] = newCount //update count for the typeName
                    print("[\(selectedFunctionality)] Var Deleted! New Count: \(newCount).")
                } else { //count is 0, remove entry from dict
                    temp[selectedFunctionality] = nil //remove entry for that typeName
                    print("[\(selectedFunctionality)] now has a count of 0! Removing type from dict...")
                }
                existingVariables[key] = temp //update real dictionary w/ temp
            } else { //error - deleted variable is not present in dictionary
                print("Error! Variable to be deleted does not exist in dictionary!!!")
            }
        }
    }
    
    // MARK: - Module Interface
    
    private func doesSetupContainFunctionality(functionality: String, forType: ModuleConfigurationTypes?) -> Bool {
        //Called by self, checks if setup contains a variable of the given functionality for the given varType (optional - if nil check for existence @ EITHER varType):
        if let type = forType { //type was given as input (look @ values for that type in dict)
            let key = getKeyForConfigType(type)
            if let existingTypes = existingVariables[key] {
                for (existingType, _) in existingTypes {
                    if (existingType == functionality) { //check if variable matches any existing func
                        return true
                    }
                }
            }
        } else { //no type was given, check in allVariables for given functionality
            if (self.allVariables.contains(functionality)) {
                return true
            }
        }
        return false //default is NO match
    }
    
    func getFilteredTypesForModule(sender: Modules) -> Set<String> { //called by every module class before constructing the behaviors & computations arrays - based on the moduleType, variable type (IV or OM), & existing variables, this method sends back the items to filter out of the array. Since these variables are strings, they will need to be converted to the module-specific enum type before being used (handled inside module class).
        var filteredTypes = Set<String>()
        
        switch sender { //for each Module subclass, define the rules for displaying the variableTypes (based on uniqueness & position in flow)
        case .CustomModule:
            
            //(1) Block variables based on location in flow:
            if (currentVarConfigType == ModuleConfigurationTypes.ActionQualifier) {
                filteredTypes.insert(CustomModuleVariableTypes.Computation_TimeDifference.rawValue) //cannot have TimeDifference as actionQualifier
            } else if (currentVarConfigType == ModuleConfigurationTypes.OutcomeMeasure) { //block vars that can't be OM
                //
            }
            
            //(2) Block variables based on presence in project (i.e. check for uniqueness);
            if (doesSetupContainFunctionality(TimeDifference_VariableTypes.DistanceFromAction.rawValue, forType: nil)) { //DistanceFromAction TD var must be unique
                filteredTypes.insert(TimeDifference_VariableTypes.DistanceFromAction.rawValue)
            }
            
        case .BiometricModule:
            
            //(1) Block variables based on variable type:
            if (currentVarConfigType == .InputVariable) {
                filteredTypes.insert(BiometricModule_HeartRateOptions.AverageOverAction.rawValue) //**
            } else if (currentVarConfigType == .OutcomeMeasure) {
                filteredTypes.insert(BiometricModule_HeartRateOptions.AverageOverAction.rawValue) //**
            }
            
            //(2) Block variables based on presence in project (i.e. check for uniqueness);
            if (doesSetupContainFunctionality(BiometricModuleVariableTypes.Computation_Age.rawValue, forType: nil)) { //AGE is unique @ ANY point
                filteredTypes.insert(BiometricModuleVariableTypes.Computation_Age.rawValue)
            }
            if (doesSetupContainFunctionality(BiometricModuleVariableTypes.Computation_BiologicalSex.rawValue, forType: nil)) { //SEX is unique @ ANY point
                filteredTypes.insert(BiometricModuleVariableTypes.Computation_BiologicalSex.rawValue)
            }
            
            //The following are unique to IV/OM (i.e. there can only be 1 per inputs, 1 per outcomes):
            if (doesSetupContainFunctionality(BiometricModuleVariableTypes.Behavior_Height.rawValue, forType: currentVarConfigType)) { //unique @ current location
                filteredTypes.insert(BiometricModuleVariableTypes.Behavior_Height.rawValue)
            }
            if (doesSetupContainFunctionality(BiometricModuleVariableTypes.Behavior_Weight.rawValue, forType: currentVarConfigType)) { //unique @ current location
                filteredTypes.insert(BiometricModuleVariableTypes.Behavior_Weight.rawValue)
            }
            if (doesSetupContainFunctionality(BiometricModuleVariableTypes.Computation_BMI.rawValue, forType: currentVarConfigType)) { //unique @ current location
                filteredTypes.insert(BiometricModuleVariableTypes.Computation_BMI.rawValue)
            }
            
        case .EnvironmentModule:
            
            //(1) Block variables based on varType:
            if (currentVarConfigType == .InputVariable) { //block vars that are ONLY allowed to come AFTER the action
                //
            } else if (currentVarConfigType == .OutcomeMeasure) { //block vars that are ONLY allowed to come BEFORE the action
                //
            }
            
            //(2) Block variables based on presence in project (i.e. check for uniqueness):
            //**
            
        case .FoodIntakeModule:
            
            //(1) Block variables based on varType:
            if (currentVarConfigType == .ActionQualifier) {
                //
            }
            
            //(2) Block variables based on presence in project (i.e. check for uniqueness):
            //**
            
        case .ExerciseModule:
            
            //(1) Block variables based on location in flow:
            if (currentVarConfigType == .ActionQualifier) {
                filteredTypes.insert(ExerciseModuleVariableTypes.Behavior_Workout.rawValue) //workout cannot be added to an action (messes up measurement flow)
            }
            
            //(2) Block variables based on presence in project (i.e. check for uniqueness):
            //**
            
        default: //for modules w/ no dynamic config needed
            break
        }
        
        return filteredTypes
    }
    
}