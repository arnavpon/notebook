//  BiometricModule.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/19/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Module for entering biometric data into HK (e.g. height, weight, etc.)

import Foundation
import HealthKit

class BiometricModule: Module {
    
    override var configureModuleLayoutObject: Dictionary<String, AnyObject> {
        get {
            var tempObject = super.configureModuleLayoutObject //obtain superclass' dict & ADD TO IT
            
            var alertMessage = Dictionary<String, [String: String]>() //1st key is section name, 2nd key is behavior/computation name (using the RAW_VALUE of the ENUM object!), value is a message for the alertController
            var messageForBehavior = Dictionary<String, String>()
            for behavior in biometricModuleBehaviors {
                messageForBehavior[behavior.rawValue] = behavior.getAlertMessageForVariable()
            }
            alertMessage[BMN_BehaviorsKey] = messageForBehavior
            var messageForComputation = Dictionary<String, String>()
            for computation in biometricModuleComputations {
                messageForComputation[computation.rawValue] = computation.getAlertMessageForVariable()
            }
            alertMessage[BMN_ComputationsKey] = messageForComputation
            tempObject[BMN_AlertMessageKey] = alertMessage //merge dictionaries
            
            return tempObject
        }
    }
    
    private let biometricModuleBehaviors: [BiometricModuleVariableTypes] = [BiometricModuleVariableTypes.Behavior_HeartRate, BiometricModuleVariableTypes.Behavior_Height, BiometricModuleVariableTypes.Behavior_Weight]
    override var behaviors: [String] { //object containing titles for TV cells
        var behaviorTitles: [String] = []
        for behavior in biometricModuleBehaviors {
            behaviorTitles.append(behavior.rawValue)
        }
        return behaviorTitles
    }
    
    private let biometricModuleComputations: [BiometricModuleVariableTypes] = [BiometricModuleVariableTypes.Computation_BiologicalSex, BiometricModuleVariableTypes.Computation_Age, BiometricModuleVariableTypes.Computation_BMI]
    override var computations: [String] { //object containing titles for TV cells
        var computationTitles: [String] = []
        for computation in biometricModuleComputations {
            computationTitles.append(computation.rawValue)
        }
        return computationTitles
    }
    
    private var variableType: BiometricModuleVariableTypes? { //converts 'selectedFunctionality' (a String) to an enum object
        get {
            if let selection = selectedFunctionality {
                return BiometricModuleVariableTypes(rawValue: selection)
            }
            return nil
        }
    }
    
    //Configuration Variables (for DataEntry):
    var dataSourceOption: BiometricModule_DataSourceOptions? //source from which to obtain data
    
    // MARK: - Initializers
    
    override init(name: String) { //set-up init
        super.init(name: name)
        self.moduleTitle = Modules.BiometricModule.rawValue
    }
    
    override init(name: String, dict: [String: AnyObject]) { //CoreData init
        super.init(name: name, dict: dict)
        self.moduleTitle = Modules.BiometricModule.rawValue
        
        //Break down the dictionary depending on the variable's type key & reconstruct object:
        if let typeName = dict[BMN_VariableTypeKey] as? String, type = BiometricModuleVariableTypes(rawValue: typeName) {
            self.selectedFunctionality = typeName //reset the variable's selectedFunctionality
            switch type { //configure according to 'variableType'
            case .Behavior_HeartRate: //unpack the linked device & measurement rates
                break
            case .Behavior_Weight: //unpack the data entry option (manual or HK extraction)
                if let source = dict[BMN_BiometricModule_DataSourceOptionsKey] as? String, selectedSource = BiometricModule_DataSourceOptions(rawValue: source) {
                    self.dataSourceOption = selectedSource
                }
                if let charLimit = dict[BMN_FreeformCell_CharacterLimitKey] as? Int, entryType = dict[BMN_FreeformCell_DataTypeKey] as? String, dataType = ProtectedFreeformTypes(rawValue: entryType) { //cell config options
                    self.FreeformCell_characterLimit = charLimit
                    self.FreeformCell_dataType = dataType
                }
            case .Behavior_Height:
                break
            case .Computation_BiologicalSex:
                break
            case .Computation_Age:
                break
            case .Computation_BMI:
                break
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
            case .Behavior_HeartRate:
                
                //For HR behavior, user needs to select the SUPPORTED device they will be using to measure the HR (AppleWatch, FitBit, etc.) & define the measurement parameters:
                let options = [BiometricModule_DataSourceOptions.AppleWatch.rawValue, BiometricModule_DataSourceOptions.FitBit.rawValue]
                array.append((ConfigurationOptionCellTypes.SelectFromOptions, [BMN_Configuration_CellDescriptorKey: BMN_BiometricModule_DataSourceOptionsID, BMN_LEVELS_MainLabelKey: "Select the device you will be using to measure your heart rate: ", BMN_SelectFromOptions_OptionsKey: options, BMN_SelectFromOptions_DefaultOptionsKey: options[0]])) //device options
                
                configurationOptionsLayoutObject = array
                
            case .Behavior_Height:
                
                configurationOptionsLayoutObject = nil //no further config needed
                
            case .Behavior_Weight:
                
                let options = [BiometricModule_DataSourceOptions.Manual.rawValue, BiometricModule_DataSourceOptions.HealthKit.rawValue] //weight entry options
                array.append((ConfigurationOptionCellTypes.SelectFromOptions, [BMN_Configuration_CellDescriptorKey: BMN_BiometricModule_DataSourceOptionsID, BMN_LEVELS_MainLabelKey: "How will you be obtaining your weight measurements?", BMN_SelectFromOptions_OptionsKey: options, BMN_SelectFromOptions_DefaultOptionsKey: options[0]])) //data entry options
                
                configurationOptionsLayoutObject = array
                
            case .Computation_BiologicalSex:
                
                break //grab gender from HK
            
            case .Computation_Age:
                
                break //grab DOB from HK
                
            case .Computation_BMI:
                
                let options = ["Manually Input Weight & Height", "Use Most Recent Value From HealthKit"] //BMI weight/height options
                array.append((ConfigurationOptionCellTypes.SelectFromOptions, [BMN_Configuration_CellDescriptorKey: "", BMN_LEVELS_MainLabelKey: "From where should the system obtain your weight & height?", BMN_SelectFromOptions_OptionsKey: options, BMN_SelectFromOptions_DefaultOptionsKey: options[0]])) //data entry options
                
                configurationOptionsLayoutObject = array
            }
        } else { //no selection, set configOptionsObj -> nil
            configurationOptionsLayoutObject = nil
        }
    }
    
