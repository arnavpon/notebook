//  CustomModule.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/7/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Module used to capture text based information based on a variable & its options. When we store this information to CoreData, we create a dictionary containing all necessary information & pass this to the managed object. When the app is reopened, this dictionary is broken down to produce individual components, which will be used for data capture.

import Foundation

class CustomModule: Module {
    
    private var prompt: String? //the (optional) prompt attached to the variable (replaces the variable's name as the section header of the TV for data collection)
    private let options: [String] //array of options associated w/ the variable/prompt
    static let configurations: [String] = ["Boolean"] //instance variable containing pre-defined configurations that can be attached to the module (e.g. the 'Boolean' attachment automatically creates 2 options, 'Yes' & 'No'
    
    init(name: String, options: [String]) { //initializer if user did not select a prompt
        self.options = options
        super.init(name: name)
        self.moduleTitle = "Custom" //overwrite moduleTitle w/ title specific to this class
    }
    
    init(name: String, prompt: String, options: [String]) { //initializer if user did select a prompt
        self.options = options
        self.prompt = prompt
        super.init(name: name)
    }
    
    internal func createDictionaryForCoreDataStore() -> Dictionary<String, AnyObject> { //generates dictionary to be saved by CoreData (this dict will allow full reconstruction of the object into a Module subclass). Each variable will occupy 1 spot in the overall dictionary, so we need to merge these individual dictionaries for each variable into 1 master dictionary. Each variable's dictionary will be indicated by the variable name, so MAKE SURE THERE ARE NO REPEAT NAMES!
        var persistentDictionary: [String: AnyObject] = ["module": self.moduleTitle, "options": self.options] //'module' name matches switch case in 'Project' > 'createModuleObjectFromModuleName' func
        if let headerTitle = prompt {
            persistentDictionary["prompt"] = headerTitle
        }
        return persistentDictionary
    }
    
    internal func getOptionsForVariable() -> [String] { //returns the 'Options' array
        return self.options
    }
    
    internal func getPromptForVariable() -> String? { //returns the 'Options' array
        return self.prompt
    }
    
    internal func setPromptForVariable(prompt: String) { //returns the 'Options' array
        self.prompt = prompt
    }
}
