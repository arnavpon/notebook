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
        
        //**Compare current location to total. If total is nil (default), . 
        //Stop using tempStorageObject as indicator? If nil - automatically pull 1st item & set locationInFlow to 1. Each time data is reported, increase locationInFlow by 1 until final dataObject is constructed (when total == locationInFlow; if nil, LIF = 2 is end). If not nil - check what current locationInFlow is & adjust accordingly. LIF must be stored @ Project level in tempStorageDict.
        //Smoothing - what happens when some variables in a given reporting section report only 1x whereas others (exerciseVars) report multiple times before being complete? Proposal - all variables show up in beforeVars, but pressing Done button moves you forward in the flow until EVERY object in the reporting section is @ the last #. Only then does pressing done either complete the dict or take you to AFTER ACTION vars. The system needs to store the intermediately reported objects each time Done btn is pressed so that the final object can be created. We need to store the LIF & the previously reported data in a temporary object.
        //For each module var, define reportCount(?), default is nil (reports only 1x). If reportCount does not match LIF, then pressing Done will only store the temporary item.
        
        //-when project is created, check how many cycles are required for each variable in project to be reported. if there are differences, provide interface for user to select which aspect of the project is being reported @ the given moment (allow user to select variable to report). When does the project switch -> AfterAction vars? Project could remove variables from potential selection after entire measurement cycle is completed for that variable, leaving only the remaining variables behind.
        
        //Scenarios for abnormal measurement cycles - (1) correlation project where we want to analyze impact foodIntake has on ability to lift (contains combination of foodIntake var + workout var). How do we set up correlation between 1 set of foodIntake & a set of workouts for every day of the week? (2) project w/ all workouts for a week where we want to add data to each workout depending on day of week. (3) project w/ only a single workout.
        //(1) we could break this project down by day - from 0:00 - 23:59, we could aggregate all food information & workout information for the day. When the next day starts, we begin a new measurement cycle.
        //How to deal w/ outcome vars containing workouts???
        //How do we incorporate vars into other vars - e.g. using a averageOverAction HR variable to gather HR during workout tracking. If cardio workout is only 1 part of the overall workout, how do we match the HR during the workout -> the appropriate variable??
        var locationInFlow: Int = 1
        if let tempStorageObject = self.project.temporaryStorageObject { //obj exists
            print("[reconstructProjFromCD] Temp object is NOT nil! Checking location in flow...")
            if let location = tempStorageObject["locationInFlow"] as? Int { //store an indicator in the tempObject to indicate that beforeVars need to continue reporting; remove indicator when all beforeVars are @ last locationInFLow
                locationInFlow = location
            }
            if let indicator = tempStorageObject["indicator"] as? Bool { //indicator is set during dataReporting time - if there are more reports to go for a var, indicator will be set until all items have reported.
                print("Indicator is present...configuring BAV")
                variableDict = self.beforeActionVariables
            } else {
                print("Configuring AFTER ACTION vars...")
                variableDict = self.afterActionVariables
            }
        } else { //object is NIL - use BEFORE ACTION vars
            print("[reconstructProjFromCD] Temp object is nil! Configuring BEFORE action vars...")
            variableDict = self.beforeActionVariables
        }
        
//        if (self.project.temporaryStorageObject == nil) { //no temp storage => report BEFORE ACTION VARS
//            print("[reconstructProjFromCD] Temp object is nil! Configuring BEFORE action vars...")
//            variableDict = self.beforeActionVariables
//        } else { //temp storage obj exists => report AFTER ACTION VARS
//            print("[reconstructProjFromCD] Temp object is NOT nil! Configuring AFTER action vars...")
//            variableDict = self.afterActionVariables
//        }
        
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
                    if (reconstructedVariable.selectedFunctionality == CustomModuleVariableTypes.Computation_TimeDifference.rawValue) { //TIME DIFFERENCE
                        //Create entry in tempStorageObject indicating there is a TimeDifference var (ONLY works if TimeDiff is an OUTPUT variable):
                        print("TIME DIFFERENCE var")
                        self.project.temporaryStorageObject?.updateValue([BMN_CustomModule_TimeDifferenceKey: reconstructedVariable.variableName], forKey: BMN_ProjectContainsTimeDifferenceKey) //store var's name in dict
                        saveManagedObjectContext() //save after inputting indicator
                    } else { //instruct the remaining auto-cap variables to report their data @ this time!
                        print("AUTO capture var")
                        reportCount += 1 //true auto cap (non-TD) vars count towards total
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