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
    
    private let customModuleBehaviors: [CustomModuleVariableTypes] = [CustomModuleVariableTypes.Behavior_CustomOptions, CustomModuleVariableTypes.Behavior_BinaryOptions, CustomModuleVariableTypes.Behavior_Counter, CustomModuleVariableTypes.Behavior_RangeScale, CustomModuleVariableTypes.Behavior_Timing]
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
        var filteredSubtypes = Set<TimeDifference_VariableTypes>() //SUB-types to be filtered
        if let blocker = moduleBlocker { //create a sub-type filter for TD vars (block DistFromAction)
            let filters = blocker.getFilteredTypesForModule(Modules.CustomModule)
            for filter in filters {
                if let enumValue = TimeDifference_VariableTypes(rawValue: filter) {
                    filteredSubtypes.insert(enumValue)
                }
            }
        }
        let tdSubtypes = [TimeDifference_VariableTypes.DistanceFromAction] //list of TD subtypes
        var tdOpts: [String] = [] //used by ConfigOptions object
        for subtype in tdSubtypes {
            if !(filteredSubtypes.contains(subtype)) { //exclude filtered var subtypes
                tdOpts.append(subtype.rawValue)
            }
        }
        if (tdOpts.isEmpty) { //if no TD options remain, filter out TD computation
            filteredTypes.insert(CustomModuleVariableTypes.Computation_TimeDifference)
        }
        
        for computation in customModuleComputations { //set final array for display
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
    var timeDifferenceSetup: (TimeDifference_VariableTypes, (Int, Int)?)? //(type, (pointA, pointB)?); point A & B correspond to locations in the measurement cycle
    
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
                }
                if let multipleSelection = dict[BMN_CustomModule_CustomOptionsMultipleSelectionAllowedKey] as? Bool {
                    self.multipleSelectionEnabled = multipleSelection
                }
            case .Behavior_BinaryOptions:
                if let opts = dict[BMN_CustomModule_OptionsKey] as? [String] {
                    self.options = opts
                }
            case .Behavior_Counter: //obtain the uniqueID (for matching -> external Counter object)
                if let id = dict[BMN_CustomModule_CounterUniqueIDKey] as? Int {
                    self.counterUniqueID = id
                }
            case .Behavior_RangeScale:
                if let min = dict[BMN_CustomModule_RangeScaleMinimumKey] as? Int, max = dict[BMN_CustomModule_RangeScaleMaximumKey] as? Int, increment = dict[BMN_CustomModule_RangeScaleIncrementKey] as? Int {
                    self.rangeScaleParameters = (min, max, increment)
                }
            case .Behavior_Timing: //set the freeform cell configObject
                self.FreeformCell_configurationObject = [] //initialize
                FreeformCell_configurationObject!.append((nil, ProtectedFreeformTypes.Timing, nil, 11, nil, "HH:MM:SS.ms")) //lone view for timing entry; no label/default/bounding (b/c of unique timing format), character limit = 11 (HH:MM:SS.ms)
                self.cellPrompt = "Enter the timing in the format HH:MM:SS.ms (e.g. 01:10:05.344):" //add prompt for cell
            case .Computation_TimeDifference:
                if let typeRaw = dict[BMN_CustomModule_TimeDifferenceTypeKey] as? String, tdType = TimeDifference_VariableTypes(rawValue: typeRaw) {
                    if let loc1 = dict[BMN_CustomModule_TimeDifferenceLocation1Key] as? Int, loc2 = dict[BMN_CustomModule_TimeDifferenceLocation2Key] as? Int { //DEFAULT type
                        self.timeDifferenceSetup = (tdType, (loc1, loc2))
                        print("[TimeDifference] Variable is a TD of type [\(typeRaw)] between loc [\(loc1)] & loc [\(loc2)] in cycle.")
                    } else { //NOT default type
                        self.timeDifferenceSetup = (tdType, nil)
                        print("[TimeDifference] Variable is a TD of type \(typeRaw).")
                    }
                }
            }
        } else {
            print("[CustomModule > CoreData initializer] Error! Could not find a type for the object.")
        }
    }
    
    init(timeDifferenceName: String, locations: (Int, Int), configType: ModuleConfigurationTypes) { //external TD init
        super.init(name: timeDifferenceName)
        self.moduleTitle = Modules.CustomModule.rawValue //set title
        self.selectedFunctionality = CustomModuleVariableTypes.Computation_TimeDifference.rawValue
        self.configurationType = configType //set config type (IV or OM)
        self.variableReportType = .TimeDifference //mark as time-diff report type
        self.timeDifferenceSetup = (.Default, locations)
    }
    
    override func copyWithZone(zone: NSZone) -> AnyObject { //creates copy of variable
        let copy = CustomModule(name: self.variableName)
        copy.existingVariables = self.existingVariables
        copy.moduleBlocker = self.moduleBlocker
        copy.configurationType = self.configurationType
        return copy
    }
    
    // MARK: - Variable Configuration
    
    internal override func setConfigurationOptionsForSelection() { //handles ALL configuration for ConfigOptionsVC - (1) Sets the 'options' value as needed; (2) Constructs the configuration TV cells if required; (3) Sets 'isAutoCaptured' var if var is auto-captured.
        super.setConfigurationOptionsForSelection() //set superclass config info
        if (configurationOptionsLayoutObject == nil) {
            configurationOptionsLayoutObject = [] //initialize
        }
        if let type = variableType { //make sure behavior/computation was selected & ONLY set the configOptionsObject if further configuration is required
            var array: [(ConfigurationOptionCellTypes, Dictionary<String, AnyObject>)] = [] //pass -> VC (CustomCellType, cell's dataSource)
            switch type {
            case .Behavior_CustomOptions:
                
                //3 config cells are needed (prompt + multiple selection + custom options):
                array.append((ConfigurationOptionCellTypes.SimpleText, [BMN_Configuration_CellDescriptorKey: BMN_CustomModule_CustomOptions_PromptID, BMN_LEVELS_CellIsOptionalKey: true, BMN_LEVELS_MainLabelKey: "Set a prompt (optional). Replaces the variable's name during data reporting:"])) //cell to accept prompt
                array.append((ConfigurationOptionCellTypes.SelectFromOptions, [BMN_Configuration_CellDescriptorKey: BMN_CustomModule_CustomOptions_MultipleSelectionAllowedID, BMN_LEVELS_MainLabelKey: "Allow multiple options to be selected (default NO):", BMN_SelectFromOptions_OptionsKey: ["YES", "NO"], BMN_SelectFromOptions_DefaultOptionsKey: ["NO"], BMN_SelectFromOptions_IsBooleanKey: true])) //cell to check whether multiple selection is allowed or not
                array.append((ConfigurationOptionCellTypes.CustomOptions, [BMN_Configuration_CellDescriptorKey: BMN_CustomModule_CustomOptions_OptionsID, BMN_LEVELS_MainLabelKey: "Enter 2 or more custom options for selection:"])) //cell to enter custom options
                configurationOptionsLayoutObject!.appendContentsOf(array)
                
            case .Behavior_BinaryOptions:
                
                options = ["Yes", "No"] //set binary options
                array.append((ConfigurationOptionCellTypes.SimpleText, [BMN_Configuration_CellDescriptorKey: BMN_CustomModule_CustomOptions_PromptID, BMN_LEVELS_CellIsOptionalKey: true, BMN_LEVELS_MainLabelKey: "Set a prompt (optional). Replaces the variable's name during data reporting:"])) //cell to accept prompt
                configurationOptionsLayoutObject!.appendContentsOf(array)
                
            case .Behavior_Counter:
                
                configurationOptionsLayoutObject!.appendContentsOf(array)
                
            case .Behavior_RangeScale:
                
                //3 config cells are needed (asking for minimum, maximum, & increment):
                array.append((ConfigurationOptionCellTypes.SimpleNumber, [BMN_Configuration_CellDescriptorKey: BMN_CustomModule_RangeScale_MinimumID, BMN_LEVELS_MainLabelKey: "Minimum for scale (default 0):", BMN_SimpleNumberConfigCell_DefaultKey: 0])) //minimum value
                array.append((ConfigurationOptionCellTypes.SimpleNumber, [BMN_Configuration_CellDescriptorKey: BMN_CustomModule_RangeScale_MaximumID, BMN_LEVELS_MainLabelKey: "Maximum for scale (default 10):", BMN_SimpleNumberConfigCell_DefaultKey: 10])) //maximum value
                array.append((ConfigurationOptionCellTypes.SimpleNumber, [BMN_Configuration_CellDescriptorKey: BMN_CustomModule_RangeScale_IncrementID, BMN_LEVELS_MainLabelKey: "Increment for scale (default 1):", BMN_SimpleNumberConfigCell_DefaultKey: 1])) //increment value
                
                configurationOptionsLayoutObject!.appendContentsOf(array)
                
            case .Behavior_Timing:
                
                configurationOptionsLayoutObject!.appendContentsOf(array)
                
            case .Computation_TimeDifference: //exclude DistanceFromAction if it is in blocker
                
                let opts = [TimeDifference_VariableTypes.DistanceFromAction.rawValue]
                array.append((ConfigurationOptionCellTypes.SelectFromOptions, [BMN_Configuration_CellDescriptorKey: BMN_CustomModule_TimeDifferenceTypeID, BMN_LEVELS_MainLabelKey: "Select the time difference variable type:", BMN_SelectFromOptions_OptionsKey: opts, BMN_SelectFromOptions_DefaultOptionsKey: [opts.first!]])) //cell to select TD type
                configurationOptionsLayoutObject = array
                
            }
        } else { //no selection, set configOptionsObj -> nil
            configurationOptionsLayoutObject = nil
        }
    }
    
    internal override func matchConfigurationItemsToProperties(configurationData: [String: AnyObject]) -> (Bool, String?, [String]?) {
        //(1) Takes as INPUT the data that was entered into each config TV cell. (2) Given the variableType, matches configuration data -> properties in the Module object by accessing specific configuration cell identifiers (defined in 'HelperFx' > 'Dictionary Keys').
        let superclassReturnVal = super.matchConfigurationItemsToProperties(configurationData)
        if (superclassReturnVal.0 == false) { //if checks are failed @ superclass lvl, return super obj
            return superclassReturnVal
        }
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
                
            case .Behavior_BinaryOptions:
                
                self.cellPrompt = configurationData[BMN_CustomModule_CustomOptions_PromptID] as? String
                return (true, nil, nil)
                
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
                if let typeArray = configurationData[BMN_CustomModule_TimeDifferenceTypeID] as? [String], typeRaw = typeArray.first, tdType = TimeDifference_VariableTypes(rawValue: typeRaw) {
                    print("Time difference variable...")
                    self.timeDifferenceSetup = (tdType, nil)
                    self.variableReportType = ModuleVariableReportTypes.TimeDifference //set report type
                    return (true, nil, nil)
                }
            default:
                return (true, nil, nil)
            }
        }
        return (false, "No selected functionality was found!", nil)
    }
    
    override func specialTypeForDynamicConfigFramework() -> String? {
        if let type = self.getTypeForVariable() {
            switch type {
            case .Computation_TimeDifference:
                if (self.timeDifferenceSetup?.0 == TimeDifference_VariableTypes.DistanceFromAction) {
                    print("[var {\(self.variableName)}] Setting special type [\(TimeDifference_VariableTypes.DistanceFromAction.rawValue)] for DCF...")
                    return TimeDifference_VariableTypes.DistanceFromAction.rawValue
                }
            default:
                break
            }
        }
        return nil
    }
    
    // MARK: - Core Data Logic
    
    internal override func createDictionaryForCoreDataStore() -> Dictionary<String, AnyObject> { //generates dictionary to be saved by CoreData (this dict allows FULL reconstruction of the object into a Module subclass). Each variable will occupy 1 spot in the overall dictionary, so we need to merge these individual dictionaries for each variable into 1 master dictionary. Each variable's dictionary will be indicated by the variable name, so MAKE SURE THERE ARE NO REPEAT NAMES!
        var persistentDictionary: [String: AnyObject] = super.createDictionaryForCoreDataStore()
        
        //Set the coreData dictionary ONLY with information pertaining to the 'selectedFunctionality':
        if let type = variableType {
            persistentDictionary[BMN_VariableTypeKey] = type.rawValue //save variable type
            switch type {
            case .Behavior_CustomOptions, .Behavior_BinaryOptions:
                if let opts = self.options { //make sure there are options
                    persistentDictionary[BMN_CustomModule_OptionsKey] = opts
                }
                if let multipleSelect = multipleSelectionEnabled { //check if multiple selection allowed
                    persistentDictionary[BMN_CustomModule_CustomOptionsMultipleSelectionAllowedKey] = multipleSelect
                }
            case .Behavior_Counter:
                if let id = counterUniqueID {
                    persistentDictionary[BMN_CustomModule_CounterUniqueIDKey] = id
                } else {
                    print("[CustomMod-createCoreDataDict] Fatal Error - counter has no uniqueID.")
                    abort()
                }
            case .Behavior_RangeScale:
                if let (min, max, increment) = self.rangeScaleParameters {
                    persistentDictionary[BMN_CustomModule_RangeScaleMinimumKey] = min
                    persistentDictionary[BMN_CustomModule_RangeScaleMaximumKey] = max
                    persistentDictionary[BMN_CustomModule_RangeScaleIncrementKey] = increment
                }
            case .Behavior_Timing: //prompt is stored by superclass so nothing to store
                break
            case .Computation_TimeDifference: //store TD type & locations
                if let setup = timeDifferenceSetup {
                    persistentDictionary[BMN_CustomModule_TimeDifferenceTypeKey] = setup.0.rawValue
                    if let (loc1, loc2) = setup.1 { //DEFAULT type - store locations
                        persistentDictionary[BMN_CustomModule_TimeDifferenceLocation1Key] = loc1
                        persistentDictionary[BMN_CustomModule_TimeDifferenceLocation2Key] = loc2
                    }
                    if (setup.0 == TimeDifference_VariableTypes.Default) { //default TD has no location
                        persistentDictionary[BMN_VariableReportLocationsKey] = nil //remove location
                    }
                }
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
            case .Behavior_Timing:
                return DataEntryCellTypes.Freeform
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
        } else if let configObject = FreeformCell_configurationObject {
            return [BMN_DataEntry_FreeformCell_NumberOfViewsKey: configObject.count]
        }
        return nil
    }
    
    override func performConversionOnUserEnteredData(input: AnyObject) -> AnyObject? {
        if let type = self.variableType {
            switch type {
            case .Behavior_Timing: //convert input value (HH:MM:SS.ms) -> # of seconds
                if let times = input as? [NSString], timeAsString = times.first {
                    let count = timeAsString.length
                    if let hours = Double(timeAsString.substringWithRange(NSRange.init(location: 0, length: 2))), minutes = Double(timeAsString.substringWithRange(NSRange.init(location: 3, length: 2))), seconds = Double(timeAsString.substringWithRange(NSRange.init(location: 6, length: (count - 6)))) {
                        return (hours * 3600 + minutes * 60 + seconds)
                    }
                }
            default:
                break
            }
        }
        return nil
    }
    
    // MARK: - Data Aggregation
    
    override func reportDataForVariable() -> [String : AnyObject]? {
        var returnObject = super.reportDataForVariable() //grab superclass obj first
        if let opts = self.options { //for vars w/ LIST{Py}/ARRAY{Sw} type mainDataObjects (custom & binary), ALL available options must be passed -> DB for table creation
            returnObject?.updateValue(opts, forKey: BMN_Module_OptionsForListKey)
        }
        return returnObject
    }
    
}

