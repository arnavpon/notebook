//  Project.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/7/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// This CoreData object is a representation of the structure of each user-created project. The object is used to store in memory the project framework so that it can be accessed by other portions of the app.

import Foundation
import CoreData

class Project: NSManagedObject {
    
    private var beforeActionVariablesArray: [Module]? //reconstructed variablesArray
    private var afterActionVariablesArray: [Module]? //reconstructed variablesArray
    
    internal func getBeforeActionVariablesArray() -> [Module]? {
        if (beforeActionVariablesArray != nil) {
            return beforeActionVariablesArray
        } else {
            print("beforeActionVarsArray is nil!")
            return nil
        }
    }
    
    internal func getAfterActionVariablesArray() -> [Module]? {
        if (afterActionVariablesArray != nil) {
            return afterActionVariablesArray
        } else {
            print("afterActionVarsArray is nil!")
            return nil
        }
    }
    
    internal func reconstructProjectFromPersistentRepresentation() {
        //Use the project's CoreData representation to reconstruct its variables as Module objects:
        beforeActionVariablesArray = [] //initialize variableArray
        afterActionVariablesArray = [] //initialize variableArray
        for (variable, dict) in self.beforeActionVars {
            let module = dict["module"] as! String
            let reconstructedVariable: Module = createModuleObjectFromModuleName(module, variableName: variable, variableDict: dict)
            beforeActionVariablesArray!.append(reconstructedVariable)
        }
        for (variable, dict) in self.afterActionVars {
            let module = dict["module"] as! String
            let reconstructedVariable: Module = createModuleObjectFromModuleName(module, variableName: variable, variableDict: dict)
            afterActionVariablesArray!.append(reconstructedVariable)
        }
    }
    
    private func createModuleObjectFromModuleName(moduleName: String, variableName: String, variableDict: [String: AnyObject]) -> Module {
        var object: Module
        switch moduleName { //the Modules enum's raw string is the moduleName for unpacking
        case Modules.CustomModule.rawValue:
//            let options = variableDict[BMN_CustomModule_OptionsKey] as! [String]
            object = CustomModule(name: variableName)
////            (object as! CustomModule).options = options
//            if let prompt = variableDict[BMN_CustomModule_PromptKey] as? String { //check for prompt
//                
//            }
        case Modules.EnvironmentModule.rawValue:
            object = EnvironmentModule(name: variableName)
        case Modules.FoodIntakeModule.rawValue:
            object = FoodIntakeModule(name: variableName)
        case Modules.ExerciseModule.rawValue:
            object = ExerciseModule(name: variableName)
        case Modules.BiometricModule.rawValue:
            object = BiometricModule(name: variableName)
        default:
            object = Module(name: variableName) //should never be called
            print("Error: default switch in [Project > 'createModuleObjectFromModuleName()']")
        }
        return object
    }
    
}
