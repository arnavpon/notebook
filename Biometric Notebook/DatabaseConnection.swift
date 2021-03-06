//  DatabaseConnection.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 6/29/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Handles all interactions between the application & the database - this includes Cloud backups, data reporting, etc.

import UIKit
import CoreData

enum DatabaseConnectionDataTypes: Int {
    case CloudModel = 0
    case EditedProjectModel = 1
    case EditedProjectData = 2 //1st transmission of data for edited project
    case ReportedData = 3
}

class DatabaseConnection: DataReportingErrorProtocol {
    
    lazy var config: NSURLSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
    lazy var session: NSURLSession = NSURLSession(configuration: self.config)
    private let email: String //current user's email
    private var managedObjectContext: NSManagedObjectContext { //MOC
        return (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    }
    
    private let ip_last: Int //**
    
    // MARK: - Initializers
    
    init?() {
        self.ip_last = NSUserDefaults.standardUserDefaults().integerForKey(IP_VALUE) //**TEMP
            
        if let email = NSUserDefaults.standardUserDefaults().stringForKey(EMAIL_KEY) {
            self.email = email
        } else { //no email -> failure
            return nil
        }
    }
    
    // MARK: - Networking Logic
    
    func pushAllDataToDatabase(count: Int) { //pushes any backups or reportedData -> DB
        if let cloudModels = fetchObjectsFromCoreDataStore("DatabaseObject", filterProperty: "dataTypeRaw", filterValue: ["\(DatabaseConnectionDataTypes.CloudModel.rawValue)"]) as? [DatabaseObject], editedProjectModels = fetchObjectsFromCoreDataStore("DatabaseObject", filterProperty: "dataTypeRaw", filterValue: ["\(DatabaseConnectionDataTypes.EditedProjectModel.rawValue)"]) as? [DatabaseObject], editedProjectObjects = fetchObjectsFromCoreDataStore("DatabaseObject", filterProperty: "dataTypeRaw", filterValue: ["\(DatabaseConnectionDataTypes.EditedProjectData.rawValue)"]) as? [DatabaseObject], dataObjects = fetchObjectsFromCoreDataStore("DatabaseObject", filterProperty: "dataTypeRaw", filterValue: ["\(DatabaseConnectionDataTypes.ReportedData.rawValue)"]) as? [DatabaseObject] {
            if !(cloudModels.isEmpty) { //(1) push cloud models
                if let cloudModel = cloudModels.first { //grab 1st item to push
                    print("\nTransmitting object (Cloud model) #\(count+1) in queue...")
                    postProjectModelToCloud(cloudModel.dataDictionary, success: { (completed) in
                        if (completed) { //operation succeeded - push next function to store
                            deleteManagedObject(cloudModel) //remove object from CoreData store
                            self.pushAllDataToDatabase((count + 1)) //pass next
                        } else { //operation failed - terminate function
                            print("Operation failed. Terminating process...\n")
                            let notification = NSNotification(name: BMN_Notification_DatabaseConnection_DataTransmissionStatusDidChange, object: nil, userInfo: [BMN_DatabaseConnection_TransmissionStatusKey: false])
                            NSNotificationCenter.defaultCenter().postNotification(notification)
                            return
                        }
                    })
                }
            } else if !(editedProjectModels.isEmpty) { //(2) push edited project models
                if let editedModel = editedProjectModels.first { //grab 1st item to push
                    print("\nTransmitting object (EDITED model) #\(count+1) in queue...")
                    postEditedProjectModelToDatabase(editedModel.dataDictionary, success: { (completed) in
                        if (completed) { //operation succeeded - push next function to store
                            deleteManagedObject(editedModel) //remove object from CoreData store
                            self.pushAllDataToDatabase((count + 1)) //pass next
                        } else { //operation failed - terminate function
                            print("Operation failed. Terminating process...\n")
                            let notification = NSNotification(name: BMN_Notification_DatabaseConnection_DataTransmissionStatusDidChange, object: nil, userInfo: [BMN_DatabaseConnection_TransmissionStatusKey: false])
                            NSNotificationCenter.defaultCenter().postNotification(notification)
                            return
                        }
                    })
                }
            } else if !(editedProjectObjects.isEmpty) { //(3) push editedProjectData (1st transmission)
                if let initialDataObject = editedProjectObjects.first { //grab 1st item to push
                    print("\nTransmitting object (EDITED data) #\(count+1) in queue...")
                    self.postDataObjectToDatabase(initialDataObject, success: { (completed) in
                        if (completed) { //the operation succeeded - push next function to store
                            deleteManagedObject(initialDataObject) //remove object from CoreData store
                            self.pushAllDataToDatabase((count + 1)) //pass next
                        } else { //the operation failed - terminate function
                            print("Operation failed! Terminating process...\n")
                            let notification = NSNotification(name: BMN_Notification_DatabaseConnection_DataTransmissionStatusDidChange, object: nil, userInfo: [BMN_DatabaseConnection_TransmissionStatusKey: false])
                            NSNotificationCenter.defaultCenter().postNotification(notification)
                            return
                        }
                    })
                }
            } else if !(dataObjects.isEmpty) { //(4) push reportedData
                if let dataObject = dataObjects.first { //grab 1st item to push
                    print("\nTransmitting object (NORMAL data) #\(count+1) in queue...")
                    self.postDataObjectToDatabase(dataObject, success: { (completed) in
                        if (completed) { //the operation succeeded - push next function to store
                            deleteManagedObject(dataObject) //remove object from CoreData store
                            self.pushAllDataToDatabase((count + 1)) //pass next
                        } else { //the operation failed - terminate function
                            print("Operation failed! Terminating process...\n")
                            let notification = NSNotification(name: BMN_Notification_DatabaseConnection_DataTransmissionStatusDidChange, object: nil, userInfo: [BMN_DatabaseConnection_TransmissionStatusKey: false])
                            NSNotificationCenter.defaultCenter().postNotification(notification)
                            return
                        }
                    })
                }
            } else { //no remaining Cloud Models or dataObjects
                if (count == 0) { //initial function call
                    print("There are no objects in the cloud queue!\n")
                } else { //some objects were pushed
                    print("\(count) objects(s) were successfully pushed to cloud!\n")
                    let notification = NSNotification(name: BMN_Notification_DatabaseConnection_DataTransmissionStatusDidChange, object: nil, userInfo: [BMN_DatabaseConnection_TransmissionStatusKey: true])
                    NSNotificationCenter.defaultCenter().postNotification(notification)
                }
            }
        }
    }
    
    // MARK: - Cloud Backup Logic
    
    func createCloudModelForProject(project: Project) { //creates temporary CD backup
        print("Creating Cloud representation for project [\(project.title)]...")
        let cloudDictionary: [String: AnyObject] = constructCloudObject(project)
        let _ = DatabaseObject(title: project.title, data: cloudDictionary, dataType: .CloudModel, insertIntoManagedObjectContext: managedObjectContext) //keep backup in CD store
        saveManagedObjectContext()
        print("Backup was created for project!\n")
    }
    
    private func constructCloudObject(project: Project) -> Dictionary<String, AnyObject> { //uses the input project to construct the dict sent -> the Cloud for backup
        var body: [String: AnyObject] = ["experiment_type": project.projectType, "title": project.title, "question": project.question, "start_date": project.startDate.timeIntervalSinceReferenceDate]
        if let hypothesis = project.hypothesis { //add hypothesis -> dict ONLY if it exists
            body.updateValue(hypothesis, forKey: "hypothesis")
        }
        if let endDate = project.endDate { //add endDate -> dict ONLY if it is defined
            let timeDifference = endDate.timeIntervalSinceDate(project.startDate)
            print("[constructCloudObj] Time Difference btwn start & end = \(timeDifference).")
            body.updateValue(timeDifference, forKey: "endpoint")
        }
        
        var groups = Dictionary<String, [String: AnyObject]>() //FORMAT = ["groups": ["groupName1": dict, "groupName2": dict, ...]]
        for projectGroups in project.groups {
            if let group = projectGroups as? Group { //construct a DB dict for EACH Group in Project
                let groupName = group.groupName //UNIQUE key for group's dict
                let groupType = group.groupType
                let action = group.action //dictionary representation for action
                let groupVariables = group.variables
                let measurementCycleLength = group.measurementCycleLength as Int
                var temp: Dictionary<String, AnyObject> = ["groupType": groupType, "action": action, "variables": groupVariables, "measurementCycleLength": measurementCycleLength]
                if let timeDifferenceVariables = group.timeDifferenceVars { //check for TD vars
                    temp.updateValue(timeDifferenceVariables, forKey: "timeDifferenceVariables")
                }
                groups.updateValue(temp, forKey: groupName) //match Group dict -> groupName
            }
        }
        body.updateValue(groups, forKey: "groups") //add Groups dict -> next lvl dictionary
        var counters: [String] = []
        for projectCounters in project.counters { //add backup for Counters in Project
            if let counter = projectCounters as? Counter {
                let variableName = counter.variableName
                counters.append(variableName)
            }
        }
        body.updateValue(counters, forKey: "counters")
        return ["BMN_EMAIL": self.email, "BMN_PROJECT_SHELL": body] //final return object
    }
    
    private func postProjectModelToCloud(model: [String: AnyObject], success: (Bool) -> Void) {
        let url = NSURL(string: "http://192.168.1.\(ip_last):8000/backup-project")!
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "POST"
        do { //pass dictionary representation -> Cloud
            let data = try NSJSONSerialization.dataWithJSONObject(model, options: NSJSONWritingOptions(rawValue: 0))
            request.HTTPBody = data
            let task = session.dataTaskWithRequest(request, completionHandler: { (data, response, error) in
                if (error == nil) { //no error
                    if let httpResponse = response as? NSHTTPURLResponse {
                        let status = httpResponse.statusCode
                        switch status {
                        case 200:
                            if let responseData = data, responseAsText = NSString(data: responseData, encoding: NSUTF8StringEncoding) {
                                switch responseAsText as String {
                                case "000":
                                    print("[000] Error - process failed.")
                                    success(false)
                                case "001": //duplicate project error
                                    print("[001] Error - duplicate project title.")
                                    success(false)
                                case "010":
                                    print("Backup was successfully created!")
                                    success(true)
                                default:
                                    print("Default in switch: returned code = \(responseAsText).")
                                    success(false)
                                }
                            }
                        default:
                            print("[CreateCloudRep] Default in switch. Code = \(status).")
                            success(false)
                        }
                    }
                } else { //error
                    self.handleAccessError(error!)
                    success(false)
                }
            })
            task.resume()
        } catch {
            print("[Create Cloud Obj] Could not create data from JSON - \(error).")
        }
    }
    
    func retrieveProjectModelsFromCloud(complete: (Bool) -> Void) { //gets all Projects for current user
        let url = NSURL(string: "http://192.168.1.\(ip_last):8000/get-projects-for-user")!
        let postData: [String: String] = ["email": self.email]
        do {
            let data = try NSJSONSerialization.dataWithJSONObject(postData, options: NSJSONWritingOptions(rawValue: 0))
            let connection = NetworkConnection(url: url, postBody: data)
            connection.downloadJSONFromURL({ (returnData) in
                if let data = returnData {
                    if let error = data["error"] as? String { //check for error key in returnObject
                        switch error {
                        case "000":
                            print("[000] ERROR - default failure value.")
                        case "001":
                            print("[001] ERROR - no projects found for given user.")
                        default:
                            print("ERROR - \(error).")
                        }
                    } else { //no errors - obtain array of projectModels
                        if let projectModels = data["project_models"] as? [[String: AnyObject]] { //all of the models are stored against the 'project_models' key
                            print("\(projectModels.count) models were returned!\n")
                            for model in projectModels { //reconstruct Project objects from shells
                                print("\nReconstructing model...")
                                self.reconstructProjectFromModel(model)
                            }
                        }
                    }
                    complete(true) //call regardless of success/failure
                }
            })
        } catch {
            print("[Reconstruct Projects from Cloud] Could not create JSON object - \(error).")
        }
    }
    
    private func reconstructProjectFromModel(projectShell: [String: AnyObject]) { //rebuilds CoreDate Project object using shell returned from DB
        if let typeRaw = projectShell["type"] as? String, type = ExperimentTypes(rawValue: typeRaw), title = projectShell["title"] as? String, question = projectShell["question"] as? String, startDate = projectShell["start_date"] as? Double, groups = projectShell["groups"] as? [String: AnyObject], counters = projectShell["counters"] as? [String] {
            var projectHypothesis: String? = nil
            if let hypothesis = projectShell["hypothesis"] as? String { //optional value
                projectHypothesis = hypothesis
            }
            var projectEndpoint: Double? = nil
            if let endpoint = projectShell["endpoint"] as? Double { //optional value
                projectEndpoint = endpoint
            }
            let project = Project(type: type, title: title, question: question, hypothesis: projectHypothesis, startDate: startDate, endpoint: projectEndpoint, insertIntoManagedObjectContext: managedObjectContext) //(1) create Project
            
            var counterSettings = Dictionary<String, [String: AnyObject]>() //obj w/ counter CD dicts
            for (groupName, settings) in groups { //(2) recreate Group objects in each Project
                print("Reconstructing GROUP = [\(groupName)].")
                if let settingsDict = settings as? [String: AnyObject], groupTypeRaw = settingsDict["groupType"] as? String, groupType = GroupTypes(rawValue: groupTypeRaw), action = settingsDict["action"] as? [String: AnyObject], groupVariables = settingsDict["variables"] as? [String: [String: AnyObject]], cycleLength = settingsDict["measurementCycleLength"] as? Int {
                    var timeDifferenceVariables: [String: [String: AnyObject]]? = nil
                    if let timeDifferences = settingsDict["timeDifferenceVariables"] as? [String: [String: AnyObject]] { //check if Group has any TD vars
                        timeDifferenceVariables = timeDifferences
                    }
                    let _ = Group(groupName: groupName, groupType: groupType, project: project, action: action, variables: groupVariables, cycleLength: cycleLength, timeDifferenceVars: timeDifferenceVariables, insertIntoManagedObjectContext: managedObjectContext)
                    
                    
                    for (variableName, dict) in groupVariables { //handle variable-specific logic
                        if (counters.contains(variableName)) { //obtain CoreData dicts for Counter vars
                            print("Found COUNTER with name = [\(variableName)].")
                            counterSettings.updateValue(dict, forKey: variableName)
                        }
                        if let moduleType = dict[BMN_VariableTypeKey] as? String { //get Datastream vars
                            if (moduleType == ExerciseModuleVariableTypes.Behavior_Workout.rawValue) {
                                print("Found WORKOUT with name = [\(variableName)].")
                                let _ = ExM_ExerciseDatastream.sharedInstance //activate sharedInstance
                            } else if (moduleType == FoodIntakeModuleVariableTypes.Behavior_FoodIntake.rawValue) {
                                print("Found FOOD INTAKE with name = [\(variableName)].")
                                let _ = FIM_FoodIntakeDatastream.sharedInstance //activate sharedInstance
                            }
                        }
                    }
                }
            }
            for (counter, settings) in counterSettings { //(3) recreate any Counter objects
                print("Reconstructing COUNTER = \(counter).")
                let variable = CustomModule(name: counter, dict: settings)
                let _ = Counter(linkedVar: variable, project: project, insertIntoManagedObjectContext: managedObjectContext)
            }
            saveManagedObjectContext() //save context after obtaining new items
        }
    }
    
    // MARK: - Edit Project Flow
    
    func commitProjectEditToDatabase(project: Project) { //EDIT PROJECT flow
        //(1) Delete all DB objects for the edited Project:
        if let itemsForProject = fetchObjectsFromCoreDataStore("DatabaseObject", filterProperty: "projectTitle", filterValue: [project.title]) as? [DatabaseObject] {
            print("[CommitProjectEdit] Deleting \(itemsForProject.count) items in DB queue for project [\(project.title)].")
            for item in itemsForProject { //delete ALL DB objects for indicated Project in queue
                deleteManagedObject(item)
            }
        }
        
        //(2) Create a Cloud Model for the edited Project:
        print("Creating new Cloud model for updated project...")
        let cloudDictionary = constructCloudObject(project)
        let _ = DatabaseObject(title: project.title, data: cloudDictionary, dataType: .EditedProjectModel, insertIntoManagedObjectContext: managedObjectContext)
        saveManagedObjectContext()
        
        var groups: [String] = []
        for groupRaw in project.groups { //construct array containing names of Project's Groups
            if let group = groupRaw as? Group {
                groups.append(group.groupName)
            }
        }
        //(3) Add the array of edited Groups -> UserDefaults (indicates to system that Group was recently edited, which triggers DB-related behaviors):
        if var editedProjects = NSUserDefaults.standardUserDefaults().valueForKey(EDITED_PROJECTS_KEY) as? [String: [String]] { //add entry for Project -> dict
            editedProjects.updateValue(groups, forKey: project.title) //overwrite existing value
            NSUserDefaults.standardUserDefaults().setValue(editedProjects, forKey: EDITED_PROJECTS_KEY)
        } else { //obj does not yet exist - initialize w/ Project's groups
            let editedProjects: [String: [String]] = [project.title: groups]
            NSUserDefaults.standardUserDefaults().setValue(editedProjects, forKey: EDITED_PROJECTS_KEY)
        }
    }
    
    private func postEditedProjectModelToDatabase(model: [String: AnyObject], success: (Bool) -> Void) {
        let url = NSURL(string: "http://192.168.1.\(ip_last):8000/edit-project-setup")!
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "POST"
        do { //pass dictionary representation -> Cloud
            let data = try NSJSONSerialization.dataWithJSONObject(model, options: NSJSONWritingOptions(rawValue: 0))
            request.HTTPBody = data
            let task = session.dataTaskWithRequest(request, completionHandler: { (data, response, error) in
                if (error == nil) { //no error
                    if let httpResponse = response as? NSHTTPURLResponse {
                        let status = httpResponse.statusCode
                        switch status {
                        case 200:
                            if let responseData = data, responseAsText = NSString(data: responseData, encoding: NSUTF8StringEncoding) {
                                switch responseAsText as String {
                                case "000":
                                    print("[000] Error - process failed.")
                                    success(false)
                                case "010":
                                    print("Backup was successfully updated!")
                                    success(true)
                                default:
                                    print("Default in switch: returned code = \(responseAsText).")
                                    success(false)
                                }
                            }
                        default:
                            print("[PostEditedModel] Default in switch. Code = \(status).")
                            success(false)
                        }
                    }
                } else { //error
                    self.handleAccessError(error!)
                    success(false)
                }
            })
            task.resume()
        } catch {
            print("[PostEditedModel] Could not create data from JSON - \(error).")
        }
    }
    
    // MARK: - Data Reporting Logic
    
    func createDataObjectForReportedData(projectTitle: String, reportedData: [String: AnyObject], group: Group) { //for data reporting
        print("Creating dataObject for reported data...")
        var dataObject = Dictionary<String, AnyObject>()
        dataObject.updateValue(email, forKey: "BMN_EMAIL") //pass email (matches data -> correct DB)
        dataObject.updateValue(projectTitle, forKey: "BMN_PROJECT_TITLE") //pass project title
        dataObject.updateValue(reportedData, forKey: "BMN_DATABASE_OBJECT") //pass data object
        dataObject.updateValue(group.groupType, forKey: "BMN_GROUP_TYPE") //pass group type
        dataObject.updateValue(group.groupName, forKey: "BMN_GROUP_NAME") //pass name (IDs reporting grp)
        
        var isEditProjectFlow: Bool = false //indicator
        if var editedProjects = NSUserDefaults.standardUserDefaults().valueForKey(EDITED_PROJECTS_KEY) as? [String: [String]] { //check if editedProjects contains 'projectTitle' & 'groupName'
            if var editedProjectGroups = editedProjects[projectTitle], let index = editedProjectGroups.indexOf(group.groupName) { //UserDefaults obj contains project & group
                print("[createDataObj] GROUP [\(group.groupName)] in PROJECT [\(projectTitle)] is in EDITED_PROJECTS! Setting indicator...")
                dataObject.updateValue(true, forKey: "BMN_EDITED_PROJECT_FIRST_TRANSMISSION") //set indctr
                editedProjectGroups.removeAtIndex(index) //remove Group from array
                if !(editedProjectGroups.isEmpty) { //NOT empty - add array back -> dict
                    editedProjects.updateValue(editedProjectGroups, forKey: projectTitle)
                    NSUserDefaults.standardUserDefaults().setValue(editedProjects, forKey: EDITED_PROJECTS_KEY) //update UserDefaults
                    print("Removed object @ index \(index)!")
                } else { //EMPTY - clear projectTitle from dict
                    editedProjects.removeValueForKey(projectTitle) //remove key from dictionary
                    NSUserDefaults.standardUserDefaults().setValue(editedProjects, forKey: EDITED_PROJECTS_KEY) //update UserDefaults
                    print("Array is EMPTY - removed dict from UserDefaults Store.")
                }
                isEditProjectFlow = true //set local indicator
            }
        }
        if !(isEditProjectFlow) { //DEFAULT flow - dataType = .ReportedData
            let _ = DatabaseObject(title: projectTitle, data: dataObject, dataType: .ReportedData, insertIntoManagedObjectContext: managedObjectContext) //save in CD store until pushed
        } else { //EDIT PROJECT flow - dataType = .EditedProjectData
            let _ = DatabaseObject(title: projectTitle, data: dataObject, dataType: .EditedProjectData, insertIntoManagedObjectContext: managedObjectContext) //save in CD store until pushed
        }
        saveManagedObjectContext()
    }
    
    private func postDataObjectToDatabase(object: DatabaseObject, success: (Bool) -> Void) {
        do {
            let jsonData = try NSJSONSerialization.dataWithJSONObject(object.dataDictionary, options: NSJSONWritingOptions(rawValue: 0))
            
            //Create POST request: ipconfig getifaddr en1; python3 manage.py runserver 192.168.1.?:8000
            let url = NSURL(string: "http://192.168.1.\(ip_last):8000/")! //**
            let request = NSMutableURLRequest(URL: url)
            request.HTTPMethod = "POST"
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            request.HTTPBody = jsonData //make JSON obj the POST body
            
            let task = session.dataTaskWithRequest(request, completionHandler: { (data, response, error) in
                if (error == nil) {
                    if let httpResponse = response as? NSHTTPURLResponse {
                        switch httpResponse.statusCode {
                        case 200:
                            if let responseData = data, responseAsText = NSString(data: responseData, encoding: NSUTF8StringEncoding) {
                                print("[postObjToDB] URL Response: [\(responseAsText)].")
                                switch responseAsText {
                                case "000":
                                    print("[\(responseAsText)] Operation completed with MySQL error!")
                                    success(false)
                                case "001":
                                    print("[\(responseAsText)] Operation was completed successfully!")
                                    success(true)
                                default:
                                    print("[postObjToDB] Error - default in switch!")
                                    success(false)
                                }
                            }
                        default:
                            print("[postObjToDB] Default in switch! Code: \(httpResponse.statusCode).")
                            success(false)
                        }
                    }
                } else { //internet/server access failure
                    self.handleAccessError(error!)
                    success(false)
                }
            })
            task.resume()
        } catch {
            print("[postObjToDB] Exception - \(error)")
            success(false)
        }
    }
    
    // MARK: - Error Handling
    
    private func handleAccessError(error: NSError) { //handles internet access error code appropriately
        switch (error.code) {
        case -1009:
            print("[postObjToDB] No internet access was detected.")
            self.reportAccessErrorForService(.Internet)
        case -1004:
            print("[postObjToDB] Error - could not connect to SERVER!")
            self.reportAccessErrorForService(.Localhost)
        default:
            print("[postObjToDB] Process failed w/ error: \(error).")
        }
    }
    
    func reportAccessErrorForService(service: ServiceTypes) { //throw alert to connect to internet
        let notification = NSNotification(name: BMN_Notification_DataReportingErrorProtocol_ServiceDidReportError, object: nil, userInfo: [BMN_DataReportingErrorProtocol_ServiceTypeKey: service.rawValue])
        NSNotificationCenter.defaultCenter().postNotification(notification)
    }
    
}