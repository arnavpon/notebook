//  CarbonEmissionsModule.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 3/24/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Used to track carbon emissions.

import Foundation

class CarbonEmissionsModule: Module {
    
    private let carbonEmissionsModuleBehaviors: [CarbonEmissionsModuleVariableTypes] = []
    override var behaviors: [String] { //object containing titles for TV cells
        var behaviorTitles: [String] = []
        for behavior in carbonEmissionsModuleBehaviors {
            behaviorTitles.append(behavior.rawValue)
        }
        return behaviorTitles
    }
    
    private let carbonEmissionsModuleComputations: [CarbonEmissionsModuleVariableTypes] = []
    override var computations: [String] { //object containing titles for TV cells
        var computationTitles: [String] = []
        for computation in carbonEmissionsModuleComputations {
            computationTitles.append(computation.rawValue)
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
    
    // MARK: - Core Data
    
    internal override func createDictionaryForCoreDataStore() -> Dictionary<String, AnyObject> {
        let persistentDictionary: [String: AnyObject] = super.createDictionaryForCoreDataStore()
        return persistentDictionary
    }
    
    internal override func setConfigurationOptionsForSelection() {
        //
    }
    
    // MARK: - Data Entry
    
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