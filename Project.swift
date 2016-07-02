//  Project.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/7/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// This CoreData object is a representation of the structure of each user-created project. The object is used to store in memory the project framework so that it can be accessed by other portions of the app.

//Each PROJECT contains 1 or more groups. Each group represents a SINGLE control or comparison group. The 'Group' class describes the input & outcome variables + action. The 'Project' class encapsulates all groups & project-specific variables (endpoint, title, question, hypothesis, etc.).

import Foundation
import CoreData

class Project: NSManagedObject {
    
    private var experimentType: ExperimentTypes? { //get projectType as an enum object
        return ExperimentTypes(rawValue: self.projectType)
    }
    
    // MARK: - External Access
    
    func getProjectTypeForDisplay() -> String? { //obtains a display-friendly projectType for VC
        return experimentType?.getTypeNameForDisplay()
    }
    
    func checkProjectCompletionStatus() { //checks if project is ACTIVE or INACTIVE
        if (self.isActive) { //ONLY perform check if project is currently active
            let currentDate = NSDate()
            if let end = endDate { //check if project has expiry date
                print("[CURRENT] \(DateTime(date: currentDate).getFullTimeStamp())")
                print("[END] \(DateTime(date: end).getFullTimeStamp())")
                if (currentDate.timeIntervalSinceReferenceDate >= end.timeIntervalSinceReferenceDate) {
                    //Project has expired - perform cleanup (delete all associated counter objects, block data reporting, etc.):
                    print("'\(self.title)' Project has expired!.")
                    self.isActive = false
                    for object in self.counters { //delete any associated Counter objects
                        if let counter = object as? Counter {
                            deleteManagedObject(counter)
                        }
                    }
                    saveManagedObjectContext() //persist all changes
                }
            }
        }
    }
    
    func refreshMeasurementCycle() { //refreshes counters & tempStorage obj (called automatically @ end of measurement cycle or manually by user)
        self.reportingGroup = nil //clear reporting group
        self.temporaryStorageObject = nil //clear temp object
        for object in self.counters { //refresh each counter
            if let counter = object as? Counter {
                counter.refreshCounter()
            }
        }
        saveManagedObjectContext() //persist all changes
    }
    
    // MARK: - Project Endpoint Logic
    
    internal func getPercentageCompleted() -> Double? { //calculates what % of project is complete
        let currentDate = NSDate() //get current time
        let currentTimeElapsed = abs(self.startDate.timeIntervalSinceDate(currentDate)) //proj run length
//        print("Current Time Elapsed: \(currentTimeElapsed).")
        if let totalTimeDifference = self.endDate?.timeIntervalSinceDate(self.startDate) { //total length
            let percentCompleted = Double(currentTimeElapsed / abs(totalTimeDifference))
//            print("Total Time Difference: \(totalTimeDifference).")
//            print("% Complete = \(percentCompleted * 100)%.")
            return percentCompleted
        }
        return nil //indefinite project (NO % value)
    }
    
    // MARK: - Data Reporting Logic
    
    //**For type II variables (sensor data), we will need to create a separate DB table b/c the entries will not be collected @ the same frequency as other data (OR SHOULD WE SET IT SO THE RATES MATCH?).
    
    func shouldDisplayGroupSelectionView() -> Bool { //accessed by DataEntryVC
        reportingGroup = nil //clear reporting group whenever this fx fires
        if let type = self.experimentType {
            switch type {
            case .InputOutput:
                return false
            case .ControlComparison:
                if let temp = temporaryStorageObject, groupDict = temp[BMN_CurrentlyReportingGroupKey] {
                    for (key, _) in groupDict { //Key & Value BOTH equal the groupType's rawValue
                        if let group = GroupTypes(rawValue: key) { //group exists
                            if let groupObjects = self.groups.allObjects as? [Group] {
                                for object in groupObjects { //find group in self.groups w/ matching type
                                    if (object.groupType == group.rawValue) { //find match
                                        self.reportingGroup = object //set indicator
                                    }
                                }
                            }
                        }
                        return false //auto-set data source for group
                    } //**both groups in CC project have EXACT SAME outputs, so it doesn't matter which group we get the variables for, both will be the same! This is redundant now, but may come in handy in the future!
                }
                return true
            }
        }
        print("[PROJECT - shouldDisplayGroupView()] No experimentType was found!")
        return false
    }
    
