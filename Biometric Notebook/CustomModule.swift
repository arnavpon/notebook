//  CustomModule.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/7/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Module used to describe behaviors & computations that don't fit into other, more specific Module types. When we a variable is created, a dictionary is saved to CoreData that contains all necessary information to configure the object for data reporting. When the persisted variable is accessed, the dictionary is used to configure the object appropriately.

import Foundation
import UIKit

class CustomModule: Module {
    
    override func getConfigureModuleLayoutObject() -> Dictionary<String, AnyObject> {
        var tempObject = super.getConfigureModuleLayoutObject() //obtain superclass' dict & ADD TO IT
        
        var alertMessage = Dictionary<String, [String: String]>() //1st key is section name, 2nd key is behavior/computation name (using the RAW_VALUE of the ENUM object!), value is a message for the alertController
        var messageForBehavior = Dictionary<String, String>()
        for behavior in customModuleBehaviors {
            messageForBehavior[behavior.rawValue] = behavior.getAlertMessageForVariable()
        }
        alertMessage[BMN_BehaviorsKey] = messageForBehavior
        var messageForComputation = Dictionary<String, String>()
        for computation in customModuleComputations {
            messageForComputation[computation.rawValue] = computation.getAlertMessageForVariable()
        }
        alertMessage[BMN_ComputationsKey] = messageForComputation
        tempObject[BMN_AlertMessageKey] = alertMessage //merge dictionaries
        return tempObject
    }
    
    private let customModuleBehaviors: [CustomModuleVariableTypes] = [CustomModuleVariableTypes.Behavior_CustomOptions, CustomModuleVariableTypes.Behavior_BinaryOptions, CustomModuleVariableTypes.Behavior_Counter, CustomModuleVariableTypes.Behavior_RangeScale]
    override func setBehaviors() -> [String]? { //dynamically assigns behaviors to list
        var behaviorTitles: [String] = []
        
        //(1) Set filters (i.e. exclude certain computations based on 'blockers' & 'locationInFlow'):
        var filteredTypes = Set<CustomModuleVariableTypes>() //set containing types to be filtered
        if let blocker = moduleBlocker {
            let filters = blocker.getFilteredTypesForModule(Modules.CustomModule)
            for filter in filters {
                if let enumValue = CustomModuleVariableTypes(rawValue: filter) {
                    filteredTypes.insert(enumValue)
                }
            }
        }
        
        //(2) Add items -> 'behaviors' array if they pass through filters:
        for behavior in customModuleBehaviors {
            if !(filteredTypes.contains(behavior)) { //exclude filtered varTypes
                behaviorTitles.append(behavior.rawValue)
            }
        }
        return behaviorTitles
    }
    
    private let customModuleComputations: [CustomModuleVariableTypes] = [CustomModuleVariableTypes.Computation_TimeDifference]
    override func setComputations() -> [String]? { //dynamically assigns computations to array
        var computationTitles: [String] = []
        
        //(1) Set filters (i.e. exclude certain computations based on 'blockers' & 'locationInFlow'):
        var filteredTypes = Set<CustomModuleVariableTypes>() //set containing types to be filtered
        if let blocker = moduleBlocker {
            let filters = blocker.getFilteredTypesForModule(Modules.CustomModule)
            for filter in filters {
                if let enumValue = CustomModuleVariableTypes(rawValue: filter) {
                    filteredTypes.insert(enumValue)
                }
            }
        }
        
        //(2) Add items -> 'computations' array if they pass through filters:
        for computation in customModuleComputations {
            if !(filteredTypes.contains(computation)) { //exclude filtered varTypes
                computationTitles.append(computation.rawValue)
            }
        }
        return computationTitles
    }
    
    private var variableType: CustomModuleVariableTypes? { //converts 'selectedFunctionality' (which contains the TV cell title string) -> an Enum object (for switch statements)
        get {
            if let selection = selectedFunctionality {
                return CustomModuleVariableTypes(rawValue: selection)
            }
            return nil
        }
    }
    
