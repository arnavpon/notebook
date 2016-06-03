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
    
    private let foodIntakeModuleBehaviors: [FoodIntakeModuleVariableTypes] = [FoodIntakeModuleVariableTypes.MealItem]
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
    
    // MARK: - Initializers
    
    override init(name: String) { //set-up init
        super.init(name: name)
        self.moduleTitle = Modules.FoodIntakeModule.rawValue
    }
    
    override init(name: String, dict: [String: AnyObject]) { //CoreData init
        super.init(name: name, dict: dict)
        self.moduleTitle = Modules.FoodIntakeModule.rawValue
        
        if let categories = dict[BMN_FoodIntakeModule_NutritionCategoriesKey] as? [String] {
            for categoryRaw in categories {
                if let category = FoodIntakeModule_NutritionCategories(rawValue: categoryRaw) {
                    self.nutritionCategories.append(category)
                }
            }
            print("[FoodIntake Init] # of saved categories = \(nutritionCategories.count).")
        }
    }
    
    override func copyWithZone(zone: NSZone) -> AnyObject { //creates copy of variable
        let copy = FoodIntakeModule(name: self.variableName)
        copy.existingVariables = self.existingVariables
        copy.moduleBlocker = self.moduleBlocker
        return copy
    }
    
    // MARK: - Variable Configuration
    
    internal override func setConfigurationOptionsForSelection() {
        if let type = variableType { //make sure behavior/computation was selected & ONLY set the configOptionsObject if further configuration is required
            var array: [(ConfigurationOptionCellTypes, Dictionary<String, AnyObject>)] = [] //pass -> VC (CustomCellType, cell's dataSource)
            switch type {
            case .MealItem:
                
                let categories: [String] = [FoodIntakeModule_NutritionCategories.Calories.rawValue, FoodIntakeModule_NutritionCategories.Protein.rawValue, FoodIntakeModule_NutritionCategories.Carbohydrates.rawValue, FoodIntakeModule_NutritionCategories.TotalFat.rawValue] //available nutrition categories
                array.append((ConfigurationOptionCellTypes.SelectFromOptions, [BMN_Configuration_CellDescriptorKey: BMN_FoodIntakeModule_NutritionCategoriesID, BMN_LEVELS_MainLabelKey: "Select the nutrition categories for which you want to obtain data:", BMN_SelectFromOptions_OptionsKey: categories, BMN_SelectFromOptions_DefaultOptionsKey: [categories[0]], BMN_SelectFromOptions_MultipleSelectionEnabledKey: true])) //nutrition categories, default is CALORIES
                
                configurationOptionsLayoutObject = array
                
            }
        }
    }
    
    override func matchConfigurationItemsToProperties(configurationData: [String : AnyObject]) -> (Bool, String?, [String]?) {
        if let type = variableType {
            switch type {
            case .MealItem: //obtain selected nutrition categories & add them -> module property
                if let rawSelections = configurationData[BMN_FoodIntakeModule_NutritionCategoriesID] as? [String] {
                    self.nutritionCategories = [] //clear array
                    for selection in rawSelections {
                        if let category = FoodIntakeModule_NutritionCategories(rawValue: selection) {
                            nutritionCategories.append(category)
                        }
                    }
                    return (true, nil, nil)
                }
            }
        }
        return (false, "No option was selected!", nil)
    }
    
    // MARK: - Core Data Logic
    
    internal override func createDictionaryForCoreDataStore() -> Dictionary<String, AnyObject> {
        var persistentDictionary: [String: AnyObject] = super.createDictionaryForCoreDataStore()
        
        //Set the coreData dictionary ONLY w/ USER-ENTERED configuration information for selected varType:
        if let type = variableType {
            switch type {
            case .MealItem: //store the selected categories
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
            case .MealItem: //depending on # of categories, return a height for TV cell
                break
            }
        }
        return nil
    }
    
    override func getDataEntryCellTypeForVariable() -> DataEntryCellTypes? { //indicates to DataEntryVC what kind of DataEntry cell should be used for this variable
        if let type = self.variableType {
            switch type {
            case .MealItem:
                return DataEntryCellTypes.FoodIntakeForMealItem
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
    
    override func reportDataForVariable() -> [String: AnyObject]? {
        let reportDict = super.reportDataForVariable() //use superclass functionality, but first...
        writeManualDataToHKStore() //before reporting, write data -> HKStore as needed
        return reportDict
    }
    
    // MARK: - HealthKit Interaction Logic
    
    func writeManualDataToHKStore() { //add aggregated nutritional info -> HK
        //
    }
    
}

enum FoodIntakeModuleVariableTypes: String { //*match each behavior/computation -> Configuration + DataEntry custom TV cells; for each new behavior/comp added, you must also add (1) Configuration logic, (2) Core Data storage logic (so the variable config can be preserved), (3) Unpacking logic (in the DataEntry initializer), & (4) DataEntry logic (enabling the user to report info).* 
    case MealItem = "Meal Item" //single cell that allows the user to aggregate all desired nutritional information (based on setup) for a given meal.
    
    func getAlertMessageForVariable() -> String {
        var message = ""
        switch self {
        case .MealItem:
            message = "Allows you to enter all of the items you consumed during a single meal."
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
    case Calories = "Calories"
    case Protein = "Protein"
    case Carbohydrates = "Carbohydrates"
    case TotalFat = "Total Fat"
}