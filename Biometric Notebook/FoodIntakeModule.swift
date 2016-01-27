//  FoodIntakeModule.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/7/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Module for inputting food intake data & computing calorific consumption & nutritional intake.

import Foundation

class FoodIntakeModule: Module {
    
    private let foodIntakeModuleBehaviors: [FoodIntakeModuleBehaviors] = []
    override var behaviors: [String] {
        var behaviorTitles: [String] = []
        for behavior in foodIntakeModuleBehaviors {
            behaviorTitles.append(behavior.rawValue)
        }
        return behaviorTitles
    }
    
    override var selectedBehavior: String? { //handle selection of a behavior
        didSet {
            
        }
    }
    
    private let foodIntakeModuleComputations: [FoodIntakeModuleComputations] = []
    override var computations: [String] {
        var computationTitles: [String] = []
        for computation in foodIntakeModuleComputations {
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
        self.moduleTitle = Modules.FoodIntakeModule.rawValue
    }
    
    internal func createDictionaryForCoreDataStore() -> Dictionary<String, AnyObject> { //generates dictionary to be saved by CoreData (this dict will allow full reconstruction of the object)
        let persistentDictionary: [String: AnyObject] = ["module": self.moduleTitle]
        return persistentDictionary
    }
    
}

enum FoodIntakeModuleBehaviors: String {
    case Dummy = ""
    
    func getAlertMessageForBehavior() -> String {
        var message = ""
        switch self {
        default:
            message = ""
        }
        return message
    }
}

enum FoodIntakeModuleComputations: String {
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