    internal override func matchConfigurationItemsToProperties(configurationData: [String: AnyObject]) -> (Bool, String?, [String]?) {
        //(1) Takes as INPUT the data that was entered into each config TV cell. (2) Given the variableType, matches configuration data -> properties in the Module object by accessing specific configuration cell identifiers (defined in 'HelperFx' > 'Dictionary Keys').
        if let type = variableType {
            switch type { //only needed for sections that require configuration
            case .Behavior_HeartRate:
                break //*
            case .Behavior_Weight:
                if let options = configurationData[BMN_BiometricModule_DataSourceOptionsID] as? [String], rawOption = options.first, selectedOption = BiometricModule_DataSourceOptions(rawValue: rawOption) {
                    self.dataSourceOption = selectedOption
                    if (selectedOption == BiometricModule_DataSourceOptions.HealthKit) {
                        self.isAutomaticallyCaptured = true //set -> auto-cap
                    }
                    return (true, nil, nil)
                } else {
                    return (false, "No option was selected!", nil)
                }
            case .Behavior_Height:
                break
            case .Computation_BMI:
                break
            default:
                print("[BiometricMod: matchConfigToProps] Error! Default in switch!")
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
            case .Behavior_HeartRate:
                break //store linked device & measurement options
            case .Behavior_Weight:
                if let source = dataSourceOption { //store selected data entry option
                    persistentDictionary[BMN_BiometricModule_DataSourceOptionsKey] = source.rawValue
                }
                //Add custom DataEntry cell configuration keys:
                persistentDictionary[BMN_FreeformCell_CharacterLimitKey] = 3 //limit weight to 3 digits?
                persistentDictionary[BMN_FreeformCell_DataTypeKey] = ProtectedFreeformTypes.Int.rawValue
            case .Behavior_Height:
                break
            case .Computation_BMI:
                break
            default:
                break
            }
        }
        return persistentDictionary
    }
    
    // MARK: - Data Entry Logic
    
    lazy var healthKitConnection = HealthKitConnection() //handles interaction w/ HK
    
    override func getDataEntryCellTypeForVariable() -> DataEntryCellTypes? { //indicates to DataEntryVC what kind of DataEntry cell should be used for this variable
        if let type = self.variableType {
            switch type { //if user chooses to enter height or weight, create cell w/ textField
            case .Behavior_Weight:
                return DataEntryCellTypes.Freeform
            default:
                return nil
            }
        }
        return nil
    }
    
    override func isSubscribedToService(service: ServiceTypes) -> Bool {
        if let type = self.variableType { //check if subscribed to service using enum object
            return type.isSubscribedToService(service)
        }
        return false
    }
    
