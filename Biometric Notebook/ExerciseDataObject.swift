//  ExerciseDataObject.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 12/28/15.
//  Copyright © 2015 Confluent Ideals. All rights reserved.

// Data object containing captured exercise information going -> DB. Needs to persist w/ CoreData.

import Foundation

class ExerciseDataObject {
    private let flow: Int //0 = before-sleep flow, 1 = after-waking flow
    private let date: String
    private let time: String //string or numerical value for calculations (e.g. hours slept)?
    private var exerciseDictionary: [String: AnyObject] //combined json dict -> DB
    
    init(flow: Int, date: String, time: String) { //initialize w/ flow # & date/time
        //Create the exerciseData object @ start of workout. Then after workout is complete, store the final bits of data to the object before pushing the entire dict -> DB in 1 go.
        self.flow = flow
        self.date = date
        self.time = time
        exerciseDictionary = ["flow": self.flow, "date": self.date, "time": self.time]
    }
    
    func recordBeforeWorkoutUserResponses(breathing: String, digestion: String, temperature: String) { //pre-workout data
        exerciseDictionary["breathing"] = breathing
        exerciseDictionary["digestion"] = digestion
        exerciseDictionary["temperature"] = temperature
    }
    
    func recordAfterWorkoutUserResponses(exerciseQuality: String) { //after-workout data
        exerciseDictionary["exerciseQuality"] = exerciseQuality
    }
    
    func getJSONDictionaryWithExerciseDate() -> [String: AnyObject] {
        for item in exerciseDictionary {
            print(item)
        }
        return exerciseDictionary
    }
}
