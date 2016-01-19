//  FoodIntakeModule.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/7/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Module for inputting food intake data & computing calorific consumption & nutritional intake.

import Foundation

class FoodIntakeModule: Module {
    
    override init(name: String) {
        super.init(name: name)
    }
    
    internal func createDictionaryForCoreDataStore() -> Dictionary<String, AnyObject> { //generates dictionary to be saved by CoreData (this dict will allow full reconstruction of the object)
        var persistentDictionary: [String: AnyObject] = ["module": "foodIntake"]
        return persistentDictionary
    }
    
}
