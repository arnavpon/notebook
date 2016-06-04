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
    
    let foodsList: [CachedFood]? //list of food names contained in the JSON object
    
    init(returnObject: [String: AnyObject]) {
        print("Initializing food search item")
        if let listDict = returnObject["list"] as? [String: AnyObject], items = listDict["item"] as? [[String: AnyObject]] {
            print("Inside 1st if let (items were obtained!")
            var temp: [CachedFood] = [] //initialize
            for item in items {
                if let name = item["name"] as? String, stringID = item["ndbno"] as? String, id = Int(stringID) {
                    print("Inside 2nd if let (name & DB id were obtained)")
                    temp.append(CachedFood(name: name, id: id))
                }
            }
            foodsList = temp
            print("Total Count in List: \(foodsList?.count).")
        } else { //cast failed
            foodsList = nil
        }
    }
    
}

struct FoodItem { //object used to represent a single food item & perform calculations based on the amount of the food & the unit of measure
    
    //Other:
    var water: [String: AnyObject]? //g
    var calories: [String: AnyObject]? //kCal
    var caffeine: [String: AnyObject]? //mg
    
    //Macronutrients:
    var protein: [String: AnyObject]? //g
    var totalSugar: [String: AnyObject]? //g
    var dietaryFiber: [String: AnyObject]? //g
    var totalFat: [String: AnyObject]? //g
    var saturatedFat: [String: AnyObject]? //g
    var monounsaturatedFat: [String: AnyObject]? //g
    var polyunsaturatedFat: [String: AnyObject]? //g
    var cholesterol: [String: AnyObject]? //mg
    var transFat: [String: AnyObject]? //g
    
    //Vitamins & Minerals:
    var calcium: [String: AnyObject]? //mg
    var iron: [String: AnyObject]? //mg
    var magnesium: [String: AnyObject]? //mg
    var phosphorus: [String: AnyObject]? //mg
    var potassium: [String: AnyObject]? //mg
    var sodium: [String: AnyObject]? //mg
    var zinc: [String: AnyObject]? //mg
    var vitaminC: [String: AnyObject]? //mg
    var vitaminB1: [String: AnyObject]? //mg
    var vitaminB2: [String: AnyObject]? //mg
    var vitaminB3: [String: AnyObject]? //mg
    var vitaminB6: [String: AnyObject]? //mg
    var folate: [String: AnyObject]? //mg
    var vitaminB12: [String: AnyObject]? //mg
    var vitaminA: [String: AnyObject]? //mg
    var vitaminD: [String: AnyObject]? //mg
    var vitaminE: [String: AnyObject]? //mg
    var vitaminK: [String: AnyObject]? //mg
    
    //W/in nutrients dict, check if name key matches the parameter set by the user & if so, obtain that information for the food. We need to match the units up (Oz, cup, slice) & then obtain the "value", then perform the conversion based on the # of units to obtain the correct total amount. B/c the user can search for a food w/o inputting the amount or unit, we need to save the whole dictionary for that nutrient in this object until the computation is done. Check if nutrient_id matches the user's selection on init & if so, store that info to the dict.
    
    // MARK: - Initializer
    
