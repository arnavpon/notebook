//  Group.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 4/13/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// A GROUP contains all necessary storage data for a SINGLE control or comparison group.

import Foundation
import CoreData

class Group: NSManagedObject {

    private var dataEntryVariablesArray: [Module]? //dataSource for VC TV
    
    func getVariablesArrayForTV() -> [Module]? {
        reconstructProjectFromPersistentRepresentation() //initialize TV dataSource
        return dataEntryVariablesArray
    }
    
    // MARK: - Reconstruction Logic
    
    private func reconstructProjectFromPersistentRepresentation() { //use the project's CoreData representation to reconstruct its variables (EITHER inputs OR outputs) as Module objects
        dataEntryVariablesArray = [] //initialize array
        if (self.project.temporaryStorageObject == nil) { //no temp storage => report BEFORE ACTION VARS
            print("Temp object is nil!!!")
            for (variable, dict) in self.beforeActionVariables { //'dict' = configuration dict for var
                if let moduleRaw = dict[BMN_ModuleTitleKey] as? String, module = Modules(rawValue: moduleRaw) {
                    let reconstructedVariable: Module = createModuleObjectFromModuleName(moduleType: module, variableName: variable, configurationDict: dict)
                    dataEntryVariablesArray!.append(reconstructedVariable)
                }
            }
        } else { //temp storage obj exists => report AFTER ACTION VARS
            print("Temp object is NOT nil")
            for (variable, dict) in self.afterActionVariables { //'dict' = configuration dict for variable
                if let moduleRaw = dict[BMN_ModuleTitleKey] as? String, module = Modules(rawValue: moduleRaw) {
                    let reconstructedVariable: Module = createModuleObjectFromModuleName(moduleType: module, variableName: variable, configurationDict: dict)
                    dataEntryVariablesArray!.append(reconstructedVariable)
                }
            }
        }
    }
    
    private func createModuleObjectFromModuleName(moduleType module: Modules, variableName: String, configurationDict: [String: AnyObject]) -> Module { //init Module obj w/ its name & config dict
        var object: Module = Module(name: variableName)
        
        //Determine the var's Module type, then pass the var's name & dictionary -> that module's CoreData initializer, which will re-create the variable (complete w/ all configuration):
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