enum CustomModuleVariableTypes: String { //*match each behavior/computation -> Configuration + DataEntry custom TV cells; for each new behavior/computation added, you must also add (1) Configuration logic, (2) Core Data storage logic (so the variable config can be preserved), (3) Unpacking logic (in the DataEntry initializer), & (4) DataEntry logic (enabling the user to report info).* 
    //*BEHAVIORS*:
    case Behavior_CustomOptions = "Custom Options" //allows user to enter custom options
    case Behavior_BinaryOptions = "Binary Options" //automatically creates 2 options, 'Yes' & 'No'.
    case Behavior_Counter = "Counter" //creates an incrementable counter
    case Behavior_RangeScale = "Range Scale" //gives users the option to select a value on a scale from A - B, where the user selects what the lower & upper limits are when they adopt this behavior; in data entry mode, the user will then select a value from this range using a slider/picker (TBD).
    case Behavior_Timing = "Timing" //allows users to enter a time measurement
    
    //*COMPUTATIONS*:
    case Computation_TimeDifference = "Time Difference" //automatically generates a variable which will obtain a time difference between the report timestamp for the 2 user-selected portions of the measurement cycle. **There can only be 1 per project & it is ALWAYS set as an OM (calculated just before final dataObject is constructed & sent -> DB).
    
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
        case .Behavior_Timing:
            message = "Allows you to enter a timing in the format HH:MM:SS."
        case .Computation_TimeDifference:
            message = "Calculates the time difference between two portions of the measurement cycle."
        }
        return message
    }
    
}

enum TimeDifference_VariableTypes: String {
    case DistanceFromAction = "Distance From Action" //measures TD between action & current time
    case Default = "Default" //defer configuration of default TD variable
}

//                array.append((ConfigurationOptionCellTypes.TimeDifference, [BMN_Configuration_CellDescriptorKey: "", BMN_LEVELS_MainLabelKey: "Select the two portions of the measurement cycle between which to measure the time difference:"])) //time difference logic**