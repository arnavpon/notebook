//  BiometricModule.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/19/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Module for entering biometric data into HK (e.g. height, weight, etc.)

import Foundation

class BiometricModule: Module {
    
    private let biometricModuleBehaviors: [BiometricModuleBehaviors] = [BiometricModuleBehaviors.Height, BiometricModuleBehaviors.Weight]
    override var behaviors: [String] {
        var behaviorTitles: [String] = []
        for behavior in biometricModuleBehaviors {
            behaviorTitles.append(behavior.rawValue)
        }
        return behaviorTitles
    }
    
    private let biometricModuleComputations: [BiometricModuleComputations] = [BiometricModuleComputations.Age, BiometricModuleComputations.BMI]
    override var computations: [String] {
        var computationTitles: [String] = []
        for computation in biometricModuleComputations {
            computationTitles.append(computation.rawValue)
        }
        return computationTitles
    }
    
    override var selectedFunctionality: String? { //handle selection of a behavior/computation
        didSet {
            
        }
    }
    
    // MARK: - Initializers
    
    override init(name: String) {
        super.init(name: name)
        self.moduleTitle = Modules.BiometricModule.rawValue
    }
    
    internal func createDictionaryForCoreDataStore() -> Dictionary<String, AnyObject> { //generates dictionary to be saved by CoreData (this dict will allow full reconstruction of the object)
        let persistentDictionary: [String: AnyObject] = [BMNModuleTitleKey: self.moduleTitle]
        return persistentDictionary
    }
    
    internal override func setConfigurationOptionsForSelection() {
        //
    }
    
}

enum BiometricModuleBehaviors: String {
    //how do we deal w/ static pieces of data like DOB? We could pull it from HK; the difference is these variables WON'T be measured on each run of dataEntry mode.
    case Height = "Height"
    case Weight = "Weight"
    
    func getAlertMessageForBehavior() -> String {
        var message = ""
        switch self {
        case .Height:
            message = ""
        case .Weight:
            message = ""
        }
        return message
    }
}

enum BiometricModuleComputations: String {
    case Age = "Age"
    case BMI = "BMI"
    
    func getAlertMessageForComputation() -> String {
        var message = ""
        switch self {
        case .Age:
            message = ""
        case .BMI:
            message = ""
        }
        return message
    }
}
