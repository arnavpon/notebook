//  FoodIntakeModule.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/7/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Module for inputting food intake data & computing calorific consumption & nutritional intake.

import Foundation

class FoodIntakeModule: Module {
    
    override func getConfigureModuleLayoutObject() -> Dictionary<String, AnyObject> {
        var tempObject = super.getConfigureModuleLayoutObject() //obtain superclass' dict & ADD TO IT
        
        var alertMessage = Dictionary<String, [String: String]>() //1st key is section name, 2nd key is behavior/computation name (using the RAW_VALUE of the ENUM object!), value is a message for the alertController
        var messageForBehavior = Dictionary<String, String>()
        for behavior in foodIntakeModuleBehaviors {
            messageForBehavior[behavior.rawValue] = behavior.getAlertMessageForVariable()
        }
        alertMessage[BMN_BehaviorsKey] = messageForBehavior
        var messageForComputation = Dictionary<String, String>()
        for computation in foodIntakeModuleComputations {
            messageForComputation[computation.rawValue] = computation.getAlertMessageForVariable()
        }
        alertMessage[BMN_ComputationsKey] = messageForComputation
        tempObject[BMN_AlertMessageKey] = alertMessage //merge dictionaries
        
        return tempObject
    }
    
    private let foodIntakeModuleBehaviors: [FoodIntakeModuleVariableTypes] = [FoodIntakeModuleVariableTypes.Behavior_FoodIntake]
    override func setBehaviors() -> [String]? {
        var behaviorTitles: [String] = []
        
        //(1) Set filters (i.e. exclude certain computations based on 'blockers' & 'locationInFlow'):
        var filteredTypes = Set<FoodIntakeModuleVariableTypes>() //set containing types to be filtered
        if let blocker = moduleBlocker {
            let filters = blocker.getFilteredTypesForModule(Modules.FoodIntakeModule)
            for filter in filters {
                if let enumValue = FoodIntakeModuleVariableTypes(rawValue: filter) {
                    filteredTypes.insert(enumValue)
                }
            }
        }
        
        //(2) Add items -> 'behaviors' array if they pass through filters:
        for behavior in foodIntakeModuleBehaviors {
            if !(filteredTypes.contains(behavior)) { //exclude filtered varTypes
                behaviorTitles.append(behavior.rawValue)
            }
        }
        return behaviorTitles
    }
    
    private let foodIntakeModuleComputations: [FoodIntakeModuleVariableTypes] = []
    override func setComputations() -> [String]? {
        var computationTitles: [String] = []
        
        //(1) Set filters (i.e. exclude certain computations based on 'blockers' & 'locationInFlow'):
        var filteredTypes = Set<FoodIntakeModuleVariableTypes>() //set containing types to be filtered
        if let blocker = moduleBlocker {
            let filters = blocker.getFilteredTypesForModule(Modules.FoodIntakeModule)
            for filter in filters {
                if let enumValue = FoodIntakeModuleVariableTypes(rawValue: filter) {
                    filteredTypes.insert(enumValue)
                }
            }
        }
        
        //(2) Add items -> 'computations' array if they pass through filters:
        for computation in foodIntakeModuleComputations {
            if !(filteredTypes.contains(computation)) { //exclude filtered varTypes
                computationTitles.append(computation.rawValue)
            }
        }
        return computationTitles
    }
    
    private var variableType: FoodIntakeModuleVariableTypes? { //converts 'selectedFunctionality' (a String) to an enum object
        get {
            if let selection = selectedFunctionality {
                return FoodIntakeModuleVariableTypes(rawValue: selection)
            }
            return nil
        }
    }
    
    lazy var nutritionCategories: [FoodIntakeModule_NutritionCategories] = [] //set by the user - lists the categories of information that the user wants to store data for (e.g. Calories, Fat, etc.)
    var selectedDataStreamLocations: [FoodIntakeModule_DataStreamLocations]? //set by the user - indicates the portion(s) of the dataStream from which to pull data for this variable
    
    // MARK: - Initializers
    
    override init(name: String) { //set-up init
        super.init(name: name)
        self.moduleTitle = Modules.FoodIntakeModule.rawValue
    }
    
