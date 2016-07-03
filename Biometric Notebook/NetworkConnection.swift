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
    let queryURL: NSURL
    
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
    }
    
    // MARK: - Networking Logic
    
    typealias JSONDictionaryCompletion = ([String: AnyObject]?) -> Void //closure typeAlias
    
    func downloadJSONFromURL(completion: JSONDictionaryCompletion) {
        let request: NSURLRequest = NSURLRequest(URL: queryURL)
        print("Downloading JSON From URL...")
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
                print("Error: not a valid HTTP response (no internet connection).")
                self.reportAccessErrorForService(.Internet)
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