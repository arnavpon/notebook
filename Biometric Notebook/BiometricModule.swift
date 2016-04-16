//  BiometricModule.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/19/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Module for entering biometric data into HK (e.g. height, weight, etc.)

import Foundation

class BiometricModule: Module {
    
    private let biometricModuleBehaviors: [BiometricModuleVariableTypes] = [BiometricModuleVariableTypes.Behavior_Height, BiometricModuleVariableTypes.Behavior_Weight]
    override var behaviors: [String] { //object containing titles for TV cells
        var behaviorTitles: [String] = []
        for behavior in biometricModuleBehaviors {
            behaviorTitles.append(behavior.rawValue)
        }
        return behaviorTitles
    }
    
    private let biometricModuleComputations: [BiometricModuleVariableTypes] = [BiometricModuleVariableTypes.Computation_Age, BiometricModuleVariableTypes.Computation_BMI]
    override var computations: [String] { //object containing titles for TV cells
        var computationTitles: [String] = []
        for computation in biometricModuleComputations {
            computationTitles.append(computation.rawValue)
        }
        return computationTitles
    }
    
    private var variableType: BiometricModuleVariableTypes? { //converts 'selectedFunctionality' (a String) to an enum object
        get {
            if let selection = selectedFunctionality {
                return BiometricModuleVariableTypes(rawValue: selection)
            }
            return nil
        }
    }
    
    // MARK: - Initializers
    
    override init(name: String) { //set-up init
        super.init(name: name)
        self.moduleTitle = Modules.BiometricModule.rawValue
    }
    
    override init(name: String, dict: [String: AnyObject]) { //CoreData init
        super.init(name: name, dict: dict)
        self.moduleTitle = Modules.BiometricModule.rawValue
    }
    
    // MARK: - Core Data Logic
    
    internal override func createDictionaryForCoreDataStore() -> Dictionary<String, AnyObject> { 
        let persistentDictionary: [String: AnyObject] = super.createDictionaryForCoreDataStore()
        return persistentDictionary
    }
    
    internal override func setConfigurationOptionsForSelection() {
        //
    }
    
    // MARK: - Data Entry Logic
    
    override func getDataEntryCellTypeForVariable() -> DataEntryCellTypes? { //indicates to DataEntryVC what kind of DataEntry cell should be used for this variable
        if let type = self.variableType {
            switch type {
            default:
                return nil
            }
        }
        return nil
    }
    
}

enum BiometricModuleVariableTypes: String { //*match each behavior/computation -> Configuration + DataEntry custom TV cells; for each new behavior/comp added, you must also add (1) Configuration logic, (2) Core Data storage logic (so the variable config can be preserved), (3) Unpacking logic (in the DataEntry initializer), & (4) DataEntry logic (enabling the user to report info).*
    
    //**how do we deal w/ static pieces of data like DOB? We could pull it from HK; the difference is these variables WON'T be measured on each run of dataEntry mode.
    //Available Behaviors:
    case Behavior_Height = "BM_behavior_Height"
    case Behavior_Weight = "BM_behavior_Weight"
    
    //Available Computations:
    case Computation_Age = "BM_computation_Age" //calculate from DOB -> current time
    case Computation_BMI = "BM_computation_BMI"
    
    func getAlertMessageForVariable() -> String {
        var message = ""
        switch self {
        case .Behavior_Height:
            message = ""
        case .Behavior_Weight:
            message = ""
        case .Computation_Age:
            message = ""
        case .Computation_BMI:
            message = ""
        }
        return message
    }
    
}