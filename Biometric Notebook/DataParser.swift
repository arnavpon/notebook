//  DataParser.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 12/27/15.
//  Copyright © 2015 Confluent Ideals. All rights reserved.

// Handle the response/data returned by the DB (through the web server) in response to the HTTP request.

import Foundation

struct DataParser {
    let jsonDict: Dictionary<String, AnyObject>?
    let openScope: EMRField?
    let useOtherInit: Bool
    
    init(openScope: EMRField) {//initialize struct by inputting the URL for our web server & the current fieldName - we then pass the data entered into each field as a JSON object.
        self.openScope = openScope
        self.useOtherInit = false
        self.jsonDict = nil
    }
    
    init(patientDict: Dictionary<String, AnyObject>) { //different init when we are creating a new patient (no openScope to use here)
        self.useOtherInit = true
        self.openScope = nil
        self.jsonDict = patientDict
    }
    
    func ParseJSON(completion : (EMRReturnedDataObject? -> Void)) {
        if (useOtherInit == true) {
            let emrConnection = EMRConnection(patientDict: self.jsonDict!)
            emrConnection.downloadJSONFromURL {
                (let JSONDictionary) in
                print("JSONDictionary Contents: \(JSONDictionary)")
                let returnedData = self.returnedDataFromJSON(JSONDictionary) //retrieve the parsed dict
                completion(returnedData) //present this dict to the user as a completion
            }
        } else {
            let emrConnection = EMRConnection(openScope: self.openScope!)
            emrConnection.downloadJSONFromURL {
                (let JSONDictionary) in
                print("JSONDictionary Contents: \(JSONDictionary)")
                let returnedData = self.returnedDataFromJSON(JSONDictionary) //retrieve the parsed dict
                completion(returnedData) //present this dict to the user as a completion
            }
        }
    }
    
    func returnedDataFromJSON(jsonDictionary : [String : AnyObject]?) -> EMRReturnedDataObject? {
        //This function takes a JSONDict as an input [w/ String Key : AnyObject Value] & returns a dictionary object. The initializer of the 'ReturnedDataObject' will break apart the dictionary and assign each value for a key to a variable in the app.
        if let returnedEMRData = jsonDictionary {
            return EMRReturnedDataObject(emrDataDictionary: returnedEMRData)
        } else {
            print("JSON dictionary returned nil.")
            return nil
        }
    }
    
}