    //Custom DataEntryCell Configuration Variables:
    var options: [String]? //array of user-created options associated w/ the variable/prompt
    var multipleSelectionEnabled: Bool? //for a variable w/ options, checks if user is allowed to select MULTIPLE OPTIONS (if nil => FALSE)
    var rangeScaleParameters: (Int, Int, Int)? //(minimum, maximum, increment)
    var counterUniqueID: Int? //unique counter ID, used to match to 'Counter' CoreData object
    var variableIsTimeDifference: Bool = false //indicates that variable is TD
    
    // MARK: - Initializers
    
    override init(name: String) { //set-up init
        super.init(name: name)
        self.moduleTitle = Modules.CustomModule.rawValue //title specific to this class
    }
    
    override init(name: String, dict: [String: AnyObject]) { //CoreData initializer
        super.init(name: name, dict: dict)
        self.moduleTitle = Modules.CustomModule.rawValue //title specific to this class
        
        //Break down the dictionary depending on the variable's type key & reconstruct object:
        if let typeName = dict[BMN_VariableTypeKey] as? String, type = CustomModuleVariableTypes(rawValue: typeName) {
            self.selectedFunctionality = typeName //reset the variable's selectedFunctionality
            switch type { //configure according to 'variableType'
            case .Behavior_CustomOptions:
                if let opts = dict[BMN_CustomModule_OptionsKey] as? [String] {
                    self.options = opts
                    for opt in opts {
                        print("[CustomOptions] Option: '\(opt)'.")
                    }
                }
                if let multipleSelection = dict[BMN_CustomModule_CustomOptionsMultipleSelectionAllowedKey] as? Bool {
                    self.multipleSelectionEnabled = multipleSelection
                    print("[CustomOptions] Multiple Selection Enabled: \(multipleSelection).")
                }
            case .Behavior_BinaryOptions:
                if let opts = dict[BMN_CustomModule_OptionsKey] as? [String] {
                    self.options = opts
                    for opt in opts {
                        print("[BinaryVariable] Option: '\(opt)'.")
                    }
                }
            case .Behavior_Counter: //obtain the uniqueID (for matching -> external Counter object)
                if let id = dict[BMN_CustomModule_CounterUniqueIDKey] as? Int {
                    self.counterUniqueID = id
                    print("[Counter] Unique ID: \(id).")
                }
            case .Behavior_RangeScale:
                if let min = dict[BMN_CustomModule_RangeScaleMinimumKey] as? Int, max = dict[BMN_CustomModule_RangeScaleMaximumKey] as? Int, increment = dict[BMN_CustomModule_RangeScaleIncrementKey] as? Int {
                    self.rangeScaleParameters = (min, max, increment)
                    print("[RangeScale] Minimum: \(min). Maximum: \(max). Increment: \(increment).")
                }
            case .Computation_TimeDifference:
                if let indicator = dict[BMN_CustomModule_IsTimeDifferenceKey] as? Bool {
                    self.variableIsTimeDifference = indicator
                    print("[TimeDifference] Variable is a TD computation.")
                }
            }
        } else {
            print("[CustomModule > CoreData initializer] Error! Could not find a type for the object.")
        }
    }
    
    // MARK: - Variable Configuration
    
