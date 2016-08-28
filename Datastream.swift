//  Datastream.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 8/24/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Define the functions that all datastream subclasses draw upon.

import Foundation
import CoreData

enum DatastreamIdentifiers: String { //enum used for streamID property
    case ExM_Workout
    case FIM_FoodIntake
}

class Datastream: NSManagedObject, DataEntryProtocol {
    
    //Location in cycle - the stream variable will sit in the measurement cycle like any other variable. It can be mixed with other variables @ the same location. However, unlike other variables, the single variable can report multiple times @ a single location. 
    //When it is time for the streamed variable to report, the system checks if a stream is currently open or not - if open, it automatically goes to the next location w/in the stream. For FI vars - if stream is NOT open, it allows the user to either open a new stream or to use cached data from the last completed stream. New streams CANNOT be opened until the existing stream is closed. FIV CANNOT use data from outside the current stream if data has been collected already for the locations that were selected during configuration - e.g. if breakfast has already been consumed & data reported, ONLY the existing breakfast data for the current stream can be used for the variable. For ExV if no stream is open, the system allows the user to select from the last 3-7? cached (completed) workouts, labeled by date of completion OR to start a new stream.
    
    //To-Do:
    //(1) Need a way to CACHE the stream data in CoreData after the stream has been closed (1 object for FI stream, 3-7? objects for workout stream)!
    //(3) Define AGGREGATION logic - how is all of the reported data compiled into a single object matched to the variable's name & then placed in the DB object? Data should ONLY be placed in DB object after it is aggregated, in the interim it should be stored in the STREAM dict!
    //(4) VISUAL design for the cells - how does the cell present popups for the user to select which items to use during reporting? Can utilize collectionViews w/in TV cells?
    
    var sender: DataEntryProtocol_ConformingClasses = .Datastream //protocol property
    
    // MARK: - Data Entry Protocol
    
    func refreshMeasurementCycle() { //refreshes tempStorage object (called when stream is automatically closed by system or manually by user)
        print("[Datastream] Refreshing measurement cycle...")
        self.temporaryStorageObject = nil //clear temp object
        saveManagedObjectContext() //persist all changes
    }
    
    func getOptionsForGroupSelectionView() -> (String, [String])? { //accessed by DataEntryVC - returns (topLabelTitle, [selectionOptions])
        return nil //default is nil (no options are presented)
    }
    
    func getVariablesForSelectedGroup(selection: Int?) -> [Module]? { //return the lone stream variable for which data is being reported **
        //need to define a dummy variable so that the system can access the appropriate functionality - which variable depends on the subclass. Adjust the aggregateData() logic to interface w/ the variable's reportData function!
        //how does this variable work? how is it linked to the stream & to other variables?
        return nil
    }
    
    func repopulateDataObjectForSubscribedVariables(erroredService service: ServiceTypes) { //called by DataEntryVC in response to error messages - instructs all variables subscribed to the specified service to re-populate their report data object
        //?? how to handle? FIM needs internet connection so it must use this function as needed
    }
    
    func getReportCountForCurrentLocationInCycle() -> Int? { //report count should only be 1
        return 1 //only 1 variable needs to be reported for the stream object
    }
    
    func constructDataObjectForReportedData() { //constructs TSO using reported data
        //override in subclasses
    }

}