    override init(name: String, dict: [String: AnyObject]) { //CoreData init
        super.init(name: name, dict: dict)
        self.moduleTitle = Modules.FoodIntakeModule.rawValue
        
        if let typeName = dict[BMN_VariableTypeKey] as? String, type = FoodIntakeModuleVariableTypes(rawValue: typeName) {
            self.selectedFunctionality = typeName //reset the variable's selectedFunctionality
            switch type { //configure according to 'variableType'
            case .Behavior_FoodIntake:
                self.linkedDatastream = DatastreamIdentifiers.FIM_FoodIntake //*set indicator*
                if let categories = dict[BMN_FoodIntakeModule_NutritionCategoriesKey] as? [String] {
                    for categoryRaw in categories {
                        if let category = FoodIntakeModule_NutritionCategories(rawValue: categoryRaw) {
                            self.nutritionCategories.append(category)
                        }
                    }
                    print("[FoodIntake Init] # of saved categories = \(nutritionCategories.count).")
                }
                if let locations = dict[BMN_FoodIntakeModule_DataStreamLocationsKey] as? [String] {
                    self.selectedDataStreamLocations = [] //initialize
                    for locationRaw in locations {
                        if let location = FoodIntakeModule_DataStreamLocations(rawValue: locationRaw) {
                            self.selectedDataStreamLocations!.append(location)
                        }
                    }
                    print("[FoodIntake Init] Locations to access = \(selectedDataStreamLocations!).")
                }
            }
        }
    }
    
    init() { //DATASTREAM init
        super.init(name: "BMN_FIM_Datastream_DummyVariable")
        self.moduleTitle = Modules.FoodIntakeModule.rawValue
        self.selectedFunctionality = FoodIntakeModuleVariableTypes.Behavior_FoodIntake.rawValue
        self.linkedDatastream = DatastreamIdentifiers.FIM_FoodIntake //*set indicator*
    }
    
    override func copyWithZone(zone: NSZone) -> AnyObject { //creates copy of variable
        let copy = FoodIntakeModule(name: self.variableName)
        copy.existingVariables = self.existingVariables
        copy.moduleBlocker = self.moduleBlocker
        copy.configurationType = self.configurationType
        return copy
    }
    
    // MARK: - Variable Configuration
    
