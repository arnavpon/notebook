//  RecipeModule.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 7/24/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Module that allows user to experiment with recipes. Each recipe object (project?) is a self-contained unit that does not mix (as of now) with other project types; each recipe project corresponds to only 1 food (i.e. the project is built around optimizing the recipe for that food). The user selects a recipe variable during setup and this dictates the configuration of the entire project. Cannot be selected if there are other variables.
//When does the user select something to set all of this in motion? Should be in Project setup to bypass the other stuff. Add a Button.

//Recipe Variable: place in food project. Automatically configures entire project on selection. Block selection when any other variable is in the project.
//Recipe project is a self contained unit (full project template?). When you select a recipe project, configuration = the characteristics that you want to rate the food on (texture, taste,...). Project setup - input is mix of 2 variables (ingredients variable and recipe [cook times + order] variable), output is rating of recipe (rating is combination of several criteria, based on rating categories that were selected during configuration). Each project is a comparison of various recipes for the SAME food. Inputs differ based on the ingredients (type, quantity) & order of operations of the cooking.
//Data analysis - extracts characteristics that make for a better recipe. For example, correlates the ingredients, quantities, and cook time/order with improved texture, taste, etc. Need to constrain inputs enough that we can extract the characteristics for analysis - how do we analyze the recipe order of operations & cook times. We can provide widgets corresponding with steps of the recipe (& empty items to fill the amount of each ingredient) that are arranged in specific ways and then analyze based on the order of arrangement. The key to analysis is determining which factors vary in any recipe and which stay the same and allowing the user to vary non static parameters while constraining static ones.
//Data Entry - [IV] 1. Ingredients - ingredient object = name + quantity + state(? chopped, sliced, minced). 2. Recipe object - how to design this? Variable parameters include cook type (bake, steam, fry), order of additions, [OM] Rating based on category - for each selected category, allows user to rate on scale of 1-5 (using RangeScale ghost variables); final output is a computed dictionary containing ratings matched against each rating category.

import UIKit
import CoreData

class RecipeModule: Module {
    
    private var variableType: RecipeModuleVariableTypes? { //converts 'selectedFunctionality' (a String) to an enum object
        get {
            if let selection = selectedFunctionality {
                return RecipeModuleVariableTypes(rawValue: selection)
            }
            return nil
        }
    }
    private var recipeName: String? //name of food for which recipe is being created
    private var ratingCategories: [RecipeModule_RatingCategories]? //for OM
    
    // MARK: - Initializers
    
    override init(name: String) { //set-up init
        super.init(name: name)
        self.moduleTitle = Modules.RecipeModule.rawValue
    }
    
    override init(name: String, dict: [String: AnyObject]) { //CoreData init
        super.init(name: name, dict: dict)
        self.moduleTitle = Modules.RecipeModule.rawValue
        
        //Break down the dictionary depending on the variable's type key & reconstruct object:
        if let typeName = dict[BMN_VariableTypeKey] as? String, type = RecipeModuleVariableTypes(rawValue: typeName) {
            self.selectedFunctionality = typeName //reset the variable's selectedFunctionality
            switch type { //configure according to 'variableType'
            case .Behavior_Ingredients: //??
                break
            case .Behavior_CookingInstructions: //??
                break
            case .Computation_RecipeRating: //unpack the rating categories
                if let rawCategories = dict[BMN_RecipeModule_RatingCategoriesKey] as? [String] {
                    self.ratingCategories = [] //init
                    for rawCategory in rawCategories {
                        if let category = RecipeModule_RatingCategories(rawValue: rawCategory) {
                            self.ratingCategories!.append(category)
                        }
                    }
                }
                //
            case .Recipe: //should never be set w/ CoreData init (not a true var)
                break
            }
        } else {
            print("[EnvironModule > CoreData initializer] Error! Could not find a type for the object.")
        }
    }
    
    override func copyWithZone(zone: NSZone) -> AnyObject { //creates copy of variable
        let copy = RecipeModule(name: self.variableName)
        copy.existingVariables = self.existingVariables
        copy.moduleBlocker = self.moduleBlocker
        copy.configurationType = self.configurationType
        return copy
    }
    
    // MARK: - Variable Configuration
    
    internal override func setConfigurationOptionsForSelection() { //handles ALL configuration for ConfigOptionsVC - (1) Sets the 'options' value as needed; (2) Constructs the configuration TV cells if required; (3) Sets 'isAutoCaptured' var if var is auto-captured.
        if let type = variableType { //make sure behavior/computation was selected & ONLY set the configOptionsObject if further configuration is required
            var array: [(ConfigurationOptionCellTypes, Dictionary<String, AnyObject>)] = [] //pass -> VC (CustomCellType, cell's dataSource)
            switch type {
            case .Recipe:
                
                //(1) User needs to add a name for the recipe (i.e. the food that is being cooked):
                array.append((ConfigurationOptionCellTypes.SimpleText, [BMN_Configuration_CellDescriptorKey: BMN_RecipeModule_RecipeNameID, BMN_LEVELS_MainLabelKey: "Enter the name of the food you are creating a recipe for:"]))
                
                //(2) User needs to select the rating categories used for OM:
                let ratingOptions = [RecipeModule_RatingCategories.Taste.rawValue, RecipeModule_RatingCategories.Texture.rawValue, RecipeModule_RatingCategories.Ambience.rawValue]
                array.append((ConfigurationOptionCellTypes.SelectFromOptions, [BMN_Configuration_CellDescriptorKey: BMN_RecipeModule_RatingCategoriesKey, BMN_LEVELS_MainLabelKey: "Select 1 or more categories you will be using to rate the recipe:", BMN_SelectFromOptions_OptionsKey: ratingOptions, BMN_SelectFromOptions_MultipleSelectionEnabledKey: true, BMN_SelectFromOptions_DefaultOptionsKey: [ratingOptions[0]]])) //rating options
                
                configurationOptionsLayoutObject = array
                
            default:
                
                configurationOptionsLayoutObject = nil
                
            }
        } else { //no selection, set configOptionsObj -> nil
            configurationOptionsLayoutObject = nil
        }
    }
    
