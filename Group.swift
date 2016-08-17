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
    var timeDifferenceIsPresent: Bool = false //indicator that reporting group contains TD
    var overrideAsyncActionBypass: Bool? //indicates whether to override an async action's bypass
    var asyncActionTimeStamp: NSDate? //*holds timeStamp to avoid it being committed until user reports data for 1st location in cycle*
    
    func getManualVariablesForDataEntry() -> [Module] {
        return reconstructProjectFromPersistentRepresentation() //initialize TV dataSource
    }
    
    // MARK: - Variable Reconstruction Logic
    
    private func reconstructProjectFromPersistentRepresentation() -> [Module] { //use the project's CoreData representation to reconstruct its variables (EITHER inputs OR outputs) as Module objects
        print("Reconstructing Project variables from persistent representation...")
        reconstructedVariables = [] //clear array
        autoCapturedVariables = [] //clear array
        reportCount = 0 //reset count
        var manualEntryVariablesArray: [Module] = [] //initialize array for manual vars (for VC)
        
        var locationInMeasurementCycle: Int = 0
        let reconstructedAction = Action(settings: self.action) //reconstruct action (used below)
        if let temp = self.project.temporaryStorageObject, timeStamps = temp[BMN_DBO_TimeStampKey] as? [AnyObject] { //temp storage obj exists - count location in measurement cycle by # of timeStamps that exist in tempObj
            locationInMeasurementCycle = (timeStamps.count + 1) //*add 1 to get CURRENT location*
            print("[reconstructProjFromCD] Temp obj is NOT nil! Loc = [\(locationInMeasurementCycle)]...")
        } else { //no temp storage => new measurement cycle
            print("[reconstructProjFromCD] Temp object is NIL! Starting NEW measurement cycle...")
            locationInMeasurementCycle = 1 //*start new cycle @ position #1*
            
            //Check if the action is asynchronous & bypass its location in flow if override is not set:
            if (reconstructedAction.actionLocation == ActionLocations.BeforeInputs) && !(reconstructedAction.occursInEachCycle) && (reconstructedAction.qualifiersCount > 0) { //*make sure action has AQs (or else it does NOT take up a position in measurement cycle)*
                print("Action is asynchronous & has qualifiers (i.e. takes up space in cycle)!")
                if (self.overrideAsyncActionBypass != true) { //bypass the Action if override is nil
                    print("Bypassing data reporting for the asychronous action...")
                    locationInMeasurementCycle = 2 //bypass Action's location in the cycle
                    if let qualifiersData = reconstructedAction.qualifiersStoredData, actionTimeStamp = reconstructedAction.actionTimeStamp { //data exists
                        print("Action qualifiers have data! Storing to tempObject...")
                        self.project.temporaryStorageObject = [:] //initialize
                        project.temporaryStorageObject!.updateValue([actionTimeStamp], forKey: BMN_DBO_TimeStampKey) //set actionTimeStamp as 1st item in timeStampsArray
                        project.temporaryStorageObject!.updateValue([self.groupName: self.groupType], forKey: BMN_TSO_ReportingGroupKey) //set reportingGroup in tempObj
                        for (variable, data) in qualifiersData { //add data -> tempObject
                            print("For variable [\(variable)], added data [\(data)] to tempObject!")
                            self.project.temporaryStorageObject!.updateValue(data, forKey: variable)
                        }
                        saveManagedObjectContext() //save changes to tempObj
                    }
                } else { //override is NOT nil - avoid bypass
                    self.overrideAsyncActionBypass = nil //*clear for next run*
                }
            }
        }
        
        //Set variableDict according to var's reportLocations (in CoreData) & locationInMeasurementCycle:
        print("\n[reconstructProjFromCD] Obtaining variables for location [\(locationInMeasurementCycle)] in measurement cycle...")
        var variablesForCurrentLocationInCycle = Dictionary<String, [String: AnyObject]>()
        for (variable, dict) in self.variables { //match variables -> locationInFlow
            if let locations = dict[BMN_VariableReportLocationsKey] as? Set<Int> {
                if (locations.contains(locationInMeasurementCycle)) { //var reports @ this location!
                    print("Added variable [\(variable)] to list of objects to report.")
                    variablesForCurrentLocationInCycle.updateValue(dict, forKey: variable) //add -> dict
                }
            }
        }
        
        //Check the Module obj for the reportType before adding var -> array:
        print("\n[reconstructProjFromCD] Sorting variables according to reportType...")
        for (variable, dict) in variablesForCurrentLocationInCycle { //'dict' = configurationDict for var
            if let moduleRaw = dict[BMN_ModuleTitleKey] as? String, module = Modules(rawValue: moduleRaw) {
                print("[GROUP] Reconstructing Variable: [\(variable)].")
                let reconstructedVariable: Module = createModuleObjectFromModuleName(moduleType: module, variableName: variable, configurationDict: dict)
                reconstructedVariables.append(reconstructedVariable) //add -> array for data capture
                switch reconstructedVariable.variableReportType { //check the var's reportType
                case .Default: //USER-ENTERED vars - add to array for display to user
                    print("MANUAL capture var")
                    reportCount += 1 //manual vars count towards total
                    manualEntryVariablesArray.append(reconstructedVariable) //add MANUAL vars -> obj
                case .AutoCapture: //AUTO captured vars - instruct to report data @ this time!
                    print("AUTO capture var")
                    reportCount += 1 //true auto cap (non-TD) vars count towards total
                    reconstructedVariable.populateDataObjectForAutoCapturedVariable()
                    autoCapturedVariables.append(reconstructedVariable) //add -> array
                case .Computation:
                    print("COMPUTATION variable")
                    break //should NOT be displayed in TV, must wait for other variables to report before populating report object
                case .TimeDifference: //TD vars should ONLY appear @ end of measurement cycle!
                    print("TIME DIFFERENCE var @ location \(locationInMeasurementCycle) for cycle length \(self.measurementCycleLength).")
                    self.timeDifferenceIsPresent = true //set indicator
                }
            }
        }
        return manualEntryVariablesArray
    }
    
    private func createModuleObjectFromModuleName(moduleType module: Modules, variableName: String, configurationDict: [String: AnyObject]) -> Module { //init Module obj w/ its name & config dict
        //Determine the var's Module type, then pass the var's name & dictionary -> that module's CoreData initializer, which will re-create the variable (complete w/ all configuration):
        var object: Module = Module(name: variableName)
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
        case .RecipeModule:
            object = RecipeModule(name: variableName, dict: configurationDict)
        }
        return object
    }
    
    // MARK: - Action Logic
    
    func asynchronousActionHasOccurred() { //handle logic for async action occurrence
        print("Asynchronous action has occurred...Creating time stamp!")
        //(1) get time @ which action occurred & save it to CoreData via the group's action obj:
        let timeStamp = NSDate()
        var reconstructedAction = Action(settings: self.action)
        if (reconstructedAction.qualifiersCount == 0) { //action has 0 AQs - commit timeStamp NOW
            reconstructedAction.actionTimeStamp = timeStamp //set timeStamp
            self.action = reconstructedAction.constructCoreDataObjectForAction() //save config -> CoreData
            saveManagedObjectContext() //commit the timeStamp change
        } else { //action has AQ - store timeStamp -> temp indicator until AQ are committed
            self.asyncActionTimeStamp = timeStamp //set indicator
        }
        
        //(2) Indicate to the group to override the async action bypass when setting the vars:
        self.overrideAsyncActionBypass = true
    }
    
}