    internal override func setConfigurationOptionsForSelection() {
        if let type = variableType { //make sure behavior/computation was selected & ONLY set the configOptionsObject if further configuration is required
            var array: [(ConfigurationOptionCellTypes, Dictionary<String, AnyObject>)] = [] //pass -> VC (CustomCellType, cell's dataSource)
            switch type {
            case .Behavior_FoodIntake:
                
                //Set filters (exclude dataStream locations using ModuleBlocker class):
                let availableOptions = [FoodIntakeModule_DataStreamLocations.Full, FoodIntakeModule_DataStreamLocations.Breakfast, FoodIntakeModule_DataStreamLocations.Lunch, FoodIntakeModule_DataStreamLocations.Dinner, FoodIntakeModule_DataStreamLocations.Snack, FoodIntakeModule_DataStreamLocations.PreWorkout, FoodIntakeModule_DataStreamLocations.PostWorkout] //list of ALL options
                var filteredOptions: [String] = [] //used by ConfigOptions object
                
                var filteredTypes = Set<FoodIntakeModule_DataStreamLocations>()
                if let blocker = moduleBlocker {
                    let filters = blocker.getFilteredTypesForModule(Modules.FoodIntakeModule)
                    for filter in filters {
                        if let enumValue = FoodIntakeModule_DataStreamLocations(rawValue: filter) {
                            filteredTypes.insert(enumValue)
                        }
                    }
                }
                for option in availableOptions {
                    if !(filteredTypes.contains(option)) { //exclude filtered varTypes
                        filteredOptions.append(option.rawValue)
                    }
                }
                
                //(1) User must select which portions of the dataStream to pull data from:
                array.append((ConfigurationOptionCellTypes.SelectFromOptions, [BMN_Configuration_CellDescriptorKey: BMN_FoodIntakeModule_DataStreamLocationsKey, BMN_LEVELS_MainLabelKey: "Choose the meals for which you would like to include nutrition data:", BMN_SelectFromOptions_OptionsKey: filteredOptions, BMN_SelectFromOptions_MultipleSelectionEnabledKey: true]))
                
                //(2) User must select the nutrition categories of interest:
                let categories: [String] = [FoodIntakeModule_NutritionCategories.Calories.rawValue, FoodIntakeModule_NutritionCategories.Water.rawValue, FoodIntakeModule_NutritionCategories.Protein.rawValue, FoodIntakeModule_NutritionCategories.TotalSugar.rawValue, FoodIntakeModule_NutritionCategories.DietaryFiber.rawValue, FoodIntakeModule_NutritionCategories.TotalFat.rawValue, FoodIntakeModule_NutritionCategories.SaturatedFat.rawValue, FoodIntakeModule_NutritionCategories.MonounsaturatedFat.rawValue, FoodIntakeModule_NutritionCategories.PolyunsaturatedFat.rawValue, FoodIntakeModule_NutritionCategories.Cholesterol.rawValue, FoodIntakeModule_NutritionCategories.TransFat.rawValue, FoodIntakeModule_NutritionCategories.Calcium.rawValue, FoodIntakeModule_NutritionCategories.Iron.rawValue, FoodIntakeModule_NutritionCategories.Magnesium.rawValue, FoodIntakeModule_NutritionCategories.Potassium.rawValue, FoodIntakeModule_NutritionCategories.Phosphorus.rawValue, FoodIntakeModule_NutritionCategories.Sodium.rawValue, FoodIntakeModule_NutritionCategories.Zinc.rawValue, FoodIntakeModule_NutritionCategories.VitaminB1.rawValue, FoodIntakeModule_NutritionCategories.VitaminB2.rawValue, FoodIntakeModule_NutritionCategories.VitaminB3.rawValue, FoodIntakeModule_NutritionCategories.VitaminB6.rawValue, FoodIntakeModule_NutritionCategories.Folate.rawValue, FoodIntakeModule_NutritionCategories.VitaminB12.rawValue, FoodIntakeModule_NutritionCategories.VitaminC.rawValue, FoodIntakeModule_NutritionCategories.VitaminD.rawValue, FoodIntakeModule_NutritionCategories.VitaminA.rawValue, FoodIntakeModule_NutritionCategories.VitaminK.rawValue, FoodIntakeModule_NutritionCategories.VitaminE.rawValue, FoodIntakeModule_NutritionCategories.Caffeine.rawValue]
                array.append((ConfigurationOptionCellTypes.SelectFromOptions, [BMN_Configuration_CellDescriptorKey: BMN_FoodIntakeModule_NutritionCategoriesKey, BMN_LEVELS_MainLabelKey: "Select the nutrition categories for which you want to obtain data:", BMN_SelectFromOptions_OptionsKey: categories, BMN_SelectFromOptions_DefaultOptionsKey: [FoodIntakeModule_NutritionCategories.Calories.rawValue], BMN_SelectFromOptions_MultipleSelectionEnabledKey: true])) //nutrition categories, default is CALORIES
                
                configurationOptionsLayoutObject = array
        
            }
        }
    }
    
    override func matchConfigurationItemsToProperties(configurationData: [String : AnyObject]) -> (Bool, String?, [String]?) {
        let superclassReturnVal = super.matchConfigurationItemsToProperties(configurationData)
        if (superclassReturnVal.0 == false) { //if checks are failed @ superclass lvl, return super obj
            return superclassReturnVal
        }
        if let type = variableType {
            switch type {
            case .Behavior_FoodIntake: //obtain selected nutrition categories & add -> module property
                self.linkedDatastream = DatastreamIdentifiers.FIM_FoodIntake //set indicator
                if let rawCategorySelections = configurationData[BMN_FoodIntakeModule_NutritionCategoriesKey] as? [String] {
                    self.nutritionCategories = [] //clear array
                    for selection in rawCategorySelections {
                        if let category = FoodIntakeModule_NutritionCategories(rawValue: selection) {
                            nutritionCategories.append(category)
                        }
                    }
                } else {
                    return (false, "No categories were selected!", nil)
                }
                if let rawStreamLocations = configurationData[BMN_FoodIntakeModule_DataStreamLocationsKey] as? [String] { //get user-selected dataStream locations
                    self.selectedDataStreamLocations = [] //initialize
                    for location in rawStreamLocations {
                        if let dataStreamLocation = FoodIntakeModule_DataStreamLocations(rawValue: location) {
                            if (dataStreamLocation == .Full) { //selection of 'Full' overrides everything
                                selectedDataStreamLocations = [FoodIntakeModule_DataStreamLocations.Full]
                                return (true, nil, nil) //*terminate fx @ this point*
                            } else {
                                selectedDataStreamLocations!.append(dataStreamLocation)
                            }
                        }
                    }
                } else {
                    return (false, "No data stream locations!", nil)
                }
                return (true, nil, nil)
            }
        }
        return (false, "No option was selected!", nil)
    }
    