    init(reportObject: [String: AnyObject], pertinentCategories: [FoodIntakeModule_NutritionCategories]) { //extract values from dict, for each object check if it is contained
        print("Initializing food item...")
        if let reportDict = reportObject["report"] as? [String: AnyObject], foodInfo = reportDict["food"] as? [String: AnyObject], nutrientsInfo = foodInfo["nutrients"] as? [[String: AnyObject]] {
            print("Inside if let - nutrientsInfo has been obtained for food!")
            
            var categories: [Int] = [] //obtain user-selected categories
            for category in pertinentCategories {
                categories.append(category.matchCategoryToNutrientID())
            }
            
            var counter = 0 //stops loop after all dicts for categories in pertinentCategory are obtained
            for nutrient in nutrientsInfo {
                if (counter <= pertinentCategories.count) { //stop loop when all items have been obtained
                    if let info = nutrient["measures"] as? [String: AnyObject], idString = nutrient["nutrient_id"] as? String, let idInt = Int(idString) {
                        if (categories.contains(idInt)) {
                            if let category = getCategoryForNutrientID(idInt) {
                                counter += 1
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
                } else {
                    print("Ending for loop. Count: \(counter). # of categories: \(pertinentCategories.count).")
                    break
                }
            }
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
        return NSURL(string: "https://api.forecast.io/forecast/\(nutritionAPIKey)/")
        return NSURL(string: "http://api.nal.usda.gov/ndb/search/?format=json") //add a sort by relevance item to query
    
        //"http://api.nal.usda.gov/ndb/search/?format=json&q=butter&sort=n&max=25&offset=0&api_key=DEMO_KEY" //full query (need to construct after getting user's search term
    }
    private var reportBaseURL: NSURL? { //base URL for a food report query
        return NSURL(string: "https://api.forecast.io/forecast/\(nutritionAPIKey)/")
        return NSURL(string: "http://api.nal.usda.gov/ndb/reports/?")
        
        //        "http://api.nal.usda.gov/ndb/reports/?ndbno=01009&type=b&format=json&api_key=DEMO_KEY" //full report query (need to construct after getting DB #
    }
    
    // MARK: - Initializer
    
    init(searchTerm: String) { //initialize w/ user's search query (part 1)
        //user 'searchBaseURL'
    }
    
    init(databaseID: Int) { //initialize w/ DB ID (part 2)
        //use 'reportBaseURL'
    }
    
    // MARK: - Networking Logic
    
    func getNamesForSearchTermFromAPI(completion: ((CurrentWeather?, DailyWeather?) -> Void)) {
        if let forecastURL = NSURL(string: "\(coordinate.latitude),\(coordinate.longitude)", relativeToURL: apiBaseURL) {
            let networkOperation = NetworkConnection(url: forecastURL)
            
            //Download JSON object from constructed URL (using API key & location coordinates):
            networkOperation.downloadJSONFromURL({ (let JSONDictionary) in
                let (current, daily) = self.parseWeatherDataFromJSON(JSONDictionary)
                completion((current, daily)) //pass constructed weather objects -> completionHandler
            })
        } else {
            print("Could not construct valid URL.")
        }
    }
    
    func getNutritionObjectFromAPI(completion: ((CurrentWeather?, DailyWeather?) -> Void)) {
        if let forecastURL = NSURL(string: "\(coordinate.latitude),\(coordinate.longitude)", relativeToURL: apiBaseURL) {
            let networkOperation = NetworkConnection(url: forecastURL)
            
            //Download JSON object from constructed URL (using API key & location coordinates):
            networkOperation.downloadJSONFromURL({ (let JSONDictionary) in
                let (current, daily) = self.parseWeatherDataFromJSON(JSONDictionary)
                completion((current, daily)) //pass constructed weather objects -> completionHandler
            })
        } else {
            print("Could not construct valid URL.")
        }
    }
    
    // MARK: - Data Parsing Logic
    
    private func parseNameDataFromJSON(jsonDictionary: [String: AnyObject]?) -> (CurrentWeather?, DailyWeather?) { //constructs a 'CurrentWeather' & 'DailyWeather' object from JSON dict returned by the URL request
        if let currentWeatherDictionary = jsonDictionary?["currently"] as? [String: AnyObject], dailyDict = jsonDictionary?["daily"] as? [String: AnyObject], days = dailyDict["data"] as? NSArray {
            //(1) Data stored against 'currently' key gives the CURRENT weather DICT:
            let current = CurrentWeather(weatherDictionary: currentWeatherDictionary)
            
            //(2) Data stored against 'daily' key > 'data' key gives an ARRAY of DAILY weather objects for the week; obtain the 1st object in the array for TODAY'S weather:
            if let today = days.firstObject as? [String: AnyObject] {
                let daily = DailyWeather(weatherDictionary: today)
                return (current, daily)
            }
        } else { //JSONDict does NOT have a 'currently' or 'daily' key
            print("JSON dictionary returned nil for 'currently' or 'daily' key")
        }
        return (nil, nil)
    }
    
    private func parseNutritionDataFromJSON(jsonDictionary: [String: AnyObject]?) -> (CurrentWeather?, DailyWeather?) { //constructs a 'CurrentWeather' & 'DailyWeather' object from JSON dict returned by the URL request
        if let currentWeatherDictionary = jsonDictionary?["currently"] as? [String: AnyObject], dailyDict = jsonDictionary?["daily"] as? [String: AnyObject], days = dailyDict["data"] as? NSArray {
            //(1) Data stored against 'currently' key gives the CURRENT weather DICT:
            let current = CurrentWeather(weatherDictionary: currentWeatherDictionary)
            
            //(2) Data stored against 'daily' key > 'data' key gives an ARRAY of DAILY weather objects for the week; obtain the 1st object in the array for TODAY'S weather:
            if let today = days.firstObject as? [String: AnyObject] {
                let daily = DailyWeather(weatherDictionary: today)
                return (current, daily)
            }
        } else { //JSONDict does NOT have a 'currently' or 'daily' key
            print("JSON dictionary returned nil for 'currently' or 'daily' key")
        }
        return (nil, nil)
    }
    
}