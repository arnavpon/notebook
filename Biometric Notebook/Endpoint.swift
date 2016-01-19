//  Endpoint.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/18/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Enumeration containing a list of possible endpoints. The logic is as follows - a selection of 'continuous' in the first picker sets the enum value to 'continuous'. Any other selection is of the format # + Unit. Initialize the enum w/ the unit & then create a function to set the #.

import Foundation

enum Endpoints: String { //assign raw values (string representations) to each enum case
    
    case Continuous = "Continuous"
    case Day = "Day(s)"
    case Week = "Week(s)"
    case Month = "Month(s)"
    case Year = "Year(s)"
    
    func generateEndpoint(numberOfUnits: Int) -> Int? { //generates the combined endpoint, defined as the # of days from the current start point that the project will last for
        let endPoint: Int
        switch self {
        case .Continuous:
            return nil
        case .Day:
            endPoint = numberOfUnits
        case .Week:
            endPoint = numberOfUnits * 7
        case .Month:
            endPoint = numberOfUnits * 30
        case .Year:
            endPoint = numberOfUnits * 365
        }
        return endPoint
    }
    
}

struct Endpoint { //storage item for CoreData
    
    let endpoint: Endpoints?
    var endpointInDays: Int?
    
    init(firstPickerSelection: String, secondPickerSelection: String) { //initializer from user selection - sets enum object & obtains the endpoint as # of days
        if (firstPickerSelection == "Continuous") {
            endpoint = Endpoints.Continuous
            endpointInDays = nil
        } else {
            endpoint = Endpoints(rawValue: secondPickerSelection)!
            if let number = Int(firstPickerSelection) {
                endpointInDays = (endpoint!.generateEndpoint(number))!
            } else {
                endpointInDays = nil
            }
        }
    }
    
    init(endpointInDays: Int?) { //initializer from CoreData store
        //If no endpointInDays is entered, it is assumed that this is a 'continuous' project
        self.endpointInDays = endpointInDays
        if (self.endpointInDays == nil) {
            endpoint = Endpoints.Continuous
        } else {
            endpoint = nil
        }
    }
}