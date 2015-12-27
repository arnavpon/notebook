//  ReturnedDataObject.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 12/27/15.
//  Copyright © 2015 Confluent Ideals. All rights reserved.

//This data object will be populated AFTER the app sends request -> server -> & obtains JSON data as a response. Once we receive JSON, we will break it down into a custom dictionary object - we know what parameters could possibly be returned & create a dictionary entry for each potential parameter.

import Foundation

struct ReturnedDataObject {
    let patientID: Int? //get back patientID after creating new patient
    let totalCount : Int?
    let practiceInfo : [[String : String]]?
    let departments : [[String : AnyObject]]?
    
    init(emrDataDictionary : [String: AnyObject]) { //Make sure to use conditional chaining b/c we don't know what pieces of info will be returned when
        self.patientID = emrDataDictionary["patientID"] as? Int
        
        self.totalCount = emrDataDictionary["totalcount"] as? Int
        self.practiceInfo = emrDataDictionary["practiceinfo"] as? [[String : String]]
        self.departments = emrDataDictionary["departments"] as? [[String : AnyObject]]
    }
}