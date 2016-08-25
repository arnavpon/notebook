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

class Datastream: NSManagedObject {
    
    // MARK: - Subclass Logic

    func writeToDatastream() {
        //override in subclasses
    }
    
    func readFromDatastream() {
        //override in subclasses
    }
    
    // MARK: - Interface Logic

}