    internal override func matchConfigurationItemsToProperties(configurationData: [String: AnyObject]) -> (Bool, String?, [String]?) {
        if let type = variableType {
            switch type {
            case .Recipe:
                if let name = configurationData[BMN_RecipeModule_RecipeNameID] as? String, rawOptions = configurationData[BMN_RecipeModule_RatingCategoriesKey] as? [String] {
                    self.recipeName = name
                    self.ratingCategories = [] //initialize**
                    for optionRaw in rawOptions {
                        if let category = RecipeModule_RatingCategories(rawValue: optionRaw) {
                            ratingCategories!.append(category)
                        } else {
                            return (false, "Enum failure", nil)
                        }
                    }
                    return (true, nil, nil)
                } else {
                    return (false, "No sampling option was found!", nil)
                }
            default:
                break
            }
        }
        return (false, "No option was selected!", nil)
    }
    
    func createProjectForRecipeModule() { //uses the configuration to create the Project
        print("Creating project for recipe...")
        //no endpoint (recipes are compared 1 by 1 as needed)
        //create 3 RecipeModule variables & add as inputs & outcomes...
        let rating = RecipeModule(name: "RecipeRating")
        rating.configurationType = .OutcomeMeasure //set as OM
        rating.ratingCategories = self.ratingCategories //set ratingCategories var
        //create as many ghost variables as necessary to feed in to the OM & compute the final dict
//        if let name = recipeName {
//            let context = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
//            let project = Project(type: .InputOutput, title: "Recipe_\(name)", question: "Which recipe works best?", hypothesis: nil, endPoint: nil, insertIntoManagedObjectContext: context)
//            let _ = Group(type: .LoneGroup, project: project, action: "Cook & Eat", beforeVariables: [:], afterVariables: [:], insertIntoManagedObjectContext: context) //always lone group
//            saveManagedObjectContext()
//        }
    }
    
    // MARK: - Core Data Logic
    
    internal override func createDictionaryForCoreDataStore() -> Dictionary<String, AnyObject> {
        var persistentDictionary: [String: AnyObject] = super.createDictionaryForCoreDataStore()
        if let type = variableType {
            persistentDictionary[BMN_VariableTypeKey] = type.rawValue //save variable type
            switch type {
            case .Computation_RecipeRating:
                if let categories = ratingCategories { //used only for OM
                    var rawCategories: [String] = []
                    for category in categories {
                        rawCategories.append(category.rawValue)
                    }
                    persistentDictionary[BMN_RecipeModule_RatingCategoriesKey] = rawCategories
                }
            default:
                break
            }
        }
        return persistentDictionary
    }
    
    // MARK: - Data Entry Logic
    
    override func getDataEntryCellTypeForVariable() -> DataEntryCellTypes? { //indicates to DataEntryVC what kind of DataEntry cell should be used for this variable
        if let type = self.variableType {
            switch type {
            case .Behavior_Ingredients: //IV - conjugate variable? that enables users to enter ingredients & fill in categories using a Freeform Cell
                return nil
            case .Behavior_CookingInstructions: //IV - ?
                return nil
            case .Computation_RecipeRating: //OM - conjugate variable consisting of several RangeScale feed-in variables
                return nil
            default:
                return nil
            }
        }
        return nil
    }
    
}

enum RecipeModuleVariableTypes: String { //*match each behavior/computation -> Configuration + DataEntry custom TV cells; for each new behavior/comp added, you must also add (1) Configuration logic, (2) Core Data storage logic (so the variable config can be preserved), (3) Unpacking logic (in the DataEntry initializer), & (4) DataEntry logic (enabling the user to report info).*
    
    //Available Behaviors:
    case Recipe = "RM_Recipe" //master variable type for RecipeModule
    case Behavior_Ingredients = "RM_Ingredients" //IV #1
    case Behavior_CookingInstructions = "CookingInstructions" //IV #2
    case Computation_RecipeRating = "RM_RecipeRating" //OM for RecipeModule
    
    func getAlertMessageForVariable() -> String {
        return "" //no alert message for RecipeModule
    }
    
}

enum RecipeModule_RatingCategories: String { //OM for project is a rating of the recipe in several categories
    case Taste = "Taste"
    case Texture = "Texture"
    case Ambience = "Ambience"
}