//  SleepDataObject.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 12/27/15.
//  Copyright © 2015 Confluent Ideals. All rights reserved.

// Data object containing captured sleep information going -> DB

import Foundation

class SleepDataObject {
    private let date: String
    private let time: String //string or numerical value for calculation?
    private let sleepDictionary: [String: AnyObject] //combined json dict -> DB
    
    init() { //note: this object will be filled @ different times w/ different pieces of data
        date = ""
        time = ""
        sleepDictionary = ["date": date, "time": time]
    }
    
    func getJSONDictionaryWithSleepDate() -> [String: AnyObject] {
        return sleepDictionary
    }
}
