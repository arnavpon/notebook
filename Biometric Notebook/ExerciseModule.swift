//  ExerciseModule.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/7/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Module for capturing Weight Training & Cardio exercise statistics such as weight lifted, calories burned, distance moved, etc.

import Foundation

class ExerciseModule: Module {
    
    override func getConfigureModuleLayoutObject() -> Dictionary<String, AnyObject> {
        var tempObject = super.getConfigureModuleLayoutObject() //obtain superclass' dict & ADD TO IT
        
        var alertMessage = Dictionary<String, [String: String]>() //1st key is section name, 2nd key is behavior/computation name (using the RAW_VALUE of the ENUM object!), value is a message for the alertController
        var messageForBehavior = Dictionary<String, String>()
        for behavior in exerciseModuleBehaviors {
            messageForBehavior[behavior.rawValue] = behavior.getAlertMessageForVariable()
        }
        alertMessage[BMN_BehaviorsKey] = messageForBehavior
        var messageForComputation = Dictionary<String, String>()
        for computation in exerciseModuleComputations {
            messageForComputation[computation.rawValue] = computation.getAlertMessageForVariable()
        }
        alertMessage[BMN_ComputationsKey] = messageForComputation
        tempObject[BMN_AlertMessageKey] = alertMessage //merge dictionaries
        
        return tempObject
    }
    
    private let exerciseModuleBehaviors: [ExerciseModuleVariableTypes] = [ExerciseModuleVariableTypes.Behavior_Workout]
    override func setBehaviors() -> [String]? { //dynamically assigns behaviors to list
        var behaviorTitles: [String] = []
        
        //(1) Set filters (i.e. exclude certain computations based on 'blockers' & 'locationInFlow'):
        var filteredTypes = Set<ExerciseModuleVariableTypes>() //set containing types to be filtered
        if let blocker = moduleBlocker {
            let filters = blocker.getFilteredTypesForModule(Modules.ExerciseModule)
            for filter in filters {
                if let enumValue = ExerciseModuleVariableTypes(rawValue: filter) {
                    filteredTypes.insert(enumValue)
                }
            }
        }
        
        //(2) Add items -> 'behaviors' array if they pass through filters:
        for behavior in exerciseModuleBehaviors {
            if !(filteredTypes.contains(behavior)) { //exclude filtered varTypes
                behaviorTitles.append(behavior.rawValue)
            }
        }
        return behaviorTitles
    }
    
    private let exerciseModuleComputations: [ExerciseModuleVariableTypes] = []
    override func setComputations() -> [String]? { //dynamically assigns comps to list
        var computationTitles: [String] = []
        
        //(1) Set filters (i.e. exclude certain computations based on 'blockers' & 'locationInFlow'):
        var filteredTypes = Set<ExerciseModuleVariableTypes>() //set containing types to be filtered
        if let blocker = moduleBlocker {
            let filters = blocker.getFilteredTypesForModule(Modules.ExerciseModule)
            for filter in filters {
                if let enumValue = ExerciseModuleVariableTypes(rawValue: filter) {
                    filteredTypes.insert(enumValue)
                }
            }
        }
        
        //(2) Add items -> 'computations' array if they pass through filters:
        for computation in exerciseModuleComputations {
            if !(filteredTypes.contains(computation)) { //exclude filtered varTypes
                computationTitles.append(computation.rawValue)
            }
        }
        return computationTitles
    }
    
    private var variableType: ExerciseModuleVariableTypes? { //converts 'selectedFunctionality' (a String) to an enum object
        get {
            if let selection = selectedFunctionality {
                return ExerciseModuleVariableTypes(rawValue: selection)
            }
            return nil
        }
    }
    
    //DataEntryCell Configuration Variables:
    private var dayOfWeek: String?
    private var exercises: [[String: AnyObject]]? //matches config cell return object
    
    // MARK: - Initializers
    
    override init(name: String) { //set-up init
        super.init(name: name)
        self.moduleTitle = Modules.ExerciseModule.rawValue
    }
    
    override init(name: String, dict: [String: AnyObject]) { //CoreData init
        super.init(name: name, dict: dict)
        self.moduleTitle = Modules.ExerciseModule.rawValue
        
        //Break down the dictionary depending on the variable's type key & reconstruct object:
        if let typeName = dict[BMN_VariableTypeKey] as? String, type = ExerciseModuleVariableTypes(rawValue: typeName) {
            self.selectedFunctionality = typeName //reset the variable's selectedFunctionality
            switch type { //configure according to 'variableType'
            case .Behavior_Workout:
                self.dayOfWeek = dict[BMN_ExerciseModule_WorkoutDayOfWeekKey] as? String
                self.exercises = dict[BMN_ExerciseModule_WorkoutExercisesKey] as? [[String: AnyObject]]
                
                self.FreeformCell_configurationObject = [] //initialize
                FreeformCell_configurationObject!.append((nil, ProtectedFreeformTypes.Decimal, nil, 6, (0, 999), nil)) //for WeightTraining, ...
                self.cellPrompt = "Fill in after completing exercise:" //mainLbl for cell
            case .Behavior_BeforeAndAfter:
                break
            }
        }
    }
    
