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
        return beforeActionVariablesArray
    }
    
    internal func getAfterActionVariablesArray() -> [Module]? {
        return afterActionVariablesArray
    }
    
    // MARK: - Reconstruction Logic
    
    internal func reconstructProjectFromPersistentRepresentation() {
        //Use the project's CoreData representation to reconstruct its variables as Module objects:
        beforeActionVariablesArray = [] //initialize variableArray
        afterActionVariablesArray = [] //initialize variableArray
        for (variable, dict) in self.beforeActionVars {
            if let moduleRaw = dict[BMN_ModuleTitleKey] as? String, module = Modules(rawValue: moduleRaw) {
                let reconstructedVariable: Module = createModuleObjectFromModuleName(moduleType: module, variableName: variable, configurationDict: dict)
                beforeActionVariablesArray!.append(reconstructedVariable)
            }
        }
        for (variable, dict) in self.afterActionVars {
            if let moduleRaw = dict[BMN_ModuleTitleKey] as? String, module = Modules(rawValue: moduleRaw) {
                let reconstructedVariable: Module = createModuleObjectFromModuleName(moduleType: module, variableName: variable, configurationDict: dict)
                afterActionVariablesArray!.append(reconstructedVariable)
            }
        }
    }
    
    private func createModuleObjectFromModuleName(moduleType module: Modules, variableName: String, configurationDict: [String: AnyObject]) -> Module {
        var object: Module = Module(name: variableName)
        
        //Determine the var's Module type, then pass the var's name & dictionary -> that module's CoreData initializer, which will create the variable (complete w/ configuration):
        switch module {
        case .CustomModule:
            object = CustomModule(name: variableName, dict: configurationDict)
        case .EnvironmentModule:
            object = EnvironmentModule(name: variableName, dict: configurationDict)
        case .FoodIntakeModule:
            object = FoodIntakeModule(name: variableName, dict: configurationDict)
        case .ExerciseModule:
            object = ExerciseModule(name: variableName, dict: configurationDict)
        case .BiometricModule:
            object = BiometricModule(name: variableName, dict: configurationDict)
        case .CarbonEmissionsModule:
            object = CarbonEmissionsModule(name: variableName, dict: configurationDict)
        }
        return object
    }
    
}
