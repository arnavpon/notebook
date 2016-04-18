//  EnvironmentModule.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/27/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Module used to collect weather data (outdoor environment) based on the user's location. Also the mdodule used to measure temperature & humidity data (indoor environment) from sensor.

import Foundation

class EnvironmentModule: Module {
    
    private let environmentModuleBehaviors: [EnvironmentModuleVariableTypes] = [EnvironmentModuleVariableTypes.Behavior_TemperatureAndHumidity, EnvironmentModuleVariableTypes.Behavior_Weather]
    override var behaviors: [String] { //object containing titles for TV cells
        var behaviorTitles: [String] = []
        for behavior in environmentModuleBehaviors {
            behaviorTitles.append(behavior.rawValue)
        }
        return behaviorTitles
    }
    
    private let environmentModuleComputations: [EnvironmentModuleVariableTypes] = []
    override var computations: [String] { //object containing titles for TV cells
        var computationTitles: [String] = []
        for computation in environmentModuleComputations {
            computationTitles.append(computation.rawValue)
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
    private let concatenationSeparator: String = "__" //separator for CoreData combinedString object
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
    
    // MARK: - Variable Configuration
    
    internal override func setConfigurationOptionsForSelection() { //handles ALL configuration for ConfigOptionsVC - (1) Sets the 'options' value as needed; (2) Constructs the configuration TV cells if required; (3) Sets 'isAutoCaptured' var if var is auto-captured.
        if let type = variableType { //make sure behavior/computation was selected & ONLY set the configOptionsObject if further configuration is required
            var array: [(ConfigurationOptionCellTypes, Dictionary<String, AnyObject>)] = [] //pass -> VC (CustomCellType, cell's dataSource)
            switch type {
            case EnvironmentModuleVariableTypes.Behavior_TemperatureAndHumidity:
                
                configurationOptionsLayoutObject = nil //no further config needed??
                
            case EnvironmentModuleVariableTypes.Behavior_Weather:
                
                //1 config cell is needed (SelectFromOptions):
                array.append((ConfigurationOptionCellTypes.SelectFromOptions, [BMN_Configuration_CellDescriptorKey: BMN_EnvironmentModule_Weather_OptionsID, BMN_LEVELS_MainLabelKey: "Select 1 or more kinds of weather data you want to capture with this variable:", BMN_SelectFromOptions_OptionsKey: [], BMN_SelectFromOptions_MultipleSelectionEnabledKey: true])) //cell that contains granular weather selection options
                
                configurationOptionsLayoutObject = array
                
            }
        } else { //no selection, set configOptionsObj -> nil
            configurationOptionsLayoutObject = nil
        }
    }
    
    internal override func matchConfigurationItemsToProperties(configurationData: [String: AnyObject]) -> (Bool, String?, [String]?) {
        //(1) Takes as INPUT the data that was entered into each config TV cell. (2) Given the variableType, matches configuration data -> properties in the Module object by accessing specific configuration cell identifiers (defined in 'HelperFx' > 'Dictionary Keys').
        if let type = variableType { //obtain config info stored against the appropriate ID
            switch type { //only needed for sections that require configuration
            case .Behavior_Weather: //incoming data - selection of weather alone, temperature alone, humidity alone, or some combination of them. Depending on the info offered by the API, set the granularity.
                
                if let options = configurationData[BMN_EnvironmentModule_Weather_OptionsID] as? [String] { //get selected options
                    self.selectedWeatherOptions = [] //clear array before proceeding
                    for option in options {
                        if let weatherOption = EnvironmentModule_WeatherOptions(rawValue: option) {
                            self.selectedWeatherOptions.append(weatherOption)
                        } else {
                            print("[EM - matchConfigItems] String does not match enum raw!")
                        }
                    }
                } else {
                    return (false, "No options were selected!", nil)
                }
                
            default:
                print("[EnvironmentMod: matchConfigToProps] Error! Default in switch!")
                return (false, "Default in switch!", nil)
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
    
    func getTypeForVariable() -> EnvironmentModuleVariableTypes? { //used by DataEntry cells for safety
        return self.variableType
    }
    
    override func getDataEntryCellTypeForVariable() -> DataEntryCellTypes? { //indicates to DataEntryVC what kind of DataEntry cell should be used for this variable
        if let type = self.variableType {
            switch type {
            default:
                return nil
            }
        }
        return nil
    }
    
    override var cellHeightUserInfo: [String : AnyObject]? { //define DYNAMIC cell heights
        return nil
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
    
}

enum EnvironmentModule_WeatherOptions: String { //granular options for the WEATHER behavior that allow the user to pick & choose what kinds of ambient information they want to collect for a given project.
    //**define this based on the information returned by the weather API
    case Weather = "Weather" //e.g. sunny, rainy, cloudy, etc.
    case AmbientTemperature = "Ambient Temperature"
    case AmbientHumidity = "Ambient Humidity"
}