    override func specialTypeForDynamicConfigFramework() -> [String]? {
        if let type = self.getTypeForVariable() {
            switch type {
            case .Behavior_FoodIntake: //return ALL of the selected locations in the dataStream -> blocker
                if let dataStreamLocations = selectedDataStreamLocations {
                    var specialTypes: [String] = []
                    for location in dataStreamLocations {
                        specialTypes.append(location.rawValue)
                    }
                    print("[var {\(self.variableName)}] Setting special type(s) [\(specialTypes)]...")
                    return specialTypes
                }
            }
        }
        return nil
    }
    
    // MARK: - Core Data Logic
    
    internal override func createDictionaryForCoreDataStore() -> Dictionary<String, AnyObject> {
        var persistentDictionary: [String: AnyObject] = super.createDictionaryForCoreDataStore()
        
        //Set the coreData dictionary ONLY w/ USER-ENTERED configuration information for selected varType:
        if let type = variableType {
            switch type {
            case .Behavior_FoodIntake: //store the selected categories & dataStream locations
                if let streamLocations = selectedDataStreamLocations {
                    var rawStreamLocations: [String] = []
                    for location in streamLocations {
                        rawStreamLocations.append(location.rawValue)
                    }
                    persistentDictionary[BMN_FoodIntakeModule_DataStreamLocationsKey] = rawStreamLocations
                }
                
                var categoriesAsString: [String] = []
                for category in nutritionCategories { //store categories as rawValues
                    categoriesAsString.append(category.rawValue)
                }
                persistentDictionary[BMN_FoodIntakeModule_NutritionCategoriesKey] = categoriesAsString
            }
        }
        return persistentDictionary
    }
    
    // MARK: - Data Entry Logic
    
    func getTypeForVariable() -> FoodIntakeModuleVariableTypes? { //external type access
        return self.variableType
    }
    
    override var cellHeightUserInfo: [String : AnyObject]? { //provides info to set height for TV cell
        if let type = variableType {
            switch type {
            case .Behavior_FoodIntake: //depending on # of categories, return a height for TV cell
                break
            }
        }
        return nil
    }
    
    override func getDataEntryCellTypeForVariable() -> DataEntryCellTypes? { //indicates to DataEntryVC what kind of DataEntry cell should be used for this variable
        if let type = self.variableType {
            switch type {
            case .Behavior_FoodIntake:
                return DataEntryCellTypes.FIM_FoodIntake //use custom FoodIntake cell for data entry
            }
        }
        return nil
    }
    
    override func isSubscribedToService(service: ServiceTypes) -> Bool {
        if let type = self.variableType { //check if var is subscribed to service using enum object
            return type.isSubscribedToService(service)
        }
        return false
    }
    
    override func reportDataForVariable() -> [String : AnyObject]? { //OVERRIDE for datastream variable!
        let reportDict = super.reportDataForVariable() //store superclass return object
        if let type = self.variableType {
            switch type {
            case .Behavior_FoodIntake:
                let sharedInstance = FIM_FoodIntakeDatastream.sharedInstance
                //all data in the datastream should ALWAYS be reported -> the parent stream
                //aggregate data - need to (1) store a timeStamp for each reported meal; (2) store the data for the meal against the appropriate 'location' (e.g. breakfast, lunch)
                //the FINAL aggregation is done when the stream is closed & matched against the ReportedDataKey before being passed -> the Project object.
                return nil //indicates that the datastream is still OPEN (only return the completed package when the data has been completely reported for this variable!)
            }
        }
        return reportDict //default is standard behavior
    }
    
    // MARK: - HealthKit Interaction Logic
    
    func writeManualDataToHKStore() { //add aggregated nutritional info -> HK
        //
    }
    
}

