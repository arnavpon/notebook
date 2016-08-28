//  ExM_ExerciseDataStream.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 8/24/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Exercise Module > defines behaviors for the exercise data stream that enables the input of workout-related data.
// *temporaryStorageObject = ["CurrentExerciseKey": [exercise: "", type: "", numberOfSets: ""], "ReportedDataKey": [[Exercise_1: [[ENTRY_1: AnyObject, TIMESTAMP_1: String], [ENTRY_2: AnyObject, TIMESTAMP_2: String]]], [Exercise_2: [ENTRY_1: AnyObject, TIMESTAMP_1: String], ...], ...]]*
// WeightTraining exercises - store the weight lifted + # of reps + timestamp
// Cardio exercises - store the time + distance + calories + timestamp

import UIKit
import CoreData

class ExM_ExerciseDataStream: Datastream {
    
    //ExV - during configuration, ask the user to pick from a set of custom ComparisonOptions for workouts - to track strength gain, correlate with intake, etc.? Or should the system just intuit what is to be analyzed? Intuit may be better b/c we cannot control the other variables added into the project with the workout.
    
    // MARK: - Singleton Definition
    
    static let sharedInstance: ExM_ExerciseDataStream = {
        let instance: ExM_ExerciseDataStream
        let context = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
        let existingInstances = fetchObjectsFromCoreDataStore("Datastream", filterProperty: "streamID", filterValue: [DatastreamIdentifiers.ExM_Workout.rawValue]) as! [Datastream] //fetch instances
        if (existingInstances.isEmpty) { //NO instance exists yet (1st run) - create it
            instance = ExM_ExerciseDataStream(streamID: DatastreamIdentifiers.ExM_Workout.rawValue, insertIntoManagedObjectContext: context)
            let id = instance.objectID.description
            print("Shared Instance ID = [\(id)]")
        } else if (existingInstances.count == 1) { //single sharedInstance exists
            if let exerciseDataStream = existingInstances.first as? ExM_ExerciseDataStream {
                instance = exerciseDataStream
                let id = instance.objectID.description
                print("Shared Instance ID = [\(id)]")
            } else {
                print("[ExM_ExerciseDataStream sharedInstance] Fatal Error!")
                abort()
            }
        } else { //fatal error, more than 1 instance
            print("[ExM_ExerciseDataStream sharedInstance] Fatal Error! > 1 instance found in store!")
            abort()
        }
        return instance
    }()
    
    // MARK: - Stream Interaction
    
    func setCurrentlyOpenExerciseInStream(exercise: String, type: ExerciseTypes, numberOfSets: Int) { //adds newly created exercise metadata -> stream
        if (self.temporaryStorageObject == nil) { //object does NOT exist yet
            self.temporaryStorageObject = [:] //initialize
        }
        self.temporaryStorageObject!.updateValue(["exercise": exercise, "exerciseType": type.rawValue, "numberOfSets": numberOfSets], forKey: BMN_ExM_CurrentExerciseKey)
        saveManagedObjectContext() //save -> store
    }
    
    func writeExerciseDataToDatastream(exercise: String, currentSet: Int, totalNumberOfSets: Int, data: [String : AnyObject]) { //adds the most recently entered exercise's data -> the datastream
        if let temp = self.temporaryStorageObject {
            let timeStamp = DateTime().getFullTimeStamp() //make new timestamp
            var newData = data //grab reported data
            newData.updateValue(timeStamp, forKey: "timestamp") //add timestamp -> input data
            if (currentSet == 1) { //entry does NOT exist in reportedData yet for CURRENT exercise
                let newEntry: [String: AnyObject] = [exercise: [newData]] //construct 1st entry
                if let reportedDataArray = temp[BMN_ExM_ReportedDataKey] as? [[String: AnyObject]] { //existing data is present for 'reportedData' key - UPDATE
                    var updatedDataArray = reportedDataArray //grab existing objects in reportedData
                    updatedDataArray.append(newEntry) //ADD newest entry -> END of array
                    self.temporaryStorageObject!.updateValue(updatedDataArray, forKey: BMN_ExM_ReportedDataKey) //update dict KEY
                } else { //reportedData does NOT exist - INITIALIZE w/ current exercise data
                    self.temporaryStorageObject!.updateValue([newEntry], forKey: BMN_ExM_ReportedDataKey) //add newest entry -> reportedData key
                }
            } else { //set > 1 => entry MUST already exist - update array w/ newest data
                if let reportedData = temp[BMN_ExM_ReportedDataKey] as? [[String: AnyObject]], lastItem = reportedData.last, existingArray = lastItem[exercise] as? [[String: AnyObject]] {
                    var updatedArray = existingArray //grab existing values
                    updatedArray.append(newData) //add most recent data -> end of array
                    var updatedExercise = lastItem //get LAST array for current exercise
                    updatedExercise.updateValue(updatedArray, forKey: exercise) //modify data for exercise
                    var updatedReportData = reportedData //grab full array of dictionaries
                    updatedReportData[(reportedData.count - 1)] = updatedExercise //modify the LAST item in 'reportedData'
                    self.temporaryStorageObject!.updateValue(updatedReportData, forKey: BMN_ExM_ReportedDataKey) //update TSO
                }
            }
            if (currentSet == totalNumberOfSets) { //LAST set for exercise - CLOSE current exercise
                self.temporaryStorageObject!.removeValueForKey(BMN_ExM_CurrentExerciseKey) //remove item
            }
            print("\n[writeToStream] UPDATED TSO = {\(self.temporaryStorageObject)}\n")
            saveManagedObjectContext() //save TSO for new data
        }
    }
    
