//  HealthKitConnection.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 12/28/15.
//  Copyright © 2015 Confluent Ideals. All rights reserved.

// Handles all communication w/ the HealthKit data store (both extracting from & saving to the store).

//CHARACTERISTIC data - represents items that typically do NOT change (DOB, blood type, sex, skin type, etc.) Can read this data directly from HK store.
//SAMPLE data - represents measurement @ a particular point in time, subclasses of HKSample class (subclass of HKObject). All sample objects have a 'type', 'startDate', & 'endDate' property. 4 types of samples are CATEGORY samples (only for sleep analysis), QUANTITY samples (data stored as numeric value, e.g. height/weight/temp/HR), CORRELATIONS (composite data containing 1 or more samples such as food or BP), & WORKOUTS (data representing physical activity).

import Foundation
import HealthKit

enum Gender: String {
    case Male = "Male"
    case Female = "Female"
    case Other = "Other"
    case NotSet = "Not Set"
}

enum PredicateComparators { //used for creating a filtering predicate when accessing data from store
    case Equal
    case LessThan
    case LessThanOrEqual
    case GreaterThan
    case GreaterThanOrEqual
}

enum HealthKitProperties { //the item in the data store against which to perform the fetch
    case EndDate
    case StartDate
}

class HealthKitConnection: DataReportingErrorProtocol {
    
