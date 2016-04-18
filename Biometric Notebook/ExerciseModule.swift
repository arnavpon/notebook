//  ExerciseModule.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/7/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Module for capturing exercise statistics such as calories burned, distance moved, etc.

import Foundation

class ExerciseModule: Module {
    
    override var configureModuleLayoutObject: Dictionary<String, AnyObject> {
        get {
            var tempObject = super.configureModuleLayoutObject //obtain superclass' dict & ADD TO IT
            
            var alertMessage = Dictionary<String, [String: String]>() //1st key is section name, 2nd key is behavior/computation name (using the RAW_VALUE of the ENUM object!), value is a message for the alertController
            var messageForBehavior = Dictionary<String, String>()
            for behavior in exerciseModuleBehaviors {
                messageForBehavior[behavior.rawValue] = behavior.getAlertMessageForVariable()
            }
            alertMessage[BMN_BehaviorsKey] = messageForBehavior
            var messageForComputation = Dictionary<String, String>()
            for computation in exerciseModuleComputations {
                messageForComputation[computation.rawValue] = computation.getAlertMessageForVariable()
            }
            alertMessage[BMN_ComputationsKey] = messageForComputation
            tempObject[BMN_AlertMessageKey] = alertMessage //merge dictionaries
            
            return tempObject
        }
    }
    
    private let exerciseModuleBehaviors: [ExerciseModuleVariableTypes] = [ExerciseModuleVariableTypes.Behavior_Exercise, ExerciseModuleVariableTypes.Behavior_BeforeAndAfter]
    override var behaviors: [String] { //object containing titles for TV cells
        var behaviorTitles: [String] = []
        for behavior in exerciseModuleBehaviors {
            behaviorTitles.append(behavior.rawValue)
        }
        return behaviorTitles
    }
    
    private let exerciseModuleComputations: [ExerciseModuleVariableTypes] = []
    override var computations: [String] { //object containing titles for TV cells
        var computationTitles: [String] = []
        for computation in exerciseModuleComputations {
            computationTitles.append(computation.rawValue)
        }
        return computationTitles
    }
    
    private var variableType: ExerciseModuleVariableTypes? { //converts 'selectedFunctionality' (a String) to an enum object
        get {
            if let selection = selectedFunctionality {
                return ExerciseModuleVariableTypes(rawValue: selection)
            }
            return nil
        }
    }
    
    // MARK: - Initializers
    
    override init(name: String) { //set-up init
        super.init(name: name)
        self.moduleTitle = Modules.ExerciseModule.rawValue
    }
    
    override init(name: String, dict: [String: AnyObject]) { //CoreData init
        super.init(name: name, dict: dict)
        self.moduleTitle = Modules.ExerciseModule.rawValue
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

enum ExerciseModuleVariableTypes: String { //*match each behavior/computation -> Configuration + DataEntry custom TV cells; for each new behavior/computation added, you must also add (1) Configuration logic, (2) Core Data storage logic (so the variable config can be preserved), (3) Unpacking logic (in the DataEntry initializer), & (4) DataEntry logic (enabling the user to report info).* 
    //Available Behaviors:
    case Behavior_Exercise = "ExM_behavior_<SingleWorkout>" //'Workout' allows the user to add a single exercise to the list for tracking the # of reps, weight, & # of sets.
    case Behavior_BeforeAndAfter = "ExM_behavior_BeforeAfterPicture" //'Before & After' allows user to take picture & save.
    
    //Available Computations:
    
    func getAlertMessageForVariable() -> String {
        var message = ""
        switch self {
        case .Behavior_Exercise:
            message = ""
        case .Behavior_BeforeAndAfter:
            message = ""
        }
        return message
    }
    
}