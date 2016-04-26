//  HealthKitConnection.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 12/28/15.
//  Copyright © 2015 Confluent Ideals. All rights reserved.

// Handles all communication w/ the HealthKit data store (both extracting from & saving to the store).

//CHARACTERISTIC data - represents items that typically do NOT change (DOB, blood type, sex, skin type, etc.) Can read this data directly from HK store.
//SAMPLE data - represents measurement @ a particular point in time, subclasses of HKSample class (subclass of HKObject). All sample objects have a 'type', 'startDate', & 'endDate' property. 4 types of samples are CATEGORY samples (only for sleep analysis), QUANTITY samples (data stored as numeric value, e.g. height/weight/temp/HR), CORRELATIONS (composite data containing 1 or more samples such as food or BP), & WORKOUTS (data representing physical activity).

import Foundation
import HealthKit

class HealthKitConnection {
    
    private let isAvailable = HKHealthStore.isHealthDataAvailable() //checks if device has access to HK
    private let healthStore = HKHealthStore() //manages interaction w/ store
    private let timeSortDescriptor: NSSortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false) //sorts HKSamples in DESC order by end date (last -> first)
    
    //HK Type Identifiers (for reading/writing to store):
    private let heartRateType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)!
    private let heightType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeight)!
    private let bodyMassType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass)!
    private let bodyTemperatureType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyTemperature)!
    private let dateOfBirthType = HKObjectType.characteristicTypeForIdentifier(HKCharacteristicTypeIdentifierDateOfBirth)!
    private let biologicalSexType = HKObjectType.characteristicTypeForIdentifier(HKCharacteristicTypeIdentifierBiologicalSex)!
    private let dietaryEnergyType: HKQuantityType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryEnergyConsumed)! //?
    private let foodType: HKCorrelationType = HKObjectType.correlationTypeForIdentifier(HKCorrelationTypeIdentifierFood)! //?
    
    // MARK: - Initializers
    
    init() {
        if (isAvailable) { //check that device has access to HKHealthStore
            let shareTypes: Set<HKSampleType> = [heartRateType, heightType, bodyMassType, bodyTemperatureType, dietaryEnergyType] //write permissions
            let readTypes: Set<HKObjectType> = [dateOfBirthType, biologicalSexType, heartRateType, heightType, bodyMassType, dietaryEnergyType] //read permissions
            healthStore.requestAuthorizationToShareTypes(shareTypes, readTypes: readTypes) { (let success, let error) -> Void in
                if (success) {
                    //user granted access
                } else {
                    //user denied access
                }
            }
        } else { //DEVICE (e.g. an iPad) is NOT equipped to use HealthStore
            print("HKHealthStore unavailable.") //fail gracefully
        }
    }
    
    // MARK: - HKStore Interaction Logic
    
    func getDataFromHKStore(type: String) -> AnyObject? { //what is most specific yet extensible return type?
        return nil
    }
    
    func writeDataToHKStore(type: String, value: Double) {
        
    }
    
    func getDateOfBirthFromHKStore(dataType: String) { //dataType is type of data wanted from store, break down by categories (quantity vs. correlation vs. category) or just use a single method
        //make a general function for extracting any specific kind of data & make a function for writing any kind of data to the store. Specify externally what kind of data to write or receive. Use enums to control for types.
        do {
            let dateOfBirth = try healthStore.dateOfBirth()
            let date = DateTime(date: dateOfBirth)
            let ageComponents: NSDateComponents = NSCalendar.currentCalendar().components(.Year, fromDate: dateOfBirth, toDate: NSDate(), options: .WrapComponents) //compute age
            print("DOB from HK: [\(date.getDateString())]. Age: \(ageComponents.year)")
        } catch (let error as NSError) {
            print("[getDOB] Error: \(error).")
        }
    }
    
    func getGenderFromHKStore() {
        do {
            let gender = try healthStore.biologicalSex().biologicalSex //returns enum object
            switch gender {
            case .NotSet:
                print("patient sex is NOT SET")
            case .Male:
                print("patient sex is MALE")
            case .Female:
                print("patient sex is FEMALE")
            case .Other:
                print("patient sex is OTHER")
            }
        } catch let error as NSError {
            print("[getGender] Error: \(error).")
        }
    }
    
    func getLastHeightFromHKStore() -> Double? { //returns the most recent height entry from the store
        var returnedHeight: Double?
        let heightUnit: HKUnit = HKUnit.footUnit() //define data unit type
        let heightQuery: HKSampleQuery = HKSampleQuery(sampleType: heightType, predicate: nil, limit: 5, sortDescriptors: [timeSortDescriptor]) { (let query, let results, let error) -> Void in
            if let heights = results {
                if !(heights.isEmpty) {
                    if let quantitySample: HKSample = heights.first {
                        let quantity = (quantitySample as! HKQuantitySample).quantity
                        let height: Double = quantity.doubleValueForUnit(heightUnit) //convert val -> feet
                        returnedHeight = height
                        print("Returned height: \(returnedHeight)")
                    }
                }
            } else {
                returnedHeight = nil
                print("Error: \(error)")
            }
        }
        healthStore.executeQuery(heightQuery)
        return returnedHeight
    }
    
    func getLastBodyMassFromHKStore() -> Double? { //returns the most recent weight entry in the store
        var returnedWeight: Double?
        let weightUnit: HKUnit = HKUnit.poundUnit()
        let weightQuery: HKSampleQuery = HKSampleQuery.init(sampleType: bodyMassType, predicate: nil, limit: 5, sortDescriptors: [timeSortDescriptor]) { (let query, let results, let error) -> Void in
            if let weights = results {
                if !(weights.isEmpty) {
                    if let quantitySample: HKSample = weights.first {
                        let quantity = (quantitySample as! HKQuantitySample).quantity
                        let weight: Double = quantity.doubleValueForUnit(weightUnit)
                        returnedWeight = weight
                        print(returnedWeight)
                    }
                }
            } else {
                print("Error: \(error)")
                returnedWeight = nil
            }
             //top-most item is nil for some reason (can't read user created information??? Also, the value of the return object may be nil b/c of threading, w/ the completion occurring on the background thread. When I call from view did load, the external function reports back before the class function, so definitely a thread problem.
                //we want to return the value as a completion!
        }
        healthStore.executeQuery(weightQuery)
        return returnedWeight
    }
    
    // MARK: - Write Methods
    
    func addHeartRateMeasurementToHKStore(heartRate: Int) { //obtains HR from AppleWatch & saves it -> HK
        let heartRateInputAuth = healthStore.authorizationStatusForType(heartRateType).rawValue
        if (heartRateInputAuth == 2) { //authorized
            let currentDate = NSDate()
            let hr: Double = Double(heartRate)
            let bpm = HKUnit.minuteUnit().reciprocalUnit() //custom unit
            let heartRateQuantity = HKQuantity(unit: bpm, doubleValue: hr) //HR requires a unit of inverse time (for measurement of counts/minute)
            let heartRateSample = HKQuantitySample(type: heartRateType, quantity: heartRateQuantity, startDate: currentDate, endDate: currentDate) 
            healthStore.saveObject(heartRateSample) { (let success, let error) -> Void in
                if (!success) {
                    print("Save failed w/ error: \(error)")
                } else {
                    print("Save successful.")
                }
            }
        } else { //not authorized to write to HR store
            print("Not authorized to input. Raw value = \(heartRateInputAuth)")
        }
    }
    
    func addHeightMeasurementToHKStore(height: Double) { //save height data point into store
        //Make sure you are authorized to SHARE specific types of data before sharing them, 2 = authorized, 1 = not authorized
        let heightInputAuth = healthStore.authorizationStatusForType(heightType).rawValue
        if (heightInputAuth == 2) {
            let currentDate = NSDate() //for sample timeStamp
            let footUnit = HKUnit.footUnit()
            let heightQuantity = HKQuantity(unit: footUnit, doubleValue: height)
            let heightSample = HKQuantitySample(type: heightType, quantity: heightQuantity, startDate: currentDate, endDate: currentDate)
            healthStore.saveObject(heightSample) { (let success, let error) -> Void in
                if (!success) {
                    print("Save failed w/ error: \(error)")
                } else {
                    print("Save successful.")
                }
            }
        } else {
            print("Not authorized to input. Raw value = \(heightInputAuth)")
        }
    }
    
    func addBodyMassMeasurementToHKStore(weight: Double) { //save weight data point into store
        let weightInputAuth = healthStore.authorizationStatusForType(bodyMassType).rawValue
        if (weightInputAuth == 2) { //authorized
            let poundUnit = HKUnit.poundUnit()
            let weightQuantity = HKQuantity(unit: poundUnit, doubleValue: weight)
            let currentDate = NSDate() //for sample timeStamp
            let weightSample = HKQuantitySample(type: bodyMassType, quantity: weightQuantity, startDate: currentDate, endDate: currentDate) //quantity sample is a single sample for a quantity occurring @ a given point in time
            healthStore.saveObject(weightSample) { (let success, let error) -> Void in
                if (!success) {
                    print("Save failed w/ error: \(error)")
                } else {
                    print("Save successful.")
                }
            }
        } else { //not authorized to write to Weight store
            print("Not authorized to input. Raw value = \(weightInputAuth)")
        }
    }
    
    func addFoodItemToHKStore(foodItem: String) { //save food item into store
        let dietaryEnergyInputAuth = healthStore.authorizationStatusForType(dietaryEnergyType).rawValue
        if (dietaryEnergyInputAuth == 2) { //authorized
            let energyConsumedType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryEnergyConsumed)!
            let energyConsumed: HKQuantity = HKQuantity(unit: HKUnit.kilocalorieUnit(), doubleValue: 800)
            let currentDate = NSDate()
            let quantity = HKQuantitySample(type: energyConsumedType, quantity: energyConsumed, startDate: currentDate, endDate: currentDate)
            let quantityAsSample = quantity as HKSample //can cast back & forth between Sample & QuantitySample
            let energySamples: Set<HKSample> = [quantityAsSample]
            let dataDict: NSDictionary = [HKMetadataKeyFoodType: "banana"]
            let foodCorrelation: HKCorrelation = HKCorrelation(type: foodType, startDate: currentDate, endDate: currentDate, objects: energySamples, metadata: dataDict as? [String : AnyObject])
            healthStore.saveObject(foodCorrelation) { (let success, let error) -> Void in
                print("Success: \(success). Error: \(error)")
            }
        } else {
            print("Not authorized to input. Raw value = \(dietaryEnergyInputAuth)")
        }
    }
    
    func getFoodItemFromHKStore() -> HKCorrelation? { //look up a food item
        var returnedFoodItem: HKCorrelation?
        let currentDate = NSDate()
        let predicate: NSPredicate = HKQuery.predicateForSamplesWithStartDate(currentDate, endDate: NSCalendar.currentCalendar().dateByAddingUnit(.Day, value: 1, toDate: currentDate, options: NSCalendarOptions.MatchFirst), options: .None)
        let foodQuery = HKSampleQuery(sampleType: foodType, predicate: predicate, limit: 100, sortDescriptors: nil) { (let query, let results, let error) -> Void in
            if (results?.count != 0) {
                for sample in results! {
                    let correlation = sample as! HKCorrelation
                    returnedFoodItem = correlation
                }
            } else {
                returnedFoodItem = nil
                print("No results. Error: \(error)")
            }
        }
        healthStore.executeQuery(foodQuery)
        return returnedFoodItem
    }
    
}