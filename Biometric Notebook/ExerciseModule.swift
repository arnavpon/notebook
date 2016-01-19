//  ExerciseModule.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/7/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Module for capturing exercise statistics such as calories burned, distance moved, etc.

import Foundation

class ExerciseModule: Module {
    
    override init(name: String) {
        super.init(name: name)
    }
    
    internal func createDictionaryForCoreDataStore() -> Dictionary<String, AnyObject> { //generates dictionary to be saved by CoreData (this dict will allow full reconstruction of the object)
        var persistentDictionary: [String: AnyObject] = ["module": "exercise"]
        return persistentDictionary
    }
}
