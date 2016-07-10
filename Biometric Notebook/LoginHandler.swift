//  LoginHandler.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 7/9/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Handles all username/password logic - creation of new user, password authentication, hashing? Designed to be extensible so as to apply to any project by simply changing the inputs.

import Foundation

enum LoginFailureTypes {
    case DuplicateEmail
    case UnknownEmail
    case IncorrectPassword
}

class LoginHandler: DataReportingErrorProtocol {
    
    private var email: String
    private var password: String
    private var url: NSURL
    lazy var config: NSURLSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
    lazy var session: NSURLSession = NSURLSession(configuration: self.config)
    
    // MARK: - Initializers
    
    init(email: String, password: String, url: String) {
        self.email = email
        self.password = password
        self.url = NSURL(string: url)!
    }
    
    // MARK: - Email Formatter
    
    class func checkEmailFormat(email: String) -> Bool { //check email format w/ RegEx
        let length = (email as NSString).length
        let fullRange = NSRange.init(location: 0, length: length)
        do {
            let expression = try NSRegularExpression(pattern: "^.+@.+\\.[a-zA-Z]{3}$", options: NSRegularExpressionOptions.AnchorsMatchLines)
            let match = expression.numberOfMatchesInString(email, options: NSMatchingOptions(rawValue: 0), range: fullRange)
            if (match == 1) {
                return true
            }
        } catch {
            print("Error - could not create regex! Message = \(error).")
        }
        return false
    }
    
    // MARK: - Network Interaction
    
    func createNewUser(success: (Bool, LoginFailureTypes?) -> Void) { //attempts to create new user
        print("Creating new user...")
        postAuthenticationObjectToDatabase { (response) in
            switch response {
            case "000": //unknown server error
                print("ERROR - unknown error.")
                success(false, nil)
            case "001": //username already exists
                print("ERROR - username already exists!")
                success(false, .DuplicateEmail)
            case "010": //successful insertion
                print("User was successfully created!")
                success(true, nil)
            default: //failure
                print("[createNewUser] Error - default in switch!")
                success(false, nil)
            }
        }
    }
    
    func authenticateUser(success: (Bool, LoginFailureTypes?) -> Void) { //checks if username & password match
        print("Authenticating user...")
        postAuthenticationObjectToDatabase { (response) in
            switch response {
            case "000":
                print("Process failed with unknown error")
                success(false, nil)
            case "001": //email was NOT found in DB
                print("Error - email was not found")
                success(false, .UnknownEmail)
            case "002": //email & pwd do NOT match
                print("Error - email & password do not match")
                success(false, .IncorrectPassword)
            case "010": //successful match
                print("Email & password match!")
                success(true, nil)
            default: //failure
                print("[authenticateUser] Error - default in switch!")
                success(false, nil)
            }
        }
    }

    private func postAuthenticationObjectToDatabase(serverResponse: (String) -> Void) {
        print("Posting object to database...")
        let authenticationObject: [String: String] = ["email": self.email, "password": self.password]
        do {
            let jsonData = try NSJSONSerialization.dataWithJSONObject(authenticationObject, options: NSJSONWritingOptions(rawValue: 0))
            
            //Create POST request: //python3 manage.py runserver 192.168.1.2:8000
            let request = NSMutableURLRequest(URL: url)
            request.HTTPMethod = "POST"
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            request.HTTPBody = jsonData
            
            let task = session.dataTaskWithRequest(request, completionHandler: { (data, response, error) in
                if (error == nil) { //no process error
                    if let httpResponse = response as? NSHTTPURLResponse {
                        switch httpResponse.statusCode {
                        case 200:
                            if let responseData = data, responseAsText = NSString(data: responseData, encoding: NSUTF8StringEncoding) {
                                print("[postObjToDB] URL Response: [\(responseAsText)].")
                                serverResponse(responseAsText as String)
                            }
                        default:
                            print("[postObjToDB] Default in switch! Code: \(httpResponse.statusCode).")
                            serverResponse("-000") //- indicates general (not server) failure object
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
                    serverResponse("-000") //- indicates general (i.e. not server) failure object
                }
            })
            task.resume()
        } catch {
            print("[postObjToDB] Exception - \(error)")
            serverResponse("-000") //- indicates general failure object
        }
    }
    
    // MARK: - Error Handling
    
    func reportAccessErrorForService(service: ServiceTypes) { //throw alert to connect to internet
        let notification = NSNotification(name: BMN_Notification_DataReportingErrorProtocol_ServiceDidReportError, object: nil, userInfo: [BMN_DataReportingErrorProtocol_ServiceTypeKey: service.rawValue])
        NSNotificationCenter.defaultCenter().postNotification(notification)
    }
    
}