    private let isAvailable = HKHealthStore.isHealthDataAvailable() //checks if device has access to HK
    private let healthStore = HKHealthStore() //manages interaction w/ store
    private let timeSortDescriptor: NSSortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false) //sorts samples in DESC order (newest -> oldest)
    
    //HK Type Identifiers (for reading/writing to store) [STATIC vars]:
    static let heartRateType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)!
    static let heightType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeight)!
    static let bodyMassType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass)!
    static let bmiType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMassIndex)!
    static let bodyTemperatureType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyTemperature)!
    static let dateOfBirthType = HKObjectType.characteristicTypeForIdentifier(HKCharacteristicTypeIdentifierDateOfBirth)!
    static let biologicalSexType = HKObjectType.characteristicTypeForIdentifier(HKCharacteristicTypeIdentifierBiologicalSex)!
    
    private let dietaryEnergyType: HKQuantityType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryEnergyConsumed)! //?
    private let foodType: HKCorrelationType = HKObjectType.correlationTypeForIdentifier(HKCorrelationTypeIdentifierFood)! //?
    
    //HK Base & Compound Units [STATIC vars]:
    static let beatsPerMinuteUnit = HKUnit.minuteUnit().reciprocalUnit() //HR unit
    static let bmiUnit = HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Kilo).unitDividedByUnit(HKUnit.meterUnit().unitRaisedToPower(2)) //BMI measured in kg/m2**
    
    // MARK: - Initializers
    
    init() {
        if (isAvailable) { //check that device has access to HKHealthStore
            let shareTypes: Set<HKSampleType> = [HealthKitConnection.heartRateType, HealthKitConnection.heightType, HealthKitConnection.bodyMassType, HealthKitConnection.bodyTemperatureType, dietaryEnergyType] //write permissions
            let readTypes: Set<HKObjectType> = [HealthKitConnection.dateOfBirthType, HealthKitConnection.biologicalSexType, HealthKitConnection.heartRateType, HealthKitConnection.heightType, HealthKitConnection.bodyMassType, dietaryEnergyType] //read permissions
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
    
    func getSampleQuantityFromHKStore(sampleType: HKSampleType, unit: HKUnit, sampleLimit: Int?, filters: [(PredicateComparators, HealthKitProperties, AnyObject)], completion: ([Double]?) -> Void) { //'predicate' format is '(Comparator [>, <, =], Property to Search, Value for Comparison)'
        
        //(1) Define the sample limit (# of samples to pass through the function):
        var limit = HKObjectQueryNoLimit
        if let definedLimit = sampleLimit { //check if user defined a limit
            limit = definedLimit
        }
        
        //(2) Construct predicate based on 'filters' object:
        var predicate: NSPredicate? = nil //final predicate object
        var predicates: [NSPredicate] = [] //used to create a combined predicate
        for filter in filters {
            
            let operatorType: NSPredicateOperatorType
            switch (filter.0) { //construct the operator type
            case .Equal:
                operatorType = NSPredicateOperatorType.EqualToPredicateOperatorType
            case .GreaterThan:
                operatorType = NSPredicateOperatorType.GreaterThanPredicateOperatorType
            case .GreaterThanOrEqual:
                operatorType = NSPredicateOperatorType.GreaterThanOrEqualToPredicateOperatorType
            case .LessThan:
                operatorType = NSPredicateOperatorType.LessThanPredicateOperatorType
            case .LessThanOrEqual:
                operatorType = NSPredicateOperatorType.LessThanOrEqualToPredicateOperatorType
            }
            
            let leftExpression: NSExpression
            switch (filter.1) {
            case .StartDate:
                leftExpression = NSExpression(forKeyPath: "startDate")
            case .EndDate:
                leftExpression = NSExpression(forKeyPath: "endDate")
            }
            
            let tempPredicate = NSComparisonPredicate.init(leftExpression: leftExpression, rightExpression: NSExpression(forConstantValue: filter.2), modifier: NSComparisonPredicateModifier.DirectPredicateModifier, type: operatorType, options: NSComparisonPredicateOptions(rawValue: 0)) //construct each predicate individually
            predicates.append(tempPredicate) //add each predicate to array
        }
        
        if !(predicates.isEmpty) { //construct combined predicate
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }
        
        //(3) Execute query w/ predicate (results will be SORTED from MOST -> LEAST RECENT by 'endDate'):
        let query: HKSampleQuery = HKSampleQuery(sampleType: sampleType, predicate: predicate, limit: limit, sortDescriptors: [timeSortDescriptor]) { (let query, let results, let error) -> Void in
            if let samples = results {
                print("[HKSampleQuery] Returned [\(samples.count)] results...")
                if !(samples.isEmpty) {
                    var quantityValues: [Double] = []
                    for sample in samples { //convert samples -> Double
                        if let quantity = sample as? HKQuantitySample {
                            quantityValues.append(quantity.quantity.doubleValueForUnit(unit))
                        }
                    }
                    completion(quantityValues) //return fetched values
                } else {
                    print("No samples were found in the store (but NO error)!")
                    completion([]) //return empty array
//                    self.reportAccessErrorForService() //throw EMPTY error (not access error)!
                }
            } else {
                print("Failed to obtain results! Error: \(error).")
                completion(nil) //return nil
                self.reportAccessErrorForService(.HealthKit) //throw access error
            }
        }
        healthStore.executeQuery(query)
    }
    
    func writeSampleQuantityToHKStore(sampleType: HKQuantityType, quantity: Double, unit: HKUnit) { //method for WRITING QUANTITIES (height, body mass, BMI, LBM, body fat %) -> HKStore
        print("[HKConnection] writing sample quantity to store...")
        let authorization = healthStore.authorizationStatusForType(sampleType).rawValue
        if (authorization == 2) { //AUTHORIZED
            let currentDate = NSDate() //use current time for sample's timeStamp
            let quantitySample = HKQuantity(unit: unit, doubleValue: quantity) //make sure unit is valid!
            let sample = HKQuantitySample(type: sampleType, quantity: quantitySample, startDate: currentDate, endDate: currentDate)
            healthStore.saveObject(sample) { (let success, let error) -> Void in
                if (success) {
                    print("[HKConnection] Save was successful!")
                } else {
                    print("[HKConnection] Save failed w/ error: \(error).")
                }
            }
        } else { //interaction is NOT authorized
            print("Not authorized to input. Raw value = \(authorization).")
            reportAccessErrorForService(.HealthKit) //throw error** (this is called when 'Done' btn is pressed, so it will be leaving the VC, need to reconfigure this
        }
    }
    
    func getCurrentAgeFromHKStore() -> Int? { //method specific to obtaining DOB to compute Age
        do {
            let dateOfBirth = try healthStore.dateOfBirth() //obtain DOB from HK
//            let date = DateTime(date: dateOfBirth)
            let ageComponents: NSDateComponents = NSCalendar.currentCalendar().components(.Year, fromDate: dateOfBirth, toDate: NSDate(), options: .WrapComponents) //compute age
            return ageComponents.year
        } catch (let error as NSError) {
            print("[getDOB] Error: \(error).")
        }
        return nil
    }
    
    func getGenderFromHKStore() -> Gender? { //method specific to obtaining Gender
        do {
            let gender = try healthStore.biologicalSex().biologicalSex //returns enum object
            switch gender {
            case .NotSet:
                return Gender.NotSet
            case .Male:
                return Gender.Male
            case .Female:
                return Gender.Female
            case .Other:
                return Gender.Other
            }
        } catch let error as NSError {
            print("[getGender] Error: \(error).")
        }
        return nil
    }
    
    // MARK: - Write Methods
    
//    func addHeightMeasurementToHKStore(height: Double) { //save height data point into store
//        //Make sure you are authorized to SHARE specific types of data before sharing them, 2 = authorized, 1 = not authorized
//        let heightInputAuth = healthStore.authorizationStatusForType(heightType).rawValue
//        if (heightInputAuth == 2) {
//            let currentDate = NSDate() //for sample timeStamp
//            let footUnit = HKUnit.footUnit()
//            let heightQuantity = HKQuantity(unit: footUnit, doubleValue: height)
//            let heightSample = HKQuantitySample(type: heightType, quantity: heightQuantity, startDate: currentDate, endDate: currentDate)
//            healthStore.saveObject(heightSample) { (let success, let error) -> Void in
//                if (!success) {
//                    print("Save failed w/ error: \(error)")
//                } else {
//                    print("Save successful.")
//                }
//            }
//        } else {
//            print("Not authorized to input. Raw value = \(heightInputAuth)")
//        }
//    }
    
//    func addBodyMassMeasurementToHKStore(weight: Double) { //save weight data point into store
//        let weightInputAuth = healthStore.authorizationStatusForType(bodyMassType).rawValue
//        if (weightInputAuth == 2) { //authorized
//            let poundUnit = HKUnit.poundUnit()
//            let weightQuantity = HKQuantity(unit: poundUnit, doubleValue: weight)
//            let currentDate = NSDate() //for sample timeStamp
//            let weightSample = HKQuantitySample(type: bodyMassType, quantity: weightQuantity, startDate: currentDate, endDate: currentDate) //quantity sample is a single sample for a quantity occurring @ a given point in time
//            healthStore.saveObject(weightSample) { (let success, let error) -> Void in
//                if (!success) {
//                    print("Save failed w/ error: \(error)")
//                } else {
//                    print("Save successful.")
//                }
//            }
//        } else { //not authorized to write to Weight store
//            print("Not authorized to input. Raw value = \(weightInputAuth)")
//        }
//    }
    
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
    
    // MARK: - Error Handling
    
    func reportAccessErrorForService(service: ServiceTypes) { //fire notification for VC
        let notification = NSNotification(name: BMN_Notification_DataReportingErrorProtocol_ServiceDidReportError, object: nil, userInfo: [BMN_DataReportingErrorProtocol_ServiceTypeKey: service.rawValue])
        NSNotificationCenter.defaultCenter().postNotification(notification)
    }
    
}