//  NutritionService.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 6/2/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Defines interaction w/ USDA nutrition API - sends request to API & populates structs based on return value.

import Foundation

struct CachedFood {
    
    let name: String
    let databaseID: Int //unique API DB ID#
    
    init(name: String, id: Int) {
        self.name = name
        self.databaseID = id
    }
    
}

struct FoodSearchItem { //object used to obtain the search results for a SEARCH NutritionAPI request
    
    let foodsList: [CachedFood] //list of food names contained in the JSON object
    
    init(items: [[String: AnyObject]]) {
        var temp: [CachedFood] = [] //initialize
        for item in items {
            if let name = item["name"] as? String, stringID = item["ndbno"] as? String, id = Int(stringID) {
                temp.append(CachedFood(name: name, id: id))
            }
        }
        foodsList = temp
    }
    
}

struct FoodItem { //object used to represent a single food item & perform calculations based on the amount of the food & the unit of measure
    
    //Other:
    var water: [[String: AnyObject]]? //g
    var calories: [[String: AnyObject]]? //kCal
    var caffeine: [[String: AnyObject]]? //mg
    
    //Macronutrients:
    var protein: [[String: AnyObject]]? //g
    var totalSugar: [[String: AnyObject]]? //g
    var dietaryFiber: [[String: AnyObject]]? //g
    var totalFat: [[String: AnyObject]]? //g
    var saturatedFat: [[String: AnyObject]]? //g
    var monounsaturatedFat: [[String: AnyObject]]? //g
    var polyunsaturatedFat: [[String: AnyObject]]? //g
    var cholesterol: [[String: AnyObject]]? //mg
    var transFat: [[String: AnyObject]]? //g
    
    //Vitamins & Minerals:
    var calcium: [[String: AnyObject]]? //mg
    var iron: [[String: AnyObject]]? //mg
    var magnesium: [[String: AnyObject]]? //mg
    var phosphorus: [[String: AnyObject]]? //mg
    var potassium: [[String: AnyObject]]? //mg
    var sodium: [[String: AnyObject]]? //mg
    var zinc: [[String: AnyObject]]? //mg
    var vitaminC: [[String: AnyObject]]? //mg
    var vitaminB1: [[String: AnyObject]]? //mg
    var vitaminB2: [[String: AnyObject]]? //mg
    var vitaminB3: [[String: AnyObject]]? //mg
    var vitaminB6: [[String: AnyObject]]? //mg
    var folate: [[String: AnyObject]]? //mg
    var vitaminB12: [[String: AnyObject]]? //mg
    var vitaminA: [[String: AnyObject]]? //mg
    var vitaminD: [[String: AnyObject]]? //mg
    var vitaminE: [[String: AnyObject]]? //mg
    var vitaminK: [[String: AnyObject]]? //mg
    
    // MARK: - Initializer
    
    init(nutrientsInfo: [[String: AnyObject]]) { //for each object check if it is in list of categories
        for nutrient in nutrientsInfo {
            if let info = nutrient["measures"] as? [[String: AnyObject]], idString = nutrient["nutrient_id"] as? String, let idInt = Int(idString) {
                if let category = getCategoryForNutrientID(idInt) {
                    switch category {
                    case .Calories:
                        self.calories = info
                    case .Caffeine:
                        self.caffeine = info
                    case .Water:
                        self.water = info
                    case .Protein:
                        self.protein = info
                    case .TotalSugar:
                        self.totalSugar = info
                    case .DietaryFiber:
                        self.dietaryFiber = info
                    case .TotalFat:
                        self.totalFat = info
                    case .SaturatedFat:
                        self.saturatedFat = info
                    case .MonounsaturatedFat:
                        self.monounsaturatedFat = info
                    case .PolyunsaturatedFat:
                        self.polyunsaturatedFat = info
                    case .TransFat:
                        self.transFat = info
                    case .Cholesterol:
                        self.cholesterol = info
                    case .Calcium:
                        self.calcium = info
                    case .Iron:
                        self.iron = info
                    case .Magnesium:
                        self.magnesium = info
                    case .Phosphorus:
                        self.phosphorus = info
                    case .Potassium:
                        self.potassium = info
                    case .Sodium:
                        self.sodium = info
                    case .Zinc:
                        self.zinc = info
                    case .VitaminA:
                        self.vitaminA = info
                    case .VitaminC:
                        self.vitaminC = info
                    case .VitaminD:
                        self.vitaminD = info
                    case .VitaminK:
                        self.vitaminK = info
                    case .VitaminE:
                        self.vitaminE = info
                    case .VitaminB1:
                        self.vitaminB1 = info
                    case .VitaminB2:
                        self.vitaminB2 = info
                    case .VitaminB3:
                        self.vitaminB3 = info
                    case .VitaminB6:
                        self.vitaminB6 = info
                    case .Folate:
                        self.folate = info
                    case .VitaminB12:
                        self.vitaminB12 = info
                    }
                }
            }
        }
    }

    func getDataForFilter(pertinentCategories: [FoodIntakeModule_NutritionCategories]) { //**
        var categories: [Int] = [] //obtain user-selected categories
        for category in pertinentCategories {
            categories.append(category.matchCategoryToNutrientID())
        }
    }
    
