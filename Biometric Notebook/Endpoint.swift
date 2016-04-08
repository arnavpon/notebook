//  Endpoint.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/18/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Enumeration containing a list of possible endpoints. The logic is as follows - a selection of 'continuous' in the first picker sets the enum value to 'continuous'. Any other selection is of the format # + Unit. Initialize the enum w/ the unit & then create a function to set the #.

import Foundation

enum Endpoints: String { //assign raw values (string representations) to each enum case
    
    case Continuous = "None"
    case Day = "Days"
    case Week = "Weeks"
    case Month = "Months"
    case Year = "Years"
    
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
    
    var endpointInDays: Int? //total # of days between now & end of project
    
    init(endpoint: Endpoints, number: Int?) { //initializer from user selection - obtains the endpoint as # of days from the enum object
        if (endpoint == .Continuous) {
            self.endpointInDays = nil
        } else { //endpoints w/ numerical values
            if let value = number {
                self.endpointInDays = (endpoint.generateEndpoint(value))!
            } else { //not intialized w/ a # for a non-Continuous endpoint
                print("Error: endpoint does not have associated number!")
                self.endpointInDays = nil
            }
            
        }
    }
    
    init(endpointInDays: Int?) { //initializer from CoreData store
        //If endpointInDays == nil, it is assumed that this is a 'continuous' project:
        self.endpointInDays = endpointInDays
    }
}