    override func populateDataObjectForAutoCapturedVariable() { //gets data for auto-cap variable
        mainDataObject = nil //clear object before overwriting!
        if let type = variableType { //source of auto-cap data depends on varType
            switch type {
            case .Behavior_HeartRate:
                break //get HR samples w/in defined time period
            case .Behavior_Weight: //get most recent weight from HK
                healthKitConnection.getSampleQuantityFromHKStore(HealthKitConnection.bodyMassType, unit: HKUnit.poundUnit(), completion: { (let wt) in
                    if let weight = wt {
                        self.mainDataObject = weight
                    } else {
                        print("[BM - populateDataObj] Weight was nil!")
                    }
                })
            case .Behavior_Height: //get last height in HK or manually entered height
                healthKitConnection.getSampleQuantityFromHKStore(HealthKitConnection.heightType, unit: HKUnit.footUnit(), completion: { (let ht) in
                    if let height = ht {
                        self.mainDataObject = height
                    }
                })
            case .Computation_BiologicalSex:
                break //pull sex from HK
            case .Computation_BMI:
                break //compute BMI from last height & weight
            case .Computation_Age:
                break //pull age from HK
            }
        }
    }
    
    func writeManualDataToHKStore() { //called by Project class during aggregation - instructs the manually entered variable to report its data to HK if it is of Biometric Class**
        print("write data firing...")
        if let type = variableType {
            switch type {
            case .Behavior_Weight:
                print("before cast")
                if let weight = self.mainDataObject as? Double {
                    print("after cast")
                    healthKitConnection.writeSampleQuantityToHKStore(HealthKitConnection.bodyMassType, quantity: weight, unit: HKUnit.poundUnit())
                }
            default:
                break
            }
        }
    }
    
}

enum BiometricModuleVariableTypes: String { //*match each behavior/computation -> Configuration + DataEntry custom TV cells; for each new behavior/comp added, you must also add (1) Configuration logic, (2) Core Data storage logic (so the variable config can be preserved), (3) Unpacking logic (in the DataEntry initializer), & (4) DataEntry logic (enabling the user to report info).*
    
    //For all of the behaviors where values are changing constantly, in config give user the option for the data to be input manually @ run time or have the last available value pulled from HK.
    
    //Available Behaviors:
    case Behavior_HeartRate = "Heart Rate" //sampling - utilize time stamps, user can configure the range of time for which to take the same (during the action makes the most sense - the system will access all values w/in that range & either compute an average of take 1 sample / time span).
    case Behavior_Height = "Height" //constant unless the person is (1) still growing, or (2) doing a very long time-span project. This variable should be auto-pulled from HK (last available measurement). If none exists, should give the user the opportunity to input a height into HK.
    case Behavior_Weight = "Weight" //access last available weight from HK; if none exists, allow the user to input the weight.
    
    //Available Computations:
    case Computation_BiologicalSex = "Biological Sex" //pull from HK (ask user to enter if no gender is set, don't know if you can set a characteristic externally).
    case Computation_Age = "Current Age" //calculate from DOB -> current time
    case Computation_BMI = "BMI" //computes BMI using last weight & height in HK store. Asks user to input if none are found. How to get the most recent value in a project where user has a variable for height & weight (don't want to pull last value when the user is inputting even more recent data on each run cycle).
    
    //**how do we deal w/ static pieces of data like DOB? We could pull it from HK; the difference is these variables WON'T be measured on each run of dataEntry mode. Constant data like DOB, gender, etc. will only need to be accessed 1x from HK for a given project (at project set-up time). How do we store these PERMANENT variables & analyze them w/in the context of the project. How does the user configure one of these variables - they will be 'auto-cap' - for now, we can 1:1 map them into the DB w/ all of the other variables (take the values from HK whenever needed).
    
    func getAlertMessageForVariable() -> String {
        var message = ""
        switch self {
        case .Behavior_HeartRate:
            message = "This variable allows you to track your heart rate using AppleWatch, FitBit, or another wearable device."
        case .Behavior_Height:
            message = "This variable enables you to input your height at the time of measurement."
        case .Behavior_Weight:
            message = "This variable enables you to input your weight at the time of measurement."
        case .Computation_BiologicalSex:
            message = "This variable corresponds with your biological sex (Male, Female, or Other)."
        case .Computation_Age:
            message = "This variable computes your current age at the time of each measurement."
        case .Computation_BMI:
            message = "This variable computes your BMI at the time of each measurement using your last recorded height and weight."
        }
        return message
    }
    
    func isSubscribedToService(service: ServiceTypes) -> Bool { //list of subscribed services for each variableType
        let subscribedServices: [ServiceTypes]
        switch self { //for each var that uses services, create list of subscribed services
        case .Behavior_HeartRate:
            subscribedServices = [ServiceTypes.HealthKit] //*access to HK & wearables or just HK?
        default:
            subscribedServices = [ServiceTypes.HealthKit] //default service is HK for Biometric vars
        }
        if (subscribedServices.contains(service)) { //subscribed to service
            return true
        } else { //NOT subscribed to service
            return false
        }
    }
    
}

enum BiometricModule_DataSourceOptions: String {
    case Manual = "Input manually" //manually enter data into BMN, data will be sent -> HK
    case HealthKit = "Use most recent value in HealthKit" //obtain (most recent?) value from HK
    case AppleWatch = "Apple Watch" //?
    case FitBit = "FitBit" //?
}