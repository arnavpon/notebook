//  NetworkConnection.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 12/27/15.
//  Copyright © 2015 Confluent Ideals. All rights reserved.

// GENERIC class responsible for creating a network connection & downloading JSON data from a specified URL.

import Foundation

class NetworkConnection {
    
    lazy var config: NSURLSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
    lazy var session: NSURLSession = NSURLSession(configuration: self.config)
    let queryURL: NSURL
    
    init(url: NSURL) { //initialize w/ the URL to which the network request is being sent
        self.queryURL = url
    }
    
    typealias JSONDictionaryCompletion = ([String: AnyObject]?) -> Void //closure typeAlias
    
    func downloadJSONFromURL(completion: JSONDictionaryCompletion) {
        let request: NSURLRequest = NSURLRequest(URL: queryURL)
        
        let dataTask = session.dataTaskWithRequest(request) { (let data, let response, let error) in
            if let httpResponse = response as? NSHTTPURLResponse {
                switch httpResponse.statusCode {
                case 200: //successful response
                    do {
                        if let receivedData = data { //serialize JSON object into a dictionary
                            let jsonDictionary = try NSJSONSerialization.JSONObjectWithData(receivedData, options: NSJSONReadingOptions(rawValue: 0)) as? [String: AnyObject]
                            completion(jsonDictionary)
                        }
                    } catch {
                        print("Error")
                    }
                default:
                    print("Get request not successful. HTTP status code: \(httpResponse.statusCode)")
                }
            } else {
                print("Error: not a valid HTTP response")
            }
        }
        dataTask.resume() //begin task
    }
    
}