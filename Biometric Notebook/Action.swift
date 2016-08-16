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
    var occursInEachCycle: Bool = true //FALSE = NOT occurring during every run cycle
    var customActionName: String? //should only be set if custom action is set
    
    var qualifiers: [String]? //**list of qualifiers matched to Action
    var actionTimeStamp: NSDate? //used to DistanceFromAction computation**
    
    // MARK: - Initializers
    
    init(action: ActionTypes, customName: String?, location: ActionLocations, occursInEachCycle: Bool, qualifiers: [String]?) { //initializer for user selection
        self.action = action
        self.occursInEachCycle = occursInEachCycle
        self.actionLocation = location
        self.qualifiers = qualifiers
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
        if let locationRaw = settings[BMN_Action_LocationKey] as? String, location = ActionLocations(rawValue: locationRaw) {
            self.actionLocation = location
        } else {
            fatalError("[Action init] No location is set!")
        }
        self.qualifiers = settings[BMN_Action_QualifiersKey] as? [String]
    }
    
    // MARK: - Core Data Logic
    
    func constructCoreDataObjectForAction() -> [String: AnyObject] { //dict holding all pertinent information for the project's action
        var coreDataObject = Dictionary<String, AnyObject>()
        coreDataObject[BMN_Action_ActionTypeKey] = action.rawValue
        coreDataObject[BMN_Action_CustomNameKey] = customActionName
        coreDataObject[BMN_Action_QualifiersKey] = qualifiers
        coreDataObject[BMN_Action_LocationKey] = actionLocation.rawValue
        coreDataObject[BMN_Action_OccursInEachCycleKey] = occursInEachCycle
        coreDataObject[""] = actionTimeStamp //save timeStamp in CoreData for access during DE
        return coreDataObject
    }

}