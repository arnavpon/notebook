//  EnvironmentModule.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/27/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Module used to collect weather data (outdoor environment) based on the user's location. Also the mdodule used to measure temperature & humidity data (indoor environment) from sensor.

import Foundation

class EnvironmentModule: Module {
    
    override func getConfigureModuleLayoutObject() -> Dictionary<String, AnyObject> {
        var tempObject = super.getConfigureModuleLayoutObject() //obtain superclass' dict & ADD TO IT
        
        var alertMessage = Dictionary<String, [String: String]>() //1st key is section name, 2nd key is behavior/computation name (using the RAW_VALUE of the ENUM object!), value is a message for the alertController
        var messageForBehavior = Dictionary<String, String>()
        for behavior in environmentModuleBehaviors {
            messageForBehavior[behavior.rawValue] = behavior.getAlertMessageForVariable()
        }
        alertMessage[BMN_BehaviorsKey] = messageForBehavior
        var messageForComputation = Dictionary<String, String>()
        for computation in environmentModuleComputations {
            messageForComputation[computation.rawValue] = computation.getAlertMessageForVariable()
        }
        alertMessage[BMN_ComputationsKey] = messageForComputation
        tempObject[BMN_AlertMessageKey] = alertMessage //merge dictionaries
        
        return tempObject
    }
    
    private let environmentModuleBehaviors: [EnvironmentModuleVariableTypes] = [EnvironmentModuleVariableTypes.Behavior_TemperatureAndHumidity, EnvironmentModuleVariableTypes.Behavior_Weather]
    override func setBehaviors() -> [String]? { //dynamically assigns behaviors
        var behaviorTitles: [String] = []
        
        //(1) Set filters (i.e. exclude certain computations based on 'blockers' & 'locationInFlow'):
        var filteredTypes = Set<EnvironmentModuleVariableTypes>() //set containing types to be filtered
        if let blocker = moduleBlocker {
            let filters = blocker.getFilteredTypesForModule(Modules.EnvironmentModule)
            for filter in filters {
                if let enumValue = EnvironmentModuleVariableTypes(rawValue: filter) {
                    filteredTypes.insert(enumValue)
                }
            }
        }
        
        //(2) Add items -> 'behaviors' array if they pass through filters:
        for behavior in environmentModuleBehaviors {
            if !(filteredTypes.contains(behavior)) { //exclude filtered varTypes
                behaviorTitles.append(behavior.rawValue)
            }
        }
        return behaviorTitles
    }
    
    private let environmentModuleComputations: [EnvironmentModuleVariableTypes] = []
    override func setComputations() -> [String]? {
        var computationTitles: [String] = []
        
        //(1) Set filters (i.e. exclude certain computations based on 'blockers' & 'locationInFlow'):
        var filteredTypes = Set<EnvironmentModuleVariableTypes>() //set containing types to be filtered
        if let blocker = moduleBlocker {
            let filters = blocker.getFilteredTypesForModule(Modules.EnvironmentModule)
            for filter in filters {
                if let enumValue = EnvironmentModuleVariableTypes(rawValue: filter) {
                    filteredTypes.insert(enumValue)
                }
            }
        }
        
        //(2) Add items -> 'computations' array if they pass through filters:
        for computation in environmentModuleComputations {
            if !(filteredTypes.contains(computation)) { //exclude filtered varTypes
                computationTitles.append(computation.rawValue)
            }
        }
        return computationTitles
    }
    
    private var variableType: EnvironmentModuleVariableTypes? { //converts 'selectedFunctionality' (a String) to an enum object
        get {
            if let selection = selectedFunctionality {
                return EnvironmentModuleVariableTypes(rawValue: selection)
            }
            return nil
        }
    }
    
    //Configuration Properties (unique to specific behaviors/computations):
    private var selectedWeatherOptions: [EnvironmentModule_WeatherOptions] = [] //granular weather options the user wants to capture
    
    // MARK: - Initializers
    
