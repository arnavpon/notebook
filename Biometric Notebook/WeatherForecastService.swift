//  WeatherForecastService.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 4/18/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

import Foundation

//***Need to make safe keys for all of the weather API dictionary objects!!!

struct CurrentWeather { //object used to represent the CURRENT WEATHER for EnvironmentModule_Weather vars
    
    let temperature: Int? //ºF
    let apparentTemperature: Int? //ºF
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
    
    func reportDataForWeatherVariable(filter: [String]) -> [String: AnyObject] { //**based on the user's defined preferences for a Weather variable, filter the data that is reported by this variable (e.g. if they only want ambient temperature, provide only that).
        var reportObject = Dictionary<String, AnyObject>()
        reportObject["temperature"] = self.temperature
        reportObject["apparentTemperature"] = self.apparentTemperature
        reportObject["humidity"] = self.relativeHumidity
        reportObject["windSpeed"] = self.windSpeed
        reportObject["icon"] = self.icon
        reportObject["precipType"] = self.precipType
        reportObject["ozone"] = self.ozone
        reportObject["pressure"] = self.pressure
        reportObject["cloudCover"] = self.cloudCover
        return reportObject
    }
    
}

struct DailyWeather { //object used to represent the DAILY WEATHER (used to grab potentially useful data points that are found in the 'daily' > 'data'.first dictionary)
    
    let sunriseTime: NSTimeInterval? //UNIX time stamp (# of seconds since Jan 1, 1970)
    let sunsetTime: NSTimeInterval? //timeStamp
    let temperatureMin: Int? //ºF
    let temperatureMinTime: NSTimeInterval? //timeStamp
    let temperatureMax: Int? //ºF
    let temperatureMaxTime: NSTimeInterval? //timeStamp
    let apparentTemperatureMin: Int? //ºF
    let apparentTemperatureMinTime: NSTimeInterval? //timeStamp
    let apparentTemperatureMax: Int? //ºF
    let apparentTemperatureMaxTime: NSTimeInterval? //timeStamp
    
    // MARK: - Initializer
    
    init(weatherDictionary: [String: AnyObject]) { //extract info from the 'DAILY' dict
        sunriseTime = weatherDictionary["sunriseTime"] as? NSTimeInterval
        sunsetTime = weatherDictionary["sunsetTime"] as? NSTimeInterval
        temperatureMin = weatherDictionary["temperatureMin"] as? Int
        temperatureMinTime = weatherDictionary["temperatureMinTime"] as? NSTimeInterval
        temperatureMax = weatherDictionary["temperatureMax"] as? Int
        temperatureMaxTime = weatherDictionary["temperatureMaxTime"] as? NSTimeInterval
        apparentTemperatureMin = weatherDictionary["apparentTemperatureMin"] as? Int
        apparentTemperatureMinTime = weatherDictionary["apparentTemperatureMinTime"] as? NSTimeInterval
        apparentTemperatureMax = weatherDictionary["apparentTemperatureMax"] as? Int
        apparentTemperatureMaxTime = weatherDictionary["apparentTemperatureMaxTime"] as? NSTimeInterval
        
        if let sunrise = sunriseTime, sunset = sunsetTime {
            let rise = NSDate(timeIntervalSince1970: sunrise)
            let set = NSDate(timeIntervalSince1970: sunset)
            print("Sunrise: \(DateTime(date: rise).getFullTimeStamp()). Sunset: \(DateTime(date: set).getFullTimeStamp()).")
        }
    }
    
    // MARK: - Data Reporting Logic
    
    func reportDataForWeatherVariable(filter: [String]) -> [String: AnyObject] {
        var reportObject = Dictionary<String, AnyObject>()
        reportObject["sunriseTime"] = self.sunriseTime
        reportObject["sunsetTime"] = self.sunsetTime
        reportObject["temperatureMin"] = self.temperatureMin
        reportObject["temperatureMinTime"] = self.temperatureMinTime
        reportObject["temperatureMax"] = self.temperatureMax
        reportObject["temperatureMaxTime"] = self.temperatureMaxTime
        reportObject["apparentTempMin"] = self.apparentTemperatureMin
        reportObject["apparentTempMinTime"] = self.apparentTemperatureMinTime
        reportObject["apparentTempMax"] = self.apparentTemperatureMax
        reportObject["apparentTempMaxTime"] = self.apparentTemperatureMaxTime
        return reportObject
    }
    
}

struct ForecastService { //creates a SPECIALIZED network connection (utilizing the 'NetworkConnection' class) w/ the WeatherAPI to obtain weather data @ the user's current location. The obtained data is used to populate the 'CurrentWeather' struct.
    
    private let forecastAPIKey = "50d0ace7a11ac15f3f335d70512f12be"
    private let coordinate: (latitude: Double, longitude: Double) //obtain coordinates from CL manager
    private var forecastBaseURL: NSURL? { //base URL for the weather API
        return NSURL(string: "https://api.forecast.io/forecast/\(forecastAPIKey)/")
    }
    
    // MARK: - Initializer
    
    init(coordinate: (latitude: Double, longitude: Double)) { //initialize w/ coordinates @ which to obtain CURRENT weather
        self.coordinate = coordinate
    }
    
    // MARK: - Networking Logic
    
    func getWeatherObjectFromAPI(completion: ((CurrentWeather?, DailyWeather?) -> Void)) {
        if let forecastURL = NSURL(string: "\(coordinate.latitude),\(coordinate.longitude)", relativeToURL: forecastBaseURL) {
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