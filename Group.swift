//  Group.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 4/13/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// A GROUP contains all necessary storage data for a SINGLE control or comparison group.

import Foundation
import CoreData

class Group: NSManagedObject {

    private var dataEntryVariablesArray: [Module] = [] //dataSource for VC TV
    
    func getVariablesArrayForDataEntry() -> [Module] {
        reconstructProjectFromPersistentRepresentation() //initialize TV dataSource
        return dataEntryVariablesArray
        //**we need to define how the interaction works for projects that have 1 or both sections fully auto-captured (in terms of the temporary storage object, the interaction w/ the VC, & when/how data is reported).**
    }
    
    // MARK: - Reconstruction Logic
    
    var reconstructedVariables: [Module] = [] //**accessed by Project Class
    
    private func reconstructProjectFromPersistentRepresentation() { //use the project's CoreData representation to reconstruct its variables (EITHER inputs OR outputs) as Module objects
        reconstructedVariables = [] //clear array
        dataEntryVariablesArray = [] //clear array
        let variableDict: [String: [String: AnyObject]]
        if (self.project.temporaryStorageObject == nil) { //no temp storage => report BEFORE ACTION VARS
            print("[reconstructProjFromCD] Temp object is nil! Configuring before action vars...")
            variableDict = self.beforeActionVariables
        } else { //temp storage obj exists => report AFTER ACTION VARS
            print("[reconstructProjFromCD] Temp object is NOT nil! Configuring after action vars...")
            variableDict = self.afterActionVariables
        }
        
        //Check the Module obj for the auto-capture indicator before adding var -> array (variables that are AUTO-captured are NOT added, but are asked to report their data now):
        for (variable, dict) in variableDict { //'dict' = configurationDict for variable
            if let moduleRaw = dict[BMN_ModuleTitleKey] as? String, module = Modules(rawValue: moduleRaw) {
                let reconstructedVariable: Module = createModuleObjectFromModuleName(moduleType: module, variableName: variable, configurationDict: dict)
                reconstructedVariables.append(reconstructedVariable) //add -> array for data capture
                if !(reconstructedVariable.isAutomaticallyCaptured) { //MANUALLY captured vars
                    dataEntryVariablesArray.append(reconstructedVariable)
                } else { //AUTO-captured vars
                    if (reconstructedVariable.selectedFunctionality == CustomModuleVariableTypes.Computation_TimeDifference.rawValue) { //TIME DIFFERENCE
                        //Create entry in tempStorageObject indicating there is a TimeDifference var (ONLY works if TimeDiff is an OUTPUT variable):
                        self.project.temporaryStorageObject?.updateValue([BMN_CustomModule_TimeDifferenceKey: reconstructedVariable.variableName], forKey: BMN_ProjectContainsTimeDifferenceKey) //store var's name in dict
                        saveManagedObjectContext() //save after inputting indicator
                    } else { //**tell the remainder of auto-cap variables to report their data!
                        reconstructedVariable.setDataObjectForAutoCapturedVariable()
                    }
                }
            }
        }
        //**Logic defined here may break down for projects that contain ONLY auto-captured variables in either inputs or outputs (such that there is no temp storage object defined)!
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
