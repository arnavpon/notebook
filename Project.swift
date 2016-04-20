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
    
    //flexible way to obtain data for auto-captured variables: (1) TYPE 1 - variables that are automatically captured 1 time just before the DB object is generated (i.e. when 'Done' button is pressed in VC); (2) TYPE 2 - data captured from sensors (how to handle this is TBD).
    //When variables are going to be reported, we need to check if any of the variables w/in a given set of IV or OM are auto-captured. If so, we need to collect that data @ this time -
    //(1) Need method to check if there are auto-captured variables - needs to introspectively check which of its groups is being reported, whether IV or OM are being reported, & for that group, determine which vars are auto vs. manual.
    //(2) Need flexible method to have all of these variables report their data back before generating the final dict - this is tricky b/c it will require access to HealthKit, Location services, etc. & if these are disabled, we won't be able to collect that info. We must prompt the user to enable that info sooner (e.g. when they open the DataEntryVC, prompt them even before DoneBtn is hit). All of the data will be reported asynchronously, aggregated w/ the manually reported data, & sent -> DB. **We could place a method inside the Module class that ONLY works for auto-cap vars, & is similar to the REPORT DATA fx in TV cells. When called by the Project class or VC, it executes an overriden functionality that sends back the data for that variable in a dictionary against its name [varName: data].
    //When do we obtain the data & how do we handle the fact that data will be returned asynchronously (hence we cannot collect it when the Done btn is pressed [OR CAN WE & just send the data asynchronously?]).
    //For type II variables (sensor data), we will need to create a separate DB table b/c the entries will not be collected @ the same frequency as other data (OR SHOULD WE SET IT SO THE RATES MATCH?).
    
    func shouldDisplayGroupSelectionView() -> Bool { //accessed by DataEntryVC
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
                return group.getVariablesArrayForDataEntry()
            } else if let group = groupType { //CC Project
                for object in groupObjects { //find the group in self.groups w/ matching type
                    if (object.groupType == group.rawValue) { //check if input type matches object type
                        reportingGroup = object //set indicator (used when constructing dataObject)
                        return object.getVariablesArrayForDataEntry()
                    }
                }
            } else { //IO Project
                reportingGroup = groupObjects.first
                return groupObjects.first?.getVariablesArrayForDataEntry()
            }
        }
        return nil
    }
    
    func constructDataObjectForDatabase() { //construct dataObject to report -> DB
        var dataObjectToDatabase = Dictionary<String, [String: AnyObject]>()
        var variables: [Module] = []
        if let group = self.reportingGroup { //get variables for currently reporting group
            variables = group.reconstructedVariables
        }
        
        
        //(1) Obtain the data stored in all of the variables that are being reported:
        for variable in variables { //each Module obj reports entered data -> VC to construct dict
            dataObjectToDatabase[variable.variableName] = variable.reportDataForVariable()
        }
        for (variableName, dict) in dataObjectToDatabase { //**
            for (key, value) in dict {
                print("DB Object: VAR = '\(variableName)'. KEY: '\(key)'. VALUE: [\(value)].")
            }
            print("\n") //*
        }
        
        //If IV are being reported, store data -> tempObj; if OM are reported, send data -> DB:
        if let temp = self.temporaryStorageObject { //tempObject EXISTS (send combined data -> DB)
            if let timeStamps = temp[BMN_Module_MainTimeStampKey], inputsReportTime = timeStamps[BMN_Module_InputsTimeStampKey] as? NSDate { //get inputTime from dict
                let outputsReportTime = NSDate() //get CURRENT time for outputs timeStamp
                    
                //Check if project contains a TimeDifference variable:
                if let tdInfo = temp[BMN_ProjectContainsTimeDifferenceKey], name =  tdInfo[BMN_CustomModule_TimeDifferenceKey] as? String { //calculate TD if it exists
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
                
            //**send combined dict -> DB (use a closure to ensure that all other data has been obtained first)
                
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