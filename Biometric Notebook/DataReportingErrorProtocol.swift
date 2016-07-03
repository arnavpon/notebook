//  DataReportingErrorProtocol.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 4/26/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Protocol that handles failure of specific BMN services (internet networking, location services, HealthKit permissions, etc.) during error reporting. Any class that interacts w/ the external world (where there is potential for failure of a service) must conform to this protocol! 
// NOTE - this protocol should be reserved ONLY for system errors (i.e. lack of internet connection, location services turned off, denied permission, etc.). It should NOT be used to cover all errors that can be generated while communicating w/ a service (e.g. if the dictionary returned by an API was not unpacked properly). 

import Foundation

protocol DataReportingErrorProtocol { //protocol for handling service access/connection errors
    
    func reportAccessErrorForService(service: ServiceTypes) //sends notification -> VC indicating the type of failed service
    
}

enum ServiceTypes: String { //list of all possible service types that are available in BMN
    
    case Internet = "BMN_Service_Internet" //need to differentiate between cellular data & Wi-Fi?
    case CoreLocation = "BMN_Service_CoreLocation"
    case HealthKit = "BMN_Service_HealthKit" //need to get more granular (read/write access for specific items), how does the system communicate specifically which data point failed?
    
    case Localhost = "BMN_Service_Localhost" //**temporary until website is available
    
}