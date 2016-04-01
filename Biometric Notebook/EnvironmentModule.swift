//  EnvironmentModule.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/27/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Module used to collect weather data (outdoor environment) based on the user's location. Also the mdodule used to measure temperature & humidity data (indoor environment) from sensor.

import Foundation

class EnvironmentModule: Module {
    
    private let environmentModuleBehaviors: [EnvironmentModuleVariableTypes] = [EnvironmentModuleVariableTypes.Behavior_TemperatureAndHumidity, EnvironmentModuleVariableTypes.Behavior_Weather]
    override var behaviors: [String] { //object containing titles for TV cells
        var behaviorTitles: [String] = []
        for behavior in environmentModuleBehaviors {
            behaviorTitles.append(behavior.rawValue)
        }
        return behaviorTitles
    }
    
    private let environmentModuleComputations: [EnvironmentModuleVariableTypes] = []
    override var computations: [String] { //object containing titles for TV cells
        var computationTitles: [String] = []
        for computation in environmentModuleComputations {
            computationTitles.append(computation.rawValue)
        }
        return computationTitles
    }
    
    private var variableType: EnvironmentModuleVariableTypes? { //converts 'selectedFunctionality' (a String) to an enum object
        get {
            if let selection = selectedFunctionality {
                return EnvironmentModuleVariableTypes(rawValue: selection)
            }
            return nil
        }
    }
    
    // MARK: - Initializers
    
    override init(name: String) { //set-up init
        super.init(name: name)
        self.moduleTitle = Modules.EnvironmentModule.rawValue
    }
    
    override init(name: String, dict: [String: AnyObject]) { //CoreData init
        super.init(name: name, dict: dict)
    }
    
    // MARK: - Core Data
    
    internal override func createDictionaryForCoreDataStore() -> Dictionary<String, AnyObject> { 
        let persistentDictionary: [String: AnyObject] = super.createDictionaryForCoreDataStore()
        return persistentDictionary
    }
    
    internal override func setConfigurationOptionsForSelection() {
        //
    }
    
}

enum EnvironmentModuleVariableTypes: String {
    //Available Behaviors:
    case Behavior_TemperatureAndHumidity = "EnM_behavior_TempHumidity"
    case Behavior_Weather = "EnM_behavior_Weather"
    
    //Available Computations:
    
    func getAlertMessageForVariable() -> String {
        var message = ""
        switch self {
        case .Behavior_TemperatureAndHumidity:
            message = ""
        case .Behavior_Weather:
            message = ""
        }
        return message
    }
    
}