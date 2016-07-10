//  DatabaseConnection.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 6/29/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Handles construction of the POST request to create a dataObject to send to the DB.

import Foundation

class DatabaseConnection: DataReportingErrorProtocol {
    
    private var databaseQueue: [Dictionary<String, AnyObject>] //data queue
    private var managedObjectReferences: [DatabaseObject]? //maintains reference to CD items for deletion
    lazy var config: NSURLSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
    lazy var session: NSURLSession = NSURLSession(configuration: self.config)
    
    // MARK: - Initializers
    
    init(objectToDatabase: Dictionary<String, [String: AnyObject]>, projectTitle: String, groupType: String) { //push specified object to DB
        var temp = Dictionary<String, AnyObject>()
        if let email = NSUserDefaults.standardUserDefaults().stringForKey(EMAIL_KEY) {
            print("\n[DatabaseConnection init()] Email is '\(email)'.")
            temp.updateValue(email, forKey: "BMN_EMAIL") //pass email
            temp.updateValue(projectTitle, forKey: "BMN_PROJECT_TITLE") //pass project title
            temp.updateValue(objectToDatabase, forKey: "BMN_DATABASE_OBJECT") //pass data object
            temp.updateValue(groupType, forKey: "BMN_GROUP_TYPE") //pass groupType
        }
        self.databaseQueue = [temp]
    }
    
    init() { //push CoreData objects en masse to DB
        var tempQueue: [Dictionary<String, AnyObject>] = []
        if let queue = fetchObjectsFromCoreDataStore("DatabaseObject", filterProperty: nil, filterValue: nil) as? [DatabaseObject] { //fetch all objects in store
            if let email = NSUserDefaults.standardUserDefaults().stringForKey(EMAIL_KEY) {
                print("\n[DatabaseConnection init()] Email is '\(email)'.")
                managedObjectReferences = [] //initialize
                for object in queue { //construct final DB object for each item in queue
                    var temp = Dictionary<String, AnyObject>() //initialize dict
                    temp.updateValue(email, forKey: "BMN_EMAIL") //pass email
                    temp.updateValue(object.projectTitle, forKey: "BMN_PROJECT_TITLE") //project title
                    temp.updateValue(object.dataDictionary, forKey: "BMN_DATABASE_OBJECT") //pass data
                    temp.updateValue(object.groupType, forKey: "BMN_GROUP_TYPE") //pass groupType
                    tempQueue.append(temp)
                    managedObjectReferences!.append(object) //store reference to object (for deletion)
                }
            }
        }
        self.databaseQueue = tempQueue
    }
    
    // MARK: - Network Interaction
    
    func transmitDataToDatabase(count: Int?) { //posts dataObjects in CD to database 1 by 1
        if let firstObject = self.databaseQueue.first { //grab 1st item in queue
            let counter: Int
            if (count != nil) {
                counter = count!
                print("\nTransmitting object #\(count!) in queue...")
            } else { //nil => 1st function call
                counter = 1
                print("\nTransmitting 1st object in queue...")
            }
            
            self.postDataObjectToDatabase(firstObject, success: { (completed) in
                if (completed) { //the operation succeeded - push next function to store
                    self.databaseQueue.removeFirst() //drop 1st object
                    if let objectReference = self.managedObjectReferences?.first { //managed references are only for multi-push (not single object push)
                        deleteManagedObject(objectReference) //remove object from core data store
                        self.managedObjectReferences?.removeFirst() //remove reference
                        self.transmitDataToDatabase((counter + 1)) //call function recursively
                    }
                } else { //the operation failed - terminate function
                    print("[transmitDataToDB()] Operation failed! Terminating process...")
                }
            })
        } else { //no items remaining in queue
            print("no items left")
            if (count == nil) { //initial function call
                print("There are no objects in the database queue!")
            } else {
                print("All objects in queue were successfully pushed to DB!")
                let notification = NSNotification(name: BMN_Notification_DatabaseConnection_DataTransmissionStatusDidChange, object: nil, userInfo: [BMN_DatabaseConnection_TransmissionStatusKey: true])
                NSNotificationCenter.defaultCenter().postNotification(notification)
            }
        }
    }
    
    private func postDataObjectToDatabase(object: [String: AnyObject], success: (Bool) -> Void) {
        print("Posting object to database...")
        do {
            let jsonData = try NSJSONSerialization.dataWithJSONObject(object, options: NSJSONWritingOptions(rawValue: 0))
            
            //Create POST request: ipconfig getifaddr en1; python3 manage.py runserver 192.168.1.?:8000
            let url = NSURL(string: "http://192.168.1.10:8000/")! //**
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