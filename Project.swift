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
        //Uses the project's CoreData representation to reconstruct its variables as Module objects:
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
        switch moduleName { //make sure these match the moduleTitle used to construct the dict!
        case "Custom":
            let options = variableDict["options"] as! [String]
            object = CustomModule(name: variableName, options: options)
        case "Weather":
            object = WeatherModule(name: variableName)
        case "Temperature & Humidity":
            object = TemperatureHumidityModule(name: variableName)
        case "Food Intake":
            object = FoodIntakeModule(name: variableName)
        case "Exercise":
            object = ExerciseModule(name: variableName)
        case "Biometric":
            object = BiometricModule(name: variableName)
        default:
            object = Module(name: variableName) //should never be called
            print("Error: default switch in Project > 'createModuleObjectFromModuleName'")
        }
        return object
    }
    
}
