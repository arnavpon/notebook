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
    
    func generateEndpoint(numberOfUnits: Int) -> NSTimeInterval? { //generates the combined endpoint, defined as the # of seconds from the current start point that the project will last for
        let endpointInDays: Int
        switch self {
        case .Continuous:
            return nil
        case .Day:
            endpointInDays = numberOfUnits
        case .Week:
            endpointInDays = numberOfUnits * 7
        case .Month:
            endpointInDays = numberOfUnits * 30
        case .Year:
            endpointInDays = numberOfUnits * 365
        }
        return NSTimeInterval(endpointInDays * 24 * 60 * 60) //convert days -> seconds
    }
    
}

struct Endpoint { //calculates endpoint-related information
    
    var endpointInSeconds: NSTimeInterval? //total # of seconds between now & end of project
    
    init(endpoint: Endpoints, number: Int?) { //initializer from user selection - obtains the endpoint as # of days from the enum object
        if (endpoint == .Continuous) {
            self.endpointInSeconds = nil
        } else { //endpoints w/ numerical values
            if let value = number {
                self.endpointInSeconds = (endpoint.generateEndpoint(value))!
            } else { //not intialized w/ a # for a non-Continuous endpoint
                print("Error: endpoint does not have associated number!")
                self.endpointInSeconds = nil
            }
        }
    }
    
    init(endpointInSeconds: NSTimeInterval?) { //initializer from CoreData store
        //If endpointInDays == nil, it is assumed that this is a 'continuous' project:
        self.endpointInSeconds = endpointInSeconds
    }
    
    func getEndpointInDays() -> Int? { //reports # of days in SummaryVC
        if let endpoint = endpointInSeconds {
            let days = Int(endpoint / 60 / 60 / 24)
            return days
        }
        return nil
    }
}