    internal override func setConfigurationOptionsForSelection() { //handles ALL configuration for ConfigOptionsVC - (1) Sets the 'options' value as needed; (2) Constructs the configuration TV cells if required; (3) Sets 'isAutoCaptured' var if var is auto-captured.
        print("Custom Module - setting configuration options for selection...")
        if let type = variableType { //make sure behavior/computation was selected & ONLY set the configOptionsObject if further configuration is required
            var array: [(ConfigurationOptionCellTypes, Dictionary<String, AnyObject>)] = [] //pass -> VC (CustomCellType, cell's dataSource)
            switch type {
            case CustomModuleVariableTypes.Behavior_CustomOptions:
                
                //3 config cells are needed (prompt + multiple selection + custom options):
                array.append((ConfigurationOptionCellTypes.SimpleText, [BMN_Configuration_CellDescriptorKey: BMN_CustomModule_CustomOptions_PromptID, BMN_LEVELS_CellIsOptionalKey: true, BMN_LEVELS_MainLabelKey: "Set a prompt (optional). Replaces the variable's name during data reporting:"])) //cell to accept prompt
                array.append((ConfigurationOptionCellTypes.SelectFromOptions, [BMN_Configuration_CellDescriptorKey: BMN_CustomModule_CustomOptions_MultipleSelectionAllowedID, BMN_LEVELS_MainLabelKey: "Allow multiple options to be selected (default NO):", BMN_SelectFromOptions_OptionsKey: ["YES", "NO"], BMN_SelectFromOptions_DefaultOptionsKey: ["NO"], BMN_SelectFromOptions_IsBooleanKey: true])) //cell to check whether multiple selection is allowed or not
                array.append((ConfigurationOptionCellTypes.CustomOptions, [BMN_Configuration_CellDescriptorKey: BMN_CustomModule_CustomOptions_OptionsID, BMN_LEVELS_MainLabelKey: "Enter 2 or more custom options for selection:"])) //cell to enter custom options
                configurationOptionsLayoutObject = array
                
            case CustomModuleVariableTypes.Behavior_BinaryOptions:
                
                //**Should we allow user to set a prompt for binary? And if so, do they set it immediately, or only if they click on the ProjectVarsTV cell?
                options = ["Yes", "No"] //set binary options
                configurationOptionsLayoutObject = nil //no further config needed
                
            case CustomModuleVariableTypes.Behavior_Counter:
                
                configurationOptionsLayoutObject = nil //no further config needed
                
            case CustomModuleVariableTypes.Behavior_RangeScale:
                
                //3 config cells are needed (asking for minimum, maximum, & increment):
                array.append((ConfigurationOptionCellTypes.SimpleNumber, [BMN_Configuration_CellDescriptorKey: BMN_CustomModule_RangeScale_MinimumID, BMN_LEVELS_MainLabelKey: "Minimum for scale (default 0):", BMN_Configuration_DefaultNumberKey: 0])) //minimum value
                array.append((ConfigurationOptionCellTypes.SimpleNumber, [BMN_Configuration_CellDescriptorKey: BMN_CustomModule_RangeScale_MaximumID, BMN_LEVELS_MainLabelKey: "Maximum for scale (default 10):", BMN_Configuration_DefaultNumberKey: 10])) //maximum value
                array.append((ConfigurationOptionCellTypes.SimpleNumber, [BMN_Configuration_CellDescriptorKey: BMN_CustomModule_RangeScale_IncrementID, BMN_LEVELS_MainLabelKey: "Increment for scale (default 1):", BMN_Configuration_DefaultNumberKey: 1])) //increment value
                
                configurationOptionsLayoutObject = array
                
            case CustomModuleVariableTypes.Computation_TimeDifference:
                
                configurationOptionsLayoutObject = nil //no further config needed
                self.isAutomaticallyCaptured = true //TD is auto-captured
                
            }
        } else { //no selection, set configOptionsObj -> nil
            configurationOptionsLayoutObject = nil
        }
    }
    
