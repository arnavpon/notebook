//  HealthKitConnection.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 12/28/15.
//  Copyright © 2015 Confluent Ideals. All rights reserved.

// Handles communicating w/ HealthKit objects & data

import Foundation
import HealthKit

class HealthKitConnection {
    private let available = HKHealthStore.isHealthDataAvailable()
    private let healthDataStore: HKHealthStore?
    private let timeSortDescriptor: NSSortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false) //sorts HKSamples in DESC order by end date
    
    //Required HK Type Identifiers:
    private let heartRateType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)!
    private let heightType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeight)!
    private let bodyMassType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass)!
    private let bodyTemperatureType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyTemperature)!
    private let dateOfBirthType = HKObjectType.characteristicTypeForIdentifier(HKCharacteristicTypeIdentifierDateOfBirth)!
    private let biologicalSexType = HKObjectType.characteristicTypeForIdentifier(HKCharacteristicTypeIdentifierBiologicalSex)!
    private let dietaryEnergyType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryEnergyConsumed)!
    private let foodType: HKCorrelationType = HKObjectType.correlationTypeForIdentifier(HKCorrelationTypeIdentifierFood)!
    
    init() {
        if (available) { //check that device has HKHealthStore
            healthDataStore = HKHealthStore()
            let shareTypes: Set<HKSampleType>? = [heartRateType, heightType, bodyMassType, bodyTemperatureType, dietaryEnergyType]
            let readTypes: Set<HKObjectType>? = [dateOfBirthType, biologicalSexType, heartRateType, heightType, bodyMassType, dietaryEnergyType]
            healthDataStore!.requestAuthorizationToShareTypes(shareTypes, readTypes: readTypes) { (let success, let error) -> Void in
                if (success) {
                    //user granted access
                } else {
                    //user denied access
                }
            }
        } else {
            healthDataStore = nil
            print("HKHealthStore unavailable.") //fail gracefully
        }
    }
    
    func getDateOfBirthFromHKStore() {
        if let healthKitStore = healthDataStore {
            do {
                let dateOfBirth = try healthKitStore.dateOfBirth()
                let date = DateTime(date: dateOfBirth)
                print(date.getCurrentDateString())
                //use DOB to compute age
                let ageComponents: NSDateComponents = NSCalendar.currentCalendar().components(.Year, fromDate: dateOfBirth, toDate: NSDate(), options: .WrapComponents) //wrap components has to do w/ rounding on the calculation
                print("Age: \(ageComponents.year)")
            } catch (let error as NSError) {
                print(error)
            }
        }
    }
    
    func getHeightFromHKStore() -> Double? { //returns the most recent height entry from the store
        var returnedHeight: Double?
        let heightUnit: HKUnit = HKUnit.footUnit()
        let heightQuery: HKSampleQuery = HKSampleQuery(sampleType: heightType, predicate: nil, limit: 5, sortDescriptors: [timeSortDescriptor]) { (let query, let results, let error) -> Void in
            if (results?.count) != 0 {
                let quantitySample: HKSample = (results?.first)!
                let quantity = (quantitySample as! HKQuantitySample).quantity
                let height: Double = quantity.doubleValueForUnit(heightUnit)
                returnedHeight = height
                print("Returned height: \(returnedHeight)")
            } else {
                returnedHeight = nil
                print("Error: \(error)")
            }
        }
        if let healthKitStore = healthDataStore {
            healthKitStore.executeQuery(heightQuery)
        }
        return returnedHeight
    }
    
    func getBodyMassFromHKStore() -> Double? { //returns the most recent weight entry in the store
        var returnedWeight: Double?
        let weightUnit: HKUnit = HKUnit.poundUnit()
        let weightQuery: HKSampleQuery = HKSampleQuery.init(sampleType: bodyMassType, predicate: nil, limit: 5, sortDescriptors: [timeSortDescriptor]) { (let query, let results, let error) -> Void in
            if (results?.count) != 0 { //top-most item is nil for some reason (can't read user created information??? Also, the value of the return object may be nil b/c of threading, w/ the completion occurring on the background thread. When I call from view did load, the external function reports back before the class function, so definitely a thread problem.
                let quantitySample: HKSample = (results?.first)!
                let quantity = (quantitySample as! HKQuantitySample).quantity
                let weight: Double = quantity.doubleValueForUnit(weightUnit)
                returnedWeight = weight
                print(returnedWeight)
            } else {
                print("Error: \(error)")
                returnedWeight = nil
            }
        }
        if let healthKitStore = healthDataStore {
            healthKitStore.executeQuery(weightQuery)
        }
        return returnedWeight
    }
    
    func addHeartRateMeasurementToHKStore(heartRate: Int) { //obtains HR from AppleWatch & saves it -> HK
        let heartRateInputAuth = healthDataStore?.authorizationStatusForType(heartRateType).rawValue
        if (heartRateInputAuth == 2) { //authorized
            let currentDate = NSDate()
            let heartRate: Double = Double(heartRate)
            let heartRateQuantity = HKQuantity(unit: HKUnit.countUnit(), doubleValue: heartRate)
            let heartRateSample = HKQuantitySample(type: heartRateType, quantity: heartRateQuantity, startDate: currentDate, endDate: currentDate)
            if let healthKitStore = healthDataStore {
                healthKitStore.saveObject(heartRateSample) { (let success, let error) -> Void in
                    if (!success) {
                        print("Save failed w/ error: \(error)")
                        abort() //ends function execution
                    } else {
                        print("Save successful.")
                    }
                }
            }
        } else { //not authorized
            print("Not authorized to input. Raw value = \(heartRateInputAuth)")
        }
    }
    
    func addHeightMeasurementToHKStore() { //save height data point into store
        //Make sure you are authorized to SHARE specific types of data before sharing them, 2 = authorized, 1 = not authorized
        let heightInputAuth = healthDataStore!.authorizationStatusForType(heightType).rawValue
        if (heightInputAuth == 2) {
            let currentDate = NSDate()
            let footUnit = HKUnit.footUnit()
            let height: Double = 5.22
            let heightQuantity = HKQuantity(unit: footUnit, doubleValue: height)
            let heightSample = HKQuantitySample(type: heightType, quantity: heightQuantity, startDate: currentDate, endDate: currentDate)
            if let healthKitStore = healthDataStore {
                healthKitStore.saveObject(heightSample) { (let success, let error) -> Void in
                    if (!success) {
                        print("Save failed w/ error: \(error)")
                        abort() //ends function execution
                    } else {
                        print("Save successful.")
                    }
                }
            }
        } else {
            print("Not authorized to input. Raw value = \(heightInputAuth)")
        }
    }
    
    func addBodyMassMeasurementToHKStore() { //save weight data point into store
        let weightInputAuth = healthDataStore!.authorizationStatusForType(bodyMassType).rawValue
        if (weightInputAuth == 2) { //authorized
            let poundUnit = HKUnit.poundUnit()
            let weight: Double = 135
            let weightQuantity = HKQuantity(unit: poundUnit, doubleValue: weight)
            let currentDate = NSDate()
            let weightSample = HKQuantitySample(type: bodyMassType, quantity: weightQuantity, startDate: currentDate, endDate: currentDate) //quantity sample is a single sample for a quantity occurring @ a given point in time
            if let healthKitStore = healthDataStore {
                healthKitStore.saveObject(weightSample) { (let success, let error) -> Void in
                    if (!success) {
                        print("Save failed w/ error: \(error)")
                        abort()
                    } else {
                        print("Save successful.")
                    }
                }
            }
        } else {
            print("Not authorized to input. Raw value = \(weightInputAuth)")
        }
    }
    
    func addFoodItemToHKStore(foodItem: FoodItem) { //save food item into store
        let dietaryEnergyInputAuth = healthDataStore!.authorizationStatusForType(dietaryEnergyType).rawValue
        if (dietaryEnergyInputAuth == 2) { //authorized
            let energyConsumedType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryEnergyConsumed)!
            let energyConsumed: HKQuantity = HKQuantity(unit: HKUnit.kilocalorieUnit(), doubleValue: 800)
            let currentDate = NSDate()
            let quantity = HKQuantitySample(type: energyConsumedType, quantity: energyConsumed, startDate: currentDate, endDate: currentDate)
            let quantityAsSample = quantity as HKSample //can cast back & forth between Sample & QuantitySample
            let energySamples: Set<HKSample> = [quantityAsSample]
            let dataDict: NSDictionary = [HKMetadataKeyFoodType: "banana"]
            let foodCorrelation: HKCorrelation = HKCorrelation(type: foodType, startDate: currentDate, endDate: currentDate, objects: energySamples, metadata: dataDict as? [String : AnyObject])
            if let healthKitStore = healthDataStore {
                healthKitStore.saveObject(foodCorrelation) { (let success, let error) -> Void in
                    print("Success: \(success). Error: \(error)")
                }
            }
        } else {
            print("Not authorized to input. Raw value = \(dietaryEnergyInputAuth)")
        }
    }
    
    func getFoodItemFromHKStore() -> HKCorrelation? { //lookup a food item
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
        if let healthKitStore = healthDataStore {
            healthKitStore.executeQuery(foodQuery)
        }
        return returnedFoodItem
    }
}