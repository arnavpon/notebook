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
    
    init(objectToDatabase: Dictionary<String, [String: AnyObject]>, projectTitle: String) { //push specified object to DB
        var temp = Dictionary<String, AnyObject>()
        if let username = NSUserDefaults.standardUserDefaults().stringForKey(USERNAME_KEY) {
            print("\n[DatabaseConnection init()] Username is '\(username)'.")
            temp.updateValue(username, forKey: "BMN_USERNAME") //pass username
            temp.updateValue(projectTitle, forKey: "BMN_PROJECT_TITLE") //pass project title
            temp.updateValue(objectToDatabase, forKey: "BMN_DATABASE_OBJECT") //pass data object
        }
        self.databaseQueue = [temp]
    }
    
    init() { //push CoreData objects en masse to DB
        var tempQueue: [Dictionary<String, AnyObject>] = []
        if let queue = fetchObjectsFromCoreDataStore("DatabaseObject", filterProperty: nil, filterValue: nil) as? [DatabaseObject] { //fetch all objects in store
            if let username = NSUserDefaults.standardUserDefaults().stringForKey(USERNAME_KEY) {
                print("\n[DatabaseConnection init()] Username is '\(username)'.")
                managedObjectReferences = [] //initialize
                for object in queue { //construct final DB object for each item in queue
                    var temp = Dictionary<String, AnyObject>() //initialize dict
                    temp.updateValue(username, forKey: "BMN_USERNAME") //pass username
                    temp.updateValue(object.projectTitle, forKey: "BMN_PROJECT_TITLE") //project title
                    temp.updateValue(object.dataDictionary, forKey: "BMN_DATABASE_OBJECT") //pass data
                    tempQueue.append(temp)
                    managedObjectReferences!.append(object) //store reference to object (for deletion)
                }
            }
        }
        self.databaseQueue = tempQueue
    }
    
    // MARK: - Network Interaction
    
    func transmitDataToDatabase(count: Int) {
        //Make sure internet is available & that connection to localhost can be made:
        self.serverIsAvailable { (isAvailable) in
            if (isAvailable) { //post dataObjects 1 by 1 & (if successful) remove from CoreData store
                if let firstObject = self.databaseQueue.first {
                    print("Transmitting object #\(count)...")
                    self.postDataObjectToDatabase(firstObject, success: { (completed) in
                        if (completed) { //the operation succeeded - push next function to store
                            self.databaseQueue.removeFirst() //drop 1st object
                            if let objectReference = self.managedObjectReferences?.first {
                                deleteManagedObject(objectReference) //remove object from core data store
                                print("[transmitData] References Before: \(self.managedObjectReferences?.count).")
                                self.managedObjectReferences?.removeFirst() //remove reference
                                print("[transmitData] References After: \(self.managedObjectReferences?.count).")
                                fetchObjectsFromCoreDataStore("DatabaseObject", filterProperty: nil, filterValue: nil) //**check success
                            }
                            self.transmitDataToDatabase((count + 1)) //call function recursively
                        } else { //the operation failed - terminate function
                            print("Operation failed! Terminating process...")
                            return
                        }
                    })
                } else {
                    print("All objects have been successfully pushed to store!")
                }
            }
        }
    }
    
    private func serverIsAvailable(completion: (Bool) -> Void) { //checks if local server is available
        print("\nEstablishing connection to localhost...")
        let url = NSURL(string: "http://192.168.1.2:8000/check_connection")!
        let request = NSURLRequest(URL: url)
        let task = session.dataTaskWithRequest(request, completionHandler: { (data, response, error) in
            if (error == nil) {
                if let httpResponse = response as? NSHTTPURLResponse {
                    switch httpResponse.statusCode {
                    case 200:
                        completion(true)
                    default:
                        print("HTTP Response: \(httpResponse.statusCode).")
                        completion(false)
                    }
                }
            } else {
                print("Connection could not be established!\n Error - [\(error).]")
                completion(false)
            }
        })
        task.resume()
    }
    
    private func postDataObjectToDatabase(object: [String: AnyObject], success: (Bool) -> Void) {
        print("Posting object to database...")
        do {
            let jsonData = try NSJSONSerialization.dataWithJSONObject(object, options: NSJSONWritingOptions(rawValue: 0))
            
            //Create POST request: //python3 manage.py runserver 192.168.1.2:8000
            let url = NSURL(string: "http://192.168.1.2:8000/")!
            let request = NSMutableURLRequest(URL: url)
            request.HTTPMethod = "POST"
            
            //Insert JSON data into the request BODY:
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            request.HTTPBody = jsonData
            
            let task = session.dataTaskWithRequest(request, completionHandler: { (data, response, error) in
                if (error == nil) {
                    if let httpResponse = response as? NSHTTPURLResponse {
                        switch httpResponse.statusCode {
                        case 200:
                            if let responseData = data, responseAsText = NSString(data: responseData, encoding: NSUTF8StringEncoding) {
                                print("URL Response: [\(responseAsText)].")
                                switch responseAsText {
                                case "000":
                                    print("[\(responseAsText)] Operation completed with error!")
                                    success(false)
                                case "001":
                                    print("[\(responseAsText)] Operation was completed successfully!")
                                    success(true)
                                default:
                                    print("Operation was not completed successfully!")
                                    success(false)
                                }
                            }
                        default:
                            print("Default in switch! Code: \(httpResponse.statusCode).")
                            success(false)
                        }
                    }
                } else {
                    print("Returned Error: \(error).")
                    success(false)
                }
            })
            task.resume()
        } catch {
            print(error)
            success(false)
        }
    }
    
    // MARK: - Error Handling
    
    func reportAccessErrorForService() {
        //need internet connection to interact w/ DB
    }
    
}