    internal override func matchConfigurationItemsToProperties(configurationData: [String: AnyObject]) -> (Bool, String?, [String]?) {
        //(1) Takes as INPUT the data that was entered into each config TV cell. (2) Given the variableType, matches configuration data -> properties in the Module object by accessing specific configuration cell identifiers (defined in 'HelperFx' > 'Dictionary Keys').
        if let type = variableType {
            switch type { //only needed for sections that require configuration
            case .Behavior_CustomOptions:
                
                self.cellPrompt = configurationData[BMN_CustomModule_CustomOptions_PromptID] as? String
                self.options = configurationData[BMN_CustomModule_CustomOptions_OptionsID] as? [String]
                if let boolSelection = (configurationData[BMN_CustomModule_CustomOptions_MultipleSelectionAllowedID] as? [String])?.first { //report type is [String]
                    if (boolSelection.lowercaseString == "yes") { //match "YES" -> true
                        self.multipleSelectionEnabled = true
                    } else if (boolSelection.lowercaseString == "no") { //match "NO" -> false
                        self.multipleSelectionEnabled = false
                    }
                }
                if (self.options != nil) && (self.multipleSelectionEnabled != nil) {
                    print("Match Config: Prompt = '\(cellPrompt)', Opts = \(options), Mult Selection = \(multipleSelectionEnabled).")
                    return (true, nil, nil)
                } else { //error
                    return (false, "Either the options or multiple selection indicator haven't been set.", nil)
                }
                
            case .Behavior_RangeScale: //inc data is INT
                
                if let min = (configurationData[BMN_CustomModule_RangeScale_MinimumID] as? Int), max = (configurationData[BMN_CustomModule_RangeScale_MaximumID] as? Int), increment = (configurationData[BMN_CustomModule_RangeScale_IncrementID] as? Int) {
                    if (min >= max) { //Check #1
                        return (false, "The minimum value must be LESS than the maximum value.", [BMN_CustomModule_RangeScale_MinimumID, BMN_CustomModule_RangeScale_MaximumID]) //flag min & max cells
                    } else if ((max - min)%increment != 0) { //Check #2 - increment must be perfectly divisible by the difference between min & max
                        return (false, "The increment must be divisible by the difference between the minimum and maximum.", [BMN_CustomModule_RangeScale_IncrementID]) //flag incrm
                    } else { //setup is OK
                        rangeScaleParameters = (min, max, increment)
                        print("Match Config: Min = \(min), Max = \(max), Inc = \(increment).")
                        return (true, nil, nil)
                    }
                } else {
                    return (false, "Could not obtain config info for range scale!", nil)
                }
                
            case .Computation_TimeDifference:
                print("time difference...")
                return (true, nil, nil)
            default:
                print("[CustomMod: matchConfigToProps] Error! Default in switch!")
                return (false, "Default in switch!", nil)
            }
        }
        return (false, "No selected functionality was found!", nil)
    }
    
    // MARK: - Core Data Logic
    
    internal override func createDictionaryForCoreDataStore() -> Dictionary<String, AnyObject> { //generates dictionary to be saved by CoreData (this dict allows FULL reconstruction of the object into a Module subclass). Each variable will occupy 1 spot in the overall dictionary, so we need to merge these individual dictionaries for each variable into 1 master dictionary. Each variable's dictionary will be indicated by the variable name, so MAKE SURE THERE ARE NO REPEAT NAMES!
        
        var persistentDictionary: [String: AnyObject] = super.createDictionaryForCoreDataStore()
        
        //Set the coreData dictionary ONLY with information pertaining to the 'selectedFunctionality':
        if let type = variableType {
            persistentDictionary[BMN_VariableTypeKey] = type.rawValue //save variable type
            switch type {
            case .Behavior_CustomOptions:
                if let prompt = self.cellPrompt { //check if user entered a prompt
                    persistentDictionary[BMN_DataEntry_MainLabelPromptKey] = prompt
                }
                if let opts = self.options { //make sure there are options
                    persistentDictionary[BMN_CustomModule_OptionsKey] = opts
                }
                if let multipleSelect = multipleSelectionEnabled { //check if multiple selection allowed
                    persistentDictionary[BMN_CustomModule_CustomOptionsMultipleSelectionAllowedKey] = multipleSelect
                }
            case .Behavior_BinaryOptions:
                if let opts = self.options { //make sure there are options
                    persistentDictionary[BMN_CustomModule_OptionsKey] = opts
                }
            case .Behavior_RangeScale:
                if let (min, max, increment) = self.rangeScaleParameters {
                    persistentDictionary[BMN_CustomModule_RangeScaleMinimumKey] = min
                    persistentDictionary[BMN_CustomModule_RangeScaleMaximumKey] = max
                    persistentDictionary[BMN_CustomModule_RangeScaleIncrementKey] = increment
                }
            case .Behavior_Counter:
                if let id = counterUniqueID {
                    persistentDictionary[BMN_CustomModule_CounterUniqueIDKey] = id
                } else {
                    print("[CustomMod createCoreDataDict] Fatal Error - counter has no uniqueID.")
                    abort()
                }
            case .Computation_TimeDifference: //indicate var is TimeDifference
                persistentDictionary[BMN_CustomModule_IsTimeDifferenceKey] = variableIsTimeDifference
            }
        }
        return persistentDictionary
    }
    
