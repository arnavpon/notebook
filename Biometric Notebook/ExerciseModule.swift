//  ExerciseModule.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/7/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Module for capturing exercise statistics such as calories burned, distance moved, etc.

import Foundation

class ExerciseModule: Module {
    
    private let exerciseModuleBehaviors: [ExerciseModuleBehaviors] = [ExerciseModuleBehaviors.Exercise, ExerciseModuleBehaviors.BeforeAndAfter]
    override var behaviors: [String] {
        var behaviorTitles: [String] = []
        for behavior in exerciseModuleBehaviors {
            behaviorTitles.append(behavior.rawValue)
        }
        return behaviorTitles
    }
    
    override var selectedBehavior: String? { //handle selection of a behavior
        didSet {
            
        }
    }
    
    private let exerciseModuleComputations: [ExerciseModuleComputations] = []
    override var computations: [String] {
        var computationTitles: [String] = []
        for computation in exerciseModuleComputations {
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
        self.moduleTitle = Modules.ExerciseModule.rawValue
    }
    
    internal func createDictionaryForCoreDataStore() -> Dictionary<String, AnyObject> { //generates dictionary to be saved by CoreData (this dict will allow full reconstruction of the object)
        let persistentDictionary: [String: AnyObject] = ["module": self.moduleTitle]
        return persistentDictionary
    }
}

enum ExerciseModuleBehaviors: String {
    case Exercise = "<Single Workout>" //'Workout' allows the user to add a single exercise to the list for tracking the # of reps, weight, & # of sets.
    case BeforeAndAfter = "Before & After Picture" //'Before & After' allows user to take picture & save.
    
    func getAlertMessageForBehavior() -> String {
        var message = ""
        switch self {
        case .Exercise:
            message = ""
        case .BeforeAndAfter:
            message = ""
        }
        return message
    }
}

enum ExerciseModuleComputations: String {
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