    override func copyWithZone(zone: NSZone) -> AnyObject { //creates copy of variable
        let copy = ExerciseModule(name: self.variableName)
        copy.existingVariables = self.existingVariables
        copy.moduleBlocker = self.moduleBlocker
        return copy
    }
    
    // MARK: - Variable Configuration
    
    internal override func setConfigurationOptionsForSelection() {
        if let type = variableType { //make sure behavior/computation was selected & ONLY set the configOptionsObject if further configuration is required
            var array: [(ConfigurationOptionCellTypes, Dictionary<String, AnyObject>)] = [] //pass -> VC (CustomCellType, cell's dataSource)
            switch type {
            case .Behavior_Workout:
                
                //2 config cells are needed (day of week + workout configuration):
                let dayOptions = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
                array.append((ConfigurationOptionCellTypes.SelectFromDropdown, [BMN_Configuration_CellDescriptorKey: BMN_ExerciseModule_WorkoutDayOfWeekID, BMN_LEVELS_CellIsOptionalKey: true, BMN_LEVELS_MainLabelKey: "Assign this workout to a specific day of the week (optional):", BMN_SelectFromDropdown_OptionsKey: dayOptions])) //cell to set day of week
                array.append((ConfigurationOptionCellTypes.ExM_Workout, [BMN_Configuration_CellDescriptorKey: BMN_ExerciseModule_WorkoutExercisesID, BMN_LEVELS_MainLabelKey: "Add individual exercises to your workout in chronologic order:"])) //cell to add exercises
                configurationOptionsLayoutObject = array
                
            case .Behavior_BeforeAndAfter:
                
                configurationOptionsLayoutObject = nil //no further config needed
                
            }
        } else { //no selection, set configOptionsObj -> nil
            configurationOptionsLayoutObject = nil
        }
    }

    override func matchConfigurationItemsToProperties(configurationData: [String : AnyObject]) -> (Bool, String?, [String]?) {
        //(1) Takes as INPUT the data that was entered into each config TV cell. (2) Given the variableType, matches configuration data -> properties in the Module object by accessing specific configuration cell identifiers (defined in 'HelperFx' > 'Dictionary Keys').
        if let type = variableType {
            switch type { //only needed for sections that require configuration
            case .Behavior_Workout:
                
                self.dayOfWeek = configurationData[BMN_ExerciseModule_WorkoutDayOfWeekID] as? String
                if let exerciseList = configurationData[BMN_ExerciseModule_WorkoutExercisesID] as? [[String: AnyObject]] {
                    print("\(exerciseList.count) exercises were added to the workout.")
                    for item in exerciseList {
                        print("NAME = \(item["name"]). SETS = \(item["sets"]).")
                    }
                    self.exercises = exerciseList
                    return (true, nil, nil)
                }
                
            default:
                print("[CustomMod: matchConfigToProps] Error! Default in switch!")
                return (false, "Default in switch!", nil)
            }
        }
        return (false, "No selected functionality was found!", nil)
    }
    
    // MARK: - Core Data Logic
    
    internal override func createDictionaryForCoreDataStore() -> Dictionary<String, AnyObject> {
        var persistentDictionary: [String: AnyObject] = super.createDictionaryForCoreDataStore()
        
        //Set the coreData dictionary ONLY with information pertaining to the 'selectedFunctionality':
        if let type = variableType {
            persistentDictionary[BMN_VariableTypeKey] = type.rawValue //save variable type
            switch type {
            case .Behavior_Workout: //store the day of week + exercises/settings for each exercise
                persistentDictionary[BMN_ExerciseModule_WorkoutDayOfWeekKey] = dayOfWeek
                persistentDictionary[BMN_ExerciseModule_WorkoutExercisesKey] = exercises
            case .Behavior_BeforeAndAfter:
                break
            }
        }
        return persistentDictionary
    }
    
    // MARK: - Data Entry Logic
    
    override func getDataEntryCellTypeForVariable() -> DataEntryCellTypes? { //indicates to DataEntryVC what kind of DataEntry cell should be used for this variable
        if let type = self.variableType {
            switch type {
            case .Behavior_Workout:
                return DataEntryCellTypes.Freeform
            default:
                return nil
            }
        }
        return nil
    }
    
}

enum ExerciseModuleVariableTypes: String { //*match each behavior/computation -> Configuration + DataEntry custom TV cells; for each new behavior/computation added, you must also add (1) Configuration logic, (2) Core Data storage logic (so the variable config can be preserved), (3) Unpacking logic (in the DataEntry initializer), & (4) DataEntry logic (enabling the user to report info).* 
    //Available Behaviors:
    case Behavior_Workout = "Workout" //a workout variable contains the list of associated Weight Training & Cardio exercises making up the complete workout
    case Behavior_BeforeAndAfter = "ExM_behavior_BeforeAfterPicture" //'Before & After' allows user to take picture & save.
    
    //Available Computations:
    
    func getAlertMessageForVariable() -> String {
        var message = ""
        switch self {
        case .Behavior_Workout:
            message = "A workout variable contains a group of exercises making up a single, complete workout."
        case .Behavior_BeforeAndAfter:
            message = ""
        }
        return message
    }
    
}