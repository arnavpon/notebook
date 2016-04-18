//  ReturnedDataObject.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 12/27/15.
//  Copyright © 2015 Confluent Ideals. All rights reserved.

//This data object will be populated AFTER the app sends request -> server -> & obtains JSON data as a response. Once we receive JSON, we will break it down into a custom dictionary object - we know what parameters could possibly be returned & create a dictionary entry for each potential parameter.

import Foundation

struct ReturnedDataObject {
    let patientID: Int? //get back patientID after creating new patient
    let totalCount : Int?
    let practiceInfo : [[String : String]]?
    let departments : [[String : AnyObject]]?
    
    init(emrDataDictionary : [String: AnyObject]) { //Make sure to use conditional chaining b/c we don't know what pieces of info will be returned when
        self.patientID = emrDataDictionary["patientID"] as? Int
        
        self.totalCount = emrDataDictionary["totalcount"] as? Int
        self.practiceInfo = emrDataDictionary["practiceinfo"] as? [[String : String]]
        self.departments = emrDataDictionary["departments"] as? [[String : AnyObject]]
    }
}

private let forecastAPIKey = "50d0ace7a11ac15f3f335d70512f12be" //used to ID ourselves to API, must be included in the unique URL call we make to the API. <Keep in mind that you may need to secure your API key>

let coordinate : (lat : Double, long : Double) = (37.8267, -122.423) //These are the coordinates being used to find the weather for a specific location.

//Model of current weather - we are creating a struct w/ some attributes. To see the format of data points coming in from the API, go to the 'DATA POINTS' section of API documentation! We may or may not get any one of the data points that we define a variable for, so we must use optionals.

struct CurrentWeather {
    
    let temperature : Int?
    let humidity : Int?
    let precipProbability : Int?
    let summary : String?
    var icon : UIImage? = UIImage(named: "default.png") //needs to be a var, not constant, so that we can change its value after initializing
    
    //Create custom initializer that will draw values for the categories (like temp, humidity) from the JSON file obtained from the web API.
    init(weatherDictionary : [String: AnyObject]) {
        temperature = weatherDictionary["temperature"] as? Int
        
        //We use optional binding here b/c we want to convert decimal humidity value into a %.
        if let humidityFloat = weatherDictionary["humidity"] as? Double {
            humidity = Int(humidityFloat * 100)
        } else {
            humidity = nil
        }
        
        //We use optional binding here b/c we want to convert decimal humidity value into a %.
        if let precipFloat = weatherDictionary["precipProbability"] as? Double {
            precipProbability = Int(precipFloat * 100)
        } else {
            precipProbability = nil
        }
        summary = weatherDictionary["summary"] as? String
        //Code w/ as! forces unwrapping of an optional. Dictionaries store values as optionals b/c people often type in keys that don't exist. If we do so, b/c we are force unwrapping, this will generate an error.
        
        //Check to see that the iconString exists in the weatherDictionary:
        if let iconString = weatherDictionary["icon"] as? String, let weatherIcon : Icon = Icon(rawValue: iconString) {
            (icon, _) = weatherIcon.toImage() //<-- method call (definition is in 'Icon' enum above)
            //When a method returns a tuple, we can grab both the values by using constants or variables in parentheses. Here, we assign the regularIcon returned from the 'toImage' method directly to the 'icon' property of 'CurrentWeather'. By using an underscore _ for the second return value, instead of assigning it to a property or constant, we ignore it!
        }
    }
    
}

struct Forecast {
    var currentWeather : CurrentWeather?
    var weekly : [DailyWeather] = [] //Array of objects of DailyWeather type
    
    //When we initialize the Forecast struct, we pass in the relevant dictionaries to the models:
    init (weatherDictionary : [String : AnyObject]?) {
        if let currentWeatherDictionary = weatherDictionary?["currently"] as? [String : AnyObject] {
            //Assign currentWeatherDict as argument for init method of 'CurrentWeather' struct:
            print(currentWeatherDictionary)
            currentWeather = CurrentWeather(weatherDictionary: currentWeatherDictionary)
        }
        
        //Generating our array of weeklyWeather objects (stored by the "daily" key in the API's returned JSON dictionary):
        //The "daily" key gives us access to a dictionary. Then we want to access the array of daily instances, so on the 'daily' key we call the 'data' key. 'Data' is an ARRAY of type DICT!
        //Since we are passing in an optional dictionary, we need to check for the 'daily' key using a ?; if this exists, we then check for the 'data' key with a ?.
        if let weeklyWeatherArray = weatherDictionary?["daily"]?["data"] as? [[String : AnyObject]] {
            //We will iterate over each object returned, and then pass it to the 'DailyWeather' struct to create instances of that type. Then we append this to the 'weekly' array.
            for dailyWeather in weeklyWeatherArray {
                let daily = DailyWeather(dailyWeatherDictionary: dailyWeather)
                weekly.append(daily)
            }
        }
    }
    
}

//Here we create a class, NOT a struct, for a specific reason - when a struct is created, it creates an immutable object w/ immutable properties. When we create the data task, we use a method that mutates the session object, which would cause Xcode to complain.
class NetworkOperation {
    lazy var config : NSURLSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
    lazy var session : NSURLSession = NSURLSession(configuration: self.config) //Make sure you use 'self.config' b/c of the lazy loading (you need to grab the current instance's config value), which isn't loaded until needed.
    //LAZY LOADING defers the loading of initial values to a class variable until right before these variables are needed. This is useful b/c if there is a gap between initialization & actual use of the variables in the code, these properties are just occupying space in the memory without doing anything (memory management issue).
    let queryURL : NSURL
    
    init(url : NSURL) {
        self.queryURL = url
    }
    
