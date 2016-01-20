//  BiometricModule.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/19/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Module for entering biometric data into HK (e.g. height, weight, etc.)

import Foundation

class BiometricModule: Module {
    
    let moduleObjects: [String] = ["Height", "Weight", "Age"] //how do we deal w/ static pieces of data like DOB? Can pull from HK?
    let computations: [String] = ["BMI"] 
    
    override init(name: String) {
        super.init(name: name)
        self.moduleTitle = "Biometric"
    }
    
    internal func createDictionaryForCoreDataStore() -> Dictionary<String, AnyObject> { //generates dictionary to be saved by CoreData (this dict will allow full reconstruction of the object)
        var persistentDictionary: [String: AnyObject] = ["module": self.moduleTitle]
        return persistentDictionary
    }
    
}