    override init(name: String) { //set-up init
        super.init(name: name)
        self.moduleTitle = Modules.EnvironmentModule.rawValue
    }
    
    override init(name: String, dict: [String: AnyObject]) { //CoreData init
        super.init(name: name, dict: dict)
        self.moduleTitle = Modules.EnvironmentModule.rawValue
        
        //Break down the dictionary depending on the variable's type key & reconstruct object:
        if let typeName = dict[BMN_VariableTypeKey] as? String, type = EnvironmentModuleVariableTypes(rawValue: typeName) {
            self.selectedFunctionality = typeName //reset the variable's selectedFunctionality
            switch type { //configure according to 'variableType'
            case .Behavior_TemperatureAndHumidity: //no unpacking needed?
                break
            case .Behavior_Weather: //unpack the selected options (weather, temp, humidity, etc.)
                if let options = dict[BMN_EnvironmentModule_Weather_SelectedOptionsKey] as? [String] {
                    //Convert the rawValues -> enum objects:
                    for option in options {
                        print("[EnM init()] Weather Option: \(option).")
                        if let weatherOption = EnvironmentModule_WeatherOptions(rawValue: option) {
                            self.selectedWeatherOptions.append(weatherOption)
                        }
                    }
                }
            }
        } else {
            print("[EnvironModule > CoreData initializer] Error! Could not find a type for the object.")
        }
    }
    
    deinit { //remove notification observer (in case service has failed)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func copyWithZone(zone: NSZone) -> AnyObject { //creates copy of variable
        let copy = EnvironmentModule(name: self.variableName)
        copy.existingVariables = self.existingVariables
        copy.moduleBlocker = self.moduleBlocker
        copy.configurationType = self.configurationType
        return copy
    }
    
    // MARK: - Variable Configuration
    
    internal override func setConfigurationOptionsForSelection() { //handles ALL configuration for ConfigOptionsVC - (1) Sets the 'options' value as needed; (2) Constructs the configuration TV cells if required; (3) Sets 'isAutoCaptured' var if var is auto-captured.
        super.setConfigurationOptionsForSelection() //set superclass config info
        if (configurationOptionsLayoutObject == nil) {
            configurationOptionsLayoutObject = [] //initialize
        }
        if let type = variableType { //make sure behavior/computation was selected & ONLY set the configOptionsObject if further configuration is required
            var array: [(ConfigurationOptionCellTypes, Dictionary<String, AnyObject>)] = [] //pass -> VC (CustomCellType, cell's dataSource)
            switch type {
            case EnvironmentModuleVariableTypes.Behavior_TemperatureAndHumidity:
                
                self.variableReportType = ModuleVariableReportTypes.AutoCapture //auto-cap
                configurationOptionsLayoutObject!.appendContentsOf(array)
                
            case EnvironmentModuleVariableTypes.Behavior_Weather:
                
                //1 config cell is needed (SelectFromOptions):
                let options = [EnvironmentModule_WeatherOptions.Temperature.rawValue, EnvironmentModule_WeatherOptions.ApparentTemperature.rawValue, EnvironmentModule_WeatherOptions.Humidity.rawValue, EnvironmentModule_WeatherOptions.WindSpeed.rawValue, EnvironmentModule_WeatherOptions.Ozone.rawValue, EnvironmentModule_WeatherOptions.BarometricPressure.rawValue, EnvironmentModule_WeatherOptions.CloudCover.rawValue, EnvironmentModule_WeatherOptions.SunriseTime.rawValue, EnvironmentModule_WeatherOptions.SunsetTime.rawValue, EnvironmentModule_WeatherOptions.WeatherCondition.rawValue] //enum opts
                array.append((ConfigurationOptionCellTypes.SelectFromOptions, [BMN_Configuration_CellDescriptorKey: BMN_EnvironmentModule_Weather_SelectedOptionsKey, BMN_LEVELS_MainLabelKey: "Select 1 or more kinds of weather data you want to capture with this variable:", BMN_SelectFromOptions_OptionsKey: options, BMN_SelectFromOptions_MultipleSelectionEnabledKey: true])) //cell that contains granular weather selection options
                
                configurationOptionsLayoutObject!.appendContentsOf(array)
                
            }
        } else { //no selection, set configOptionsObj -> nil
            configurationOptionsLayoutObject = nil
        }
    }
    