enum FoodIntakeModuleVariableTypes: String { //*match each behavior/computation -> Configuration + DataEntry custom TV cells; for each new behavior/comp added, you must also add (1) Configuration logic, (2) Core Data storage logic (so the variable config can be preserved), (3) Unpacking logic (in the DataEntry initializer), & (4) DataEntry logic (enabling the user to report info).* 
    case Behavior_FoodIntake = "Food Intake" //single cell that allows the user to aggregate all desired nutritional information (based on setup) for a given meal.
    
    func getAlertMessageForVariable() -> String {
        var message = ""
        switch self {
        case .Behavior_FoodIntake:
            message = "Allows you to track nutrition data for the foods that were consumed during 1 or more meals."
        }
        return message
    }
    
    func isSubscribedToService(service: ServiceTypes) -> Bool { //list of subscribed services for each variableType
        let subscribedServices: [ServiceTypes]
        switch self { //for each var that uses services, create list of subscribed services
        default:
            subscribedServices = [ServiceTypes.Internet, ServiceTypes.HealthKit] //meal items require access to internet (for API) & HK (for writing data to store)
        }
        if (subscribedServices.contains(service)) { //subscribed to service
            return true
        } else { //NOT subscribed to service
            return false
        }
    }

}

enum FoodIntakeModule_NutritionCategories: String {
    
    //Other:
    case Calories = "Calories"
    case Water = "Water"
    case Caffeine = "Caffeine"
    
    //Macronutrients:
    case Protein = "Protein"
    case TotalFat = "Total Fat"
    case SaturatedFat = "Saturated Fat"
    case MonounsaturatedFat = "Monounsaturated Fat"
    case PolyunsaturatedFat = "Polyunsaturated Fat"
    case Cholesterol = "Cholesterol"
    case TransFat = "Trans Fat"
    case TotalSugar = "Total Sugar"
    case DietaryFiber = "Dietary Fiber"
    
    //Vitamins & Minerals:
    case Calcium = "Calcium"
    case Iron = "Iron"
    case Magnesium = "Magnesium"
    case Phosphorus = "Phosphorus"
    case Potassium = "Potassium"
    case Sodium = "Sodium"
    case Zinc = "Zinc"
    case VitaminC = "Vitamin C"
    case VitaminB1 = "Vitamin B1"
    case VitaminB2 = "Vitamin B2"
    case VitaminB3 = "Vitamin B3"
    case VitaminB6 = "Vitamin B6"
    case Folate = "Folate"
    case VitaminB12 = "Vitamin B12"
    case VitaminA = "Vitamin A"
    case VitaminD = "Vitamin D"
    case VitaminE = "Vitamin E"
    case VitaminK = "Vitamin K"
    
    func matchCategoryToNutrientID() -> Int { //matches enum obj -> NutritionAPI Nutrient ID#
        switch self {
        case .Calories:
            return 208
        case .Water:
            return 255
        case .Protein:
            return 203
        case .TotalFat:
            return 204
        case .TotalSugar:
            return 269
        case .DietaryFiber:
            return 291
        case .Calcium:
            return 301
        case .Iron:
            return 303
        case .Magnesium:
            return 304
        case .Phosphorus:
            return 305
        case .Potassium:
            return 306
        case .Sodium:
            return 307
        case .Zinc:
            return 309
        case .VitaminC:
            return 401
        case .VitaminB1:
            return 404
        case .VitaminB2:
            return 405
        case .VitaminB3:
            return 406
        case .VitaminB6:
            return 415
        case .Folate: //unknown unit
            return 435
        case .VitaminB12: //?
            return 418
        case .VitaminA: //IU*
            return 318
        case .VitaminD: //IU*
            return 324
        case .VitaminK: //?
            return 430
        case .VitaminE: //?
            return 323
        case .SaturatedFat:
            return 606
        case .MonounsaturatedFat:
            return 645
        case .PolyunsaturatedFat:
            return 646
        case .TransFat:
            return 605
        case .Cholesterol:
            return 601
        case .Caffeine:
            return 262
        }
    }
}

enum FoodIntakeModule_DataStreamLocations: String { //locations of data stream from which to pull data
    case Full = "Full Day"
    case Breakfast = "Breakfast"
    case Lunch = "Lunch"
    case Dinner = "Dinner"
    case Snack = "Snack"
    case PreWorkout = "Pre-Workout"
    case PostWorkout = "Post-Workout"
}