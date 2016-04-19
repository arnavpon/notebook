//  WeatherForecastService.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 4/18/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

import Foundation

struct CurrentWeather { //object used to represent the CURRENT WEATHER for EnvironmentModule_Weather vars
    
    let temperature: Int? //degrees F
    let apparentTemperature: Int? //degrees F
    let relativeHumidity: Int? //0-100%
    let windSpeed: Int? //measured in MPH
    let icon: String? //name indicates the current Weather
    let precipType: String? //if precipIntensity > 0, indicates the type of precipitation (make sure it matches the icon)
    let ozone: Int? //measured in Dobson units
    let pressure: Int? //measured in millibars
    let cloudCover: Int? //0-100%, indicates % of sky occluded by clouds
    
    // MARK: - Initializer
    
    init(weatherDictionary: [String: AnyObject]) { //extract values from the 'CURRENT' dict
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
    
    func reportDataForWeatherVariable(variable: EnvironmentModule) -> [String: AnyObject] { //**based on the user's defined preferences for a Weather variable, filter the data that is reported by this variable (e.g. if they only want ambient temperature, provide only that).
        let reportObject = Dictionary<String, AnyObject>()
        return reportObject
    }
    
}

struct DailyWeather { //object used to represent the DAILY WEATHER (used to grab potentially useful data points that are found in the 'daily' dictionary)
    
    let sunriseTime: Int? //represented as UNIX time stamp w/ # of seconds since Jan 1, 1970 (NSDate has method to convert that)
    let sunsetTime: Int? //**may be different type!
    let temperatureMin: Int? //ºF
    let temperatureMinTime: Int? //UNIX timeStamp
    let temperatureMax: Int? //ºF
    let temperatureMaxTime: Int?
    let apparentTemperatureMin: Int? //ºF
    let apparentTemperatureMinTime: Int?
    let apparentTemperatureMax: Int? //ºF
    let apparentTemperatureMaxTime: Int?
    
    // MARK: - Initializer
    
    init(weatherDictionary: [String: AnyObject]) { //extract info from the 'DAILY' dict
        sunriseTime = weatherDictionary["sunriseTime"] as? Int
        sunsetTime = weatherDictionary["sunsetTime"] as? Int
        temperatureMin = weatherDictionary["temperatureMin"] as? Int
        temperatureMinTime = weatherDictionary["temperatureMinTime"] as? Int
        temperatureMax = weatherDictionary["temperatureMax"] as? Int
        temperatureMaxTime = weatherDictionary["temperatureMaxTime"] as? Int
        apparentTemperatureMin = weatherDictionary["apparentTemperatureMin"] as? Int
        apparentTemperatureMinTime = weatherDictionary["apparentTemperatureMinTime"] as? Int
        apparentTemperatureMax = weatherDictionary["apparentTemperatureMax"] as? Int
        apparentTemperatureMaxTime = weatherDictionary["apparentTemperatureMaxTime"] as? Int
    }
    
    // MARK: - Data Reporting Logic
    
    func reportDataForWeatherVariable(variable: EnvironmentModule) -> [String: AnyObject] { //**
        let reportObject = Dictionary<String, AnyObject>()
        return reportObject
    }
    
}

struct ForecastService { //creates a SPECIALIZED network connection (utilizing the 'NetworkConnection' class) w/ the WeatherAPI to obtain weather data @ the user's current location. The obtained data is used to populate the 'CurrentWeather' struct.
    
    private let forecastAPIKey = "50d0ace7a11ac15f3f335d70512f12be" //**key still working???
    private let coordinate: (latitude: Double, longitude: Double) //obtain coordinates from CL manager
    private var forecastBaseURL: NSURL? { //base URL for the weather API
        return NSURL(string: "https://api.forecast.io/forecast/\(forecastAPIKey)/")
    }
    
    // MARK: - Initializer
    
    init(coordinate: (Double, Double)) { //initialize w/ coordinates @ which to obtain CURRENT weather
        self.coordinate = coordinate
    }
    
    // MARK: - Networking Logic
    
    func getCurrentWeather(completion: (CurrentWeather? -> Void)) {
        if let forecastURL = NSURL(string: "\(coordinate.latitude),\(coordinate.longitude)", relativeToURL: forecastBaseURL) {
            let networkOperation = NetworkConnection(url: forecastURL)
            
            //Download JSON object from constructed URL (w/ API key & location coordinates):
            networkOperation.downloadJSONFromURL({ (let JSONDictionary) in
                let currentWeather = self.currentWeatherFromJSON(JSONDictionary)
                completion(currentWeather) //pass forecast -> completionHandler
            })
        } else {
            print("Could not construct valid URL")
        }
    }
    
    func getDailyWeather(completion: (DailyWeather? -> Void)) {
        if let forecastURL = NSURL(string: "\(coordinate.latitude),\(coordinate.longitude)", relativeToURL: forecastBaseURL) {
            let networkOperation = NetworkConnection(url: forecastURL)
            
            //Download JSON object from constructed URL (w/ API key & location coordinates):
            networkOperation.downloadJSONFromURL({ (let JSONDictionary) in
                let dailyWeather = self.dailyWeatherFromJSON(JSONDictionary)
                completion(dailyWeather) //pass forecast -> completionHandler
            })
        } else {
            print("Could not construct valid URL")
        }
    }

    
    // MARK: - Data Parsing Logic
    
    private func currentWeatherFromJSON(jsonDictionary: [String: AnyObject]?) -> CurrentWeather? { //construct a 'CurrentWeather' object from the JSON dict returned by the URL request
        if let currentWeatherDictionary = jsonDictionary?["currently"] as? [String: AnyObject] { //data stored against 'currently' key gives CURRENT weather
            print(currentWeatherDictionary)
            return CurrentWeather(weatherDictionary: currentWeatherDictionary)
        } else { //JSONDict does NOT have a 'currently' key
            print("JSON dictionary returned nil for 'currently' key")
            return nil
        }
    }
    
    private func dailyWeatherFromJSON(jsonDictionary: [String: AnyObject]?) -> DailyWeather? { //construct a 'DailyWeather' object from the JSON dict returned by the URL request
        if let dailyWeatherDictionary = jsonDictionary?["daily"] as? [String: AnyObject] { //data stored against 'daily' key gives DAILY weather
            print(dailyWeatherDictionary)
            return DailyWeather(weatherDictionary: dailyWeatherDictionary)
        } else { //JSONDict does NOT have a 'daily' key
            print("JSON dictionary returned nil for 'daily' key")
            return nil
        }
    }
    
}