    func getCategoryForNutrientID(id: Int) -> FoodIntakeModule_NutritionCategories? {
        switch id {
        case 208:
            return .Calories
        case 255:
            return .Water
        case 203:
            return .Protein
        case 204:
            return .TotalFat
        case 269:
            return .TotalSugar
        case 291:
            return .DietaryFiber
        case 301:
            return .Calcium
        case 303:
            return .Iron
        case 304:
            return .Magnesium
        case 305:
            return .Phosphorus
        case 306:
            return .Potassium
        case 307:
            return .Sodium
        case 309:
            return .Zinc
        case 401:
            return .VitaminC
        case 404:
            return .VitaminB1
        case 405:
            return .VitaminB2
        case 406:
            return .VitaminB3
        case 415:
            return .VitaminB6
        case 435: //unknown unit
            return .Folate
        case 418: //?
            return .VitaminB12
        case 318: //IU*
            return .VitaminA
        case 324: //IU*
            return .VitaminD
        case 430: //?
            return .VitaminK
        case 323: //?
            return .VitaminE
        case 606:
            return .SaturatedFat
        case 645:
            return .MonounsaturatedFat
        case 646:
            return .PolyunsaturatedFat
        case 605:
            return .TransFat
        case 601:
            return .Cholesterol
        case 262:
            return .Caffeine
        default: //doesn't match
            print("[getCategoryForNutrientID] Error - default in switch!")
        }
        return nil
    }
    
    // MARK: - Calculation Logic
    
    func obtainNutrition() -> Int { //handles calculations
        return 0
    }
    
}

struct NutritionService { //creates a SPECIALIZED network connection (utilizing the 'NetworkConnection' class) w/ the USDA Nutrition API to obtain nutrition data based on the entered search term.
    
    private let nutritionAPIKey = "0jameHAG5KPLOnaKg6eeuoEyw4giFm3seOzkIxFg"
    private var searchBaseURL: NSURL? { //base URL for a food search query
        return NSURL(string: "https://api.nal.usda.gov/ndb/search/")
    }
    private var reportBaseURL: NSURL? { //base URL for a food report query
        return NSURL(string: "https://api.nal.usda.gov/ndb/reports/")
    }
    private var searchFullURL: NSURL?
    private var reportFullURL: NSURL?
    
    // MARK: - Initializer
    
    init(searchTerm: String) { //initialize w/ user's search query (part 1)
        searchFullURL = NSURL(string: "?format=json&q=\(searchTerm)&sort=r&max=15&offset=0&api_key=\(nutritionAPIKey)", relativeToURL: searchBaseURL) //construct full search URL
    }
    
    init(databaseID: Int) { //initialize w/ DB ID (part 2) obtain from user's selection
        reportFullURL = NSURL(string: "?ndbno=\(databaseID)&type=b&format=json&api_key=\(nutritionAPIKey)", relativeToURL: reportBaseURL) //construct full report URL
    }
    
    // MARK: - Networking Logic
    
    func getNamesForSearchTermFromAPI(completion: (FoodSearchItem? -> Void)) {
        if let searchURL = searchFullURL {
            let networkOperation = NetworkConnection(url: searchURL)
            
            //Download JSON object from constructed URL (using API key & location coordinates):
            networkOperation.downloadJSONFromURL({ (let JSONDictionary) in
                let searchItem = self.parseNameDataFromJSON(JSONDictionary)
                completion(searchItem) //pass list of food names -> completionHandler
            })
        } else {
            print("Could not construct valid URL.")
        }
    }
    
    func getNutritionObjectFromAPI(completion: (FoodItem? -> Void)) {
        if let reportURL = reportFullURL {
            let networkOperation = NetworkConnection(url: reportURL)
            
            //Download JSON object from constructed URL (using API key & location coordinates):
            networkOperation.downloadJSONFromURL({ (let JSONDictionary) in
                print(JSONDictionary)
                let foodItem = self.parseNutritionDataFromJSON(JSONDictionary)
                completion(foodItem) //pass constructed food item -> completionHandler
            })
        } else {
            print("Could not construct valid URL.")
        }
    }
    
    // MARK: - Data Parsing Logic
    
    private func parseNameDataFromJSON(jsonDictionary: [String: AnyObject]?) -> FoodSearchItem? { //constructs a 'FoodSearchItem' object from JSON dict returned by the URL request
        if let apiObject = jsonDictionary, listDict = apiObject["list"] as? [String: AnyObject], items = listDict["item"] as? [[String: AnyObject]] {
            return FoodSearchItem(items: items)
        } else { //incorrect keys
            print("Cast failed!")
        }
        return nil
    }
    
    private func parseNutritionDataFromJSON(jsonDictionary: [String: AnyObject]?) -> FoodItem? { //constructs a 'FoodItem' object from JSON dict returned by the URL request
        if let apiObject = jsonDictionary, reportDict = apiObject["report"] as? [String: AnyObject], foodInfo = reportDict["food"] as? [String: AnyObject], nutrientsInfo = foodInfo["nutrients"] as? [[String: AnyObject]] {
            return FoodItem(nutrientsInfo: nutrientsInfo)
        } else { //JSONDict does NOT have specified keys
            print("Cast failed!")
        }
        return nil
    }
    
}