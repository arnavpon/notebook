//  DatabaseConnection.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 6/29/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Handles all interactions between the application & the database - this includes Cloud backups, data reporting, etc.

import UIKit
import CoreData

enum DatabaseConnectionDataTypes: Int {
    case CloudModel = 0
    case ReportedData = 1
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
        print("Creating Cloud representation for project...")
            
        self.ip_last = NSUserDefaults.standardUserDefaults().integerForKey(IP_VALUE) //**TEMP
            
        if let email = NSUserDefaults.standardUserDefaults().stringForKey(EMAIL_KEY) {
            self.email = email
        } else { //no email -> failure
            return nil
        }
    }
    
    // MARK: - Networking Logic
    
    func pushAllDataToDatabase(count: Int) { //pushes any backups or reportedData -> DB
        if let cloudModels = fetchObjectsFromCoreDataStore("DatabaseObject", filterProperty: "dataTypeRaw", filterValue: ["0"]) as? [DatabaseObject], dataObjects = fetchObjectsFromCoreDataStore("DatabaseObject", filterProperty: "dataTypeRaw", filterValue: ["1"]) as? [DatabaseObject] {
            if !(cloudModels.isEmpty) { //(1) push cloud models
                if let cloudModel = cloudModels.first, type = DatabaseConnectionDataTypes(rawValue: cloudModel.dataTypeRaw as Int) { //grab 1st item to push
                    print("\nTransmitting object (model) #\(count+1) in queue...")
                    switch type { //check type of data
                    case .CloudModel: //post Cloud backup
                        postProjectModelToCloud(cloudModel, success: { (completed) in
                            if (completed) { //operation succeeded - push next function to store
                                deleteManagedObject(cloudModel) //remove object from CoreData store
                                self.pushAllDataToDatabase((count + 1)) //pass next
                            } else { //operation failed - terminate function
                                print("Operation failed. Terminating process...\n")
                                return
                            }
                        })
                    case .ReportedData: //error
                        print("Error - reportedData found in CloudModel area...\n")
                    }
                }
            } else if !(dataObjects.isEmpty) { //(2) push reportedData
                if let dataObject = dataObjects.first, type = DatabaseConnectionDataTypes(rawValue: dataObject.dataTypeRaw as Int) { //grab 1st item to push
                    print("\nTransmitting object (data) #\(count+1) in queue...")
                    switch type { //check type of data
                    case .CloudModel: //post Cloud backup
                        print("Error - cloudModel found in reportedData area!")
                    case .ReportedData: //post Reported Data
                        self.postDataObjectToDatabase(dataObject, success: { (completed) in
                            if (completed) { //the operation succeeded - push next function to store
                                deleteManagedObject(dataObject) //remove object from CoreData store
                                self.pushAllDataToDatabase((count + 1)) //pass next
                            } else { //the operation failed - terminate function
                                print("Operation failed! Terminating process...\n")
                                return
                            }
                        })
                    }
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
        print("Creating Cloud representation for project...")
        var body: [String: AnyObject] = ["experiment_type": project.projectType, "title": project.title, "question": project.question, "start_date": project.startDate.timeIntervalSinceReferenceDate]
        if let hypothesis = project.hypothesis {
            body.updateValue(hypothesis, forKey: "hypothesis")
        }
        if let endDate = project.endDate {
            let timeDifference = endDate.timeIntervalSinceDate(project.startDate)
            print("Time Difference btwn start & end = \(timeDifference).")
            body.updateValue(timeDifference, forKey: "endpoint")
        }
        var groups = Dictionary<String, [String: AnyObject]>() //["groups": ["group1": dict, "group2": dict, ...]]
        for projectGroups in project.groups {
            if let group = projectGroups as? Group {
                let type = group.groupType
                let action = group.action
                let beforeVars = group.beforeActionVariables
                let afterVars = group.afterActionVariables
                groups.updateValue(["action": action, "beforeVars": beforeVars, "afterVars": afterVars], forKey: type)
                print("Groups Model: \(groups)")
            }
        }
        body.updateValue(groups, forKey: "groups")
        var counters: [String] = [] //**
        for projectCounters in project.counters {
            if let counter = projectCounters as? Counter {
                let variableName = counter.variableName
                counters.append(variableName)
            }
        }
        body.updateValue(counters, forKey: "counters")
        let cloudDictionary: [String: AnyObject] = ["BMN_EMAIL": self.email, "BMN_PROJECT_SHELL": body]
        let _ = DatabaseObject(data: cloudDictionary, dataType: .CloudModel, insertIntoManagedObjectContext: managedObjectContext) //keep backup in CD store until pushed
        saveManagedObjectContext()
        print("Backup was created for project!\n")
    }
    
    private func postProjectModelToCloud(model: DatabaseObject, success: (Bool) -> Void) {
        let url = NSURL(string: "http://192.168.1.\(ip_last):8000/backup-project")!
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "POST"
        do { //pass dictionary representation -> Cloud
            let data = try NSJSONSerialization.dataWithJSONObject(model.dataDictionary, options: NSJSONWritingOptions(rawValue: 0))
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
                                    print("Error - process failed.")
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
                    switch (error!.code) {
                    case -1009:
                        print("[postObjToDB] No internet access was detected.")
                        self.reportAccessErrorForService(.Internet)
                    case -1004:
                        print("[postObjToDB] Error - could not connect to SERVER!")
                        self.reportAccessErrorForService(.Localhost)
                    default:
                        print("[postObjToDB] Process failed w/ error: \(error).")
                    }
                    success(false)
                }
            })
            task.resume()
        } catch {
            print("[Create Cloud Obj] Could not create data from JSON - \(error).")
        }
    }
    
    func reconstructProjectsFromCloud() { //gets all active projects for the current user
        let url = NSURL(string: "http://192.168.1.\(ip_last):8000/get-projects-for-user")!
        let postData: [String: String] = ["email": self.email]
        do {
            let data = try NSJSONSerialization.dataWithJSONObject(postData, options: NSJSONWritingOptions(rawValue: 0))
            let connection = NetworkConnection(url: url, postBody: data)
            connection.downloadJSONFromURL({ (returnData) in
                print("Reconstruct Project: \(returnData).")
            })
        } catch {
            print("[Reconstruct Projects from Cloud] Could not create JSON object - \(error).")
        }
    }
    
    // MARK: - Data Reporting Logic
    
    func createDataObjectForReportedData(projectTitle: String, reportedData: [String: AnyObject], groupType: String) { //for data reporting
        print("Creating dataObject for reported data...")
        
        var dataObject = Dictionary<String, AnyObject>()
        dataObject.updateValue(email, forKey: "BMN_EMAIL") //pass email
        dataObject.updateValue(projectTitle, forKey: "BMN_PROJECT_TITLE") //pass project title
        dataObject.updateValue(reportedData, forKey: "BMN_DATABASE_OBJECT") //pass data object
        dataObject.updateValue(groupType, forKey: "BMN_GROUP_TYPE") //pass groupType
        let _ = DatabaseObject(data: dataObject, dataType: .ReportedData, insertIntoManagedObjectContext: managedObjectContext) //hold data in CD store until it is pushed
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
                    switch (error!.code) {
                    case -1009:
                        print("[postObjToDB] No internet access was detected.")
                        self.reportAccessErrorForService(.Internet)
                    case -1004:
                        print("[postObjToDB] Error - could not connect to SERVER!")
                        self.reportAccessErrorForService(.Localhost)
                    default:
                        print("[postObjToDB] Process failed w/ error: \(error).")
                    }
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
    
    func reportAccessErrorForService(service: ServiceTypes) { //throw alert to connect to internet
        let notification = NSNotification(name: BMN_Notification_DataReportingErrorProtocol_ServiceDidReportError, object: nil, userInfo: [BMN_DataReportingErrorProtocol_ServiceTypeKey: service.rawValue])
        NSNotificationCenter.defaultCenter().postNotification(notification)
    }
    
}