    internal override func matchConfigurationItemsToProperties(configurationData: [String: AnyObject]) -> (Bool, String?, [String]?) {
        //(1) Takes as INPUT the data that was entered into each config TV cell. (2) Given the variableType, matches configuration data -> properties in the Module object by accessing specific configuration cell identifiers (defined in 'HelperFx' > 'Dictionary Keys').
        let superclassReturnVal = super.matchConfigurationItemsToProperties(configurationData)
        if (superclassReturnVal.0 == false) { //if checks are failed @ superclass lvl, return super obj
            return superclassReturnVal
        }
        if let type = variableType { //obtain config info stored against the appropriate ID
            switch type { //only needed for sections that require configuration
            case .Behavior_Weather: //incoming data - selection of subsets of weather data
                
                if let options = configurationData[BMN_EnvironmentModule_Weather_SelectedOptionsKey] as? [String] { //get selected options
                    self.selectedWeatherOptions = [] //clear array before proceeding
                    for option in options {
                        if let weatherOption = EnvironmentModule_WeatherOptions(rawValue: option) {
                            self.selectedWeatherOptions.append(weatherOption)
                            self.variableReportType = ModuleVariableReportTypes.AutoCapture //auto-cap
                        } else {
                            print("[EM - matchConfigItems] String does not match enum raw!")
                        }
                    }
                    print("Selected Options: \(selectedWeatherOptions).")
                    return (true, nil, nil) //passed check
                } else {
                    return (false, "No options were selected!", nil)
                }
                
            default:
                return (true, nil, nil)
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
            case .Behavior_TemperatureAndHumidity:
                break //nothing to store? (sensor transmits whatever data it is designed to transmit)
            case .Behavior_Weather:
                var optionsAsString: [String] = []
                for option in selectedWeatherOptions { //store options as rawValues
                    optionsAsString.append(option.rawValue)
                }
                persistentDictionary[BMN_EnvironmentModule_Weather_SelectedOptionsKey] = optionsAsString
            }
        }
        return persistentDictionary
    }
    
    // MARK: - Data Entry Logic
    
    lazy var coreLocationManager = CoreLocationManager()
    
    func getTypeForVariable() -> EnvironmentModuleVariableTypes? { //used by DataEntry clls as safety chck
        return self.variableType
    }
    
