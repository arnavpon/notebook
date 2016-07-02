//  DatabaseConnection.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 6/29/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Handles construction of the POST request to create a dataObject to send to the DB.

import Foundation

class DatabaseConnection: DataReportingErrorProtocol {
    
    let dataObject: Dictionary<String, AnyObject>
    lazy var config: NSURLSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
    lazy var session: NSURLSession = NSURLSession(configuration: self.config)
    
    // MARK: - Initializers
    
    init(objectToDatabase: Dictionary<String, [String: AnyObject]>, projectTitle: String) {
        var temp = Dictionary<String, AnyObject>()
        if let username = NSUserDefaults.standardUserDefaults().stringForKey(USERNAME_KEY) {
            print("[DatabaseConnection init()] Username is '\(username)'.")
            temp.updateValue(username, forKey: "BMN_USERNAME") //pass username
            temp.updateValue(projectTitle, forKey: "BMN_PROJECT_TITLE") //pass project title
            temp.updateValue(objectToDatabase, forKey: "BMN_DATABASE_OBJECT") //pass data object
        }
        self.dataObject = temp
    }
    
    // MARK: - Network Interaction
    
    func postObjectToDatabase() {
        do {
            let jsonData = try NSJSONSerialization.dataWithJSONObject(dataObject, options: NSJSONWritingOptions(rawValue: 0))
            
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
                                case "001":
                                    print("[\(responseAsText)] Operation was completed successfully!")
                                default:
                                    print("Operation was not completed successfully!")
                                }
                            }
                        default:
                            print("Default in switch! Code: \(httpResponse.statusCode).")
                        }
                    }
                } else {
                    print("Returned Error: \(error).")
                    return
                }
            })
            task.resume()
        } catch {
            print(error)
        }
    }
    
    // MARK: - Error Handling
    
    func reportAccessErrorForService() {
        //need internet connection to interact w/ DB
    }
    
}