//  Datastream.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 8/24/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Define the functions that all datastream subclasses draw upon - a stream variable occupes 1 location in the measurement cycle (like any other variable) & can be mixed w/ other variables @ the same location. However, UNLIKE other variables, the single variable can report MULTIPLE times @ a SINGLE location.
// When the user enters DataEntry mode for a stream variable, the system checks if the stream is currently open or closed. If OPEN, the system automatically presents the next location w/in the stream. If CLOSED, the user has the option to either open a new stream or use cached data from an old one.

import Foundation
import CoreData

enum DatastreamIdentifiers: String { //enum used for streamID property
    case ExM_Workout
    case FIM_FoodIntake
}

class Datastream: NSManagedObject, DataEntryProtocol {
    
    var sender: DataEntryProtocol_ConformingClasses = .Datastream //protocol property
    
    // MARK: - Data Entry Protocol
    
    func refreshMeasurementCycle() { //refreshes tempStorageObject (called when user manually refreshes)
        print("[Datastream] Refreshing measurement cycle...")
        self.temporaryStorageObject = nil //clear TSO (thereby closing the stream)
        saveManagedObjectContext() //persist all changes
    }
    
    func getOptionsForGroupSelectionView() -> (String, [String])? { //accessed by DataEntryVC - returns (topLabelTitle, [selectionOptions])
        return nil //default is nil (no options are presented)
    }
    
    func getVariablesForSelectedGroup(selection: Int?) -> [Module]? { //return a single dummy datastream variable for which data will be reported
        //override in subclasses
        return nil
    }
    
    func repopulateDataObjectForSubscribedVariables(erroredService service: ServiceTypes) { //called by DataEntryVC in response to error messages - instructs all variables subscribed to the specified service to re-populate their report data object
        //?? how to handle? FIM needs internet connection so it must use this function as needed
    }
    
    func getReportCountForCurrentLocationInCycle() -> Int? { //report count for stream == 1
        return 1 //only 1 variable needs to be reported for the stream object
    }
    
    func constructDataObjectForReportedData() { //aggregates data that is reported
        //override in subclasses
    }

}