//  CarbonEmissionsModule.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 3/24/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Used to track carbon emissions.

import Foundation

class CarbonEmissionsModule: Module {
    
    override func getConfigureModuleLayoutObject() -> Dictionary<String, AnyObject> {
        var tempObject = super.getConfigureModuleLayoutObject() //obtain superclass' dict & ADD TO IT
        
        var alertMessage = Dictionary<String, [String: String]>() //1st key is section name, 2nd key is behavior/computation name (using the RAW_VALUE of the ENUM object!), value is a message for the alertController
        var messageForBehavior = Dictionary<String, String>()
        for behavior in carbonEmissionsModuleBehaviors {
            messageForBehavior[behavior.rawValue] = behavior.getAlertMessageForVariable()
        }
        alertMessage[BMN_BehaviorsKey] = messageForBehavior
        var messageForComputation = Dictionary<String, String>()
        for computation in carbonEmissionsModuleComputations {
            messageForComputation[computation.rawValue] = computation.getAlertMessageForVariable()
        }
        alertMessage[BMN_ComputationsKey] = messageForComputation
        tempObject[BMN_AlertMessageKey] = alertMessage //merge dictionaries
        
        return tempObject
    }
    
    private let carbonEmissionsModuleBehaviors: [CarbonEmissionsModuleVariableTypes] = []
    override func setBehaviors() -> [String]? { //dynamically assigns behaviors to list
        var behaviorTitles: [String] = []
        for behavior in carbonEmissionsModuleBehaviors {
            behaviorTitles.append(behavior.rawValue)
        }
        
        //(1) Set filters (i.e. exclude certain computations based on 'blockers' & 'locationInFlow'):
        var filteredTypes = Set<CarbonEmissionsModuleVariableTypes>() //set containing types to be filtered
        if let blocker = moduleBlocker {
            let filters = blocker.getFilteredTypesForModule(Modules.CarbonEmissionsModule)
            for filter in filters {
                if let enumValue = CarbonEmissionsModuleVariableTypes(rawValue: filter) {
                    filteredTypes.insert(enumValue)
                }
            }
        }
        
        //(2) Add items -> 'behaviors' array if they pass through filters:
        for behavior in carbonEmissionsModuleBehaviors {
            if !(filteredTypes.contains(behavior)) { //exclude filtered varTypes
                behaviorTitles.append(behavior.rawValue)
            }
        }
        return behaviorTitles
    }
    
    private let carbonEmissionsModuleComputations: [CarbonEmissionsModuleVariableTypes] = []
    override func setComputations() -> [String]? { //dynamically assigns comps to list
        var computationTitles: [String] = []
        for computation in carbonEmissionsModuleComputations {
            computationTitles.append(computation.rawValue)
        }
        
        //(1) Set filters (i.e. exclude certain computations based on 'blockers' & 'locationInFlow'):
        var filteredTypes = Set<CarbonEmissionsModuleVariableTypes>() //set containing types to be filtered
        if let blocker = moduleBlocker {
            let filters = blocker.getFilteredTypesForModule(Modules.CarbonEmissionsModule)
            for filter in filters {
                if let enumValue = CarbonEmissionsModuleVariableTypes(rawValue: filter) {
                    filteredTypes.insert(enumValue)
                }
            }
        }
        
        //(2) Add items -> 'computations' array if they pass through filters:
        for computation in carbonEmissionsModuleComputations {
            if !(filteredTypes.contains(computation)) { //exclude filtered varTypes
                computationTitles.append(computation.rawValue)
            }
        }
        return computationTitles
    }
    
    private var variableType: CarbonEmissionsModuleVariableTypes? { //converts 'selectedFunctionality' (a String) to an enum object
        get {
            if let selection = selectedFunctionality {
                return CarbonEmissionsModuleVariableTypes(rawValue: selection)
            }
            return nil
        }
    }
    
    // MARK: - Initializers
    
    override init(name: String) { //set-up init
        super.init(name: name)
        self.moduleTitle = Modules.CarbonEmissionsModule.rawValue
    }
    
    override init(name: String, dict: [String: AnyObject]) { //CoreData init
        super.init(name: name, dict: dict)
        self.moduleTitle = Modules.CarbonEmissionsModule.rawValue
    }
    
    // MARK: - Core Data Logic
    
    internal override func createDictionaryForCoreDataStore() -> Dictionary<String, AnyObject> {
        let persistentDictionary: [String: AnyObject] = super.createDictionaryForCoreDataStore()
        return persistentDictionary
    }
    
    internal override func setConfigurationOptionsForSelection() {
        //
    }
    
    // MARK: - Data Entry Logic
    
    override func getDataEntryCellTypeForVariable() -> DataEntryCellTypes? { //indicates to DataEntryVC what kind of DataEntry cell should be used for this variable
        if let type = self.variableType {
            switch type {
            default:
                return nil
            }
        }
        return nil
    }

}

enum CarbonEmissionsModuleVariableTypes: String { //*match each behavior/computation -> Configuration + DataEntry custom TV cells; for each new behavior/comp added, you must also add (1) Configuration logic, (2) Core Data storage logic (so the variable config can be preserved), (3) Unpacking logic (in the DataEntry initializer), & (4) DataEntry logic (enabling the user to report info).* 
    //Available Behaviors:
    case Dummy
    
    //Available Computations:
    
    func getAlertMessageForVariable() -> String {
        var message = ""
        switch self {
        case .Dummy:
            message = ""
        }
        return message
    }
    
}