    typealias JSONDictionaryCompletion = ([String : AnyObject]?) -> Void //Type Alias for closure type
    
    //Functions implementing callbacks, as the following function does, take a FUNC as an ARGUMENT (the closure)! Essentially, the closure is a function being used as an input parameter to the current function being called. That function has an input & return type, like any other function does. Our closure has a dictionary input type, and returns VOID. This might seem counterintuitive - in our downloadJSON function, we want to RETURN a dictionary, not input it as a parameter. This is where the idea of a callback comes in - we don't want to return the dictionary, b/c this will block the main thread until the return is complete. Instead, we call a function that the person calling the downloadJSON function has given us & provide the associated arguments: this means that the callback/closure is ONLY defined when the function is called in the code, not when it is defined (as we are doing below). Go to the 'NetworkOperation' file to see what happens when the code is called.
    func downloadJSONFromURL(completion : JSONDictionaryCompletion) {
        //The dictionary parameter contains objects of type [String key : AnyObject value], returns void; the 'download' method downloads JSON information from the queryURL we stored as a property above, & has a single parameter (a closure, as a callback).
        //The forecast API returns JSON data formatted as a dictionary, so we are choosing to return the data as a dictionary. The parameter in this closure - the dictionary - will be populated AFTER the 'download' method has been performed with the JSON data from the API! Thus, the completion handler RETURNS a JSON DICT!
        //Our Dictionary is ? type b/c the network call might not work & we will get nil as the variable's value; we want our code to avoid crashing in this case.
        let request : NSURLRequest = NSURLRequest(URL: queryURL)
        let dataTask = session.dataTaskWithRequest(request) {//Creating a trailing closure since it is the last argument; return type is void so we don't need to type it. 'Data', 'Response' & 'Error' refer to the parameters in the original closure recommended by the dataTask function.
            (let data, let response, let error) in
            //1. Check HTTP response for successful GET request - HTTP response is a message the server sends the client when it receives a request (response contains information like status code, date, etc.). First we must cast 'response' to an NSHTTPURLResponse object.
            if let httpResponse = response as? NSHTTPURLResponse {
                //If we have a valid response object we can carry on w/ step 2. If we don't have a valid response, we need to let the user know.
                switch httpResponse.statusCode {//Create switch statement for different status codes that can be generated
                case 200: //2. Successful response: create JSON object w/ data
                    let jsonDictionary = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: nil) as? [String : AnyObject] //NSJSONSerialization converts between JSON objects & foundations ones (usually dictionaries). The 'option' parameter specifies ways you might want the data to be formatted. We use the default.
                    
                    completion(jsonDictionary) //Return the jsonDict to the closure, allowing it to act as the output of the function.
                default:
                    print("Get request not successful. HTTP status code: \(httpResponse.statusCode)")
                }
            } else {
                print("Error: not a valid HTTP response")
            }
        }
        dataTask.resume()
    }
    //Now we can create an instance of this class & use the downloadJSONFromURL function to pull data from the API into the app.
    //We use a CLASS for the NetworkOperation instead of a STRUCT b/c we are creating a data task w/ a method that CHANGES the session object (structs have immutable properties).
}

struct ForecastService {
    let forecastAPIKey : String //need API key property to interact w/ API
    let forecastBaseURL : NSURL? //the base URL to get to the website w/ data
    
    init(APIKey : String) {
        self.forecastAPIKey = APIKey
        forecastBaseURL = NSURL(string: "https://api.forecast.io/forecast/\(forecastAPIKey)/")
    }
    
    func getForecast(lat : Double, long : Double, completion : (Forecast? -> Void)) {
        //We use a closure here b/c from inside this method, we call the downloadJSONFromURL method in the NetworkOperation class (making an asynchronous call). We can't return an object from inside the closure unless we implement a callback. Since our network request can fail, we make the Forecast type optional.
        if let forecastURL = NSURL(string: "\(lat),\(long)", relativeToURL: forecastBaseURL) {
            let networkOperation = NetworkOperation(url: forecastURL)
            networkOperation.downloadJSONFromURL {//trailing closure: here we DEFINE the 'completion' closure found in the downloadJSONFromURL function.
                (let JSONDictionary) in
                //In this method, we parse the contents of the dictionary & create a populated instance of the 'CurrentWeather' class.
                let forecast = Forecast(weatherDictionary: JSONDictionary)
                completion(forecast) //When we call 'completion' & pass it 'currentWeather' object, this sends it up to the completionHandler, giving it access to the populated instance.
            }
        } else {
            print("Could not construct valid URL")
        }
    }
    
    //This function takes as an input a jsonDictionary (obtained from the NetworkOperation.downloadJSONDictionary method). It uses this dictionary to populate an object of type CurrentWeather (basically it takes contents of the dictionary & uses them to populate variables in the CurrentWeather struct).
    func currentWeatherFromJSON(jsonDictionary : [String : AnyObject]?) -> CurrentWeather? {
        //Check that 'jsonDictionary' returns a non-nil value for the key 'currently'. The key 'currently', if you look @ the DarkSky API reference, returns the parameters like temperature & humidity for our location at the current time, stored as key value pairs. 'Currently' is contained in the JSON dictionary returned by the API, and its value returns another dictionary containing key-value pairs of weather information. We use the values contained in the 'currently' dict to populate our custom dictionary in CurrentWeather.
        if let currentWeatherDictionary = jsonDictionary?["currently"] as? [String : AnyObject] {
            //Assign currentWeatherDict as argument for init method of 'CurrentWeather' struct:
            print(currentWeatherDictionary)
            return CurrentWeather(weatherDictionary: currentWeatherDictionary)
        } else { //JSONDict does NOT have a 'currently' key
            print("JSON dictionary returned nil for 'currently' key")
            return nil
        }
    }
    
}