    func getCurrentExerciseFromDatastream() -> (String, ExerciseTypes, (Int, Int))? { //called by ExV TV cell - checks datastream for info about CURRENTLY OPEN exercise & returns (Ex_Name, Ex_Type, (TOTAL # Sets, CURRENT Set #)])
        if let temp = self.temporaryStorageObject, currentExerciseDict = temp[BMN_ExM_CurrentExerciseKey] as? [String: AnyObject] {
            if let exercise = currentExerciseDict["exercise"] as? String, typeRaw = currentExerciseDict["exerciseType"] as? Int, type = ExerciseTypes(rawValue: typeRaw), numberOfSets = currentExerciseDict["numberOfSets"] as? Int {
                if let reportedData = temp[BMN_ExM_ReportedDataKey] as? [[String: AnyObject]], lastItem = reportedData.last, values = lastItem[exercise] as? [[String: AnyObject]] { //check LAST (most recent) ITEM in reportedData for current set #
                    return (exercise, type, (numberOfSets, (values.count + 1))) //current set # = # of entries in 'values' dict + 1
                }
                return (exercise, type, (numberOfSets, 1)) //default -> 1st set if NO data value is found
            }
        }
        return nil //default return value - indicates NO OPEN EXERCISE
    }
    
    func closeCurrentDatastream() -> AnyObject? { //ONLY called if there are NO remaining sets for the current exercise; returns the FULL reportedData ARRAY of DICTs
        print("\nClosing current datastream...")
        print("ORIGINAL CACHE = {\(self.cachedData)}")
        if let temp = self.temporaryStorageObject, reportedData = temp[BMN_ExM_ReportedDataKey] { //cache reportedData values -> CoreData object
            if (self.cachedData == nil) { //NO cached objects
                self.cachedData = [:] //initialize
            }
            let count = self.cachedData!.count
            if (count >= 3) { //cached limit has been exceeded - clear most recent cached obj
                print("Cache is @ maximum capacity! Removing earliest workout...")
                var minimum: Double? = nil //keeps track of EARLIEST date
                for (date, _) in self.cachedData! {
                    print("DATE = [\(DateTime(date: date).getFullTimeStamp())]")
                    if (minimum == nil) {
                        print("NEW MINIMUM!")
                        minimum = date.timeIntervalSinceReferenceDate //initialize
                    }
                    if (date.timeIntervalSinceReferenceDate < minimum) { //NEW minimum
                        print("NEW MINIMUM!")
                        minimum = date.timeIntervalSinceReferenceDate
                    }
                }
                if let min = minimum { //drop the earliest workout from the cache
                    let dateToRemove = NSDate(timeIntervalSinceReferenceDate: min) //recreate NSDate
                    self.cachedData!.removeValueForKey(dateToRemove) //remove from cache
                    print("Dropped Workout [\(DateTime(date: dateToRemove).getFullTimeStamp())] from cache!")
                }
            }
            let timestamp = NSDate() //to ID workouts - must be stored as NSDate for comparisons!
            self.cachedData!.updateValue(reportedData, forKey: timestamp) //cache newest workout
            self.temporaryStorageObject = nil //clear TSO after caching
            saveManagedObjectContext() //save cache & TSO
            print("UPDATED CACHE = {\(self.cachedData)}")
            return reportedData //send reportedData -> TV cell for aggregation
        }
        return nil
    }
    
    // MARK: Protocol Logic
    
    private var currentStreamVariable: Module? //currently reporting stream variable
    
    override func getVariablesForSelectedGroup(selection: Int?) -> [Module]? { //return 1 dummy variable
        let workoutVariable = ExerciseModule() //use Datastream initializer
        self.currentStreamVariable = workoutVariable
        return [workoutVariable]
    }
    
    override func constructDataObjectForReportedData() { //called when user hits 'Done' btn in Datastream report mode - forces the dummy variable to report its data, which triggers behaviors
        print("\n[Datastream] Constructing data object for reported data...")
        if let currentVariable = currentStreamVariable { //get the current variable
            if let data = currentVariable.reportDataForVariable() { //*instruct variable to report data!*
                print("\n")
                for (key, value) in data {
                    print("[ReportedData] KEY = [\(key)]. VALUE: {\(value)}.")
                }
                print("\n")
            } else { //report object is NIL => stream is still OPEN
                print("Datastream is still open!")
            }
            self.currentStreamVariable = nil //clear variable @ end of fx
        }
    }
    
}