    override func populateDataObjectForAutoCapturedVariable() { //gets data for auto-cap variable
        mainDataObject = nil //clear object before overwriting!
        if let type = variableType { //source of auto-cap data depends on varType
            switch type {
            case .Behavior_Weather: //access current location from CLManager
                NSNotificationCenter.defaultCenter().removeObserver(self, name: BMN_Notification_CoreLocationManager_LocationDidChange, object: nil) //*safety item*
                NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.didReceiveLocationFromCLManager(_:)), name: BMN_Notification_CoreLocationManager_LocationDidChange, object: nil) //register
                let success = coreLocationManager.startStandardUpdates() //start up CL to get location
                if !(success) { //no access to location services, remove notification observer
                    NSNotificationCenter.defaultCenter().removeObserver(self, name: BMN_Notification_CoreLocationManager_LocationDidChange, object: nil)
                }
            case .Behavior_TemperatureAndHumidity:
                break
            }
        }
    }
    
    @objc func didReceiveLocationFromCLManager(notification: NSNotification) {
        if let info = notification.userInfo, latitude = info[BMN_CoreLocationManager_LatitudeKey] as? Double, longitude = info[BMN_CoreLocationManager_LongitudeKey] as? Double {
            NSNotificationCenter.defaultCenter().removeObserver(self) //remove observer after firing 1x
            let service = WeatherForecastService(coordinate: (latitude, longitude)) //create API request
            service.getWeatherObjectFromAPI({ (let weather) in
                if let currentWeather = weather.0, dailyWeather = weather.1 { //check for nil objects
                    var combinedDict = Dictionary<String, AnyObject>()
                    let currentInfo = currentWeather.reportDataForWeatherVariable(self.selectedWeatherOptions)
                    let dailyInfo = dailyWeather.reportDataForWeatherVariable(self.selectedWeatherOptions)
                    for (key, value) in currentInfo { //update combinedObject w/ currentWeatherInfo
                        combinedDict.updateValue(value, forKey: key)
                    }
                    for (key, value) in dailyInfo { //update combinedObject w/ dailyWeatherInfo
                        combinedDict.updateValue(value, forKey: key)
                    }
                    self.mainDataObject = combinedDict
                }
            })
        }
    }
    
    override func isSubscribedToService(service: ServiceTypes) -> Bool {
        if let type = self.variableType { //check if subscribed to service using enum object
            return type.isSubscribedToService(service)
        }
        return false
    }
    
    // MARK: - Data Aggregation Logic
    
    override func reportDataForVariable() -> [String : AnyObject]? {
        var returnObject = super.reportDataForVariable() //grab superclass obj first
        var selections: [String] = [] //list of all selected weather options
        for selection in selectedWeatherOptions { //for vars w/ 'dict' type mainDataObjects (weather), ALL available options must be passed -> DB for table creation
            selections.append(selection.rawValue)
        }
        returnObject?.updateValue(selections, forKey: BMN_Module_OptionsForDictKey)
        return returnObject
    }
    
}

enum EnvironmentModuleVariableTypes: String {//*match each behavior/computation -> Configuration + DataEntry custom TV cells; for each new behavior/comp added, you must also add (1) Configuration logic, (2) Core Data storage logic (so the variable config can be preserved), (3) Unpacking logic (in the DataEntry initializer), & (4) DataEntry logic (enabling the user to report info).* 
    //Available Behaviors:
    case Behavior_TemperatureAndHumidity = "Temperature & Humidity"
    case Behavior_Weather = "Weather"
    
    //Available Computations:
    
    func getAlertMessageForVariable() -> String {
        var message = ""
        switch self {
        case .Behavior_TemperatureAndHumidity:
            message = "A variable that uses a custom sensor to determine the temperature &/or humidity in the indoor environment surrounding you."
        case .Behavior_Weather:
            message = "A variable that determines the current weather at your location, including ambient temperature & humidity. <Must enable location services for its use>"
        }
        return message
    }
    
    func isSubscribedToService(service: ServiceTypes) -> Bool { //list of subscribed services for each variableType
        let subscribedServices: [ServiceTypes]
        switch self { //for each var that uses services, create list of subscribed services
        case .Behavior_Weather:
            subscribedServices = [ServiceTypes.CoreLocation, ServiceTypes.Internet]
        default:
            subscribedServices = [] //no subscribed services
        }
        if (subscribedServices.contains(service)) { //subscribed to service
            return true
        } else { //NOT subscribed to service
            return false
        }
    }
    
}

enum EnvironmentModule_WeatherOptions: String { //granular options for the WEATHER behavior that allow the user to pick & choose what kinds of ambient information they want to collect for a given project

    case Temperature = "Temperature"
    case ApparentTemperature = "Apparent Temperature"
    case Humidity = "Humidity"
    case WindSpeed = "Wind Speed"
    case WeatherCondition = "Weather Condition"
    case Ozone = "Ozone"
    case BarometricPressure = "Barometric Pressure"
    case CloudCover = "Cloud Cover"
    case SunriseTime = "Sunrise Time"
    case SunsetTime = "Sunset Time"
    
}