//  DataEntryProtocol.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 8/25/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Protocol that defines the behaviors that are common to all objects that enable users to report data to the system (e.g. the Project class & the Datastream). Interfaces with DataEntryVC.

import Foundation

enum DataEntryProtocol_ConformingClasses {
    case Project
    case Datastream
}

protocol DataEntryProtocol {
    
    // MARK: - Required Properties
    
    var sender: DataEntryProtocol_ConformingClasses {get} //indicates sender for TV cell
    var temporaryStorageObject: [String: AnyObject]? {get set} //holds data during cycle
    
    // MARK: - Required Methods
    
    func refreshMeasurementCycle() //handles measurement cycle refresh
    
    func getOptionsForGroupSelectionView() -> (String, [String])? //handles display of options
    
    func getVariablesForSelectedGroup(selection: Int?) -> [Module]? //populates DEVC w/ variables
    
    func getReportCountForCurrentLocationInCycle() -> Int? //indicates how many vars need to report
    
    func repopulateDataObjectForSubscribedVariables(erroredService service: ServiceTypes) //function called when there is an error in accessing a service
    
    func constructDataObjectForReportedData() //aggregates data from variables for DB object
    
}