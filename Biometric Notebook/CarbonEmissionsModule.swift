//  CarbonEmissionsModule.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 3/24/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Used to track carbon emissions.

import Foundation

class CarbonEmissionsModule: Module {
    
    private let carbonEmissionsModuleBehaviors: [CarbonEmissionsModuleBehaviors] = []
    override var behaviors: [String] {
        var behaviorTitles: [String] = []
        for behavior in carbonEmissionsModuleBehaviors {
            behaviorTitles.append(behavior.rawValue)
        }
        return behaviorTitles
    }
    
    private let carbonEmissionsModuleComputations: [CarbonEmissionsModuleComputations] = []
    override var computations: [String] {
        var computationTitles: [String] = []
        for computation in carbonEmissionsModuleComputations {
            computationTitles.append(computation.rawValue)
        }
        return computationTitles
    }
    
    override var selectedFunctionality: String? { //handle selection of a behavior/computation
        didSet {
            
        }
    }
    
    override init(name: String) {
        super.init(name: name)
        self.moduleTitle = Modules.CarbonEmissionsModule.rawValue
    }
    
    internal func createDictionaryForCoreDataStore() -> Dictionary<String, AnyObject> { //generates dictionary to be saved by CoreData (this dict will allow full reconstruction of the object)
        let persistentDictionary: [String: AnyObject] = [BMNModuleTitleKey: self.moduleTitle]
        return persistentDictionary
    }
    
}

enum CarbonEmissionsModuleBehaviors: String {
    case Dummy
    
    func getAlertMessageForBehavior() -> String {
        let message = ""
//        switch self {
//        case .Height:
//            message = ""
//        }
        return message
    }
}

enum CarbonEmissionsModuleComputations: String {
    case Dummy
    
    func getAlertMessageForComputation() -> String {
        let message = ""
//        switch self {
//        case .Age:
//            message = ""
//        }
        return message
    }
}