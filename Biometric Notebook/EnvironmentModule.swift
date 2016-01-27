//  EnvironmentModule.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/27/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Module used to collect weather data (outdoor environment) based on the user's location. Also the mdodule used to measure temperature & humidity data (indoor environment) from sensor.

import Foundation

class EnvironmentModule: Module {
    
    private let environmentModuleBehaviors: [EnvironmentModuleBehaviors] = [EnvironmentModuleBehaviors.TemperatureAndHumidity, EnvironmentModuleBehaviors.Weather]
    override var behaviors: [String] {
        var behaviorTitles: [String] = []
        for behavior in environmentModuleBehaviors {
            behaviorTitles.append(behavior.rawValue)
        }
        return behaviorTitles
    }
    
    override var selectedBehavior: String? { //handle selection of a behavior
        didSet {
            
        }
    }
    
    private let environmentModuleComputations: [EnvironmentModuleComputations] = []
    override var computations: [String] {
        var computationTitles: [String] = []
        for computation in environmentModuleComputations {
            computationTitles.append(computation.rawValue)
        }
        return computationTitles
    }
    
    override var selectedComputations: [String]? { //handle selection of computation(s)
        didSet {
            
        }
    }
    
    override init(name: String) {
        super.init(name: name)
        self.moduleTitle = Modules.EnvironmentModule.rawValue
    }
    
    internal func createDictionaryForCoreDataStore() -> Dictionary<String, AnyObject> { //generates dictionary to be saved by CoreData (this dict will allow full reconstruction of the object)
        let persistentDictionary: [String: AnyObject] = ["module": self.moduleTitle]
        return persistentDictionary
    }
    
}

enum EnvironmentModuleBehaviors: String {
    case TemperatureAndHumidity = "Temperature & Humidity"
    case Weather = "Weather"
    
    func getAlertMessageForBehavior() -> String {
        var message = ""
        switch self {
        case .TemperatureAndHumidity:
            message = ""
        case .Weather:
            message = ""
        }
        return message
    }
}

enum EnvironmentModuleComputations: String {
    case Dummy = ""
    
    func getAlertMessageForComputation() -> String {
        var message = ""
        switch self {
        default:
            message = ""
        }
        return message
    }
}