//  TemperatureHumidityModule.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/7/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Module used to measure temperature & humidity data from external sensor.

import Foundation

class TemperatureHumidityModule: Module {
    
    override init(name: String) {
        super.init(name: name)
    }
    
    internal func createDictionaryForCoreDataStore() -> Dictionary<String, AnyObject> { //generates dictionary to be saved by CoreData (this dict will allow full reconstruction of the object)
        var persistentDictionary: [String: AnyObject] = ["module": "tempAndHumidity"]
        return persistentDictionary
    }
    
}