    // MARK: - Data Entry Logic
    
    func getTypeForVariable() -> CustomModuleVariableTypes? { //used by DataEntry TV cells as safety check
        return self.variableType
    }
    
    override func getDataEntryCellTypeForVariable() -> DataEntryCellTypes? { //indicates to DataEntryVC what kind of DataEntry cell should be used for this variable
        if let type = self.variableType {
            switch type {
            case .Behavior_CustomOptions, .Behavior_BinaryOptions:
                return DataEntryCellTypes.CustomWithOptions
            case .Behavior_Counter:
                return DataEntryCellTypes.CustomWithCounter
            case .Behavior_RangeScale:
                return DataEntryCellTypes.CustomWithRangeScale
            default:
                return nil
            }
        }
        return nil
    }
    
    override var cellHeightUserInfo: [String : AnyObject]? {
        if let opts = options { //return the # of options cells that are present (VC adds 1 lvl per opt)
            if (variableType == CustomModuleVariableTypes.Behavior_BinaryOptions) { //BINARY layout
                return [BMN_DataEntry_CustomWithOptions_NumberOfOptionsKey: 1] //only need 1 lvl
            } else {
                return [BMN_DataEntry_CustomWithOptions_NumberOfOptionsKey: opts.count]
            }
        }
        return nil
    }
    
}

enum CustomModuleVariableTypes: String { //*match each behavior/computation -> Configuration + DataEntry custom TV cells; for each new behavior/computation added, you must also add (1) Configuration logic, (2) Core Data storage logic (so the variable config can be preserved), (3) Unpacking logic (in the DataEntry initializer), & (4) DataEntry logic (enabling the user to report info).* 
    //*BEHAVIORS*:
    case Behavior_CustomOptions = "Custom Options" //allows user to enter custom options
    case Behavior_BinaryOptions = "Binary Options" //automatically creates 2 options, 'Yes' & 'No'.
    case Behavior_Counter = "Counter" //creates an incrementable counter
    case Behavior_RangeScale = "Range Scale" //gives users the option to select a value on a scale from A - B, where the user selects what the lower & upper limits are when they adopt this behavior; in data entry mode, the user will then select a value from this range using a slider/picker (TBD).
    
    //*COMPUTATIONS*:
    case Computation_TimeDifference = "Time Difference" //automatically generates a variable which will obtain a time difference between the report time for IVs & OMs (no configuration needed). There can only be 1 per project & it is ALWAYS set as an OM (calculated just before final dataObject is constructed & sent -> DB).
    
    func getAlertMessageForVariable() -> String { //provides an informative pop-up about the behavior
        var message = ""
        switch self {
        case .Behavior_CustomOptions:
            message = "Create custom selection options."
        case .Behavior_BinaryOptions:
            message = "A binary configuration offers two options - 'Yes' and 'No'. Useful for variables with only two possibilities."
        case .Behavior_Counter:
            message = "A counter that allows you to keep track of how many times something has occurred."
        case .Behavior_RangeScale:
            message = "A scale allows you to pick an integer value between the minimum and the maximum value that you set."
        case .Computation_TimeDifference:
            message = "Calculates the time difference between reporting the input variables & reporting the output variables (equivalent to the duration of the action)."
        }
        return message
    }
    
}