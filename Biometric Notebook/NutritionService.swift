//  NutritionService.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 6/2/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Defines interaction w/ USDA nutrition API - sends request to API & populates structs based on return value.

import Foundation

struct FoodItem { //object used to represent a single food item
    
    let temperature: Int? //ºF
    let apparentTemperature: Int? //ºF
    let relativeHumidity: Int? //0-100%
    let windSpeed: Int? //measured in MPH
    let icon: String? //name indicates the current Weather condition (from set of possibilities)
    let precipType: String? //if precipIntensity > 0, indicates the type of precipitation (make sure it matches the icon)
    let ozone: Int? //measured in Dobson units
    let pressure: Int? //measured in millibars
    let cloudCover: Int? //0-100%, indicates % of sky occluded by clouds
    
    // MARK: - Initializer
    
    init(weatherDictionary: [String: AnyObject]) { //extract values from the 'CURRENT' dict, keys MUST match values specified in API!
        temperature = weatherDictionary["temperature"] as? Int
        apparentTemperature = weatherDictionary["apparentTemperature"] as? Int
        windSpeed = weatherDictionary["windSpeed"] as? Int
        icon = weatherDictionary["icon"] as? String
        precipType = weatherDictionary["precipType"] as? String
        ozone = weatherDictionary["ozone"] as? Int
        pressure = weatherDictionary["pressure"] as? Int
        
        if let humidityFloat = weatherDictionary["humidity"] as? Double {
            relativeHumidity = Int(humidityFloat * 100)
        } else {
            relativeHumidity = nil
        }
        if let cloudCoverFloat = weatherDictionary["cloudCover"] as? Double {
            cloudCover = Int(cloudCoverFloat * 100)
        } else {
            cloudCover = nil
        }
    }
    
    // MARK: - Data Reporting Logic
    
    func reportDataForWeatherVariable(filter: [EnvironmentModule_WeatherOptions]) -> [String: AnyObject] { //based on the user's defined preferences for a Weather variable, filter the data that is reported by this variable (e.g. if they only want ambientTemp, provide only that)
        var reportObject = Dictionary<String, AnyObject>()
        for filterOption in filter { //for each filter, add the specified data -> reportDict
            switch filterOption {
            case .Temperature:
                reportObject["temperature"] = self.temperature
            case .ApparentTemperature:
                reportObject["apparentTemperature"] = self.apparentTemperature
            case .Humidity:
                reportObject["humidity"] = self.relativeHumidity
            case .WindSpeed:
                reportObject["windSpeed"] = self.windSpeed
            case .WeatherCondition:
                reportObject["weatherCondition"] = self.icon
            case .Ozone:
                reportObject["ozone"] = self.ozone
            case .BarometricPressure:
                reportObject["pressure"] = self.pressure
            case .CloudCover:
                reportObject["cloudCover"] = self.cloudCover
            default:
                break
            }
        }
        return reportObject
    }
    
}

struct NutritionService { //creates a SPECIALIZED network connection (utilizing the 'NetworkConnection' class) w/ the USDA Nutrition API to obtain nutrition data based on the entered search term.
    
    private let nutritionAPIKey = "0jameHAG5KPLOnaKg6eeuoEyw4giFm3seOzkIxFg"
    private let coordinate: (latitude: Double, longitude: Double) //obtain coordinates from CL manager
    private var apiBaseURL: NSURL? { //base URL for the weather API
        return NSURL(string: "https://api.forecast.io/forecast/\(nutritionAPIKey)/")
        
//        "http://api.nal.usda.gov/ndb/search/?format=json&q=butter&sort=n&max=25&offset=0&api_key=DEMO_KEY" //search URL
    }
    
    // MARK: - Initializer
    
    init(coordinate: (latitude: Double, longitude: Double)) { //initialize w/ coordinates @ which to obtain CURRENT weather
        self.coordinate = coordinate
    }
    
    // MARK: - Networking Logic
    
    func getWeatherObjectFromAPI(completion: ((CurrentWeather?, DailyWeather?) -> Void)) {
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
    
    private func parseWeatherDataFromJSON(jsonDictionary: [String: AnyObject]?) -> (CurrentWeather?, DailyWeather?) { //constructs a 'CurrentWeather' & 'DailyWeather' object from JSON dict returned by the URL request
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