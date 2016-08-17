//  Actions.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/7/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Enumeration containing a list of possible actions.

import Foundation

enum ActionTypes: String { //assign raw values (string representations) to each enum case
    case Sleep = "Sleep"
    case Exercise = "Exercise"
    case Eat = "Eat"
    case Custom = "Custom"
}

enum ActionLocations: String {
    case BeforeInputs = "Before Variables"
    case BetweenInputsAndOutcomes = "Between Inputs & Outcomes"
}

struct Action { //used to create the project action from & store the project action to CoreData
    
    let action: ActionTypes
    let actionLocation: ActionLocations //before IV or between IV/OM
    let qualifiersCount: Int //counts the # of qualifiers for the Action
    var occursInEachCycle: Bool = true //FALSE = NOT occurring during every run cycle
    
    var locationInMeasurementCycle: Int? //location in cycle when action reports (nil if action has no AQ)
    var customActionName: String? //should only be set if custom action is set
    var actionTimeStamp: NSDate? //used by TD DistanceFromAction computation
    var qualifiersStoredData: [String: [String: AnyObject]]? //stores the AQ data for an async Action - format is [Variable_Name: [Data_Dictionary]] (matches DB object in Project class)
    
    // MARK: - Initializers
    
    init(action: ActionTypes, customName: String?, location: ActionLocations, occursInEachCycle: Bool, qualifiersCount: Int) { //initializer for user selection
        self.action = action
        self.actionLocation = location
        self.occursInEachCycle = occursInEachCycle
        self.qualifiersCount = qualifiersCount //set # of AQ for action
        if (self.action == ActionTypes.Custom) { //set name for custom action
            customActionName = customName
        }
    }
    
    init(settings: [String: AnyObject]) { //initializer for CoreData object
        if let actionRaw = settings[BMN_Action_ActionTypeKey] as? String, actionType = ActionTypes(rawValue: actionRaw) {
            self.action = actionType
        } else {
            fatalError("[Action init] No actionType is set!")
        }
        self.customActionName = settings[BMN_Action_CustomNameKey] as? String
        if let eachCycle = settings[BMN_Action_OccursInEachCycleKey] as? Bool {
            self.occursInEachCycle = eachCycle
        }
        if let locationRaw = settings[BMN_Action_EnumLocationKey] as? String, location = ActionLocations(rawValue: locationRaw) {
            self.actionLocation = location
        } else {
            fatalError("[Action init] No location is set!")
        }
        self.locationInMeasurementCycle = settings[BMN_Action_LocationInCycleKey] as? Int
        if let count = settings[BMN_Action_QualifiersCountKey] as? Int {
            self.qualifiersCount = count
        } else {
            fatalError("[Action init] No qualifier count is set!")
        }
        self.actionTimeStamp = settings[BMN_Action_ActionTimeStampKey] as? NSDate
        self.qualifiersStoredData = settings[BMN_Action_QualifiersStoredDataKey] as? [String: [String: AnyObject]]
    }
    
    // MARK: - Core Data Logic
    
    func constructCoreDataObjectForAction() -> [String: AnyObject] { //dict holding all pertinent information for the Group's action (stored in Group object)
        var coreDataObject = Dictionary<String, AnyObject>()
        coreDataObject[BMN_Action_ActionTypeKey] = action.rawValue
        coreDataObject[BMN_Action_CustomNameKey] = customActionName
        coreDataObject[BMN_Action_QualifiersCountKey] = qualifiersCount
        coreDataObject[BMN_Action_QualifiersStoredDataKey] = qualifiersStoredData //data for AQ vars
        coreDataObject[BMN_Action_EnumLocationKey] = actionLocation.rawValue
        coreDataObject[BMN_Action_LocationInCycleKey] = locationInMeasurementCycle
        coreDataObject[BMN_Action_OccursInEachCycleKey] = occursInEachCycle
        coreDataObject[BMN_Action_ActionTimeStampKey] = actionTimeStamp //occurrence timeStamp
        return coreDataObject
    }

}