    var reportingGroup: Group? //keeps track of currently reporting group
    
    func getVariablesForGroup(groupType: GroupTypes?) -> [Module]? { //input the name of the user-selected group to get the variables array (for projects w/ > 1 group) or input nil (for Project w/ 1 grp)
        if let groupObjects = self.groups.allObjects as? [Group] {
            if let group = reportingGroup { //check if there is a reporting group (CC Project OM)
                return group.getManualVariablesForDataEntry()
            } else if let group = groupType { //CC Project
                for object in groupObjects { //find the group in self.groups w/ matching type
                    if (object.groupType == group.rawValue) { //check if input type matches object type
                        reportingGroup = object //set indicator (used when constructing dataObject)
                        return object.getManualVariablesForDataEntry()
                    }
                }
            } else { //IO Project
                reportingGroup = groupObjects.first
                return groupObjects.first?.getManualVariablesForDataEntry()
            }
        }
        return nil
    }
    
    func repopulateDataObjectForSubscribedVariables(erroredService service: ServiceTypes) { //called by DataEntryVC in response to error messages - instructs all variables subscribed to the specified service to re-populate their report data object
        if let group = self.reportingGroup {
            for variable in group.autoCapturedVariables { //check if var is subscribed to service
                if (variable.isSubscribedToService(service)) {
                    variable.populateDataObjectForAutoCapturedVariable() //if it is subscribed, ask it to re-populate the data object
                }
            }
        }
    }
    
    // MARK: - Data Aggregation Logic
    
