//  Group.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 4/13/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// A GROUP contains all necessary storage data for a SINGLE control or comparison group.

import Foundation
import CoreData

class Group: NSManagedObject {

    var reconstructedVariables: [Module] = [] //contains ALL variables for current measurement cycle; accessed by Project Class during data reporting
    var autoCapturedVariables: [Module] = [] //contains ONLY auto-captured variables for current measurement cycle; accessed by Project Class
    var reportCount: Int = 0 //counts the # of variables that must be reported (accessed by VC)
    
    func getManualVariablesForDataEntry() -> [Module] {
        return reconstructProjectFromPersistentRepresentation() //initialize TV dataSource
    }
    
    // MARK: - Reconstruction Logic
    
    private func reconstructProjectFromPersistentRepresentation() -> [Module] { //use the project's CoreData representation to reconstruct its variables (EITHER inputs OR outputs) as Module objects
        reconstructedVariables = [] //clear array
        autoCapturedVariables = [] //clear array
        var manualEntryVariablesArray: [Module] = [] //initialize array for manual vars (for VC)
        reportCount = 0 //reset count
        let variableDict: [String: [String: AnyObject]]
        if (self.project.temporaryStorageObject == nil) { //no temp storage => report BEFORE ACTION VARS
            print("[reconstructProjFromCD] Temp object is nil! Configuring BEFORE action vars...")
            variableDict = self.beforeActionVariables
        } else { //temp storage obj exists => report AFTER ACTION VARS
            print("[reconstructProjFromCD] Temp object is NOT nil! Configuring AFTER action vars...")
            variableDict = self.afterActionVariables
        }
        
        //Check the Module obj for the reportType before adding var -> array:
        for (variable, dict) in variableDict { //'dict' = configurationDict for variable
            if let moduleRaw = dict[BMN_ModuleTitleKey] as? String, module = Modules(rawValue: moduleRaw) {
                print("[GROUP] Reconstructing Variable: [\(variable)].")
                let reconstructedVariable: Module = createModuleObjectFromModuleName(moduleType: module, variableName: variable, configurationDict: dict)
                reconstructedVariables.append(reconstructedVariable) //add -> array for data capture
                switch reconstructedVariable.variableReportType { //check the var's reportType
                case .Default: //USER-ENTERED vars - add to array for display to user
                    print("MANUAL capture var")
                    reportCount += 1 //manual vars count towards total
                    manualEntryVariablesArray.append(reconstructedVariable) //add MANUAL vars -> obj
                case .AutoCapture: //AUTO captured vars
                    print("AUTO capture var")
                    reportCount += 1 //auto cap vars count towards total
                    if (reconstructedVariable.selectedFunctionality == CustomModuleVariableTypes.Computation_TimeDifference.rawValue) { //TIME DIFFERENCE
                        //Create entry in tempStorageObject indicating there is a TimeDifference var (ONLY works if TimeDiff is an OUTPUT variable):
                        self.project.temporaryStorageObject?.updateValue([BMN_CustomModule_TimeDifferenceKey: reconstructedVariable.variableName], forKey: BMN_ProjectContainsTimeDifferenceKey) //store var's name in dict
                        saveManagedObjectContext() //save after inputting indicator
                    } else { //instruct the remaining auto-cap variables to report their data @ this time!
                        reconstructedVariable.populateDataObjectForAutoCapturedVariable()
                        autoCapturedVariables.append(reconstructedVariable) //add -> array
                    }
                case .Computation:
                    print("COMPUTATION variable")
                    break //should NOT be displayed in TV, must wait for other variables to report before populating report object...
                }
            }
        }
        return manualEntryVariablesArray
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