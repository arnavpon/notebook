//  CustomModule.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/7/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Module used to capture text based information based on a variable & its options. When we store this information to CoreData, we create a dictionary containing all necessary information & pass this to the managed object. When the app is reopened, this dictionary is broken down to produce individual components, which will be used for data capture.
// In a custom module, the user can either enter a prompt (to replace the variable name as a section title), their own options, or select a behavior from a pre-built list.

import Foundation
import UIKit

class CustomModule: Module {
    
    //Need to transform the 'behaviors' into an enum (which will need to be rewritten depending on the module).
    override var tableViewLayoutObject: Dictionary<String, AnyObject> {
        get {
            var tempObject = Dictionary<String, AnyObject>()
            
            var viewForSection = Dictionary<String, CustomTableViewHeader>()
            for section in sectionsToDisplay { //assign rows to their respective sections
                switch section { //use the lowercare string for the dict key
                case "options":
                    //To this view, we want to position the 'add' button in the ConfigureVC on top of the section! Set up the behavior for this here:
                    let header = CustomTableViewHeader(frame: CGRect(x: 0, y: 0, width: 0, height: 24), text: "Or add options for your variable")
                    viewForSection[section] = header
                case "behaviors":
                    viewForSection[section] = CustomTableViewHeader(frame: CGRect(x: 0, y: 0, width: 0, height: 24), text: "Select a pre-built configuration")
                default:
                    print("[Custom - TVLayout] error: default switch")
                }
            }
            tempObject["viewForSection"] = viewForSection
            
            var rowsForSection = Dictionary<String, [String]>()
            for section in sectionsToDisplay { //assign rows to their respective sections
                switch section { //use the lowercare string for the dict key
                case "options":
                    rowsForSection[section] = options
                case "behaviors":
                    rowsForSection[section] = behaviors
                case "computations":
                    rowsForSection[section] = computations
                default:
                    print("[Custom - TVLayout] error: default switch")
                }
            }
            tempObject["rowsForSection"] = rowsForSection
            
            var selectable = Dictionary<String, Bool>()
            for section in sectionsToDisplay { //dict indicating whether rows in a section can be selected
                switch section { //use the lowercare string for the dict key
                case "options":
                    selectable[section] = false
                case "behaviors":
                    selectable[section] = true
                case "computations":
                    selectable[section] = true
                default:
                    print("Custom - TVLayout] error: default switch")
                }
            }
            tempObject["selectable"] = selectable
            
            tempObject["buttons"] = ["add", "prompt"] //indicate if there are any buttons that need to be added to the view (CustomMod needs a + button for adding options & a 'prompt' button for adding an options prompt). 
            //Custom view creation paradigm: create the view object in the Module class declaration & then add it to the superview (applying any view resizing/formatting) in the VC.
            
            return tempObject
        }
    }
    
    private let customModuleBehaviors: [CustomModuleBehaviors] = [CustomModuleBehaviors.Binary, CustomModuleBehaviors.Scale]
    override var behaviors: [String] { //'behaviors' = instance variables containing pre-defined behaviors that the module can adopt in place of the standard user-created options
        var behaviorTitles: [String] = []
        for behavior in customModuleBehaviors {
            behaviorTitles.append(behavior.rawValue)
        }
        return behaviorTitles
    } //HIDE these options if the user creates any of their own choices!
    
    override var selectedBehavior: String? { //handle selection of a behavior
        didSet { //when user selects a behavior, set the options accordingly; disable the + button so that user cannot add further items & enable the 'Save' option in the VC
            if let behavior = selectedBehavior {
                switch behavior {
                case behaviors[0]: //binary
                    options = ["Yes", "No"]
                case behaviors[1]: //range scale
                    print("")
                default:
                    print("[Custom] error: default switch 'selectedBehavior'")
                }
            }
        }
    }
    
    private var prompt: String? //the (optional) prompt attached to the variable (replaces the variable's name as the section header of the TV for data collection)
    
    var options: [String] = [] { //array of user-created options associated w/ the variable/prompt
        didSet { //if user adds an option, remove the behavior options
            if (options.isEmpty) { //no options, 'behaviors' are available
                sectionsToDisplay.insert("behaviors", atIndex: 0) //*
            } else { //options have been entered, hide the behaviors
                if let index = sectionsToDisplay.indexOf("behaviors") {
                    sectionsToDisplay.removeAtIndex(index)
                }
            }
        }
    }
    
    override init(name: String) {
        super.init(name: name)
        self.moduleTitle = Modules.CustomModule.rawValue //title specific to this class
        self.sectionsToDisplay.append("options") //'options' come after 'behaviors' (added to array in super.init)
    }
    
    // MARK: - View Layout
    
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

enum CustomModuleBehaviors: String {
    case Binary = "Binary" //automatically creates 2 options, 'Yes' & 'No'.
    case Scale = "<Range Scale" //gives users the option to select a value on a scale from A - B, where the user selects what the lower & upper limits are when they adopt this behavior; in data entry mode, the user will then select a value from this range using a slider/picker (TBD).
}
