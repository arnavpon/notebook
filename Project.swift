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
//                print("[CURRENT] \(DateTime(date: currentDate).getFullTimeStamp())")
//                print("[END] \(DateTime(date: end).getFullTimeStamp())")
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
        print("Refreshing measurement cycle...")
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
    
    var reportingGroup: Group? //keeps track of currently reporting group
    var groupSelectionOptions: [(String, String?)]? //(groupName, groupType)
    
    func getOptionsForGroupSelectionView() -> (String, [String])? { //accessed by DataEntryVC - returns (topLabelTitle, [selectionOptions])
        reportingGroup = nil //clear reporting group whenever this fx fires
        if let type = self.experimentType {
            switch type {
            case .InputOutput: //check for asynchronous action
                if let temp = temporaryStorageObject, _ = temp[BMN_TSO_ReportingGroupKey] as? [String: String] { //check if tempObject already contains a reportingGroup
                    return nil
                } else if let projectGroups = self.groups.allObjects as? [Group], loneGroup = projectGroups.first { //ONLY check for async action @ START of measurement cycle (i.e. if there is NO reporting group present)
                    let action = Action(settings: loneGroup.action) //reconstruct action
                    var actionName = ""
                    if let custom = action.customActionName {
                        actionName = custom
                    } else {
                        actionName = action.action.rawValue
                    }
                    if (action.actionLocation == ActionLocations.BeforeInputs) && !(action.occursInEachCycle) { //check if Action is asynchronous
                        if let _ = action.actionTimeStamp { //timeStamp is SET => the asynchronous Action has occurred at least 1 time previously!
                            let options = ["'\(actionName)' (Action) has occurred!", "Report Data"]
                            groupSelectionOptions = [("1st", nil), ("2", nil)]
                            return ("Did you perform the action or are you just reporting data?", options)
                        } else { //no timeStamp => the async Action has NEVER occurred before
                            loneGroup.asynchronousActionHasOccurred() //call async Action fx
                        }
                    }
                }
            case .ControlComparison:
                if let temp = temporaryStorageObject, groupDict = temp[BMN_TSO_ReportingGroupKey] as? [String: String] { //check if tempObject contains a reportingGroup
                    for (name, type) in groupDict { //key = groupName; value = groupType's rawValue
                        if let group = GroupTypes(rawValue: type) { //groupType exists
                            if let groupObjects = self.groups.allObjects as? [Group] {
                                for object in groupObjects { //find group in self.groups w/ matching type
                                    if (object.groupType == group.rawValue) && (object.groupName == name) { //match found
                                        print("[SetGroupSelectionView] Matching group found!")
                                        self.reportingGroup = object //set indicator
                                        return nil //terminate loop
                                    }
                                }
                            }
                        }
                    } //**all groups in CC project have EXACT SAME outputs, so it doesn't matter which group we get the variables for, both will be the same! This is redundant now, but may come in handy in the future!
                } else if let projectGroups = groups.allObjects as? [Group] { //no group - user must pick
                    groupSelectionOptions = [] //initialize reference array
                    var options: [String] = [] //list of options for VC
                    for item in projectGroups {
                        groupSelectionOptions!.append((item.groupName, item.groupType))
                        options.append("\(item.groupName) [\(item.groupType) Group]") //full opt title
                    }
                    return ("Select the group you want to report data for:", options)
                }
            }
        }
        return nil //default is nil (no options are presented)
    }
    
    func getVariablesForSelectedGroup(selection: Int?) -> [Module]? { //check which option the user selected & generate the variables for the selection
        if let currentGroup = reportingGroup { //check if reportingGroup is already set
            return currentGroup.getManualVariablesForDataEntry()
        } else { //reporting group is not set - assign the reporting group
            if let groupObjects = self.groups.allObjects as? [Group] {
                if let index = selection, options = groupSelectionOptions, experiment = self.experimentType {
                    switch experiment {
                    case .InputOutput: //match selection -> Group
                        reportingGroup = groupObjects.first //set reportingGroup
                        if (index == 0) { //async action has occurred
                            reportingGroup?.asynchronousActionHasOccurred() //handle btn click
                        }
                        return groupObjects.first?.getManualVariablesForDataEntry() //return variables
                    case .ControlComparison: //match selection -> Group
                        let groupID = options[index]
                        for object in groupObjects {
                            if (object.groupName == groupID.0) && (object.groupType == groupID.1) {
                                reportingGroup = object //set reportingGroup
                                return object.getManualVariablesForDataEntry() //match found
                            }
                        }
                    }
                    groupSelectionOptions = nil //*clear for next cycle*
                } else { //no selection & no reporting group (default for IO Project)
                    reportingGroup = groupObjects.first //set reportingGroup
                    return groupObjects.first?.getManualVariablesForDataEntry()
                }
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
        var measurementCycleLength: Int = 0 //total length of measurement cycle
        var actionQualifiers: [String]? //list of AQ names (for async Action logic)
        if let group = self.reportingGroup { //get variables for currently reporting group
            variables = group.reconstructedVariables
            measurementCycleLength = group.measurementCycleLength as Int
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
            } else if (variable.variableReportType == ModuleVariableReportTypes.TimeDifference) {
                if let customMod = variable as? CustomModule, setup = customMod.timeDifferenceSetup {
                    if (setup.0 == .DistanceFromAction) { //DistanceFromAction TD - compute value
                        if let currentGroup = self.reportingGroup {
                            let action = Action(settings: currentGroup.action)
                            if let actionTimeStamp = action.actionTimeStamp {
                                print("[Project] Calculating distance from action...")
                                let currentTime = NSDate()
                                let difference = currentTime.timeIntervalSinceDate(actionTimeStamp)
                                print("Time Difference = [\(difference)] seconds!")
                                dataObjectToDatabase[variable.variableName] = [BMN_Module_ReportedDataKey: difference] //set item in database object
                            }
                        }
                    }
                }
            } else { //default behavior
                if let data = variable.reportDataForVariable() { //check if data was successfully reported
                    if !(variable.isGhost) { //add non-ghosts to DB object
                        dataObjectToDatabase[variable.variableName] = data
                        if let customVar = variable as? CustomModule, id = customVar.counterUniqueID {
                            //*COUNTER variable - refresh count for next measurement*:
                            for object in self.counters { //pick counter out from group
                                if let counter = object as? Counter {
                                    if (counter.id == id) { //IDs match
                                        counter.refreshCounter() //refresh this counter
                                    }
                                }
                            }
                        }
                    } else { //GHOST var (add to computation inputs object)
                        inputsReportData[variable.variableName] = data
                    }
                    reportCount += 1 //compare report count -> full count
                } else {
                    print("[constructDataObject] Error - no data for '\(variable.variableName)' variable!")
                }
            }
            
            //For async Action - check if any of the vars are AQ:
            if (variable.configurationType == .ActionQualifier) {
                if (actionQualifiers == nil) { //array does NOT yet exist
                    actionQualifiers = [] //initialize
                }
                actionQualifiers!.append(variable.variableName) //add name -> array
            }
        }
        for (variableName, dict) in dataObjectToDatabase { //**
            for (key, value) in dict {
                print("DB Object: VAR = [\(variableName)]. KEY: [\(key)]. VALUE: [\(value)].")
            }
            print("\n")
        }
        
        //(2) Check if any of the variables are computations & (if so) compute their values now:
        if !(deferredComputations.isEmpty) { //COMPUTATION(S) exist
            for name in inputNames { //*add NON-GHOST inputs to dict for CompFr AFTER all vars report*
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
        
        //(3) For an async action - store actionQualifier data -> the action:
        if let qualifiers = actionQualifiers { //this location has AQ
            storeQualifierDataForAsyncAction(qualifiers, databaseObject: dataObjectToDatabase)
        }
        
        //(4) If this is NOT the last location in measurement cycle, store data -> tempObject; if it is the last location, send the data -> DB:
        parseDatabaseObject(measurementCycleLength, dataObjectToDatabase: dataObjectToDatabase)
    }
    
    private func parseDatabaseObject(measurementCycleLength: Int, dataObjectToDatabase: [String: [String: AnyObject]]) {
        print("Analyzing temp object... Measurement cycle length = [\(measurementCycleLength)].")
        if let temp = self.temporaryStorageObject, timeStampsArray = temp[BMN_DBO_TimeStampKey] as? [NSDate] { //tempObject EXISTS - determine location by counting # of timeStamps in the dict (count reflects # of times data has been reported, but does NOT include data from the CURRENT location in cycle, hence we must add 1)
            print("Temp obj exists - current loc in meas cycle = [\(timeStampsArray.count+1)]!")
            var updatedTimeStamps = timeStampsArray //update timeStamps array
            updatedTimeStamps.append(NSDate()) //add newest timeStamp -> updated array
            self.temporaryStorageObject!.updateValue(updatedTimeStamps, forKey: BMN_DBO_TimeStampKey)
            
            for (variable, reportedData) in dataObjectToDatabase { //add all items in DB object -> tempObj
                var updatedDict = reportedData //set existing data
                var mappedDict = Dictionary<Int, AnyObject>()
                if let newData = reportedData[BMN_Module_ReportedDataKey] {
                    if let existingDict = temp[variable], existingData = existingDict[BMN_Module_ReportedDataKey] as? [Int: AnyObject] { //check for existing data
                        mappedDict = existingData //add existing data -> dict if it is present
                    }
                    mappedDict.updateValue(newData, forKey: (timeStampsArray.count + 1)) //match newData to the current location in measurement cycle
                }
                updatedDict.updateValue(mappedDict, forKey: BMN_Module_ReportedDataKey) //each object's reported data must be matched to its location in the measurement cycle (used to cross reference the timeStamp for that measurement location)
                self.temporaryStorageObject!.updateValue(updatedDict, forKey: variable)
            }
            if (measurementCycleLength > (timeStampsArray.count + 1)) { //NOT end - store data in temp
                print("Some items remain to be reported! Storing data in tempObj...")
                saveManagedObjectContext() //save tempDict in CoreData
            } else { //no more reports remain - send data -> DB
                print("All items in the measurement cycle have reported! Sending data -> DB...")
                addDatabaseObjectToPOSTQueue(self.temporaryStorageObject!) //create DB operation for data
            }
        } else { //tempObject does NOT exist (current location in cycle == 1)
            print("Temp obj does NOT exist!")
            self.temporaryStorageObject = Dictionary<String, AnyObject>() //initialize
            temporaryStorageObject![BMN_DBO_TimeStampKey] = [NSDate()] //set a single time stamp for each point in measurement cycle - *timeStamp must initially be set as NSDATE obj so it can be used to calculate time differences*
            if let group = reportingGroup { //always store reporting group
                temporaryStorageObject![BMN_TSO_ReportingGroupKey] = [group.groupName: group.groupType] //store Group's name & type in dict
            }
            for (variable, reportedData) in dataObjectToDatabase { //store DB obj -> tempObj (KEY = var)
                var updatedDict = reportedData
                var mappedDict = Dictionary<Int, AnyObject>()
                if let data = reportedData[BMN_Module_ReportedDataKey] {
                    mappedDict[1] = data //match data to 1st position in measurement cycle
                }
                updatedDict.updateValue(mappedDict, forKey: BMN_Module_ReportedDataKey) //each object's reported data must be matched to its location in the measurement cycle (used to cross reference the timeStamp for that measurement location)
                self.temporaryStorageObject!.updateValue(updatedDict, forKey: variable)
            }
            if (measurementCycleLength > 1) { //save dict -> tempObject until all data is reported
                print("Measurement cycle length > 1! Saving temp object...")
                saveManagedObjectContext() //save tempObject
            } else if (measurementCycleLength == 1) { //only 1 location in cycle - send data -> DB
                print("Only 1 report per cycle for this group. Sending data -> DB...")
                addDatabaseObjectToPOSTQueue(self.temporaryStorageObject!)
            }
        }
    }
    
    private func addDatabaseObjectToPOSTQueue(dbObject: [String: AnyObject]) { //add dict -> POST queue (when DB is online, we will check for internet connection & post immediately if it exists, store to queue if it doesn't)
        var updatedObject = dbObject
        if let timeStamps = dbObject[BMN_DBO_TimeStampKey] as? [NSDate] { //calculate TD if any exist
            if let timeDifferenceVars = self.reportingGroup?.timeDifferenceVars {
                print("Computing time differences (\(timeDifferenceVars.count) total)...")
                for (variable, settings) in timeDifferenceVars {
                    let timeDifference = CustomModule(name: variable, dict: settings)
                    if let setup = timeDifference.timeDifferenceSetup, (loc1, loc2) = setup.1 {
                        let time1 = timeStamps[(loc1 - 1)]
                        let time2 = timeStamps[(loc2 - 1)]
                        let difference = time2.timeIntervalSinceDate(time1)
                        print("TD for variable [\(variable)] = [\(difference)] seconds.")
                        updatedObject.updateValue(difference, forKey: variable) //add var -> DB object
                    }
                }
            }
            
            var formattedTimeStamps: [String] = [] //format timeStamps before constructing POST
            for timeStamp in timeStamps {
                let formattedStamp = DateTime(date: timeStamp).getFullTimeStamp() //string value
                formattedTimeStamps.append(formattedStamp)
            }
            updatedObject.updateValue(formattedTimeStamps, forKey: BMN_DBO_TimeStampKey) //update obj
        }
        updatedObject[BMN_TSO_ReportingGroupKey] = nil //strip the group from the DB object (it will be added back later to topLevel of dict)
        
        if let connection = DatabaseConnection(), group = self.reportingGroup {
            connection.createDataObjectForReportedData(self.title, reportedData: updatedObject, group: group) //creates data object & stores it in CD
            
            for (key, value) in updatedObject { //**
                if let val = value as? [String: AnyObject] {
                    for (innerKey, data) in val {
                        print("DB Object: VAR = [\(key)]. KEY: [\(innerKey)]. VALUE: [\(data)].")
                    }
                } else {
                    print("DB Object: KEY = [\(key)]. Value = [\(value)].")
                }
            }
            print("\n") //**
            
            self.refreshMeasurementCycle() //set tempObj -> nil & refresh counters after reporting
        } else {
            print("ERROR - failed to create database object for reported data!")
        }
    }
    
    private func storeQualifierDataForAsyncAction(qualifiers: [String], databaseObject: [String: [String: AnyObject]]) { //for an async action - stores reported data for AQ -> the Action object
        print("\n[storeQualifierDataForAsyncAction()] Checking if action is async...")
        if let group = self.reportingGroup {
            var action = Action(settings: group.action) //obtain Action for reportingGroup
            if (action.actionLocation == ActionLocations.BeforeInputs) && !(action.occursInEachCycle) && (action.qualifiersCount > 0) { //check if action is async & has location in cycle
                print("Action is asynchronous & has a location in the cycle! Storing data...")
                var actionStoredData: [String: [String: AnyObject]] = [:]
                for qualifier in qualifiers {
                    if let data = databaseObject[qualifier] { //check if data was set for variable
                        var updatedDict = data //set existing data
                        var mappedDict = Dictionary<Int, AnyObject>() //temp obj w/ mapping -> location
                        if let newData = data[BMN_Module_ReportedDataKey] { //get reported value
                            mappedDict.updateValue(newData, forKey: 1) //match data -> loc 1 in cycle
                        }
                        updatedDict.updateValue(mappedDict, forKey: BMN_Module_ReportedDataKey) //each object's reported data must be matched to its location in the measurement cycle (used to cross reference the timeStamp for that measurement location)
                        actionStoredData.updateValue(updatedDict, forKey: qualifier) //save in action
                        print("Stored data for qualifier [\(qualifier)] in action!")
                    }
                }
                action.qualifiersStoredData = actionStoredData //store item to action
                self.reportingGroup!.action = action.constructCoreDataObjectForAction()
                saveManagedObjectContext()
            }
        }
    }
    
//    func constructDataObjectForDatabase() { //construct dataObject to report -> DB
//        var dataObjectToDatabase = Dictionary<String, [String: AnyObject]>()
//        var variables: [Module] = []
//        if let group = self.reportingGroup { //get variables for currently reporting group
//            variables = group.reconstructedVariables
//        }
//        
//        //(1) Obtain the data stored in ALL variables (manual + auto) that are being reported:
//        var reportCount = 0
//        var deferredComputations: [Module] = [] //array containing computations
//        var inputNames: [String] = [] //names of all computation inputs
//        var inputsReportData = Dictionary<String, [String: AnyObject]>() //data in all computation inputs
//        for variable in variables { //each Module obj reports entered data -> VC to construct dict
//            if (variable.variableReportType == ModuleVariableReportTypes.Computation) {
//                deferredComputations.append(variable) //defer computations til ALL vars are reported
//                for (_, inputName) in variable.computationInputs { //grab names of inputs
//                    inputNames.append(inputName)
//                }
//            } else { //default behavior
//                if let data = variable.reportDataForVariable() { //check if data was successfully reported
//                    if !(variable.isGhost) { //add non-ghosts to DB object
//                        dataObjectToDatabase[variable.variableName] = data
//                    } else { //GHOST var (add to computation inputs object)
//                        inputsReportData[variable.variableName] = data
//                    }
//                    reportCount += 1 //compare report count -> full count
//                } else {
//                    print("[constructDataObject] Error - no data for '\(variable.variableName)' variable!")
//                }
//            }
//        }
//        for (variableName, dict) in dataObjectToDatabase { //**
//            for (key, value) in dict {
//                print("DB Object: VAR = '\(variableName)'. KEY: '\(key)'. VALUE: [\(value)].")
//            }
//            print("\n")
//        }
//        
//        //(2) Check if any of the variables are computations & (if so) compute their values now:
//        if !(deferredComputations.isEmpty) { //COMPUTATION(S) exist
//            for name in inputNames { //*add NON-GHOST inputs to dict for CF AFTER all vars report*
//                if (inputsReportData[name] == nil) { //ONLY add new entry for NON-ghost (ghosts are ALREADY present in dictionary)!
//                    inputsReportData[name] = dataObjectToDatabase[name]
//                }
//            }
//            let computationFramework = Module_ComputationFramework()
//            computationFramework.setReportObjectForComputations(deferredComputations, inputsReportData: inputsReportData) //load computations w/ return values
//            for computation in deferredComputations { //have computations report their values -> DB object
//                if let reportObject = computation.reportDataForVariable() {
//                    dataObjectToDatabase[computation.variableName] = reportObject
//                }
//            }
//        }
//        
//        //(3) If IV are being reported, store data -> tempObj; if OM are reported, send data -> DB:
//        if let temp = self.temporaryStorageObject { //tempObject EXISTS (send combined data -> DB)
//            if let timeStamps = temp[BMN_Module_MainTimeStampKey], inputsReportTime = timeStamps[BMN_Module_InputsTimeStampKey] as? NSDate { //get inputTime from dict
//                let outputsReportTime = NSDate() //get CURRENT time for outputs timeStamp
//                
//                //Check if project contains a TimeDifference variable:
//                if let tdInfo = temp[BMN_ProjectContainsTimeDifferenceKey], name = tdInfo[BMN_CustomModule_TimeDifferenceKey] as? String { //calculate TD if it exists
//                    let difference = outputsReportTime.timeIntervalSinceReferenceDate - inputsReportTime.timeIntervalSinceReferenceDate
//                    self.temporaryStorageObject![BMN_ProjectContainsTimeDifferenceKey] = nil //clear indicator in tempObject
//                    dataObjectToDatabase[name] = [BMN_Module_ReportedDataKey: difference] //save time difference in var's 'reportedDataKey'
//                }
//                self.temporaryStorageObject?.removeValueForKey(BMN_Module_MainTimeStampKey)
//                self.temporaryStorageObject?.removeValueForKey(BMN_CurrentlyReportingGroupKey) //remove indicator from dict before posting to DB
//                
//                //Update dataObject's input & output NSDate timeStamps w/ STRING timeStamps:
//                let outputsTimeStamp = DateTime(date: outputsReportTime).getFullTimeStamp() //string
//                dataObjectToDatabase[BMN_Module_MainTimeStampKey] = [BMN_Module_OutputsTimeStampKey: outputsTimeStamp]
//                let inputsTimeStamp = DateTime(date: inputsReportTime).getFullTimeStamp() //string
//                dataObjectToDatabase[BMN_Module_MainTimeStampKey]?.updateValue(inputsTimeStamp, forKey: BMN_Module_InputsTimeStampKey)
//            }
//            
//            //Obtain data from tempDataObject:
//            if let updatedTemp = self.temporaryStorageObject { //get UPDATED temp object
//                for (key, value) in updatedTemp { //add all items in temp object -> DB data object
//                    dataObjectToDatabase.updateValue(value, forKey: key)
//                }
//            }
//            
//            //Add dictionary to POST queue (when DB is online, we will check for internet connection & post immediately if it exists, store to queue if it doesn't):
//            if let connection = DatabaseConnection(), groupType = self.reportingGroup?.groupType {
//                connection.createDataObjectForReportedData(self.title, reportedData: dataObjectToDatabase, groupType: groupType) //creates data object & stores it in CD
//                
//                for (variableName, dict) in dataObjectToDatabase { //**
//                    for (key, value) in dict {
//                        print("DB Object: VAR = '\(variableName)'. KEY: '\(key)'. VALUE: [\(value)].")
//                    }
//                }
//                print("\n") //**
//                
//                self.refreshMeasurementCycle() //set tempObj -> nil & refresh counters after reporting
//            } else {
//                print("ERROR - failed to create database object for reported data!")
//            }
//            
//        } else { //tempObject does NOT exist (save dict -> tempObject until outputs are reported)
//            dataObjectToDatabase[BMN_Module_MainTimeStampKey] = [BMN_Module_InputsTimeStampKey: NSDate()] //set single time stamp for ALL of the IVs - *this timeStamp must initially be set as an NSDATE obj so that it can be used to calculate time differences*
//            let numberOfGroups = self.groups.count
//            if (numberOfGroups > 1) { //multiple groups (save a groupType in the tempObject)
//                if let group = reportingGroup {
//                    dataObjectToDatabase[BMN_CurrentlyReportingGroupKey] = [group.groupType: group.groupType] //store Group type in dict
//                }
//            }
//            self.temporaryStorageObject = dataObjectToDatabase //store obj -> temp
//            saveManagedObjectContext() //save tempObject
//        }
//    }
    
}