//  SleepDataObject.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 12/27/15.
//  Copyright © 2015 Confluent Ideals. All rights reserved.

// Data object containing captured sleep information going -> DB

import Foundation

class SleepDataObject {
    private let flow: Int //0 = before-sleep flow, 1 = after-waking flow
    private let date: String
    private let time: String //string or numerical value for calculations (e.g. hours slept)?
    private var sleepDictionary: [String: AnyObject] //combined json dict -> DB
    
    init(flow: Int, date: String, time: String) { //initialize w/ flow # & date/time
        self.flow = flow
        self.date = date
        self.time = time
        sleepDictionary = ["flow": self.flow, "date": self.date, "time": self.time]
    }
    
    func recordBeforeSleepUserResponses(meditation: String, bathroom: String) { //records data from flow 0
        sleepDictionary["meditation"] = meditation
        sleepDictionary["bathroom"] = bathroom
    }
    
    func recordAfterWakingUserResponses(mentalState: String, wakeReason: String, temperature: String, weather: String, shadesDown: String) { //records data from flow 1
        sleepDictionary["mentalState"] = mentalState
        sleepDictionary["wakeReason"] = wakeReason
        sleepDictionary["temperature"] = temperature
        sleepDictionary["weather"] = weather
        sleepDictionary["shadesDown"] = shadesDown
    }
    
    func getJSONDictionaryWithSleepDate() -> [String: AnyObject] {
        for item in sleepDictionary {
            print(item)
        }
        return sleepDictionary
    }
}