    func constructDataObjectForDatabase() { //construct dataObject to report -> DB
        var dataObjectToDatabase = Dictionary<String, [String: AnyObject]>()
        var variables: [Module] = []
        if let group = self.reportingGroup { //get variables for currently reporting group
            variables = group.reconstructedVariables
        }
        
        //(1) Obtain the data stored in ALL variables (manual + auto) that are being reported:
        var reportCount = 0
        var deferredComputations: [Module] = [] //array containing computations
        var inputNames: [String] = [] //names of all computation inputs
        var inputsReportData = Dictionary<String, [String: AnyObject]>() //data in all computation inputs
        for variable in variables { //each Module obj reports entered data -> VC to construct dict
            if (variable.variableReportType == ModuleVariableReportTypes.Computation) {
                deferredComputations.append(variable) //defer computations til ALL vars are reported
                for (_, inputName) in variable.computationInputs { //grab names of inputs
                    inputNames.append(inputName)
                }
            } else { //default behavior
                if let data = variable.reportDataForVariable() { //check if data was successfully reported
                    if !(variable.isGhost) { //add non-ghosts to DB object
                        dataObjectToDatabase[variable.variableName] = data
                    } else { //GHOST var (add to computation inputs object)
                        inputsReportData[variable.variableName] = data
                    }
                    reportCount += 1 //compare report count -> full count
                } else {
                    print("[constructDataObject] Error - no data for '\(variable.variableName)' variable!")
                }
            }
        }
        for (variableName, dict) in dataObjectToDatabase { //**
            for (key, value) in dict {
                print("DB Object: VAR = '\(variableName)'. KEY: '\(key)'. VALUE: [\(value)].")
            }
            print("\n")
        }
        
        //(2) Check if any of the variables are computations & (if so) compute their values now:
        if !(deferredComputations.isEmpty) { //COMPUTATION(S) exist
            for name in inputNames { //*add NON-GHOST inputs to dict for CF AFTER all vars report*
                if (inputsReportData[name] == nil) { //ONLY add new entry for NON-ghost (ghosts are ALREADY present in dictionary)!
                    inputsReportData[name] = dataObjectToDatabase[name]
                }
            }
            let computationFramework = Module_ComputationFramework()
            computationFramework.setReportObjectForComputations(deferredComputations, inputsReportData: inputsReportData) //load computations w/ return values
            for computation in deferredComputations { //have computations report their values -> DB object
                if let reportObject = computation.reportDataForVariable() {
                    dataObjectToDatabase[computation.variableName] = reportObject
                }
            }
        }
        
        //(3) If IV are being reported, store data -> tempObj; if OM are reported, send data -> DB:
        if let temp = self.temporaryStorageObject { //tempObject EXISTS (send combined data -> DB)
            if let timeStamps = temp[BMN_Module_MainTimeStampKey], inputsReportTime = timeStamps[BMN_Module_InputsTimeStampKey] as? NSDate { //get inputTime from dict
                let outputsReportTime = NSDate() //get CURRENT time for outputs timeStamp
                    
                //Check if project contains a TimeDifference variable:
                if let tdInfo = temp[BMN_ProjectContainsTimeDifferenceKey], name = tdInfo[BMN_CustomModule_TimeDifferenceKey] as? String { //calculate TD if it exists
                    let difference = outputsReportTime.timeIntervalSinceReferenceDate - inputsReportTime.timeIntervalSinceReferenceDate
                    self.temporaryStorageObject![BMN_ProjectContainsTimeDifferenceKey] = nil //clear indicator in tempObject
                    dataObjectToDatabase[name] = [BMN_Module_ReportedDataKey: difference] //save time difference in var's 'reportedDataKey'
                }
                self.temporaryStorageObject![BMN_Module_MainTimeStampKey] = nil //clear item
                    
                //Update dataObject's input & output NSDate timeStamps w/ STRING timeStamps:
                let outputsTimeStamp = DateTime(date: outputsReportTime).getFullTimeStamp() //string
                dataObjectToDatabase[BMN_Module_MainTimeStampKey]?.updateValue(outputsTimeStamp, forKey: BMN_Module_OutputsTimeStampKey)
                dataObjectToDatabase[BMN_Module_MainTimeStampKey] = [BMN_Module_OutputsTimeStampKey: outputsTimeStamp]
                let inputsTimeStamp = DateTime(date: inputsReportTime).getFullTimeStamp() //string
                dataObjectToDatabase[BMN_Module_MainTimeStampKey]?.updateValue(inputsTimeStamp, forKey: BMN_Module_InputsTimeStampKey)
            }
                
            //Obtain data from tempDataObject:
            if let updatedTemp = self.temporaryStorageObject { //get UPDATED temp object
                for (key, value) in updatedTemp { //add all items in temp object -> DB data object
                    dataObjectToDatabase.updateValue(value, forKey: key)
                }
            }
                
            //**Send combined dict -> DB (use a closure to ensure that all other data has been obtained first). Add dictionary to POST queue (in case internet connection is not available).
            let dbConnection = DatabaseConnection(objectToDatabase: dataObjectToDatabase, projectTitle: self.title)
            dbConnection.postObjectToDatabase()
                
            for (variableName, dict) in dataObjectToDatabase { //**
                for (key, value) in dict {
                    print("DB Object: VAR = '\(variableName)'. KEY: '\(key)'. VALUE: [\(value)].")
                }
            }
            print("\n") //**
                
            self.refreshMeasurementCycle() //set tempObj -> nil & refresh counters after reporting
        } else { //tempObject does NOT exist (save dict -> tempObject until outputs are reported)
            dataObjectToDatabase[BMN_Module_MainTimeStampKey] = [BMN_Module_InputsTimeStampKey: NSDate()] //set single time stamp for ALL of the IVs - *this timeStamp must initially be set as an NSDATE obj so that it can be used to calculate time differences*
            let numberOfGroups = self.groups.count
            if (numberOfGroups > 1) { //multiple groups (save a groupType in the tempObject)
                if let group = reportingGroup {
                    dataObjectToDatabase[BMN_CurrentlyReportingGroupKey] = [group.groupType: group.groupType] //store Group type in dict
                }
            }
            self.temporaryStorageObject = dataObjectToDatabase //store obj -> temp
            saveManagedObjectContext() //save tempObject
        }
    }
    
}