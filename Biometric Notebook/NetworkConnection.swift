//  NetworkConnection.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 12/27/15.
//  Copyright © 2015 Confluent Ideals. All rights reserved.

// GENERIC class responsible for creating a network connection & downloading JSON data from a specified URL.

import Foundation
import SystemConfiguration

class NetworkConnection: DataReportingErrorProtocol { //conforms to error reporting protocol
    
    lazy var config: NSURLSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
    lazy var session: NSURLSession = NSURLSession(configuration: self.config)
    private let queryURL: NSURL
    private let postBody: NSData? //optional POST request body
    
    // MARK: - Network Connectivity [CLASS METHOD]
    
    class func deviceIsConnectedToNetwork() -> Bool { //checks if Wifi is available; **does not work for 4G or 3G apparently!
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(sizeofValue(zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        let defaultRouteReachability = withUnsafePointer(&zeroAddress) {
            SCNetworkReachabilityCreateWithAddress(nil, UnsafePointer($0))
        }
        var flags = SCNetworkReachabilityFlags()
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
            return false
        }
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        return (isReachable && !needsConnection)
    }
    
    // MARK: - Initializers
    
    init(url: NSURL) { //initialize w/ the URL to which the network request is being sent
        self.queryURL = url
        self.postBody = nil
    }
    
    init(url: NSURL, postBody: NSData) { //POST request initializer
        self.queryURL = url
        self.postBody = postBody
    }
    
    // MARK: - Networking Logic
    
    typealias JSONDictionaryCompletion = ([String: AnyObject]?) -> Void //closure typeAlias
    
    func downloadJSONFromURL(completion: JSONDictionaryCompletion) {
        print("Downloading JSON From URL...")
        let request = NSMutableURLRequest(URL: queryURL)
        if let _ = postBody { //check if request contains JSON data to POST
            request.HTTPMethod = "POST"
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            request.HTTPBody = postBody
        }
        let dataTask = session.dataTaskWithRequest(request) { (let data, let response, let error) in
            if let httpResponse = response as? NSHTTPURLResponse {
                switch httpResponse.statusCode {
                case 200: //successful response
                    print("HTTP Response 200")
                    do {
                        if let receivedData = data { //serialize JSON object into a dictionary
                            let jsonDictionary = try NSJSONSerialization.JSONObjectWithData(receivedData, options: NSJSONReadingOptions(rawValue: 0)) as? [String: AnyObject]
                            completion(jsonDictionary)
                        }
                    } catch {
                        print("Error - could not serialize JSON")
                    }
                default:
                    print("Get request not successful. HTTP status code: \(httpResponse.statusCode)")
                    self.reportAccessErrorForService(.Internet) //throw error
                }
            } else {
                switch (error!.code) {
                case -1009:
                    print("[downloadJSON] No internet access was detected.")
                    self.reportAccessErrorForService(.Internet)
                case -1004:
                    print("[downloadJSON] Error - could not connect to SERVER!")
                    self.reportAccessErrorForService(.Localhost)
                default:
                    print("[downloadJSON] Process failed w/ error: \(error).")
                }
            }
        }
        dataTask.resume() //begin task
    }
    
    // MARK: - Error Handling
    
    func reportAccessErrorForService(service: ServiceTypes) { //fire notification for VC
        let notification = NSNotification(name: BMN_Notification_DataReportingErrorProtocol_ServiceDidReportError, object: nil, userInfo: [BMN_DataReportingErrorProtocol_ServiceTypeKey: service.rawValue])
        NSNotificationCenter.defaultCenter().postNotification(notification)
    }
    
}