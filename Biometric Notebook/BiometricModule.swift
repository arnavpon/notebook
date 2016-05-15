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
        
        //(1) Set filters (certain BM variable types are unique such as weight, height, ...):
        var filteredTypes = Set<BiometricModuleVariableTypes>() //set containing types to be filtered
        if let blocks = blockers { //check for defined blockers
            if (blocks.contains(BMN_Blocker_BiometricModule_Behavior_Weight)) { //filter weight
                filteredTypes.insert(BiometricModuleVariableTypes.Behavior_Weight)
            }
            if (blocks.contains(BMN_Blocker_BiometricModule_Behavior_Height)) { //filter height
                filteredTypes.insert(BiometricModuleVariableTypes.Behavior_Height)
            }
        }
        
        //(2) Add items -> 'behaviors' array if they pass through filters:
        for behavior in biometricModuleBehaviors {
            if !(filteredTypes.contains(behavior)) { //exclude filtered varTypes
                behaviorTitles.append(behavior.rawValue)
            }
        }
        return behaviorTitles
    }
    
    private let biometricModuleComputations: [BiometricModuleVariableTypes] = [BiometricModuleVariableTypes.Computation_BiologicalSex, BiometricModuleVariableTypes.Computation_Age, BiometricModuleVariableTypes.Computation_BMI]
    override var computations: [String] { //object containing titles for TV cells
        var computationTitles: [String] = []
        
        //(1) Set filters (certain BM variable types are unique such as age, gender, BMI, ...):
        var filteredTypes = Set<BiometricModuleVariableTypes>() //set containing types to be filtered
        if let blocks = blockers { //check for defined blockers
            if (blocks.contains(BMN_Blocker_BiometricModule_Computation_Age)) { //filter age
                filteredTypes.insert(BiometricModuleVariableTypes.Computation_Age)
            }
            if (blocks.contains(BMN_Blocker_BiometricModule_Computation_BMI)) { //filter BMI
                filteredTypes.insert(BiometricModuleVariableTypes.Computation_BMI)
            }
            if (blocks.contains(BMN_Blocker_BiometricModule_Computation_BiologicalSex)) { //filter gender
                filteredTypes.insert(BiometricModuleVariableTypes.Computation_BiologicalSex)
            }
        }
        
        //(2) Add items -> 'computations' array if they pass through filters:
        for computation in biometricModuleComputations {
            if !(filteredTypes.contains(computation)) { //exclude filtered varTypes
                computationTitles.append(computation.rawValue)
            }
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
    var heartRateSamplingOption: BiometricModule_HeartRateOptions? //HR sampling option
    var pickerDataSource: [[Int]]? //data source for pickerView in 'DataEntryCellWithPicker'
    
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
            if let source = dict[BMN_BiometricModule_DataSourceOptionsKey] as? String, selectedSource = BiometricModule_DataSourceOptions(rawValue: source) { //dataSource common to ALL variables
                self.dataSourceOption = selectedSource
            }
            
            switch type { //configure according to 'variableType'
            case .Behavior_HeartRate: //unpack the sampling type
                if let rawOption = dict[BMN_BiometricModule_HeartRateSamplingOptionKey] as? String, samplingOption = BiometricModule_HeartRateOptions(rawValue: rawOption) {
                    self.heartRateSamplingOption = samplingOption
                    
                    if (samplingOption == BiometricModule_HeartRateOptions.ChooseSampleAtCollection) {
                        pickerDataSource = [[0, 1, 2], [0, 15, 30, 45]] //define data source for picker in CustomTV cell
                    }
                }
            case .Behavior_Weight: //unpack data entry option (manual or HK extraction)
                //If source is MANUAL entry, set the freeform cell configObject:
                if (self.dataSourceOption == BiometricModule_DataSourceOptions.Manual) {
                    self.FreeformCell_configurationObject = [] //initialize
                    FreeformCell_configurationObject!.append((nil, ProtectedFreeformTypes.Decimal, nil, 6, (0, 999))) //lone view for weight entry
                }
            case .Behavior_Height:
                //If source is MANUAL entry, set the freeform cell configObject:
                if (self.dataSourceOption == BiometricModule_DataSourceOptions.Manual) {
                    self.FreeformCell_configurationObject = [] //initialize
                    self.FreeformCell_labelBeforeField = false //label goes AFTER field
                    FreeformCell_configurationObject!.append(("feet", ProtectedFreeformTypes.Int, nil, 1, nil)) //view 1 (for # of feet)
                    FreeformCell_configurationObject!.append(("inches", ProtectedFreeformTypes.Int, nil, 2, (0, 12))) //view 2 (for # of inches)
                }
            case .Computation_BMI:
                break //if user wants it selected from HK, simply pull the last value; if user wants it computed, get the last height/weight for computation (fix this after adjust Project configuration)
            case .Computation_BiologicalSex, .Computation_Age:
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
                
                //For HR behavior, user needs to select the SUPPORTED device they will be using to measure the HR (AppleWatch, FitBit, etc.) & define the sampling parameters:
                let sourceOptions = [BiometricModule_DataSourceOptions.AppleWatch.rawValue, BiometricModule_DataSourceOptions.FitBit.rawValue]
                array.append((ConfigurationOptionCellTypes.SelectFromOptions, [BMN_Configuration_CellDescriptorKey: BMN_BiometricModule_DataSourceOptionsID, BMN_LEVELS_MainLabelKey: "Select the device you will be using to measure your heart rate: ", BMN_SelectFromOptions_OptionsKey: sourceOptions, BMN_SelectFromOptions_DefaultOptionsKey: [sourceOptions[0]]])) //device options
                
                var sampleOptions = [BiometricModule_HeartRateOptions.MostRecent.rawValue, BiometricModule_HeartRateOptions.ChooseSampleAtCollection.rawValue]
                if (self.locationInFlow == VariableLocations.AfterAction) { //AverageOverAction option is ONLY allowed for AfterAction variables
                    sampleOptions.append(BiometricModule_HeartRateOptions.AverageOverAction.rawValue)
                }
                
                array.append((ConfigurationOptionCellTypes.SelectFromOptions, [BMN_Configuration_CellDescriptorKey: BMN_BiometricModule_HeartRateSamplingOptionsID, BMN_LEVELS_MainLabelKey: "Choose the time period over which to sample your heart rate:", BMN_SelectFromOptions_OptionsKey: sampleOptions]))
                
                configurationOptionsLayoutObject = array
                
            case .Behavior_Height:
                
                let options = [BiometricModule_DataSourceOptions.Manual.rawValue, BiometricModule_DataSourceOptions.HealthKit.rawValue] //height entry options
                array.append((ConfigurationOptionCellTypes.SelectFromOptions, [BMN_Configuration_CellDescriptorKey: BMN_BiometricModule_DataSourceOptionsID, BMN_LEVELS_MainLabelKey: "How will you be obtaining your height measurements?", BMN_SelectFromOptions_OptionsKey: options, BMN_SelectFromOptions_DefaultOptionsKey: [options[0]]])) //data entry options, default is MANUAL
                
                configurationOptionsLayoutObject = array
                
            case .Behavior_Weight:
                
                let options = [BiometricModule_DataSourceOptions.Manual.rawValue, BiometricModule_DataSourceOptions.HealthKit.rawValue] //weight entry options
                array.append((ConfigurationOptionCellTypes.SelectFromOptions, [BMN_Configuration_CellDescriptorKey: BMN_BiometricModule_DataSourceOptionsID, BMN_LEVELS_MainLabelKey: "How will you be obtaining your weight measurements?", BMN_SelectFromOptions_OptionsKey: options, BMN_SelectFromOptions_DefaultOptionsKey: [options[0]]])) //data entry options, default is MANUAL
                
                configurationOptionsLayoutObject = array
                
            case .Computation_BMI:
                
                let options = [BiometricModule_DataSourceOptions.Calculate.rawValue, BiometricModule_DataSourceOptions.HealthKit.rawValue]
                array.append((ConfigurationOptionCellTypes.SelectFromOptions, [BMN_Configuration_CellDescriptorKey: BMN_BiometricModule_DataSourceOptionsID, BMN_LEVELS_MainLabelKey: "How will you be obtaining your BMI computations?", BMN_SelectFromOptions_OptionsKey: options, BMN_SelectFromOptions_DefaultOptionsKey: [options[0]]])) //data entry options, default is CALCULATION
                
                configurationOptionsLayoutObject = array
            
            case .Computation_BiologicalSex, .Computation_Age:
                configurationOptionsLayoutObject = nil //no further config needed
                self.isAutomaticallyCaptured = true //vars are auto-captured from HK store
            }
        } else { //no selection, set configOptionsObj -> nil
            configurationOptionsLayoutObject = nil
        }
    }
    
    internal override func matchConfigurationItemsToProperties(configurationData: [String: AnyObject]) -> (Bool, String?, [String]?) {
        //(1) Takes as INPUT the data that was entered into each config TV cell. (2) Given the variableType, matches configuration data -> properties in the Module object by accessing specific configuration cell identifiers (defined in 'HelperFx' > 'Dictionary Keys').
        if let type = variableType {
            if let options = configurationData[BMN_BiometricModule_DataSourceOptionsID] as? [String], rawOption = options.first, selectedOption = BiometricModule_DataSourceOptions(rawValue: rawOption) { //all BiometricMod variables require a DataSource
                self.dataSourceOption = selectedOption
                
                switch type { //only needed for sections that require configuration
                case .Behavior_HeartRate:
                    if let samplingOpts = configurationData[BMN_BiometricModule_HeartRateSamplingOptionsID] as? [String], rawOption = samplingOpts.first, selectedOption = BiometricModule_HeartRateOptions(rawValue: rawOption) { //check for HR sampling
                        self.heartRateSamplingOption = selectedOption
                        switch selectedOption {
                        case .ChooseSampleAtCollection:
                            break //NOT auto-cap - user needs to select sample size @ collection time!
                        default: //for other options, capture is automatic
                            self.isAutomaticallyCaptured = true
                        }
                        return (true, nil, nil)
                    } else {
                        return (false, "No sampling option was found!", nil)
                    }
                case .Behavior_Weight, .Behavior_Height:
                    if (selectedOption == BiometricModule_DataSourceOptions.HealthKit) {
                        self.isAutomaticallyCaptured = true //set -> auto-cap
                    }
                    return (true, nil, nil) //no further config aside from data source
                case .Computation_BMI:
                    self.isAutomaticallyCaptured = true //always set -> auto-cap
                    return (true, nil, nil) //no further config aside from data source
                default:
                    print("[BiometricMod: matchConfigToProps] Error! Default in switch!")
                    return (false, "Default in switch!", nil)
                }
            }
        }
        return (false, "No option was selected!", nil)
    }
    
    // MARK: - Core Data Logic
    
    internal override func createDictionaryForCoreDataStore() -> Dictionary<String, AnyObject> { 
        var persistentDictionary: [String: AnyObject] = super.createDictionaryForCoreDataStore()
        
        //Set the coreData dictionary ONLY with information pertaining to the 'selectedFunctionality':
        if let type = variableType {
            persistentDictionary[BMN_VariableTypeKey] = type.rawValue //save variable type
            if let source = dataSourceOption { //store selected data source option
                persistentDictionary[BMN_BiometricModule_DataSourceOptionsKey] = source.rawValue
            }
            
            switch type { //check for any other items to pack
            case .Behavior_HeartRate:
                if let samplingOption = heartRateSamplingOption {
                    persistentDictionary[BMN_BiometricModule_HeartRateSamplingOptionKey] = samplingOption.rawValue
                    if (samplingOption == BiometricModule_HeartRateOptions.ChooseSampleAtCollection) {
                        persistentDictionary[BMN_DataEntry_MainLabelPromptKey] = "Choose a time span of heart rates:"
                    }
                }
            case .Behavior_Weight, .Behavior_Height:
                if (type == BiometricModuleVariableTypes.Behavior_Weight) { //add a prompt
                    persistentDictionary[BMN_DataEntry_MainLabelPromptKey] = "Enter your current weight:"
                } else if (type == BiometricModuleVariableTypes.Behavior_Height) { //add a prompt
                    persistentDictionary[BMN_DataEntry_MainLabelPromptKey] = "Enter your current height:"
                }
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
            switch type {
            case .Behavior_Weight, .Behavior_Height:
                return DataEntryCellTypes.Freeform //create cell w/ textField
            case .Behavior_HeartRate:
                if let samplingOpt = heartRateSamplingOption {
                    if (samplingOpt == BiometricModule_HeartRateOptions.ChooseSampleAtCollection) {
                        return DataEntryCellTypes.Picker //create cell w/ picker
                    }
                }
            default:
                return nil
            }
        }
        return nil
    }
    
    override var cellHeightUserInfo: [String : AnyObject]? { //provides info to set height for TV cell
        if let configObject = FreeformCell_configurationObject, type = variableType {
            switch type {
            case .Behavior_Weight, .Behavior_Height: //supply # of freeformViews for the cell
                return [BMN_DataEntry_FreeformCell_NumberOfViewsKey: configObject.count]
            default:
                break
            }
        }
        return nil
    }
    
    override func isSubscribedToService(service: ServiceTypes) -> Bool {
        if let type = self.variableType { //check if var is subscribed to service using enum object
            return type.isSubscribedToService(service)
        }
        return false
    }
    
    override func performConversionOnUserEnteredData(input: AnyObject) -> AnyObject? { //convert user entered data to HK-appropriate form before saving it to moduleReportObject
        if let type = variableType {
            switch type {
            case .Behavior_Weight: //convert inc array from TV cell -> a SINGLE weight value
                if let inputAsArray = input as? [String], weight = inputAsArray.first {
                    return Double(weight)
                }
            case .Behavior_Height: //convert user-entered height (feet + inches) -> inches
                if let heightValues = input as? [String], feet = Int(heightValues[0]), inches = Int(heightValues[1]) {
                    return (feet * 12 + inches) //convert height to 1 data point in inches
                }
            default:
                break
            }
        }
        return nil
    }
    
    override func populateDataObjectForAutoCapturedVariable() { //gets data for auto-cap variable
        mainDataObject = nil //clear object before overwriting!
        if let type = variableType { //source of auto-cap data depends on varType
            switch type {
            case .Behavior_HeartRate:
                if let sampleOption = self.heartRateSamplingOption {
                    switch sampleOption {
                    case .MostRecent: //get last HR in HK store
                        
                    healthKitConnection.getSampleQuantityFromHKStore(HealthKitConnection.heartRateType, unit: HealthKitConnection.beatsPerMinuteUnit, sampleLimit: 1, filters: [], completion: { (let rates) in
                        if let heartRates = rates, hr = heartRates.first { //get most recent HR
                            self.mainDataObject = hr
                        } else {
                            print("[populateDataObject] Error - no HR found in store.")
                        }
                    })
                    case .AverageOverAction: //get all recorded values during action & calculate average
                        if let inputsTimeStamp = NSUserDefaults.standardUserDefaults().valueForKey(INPUTS_TIME_STAMP) { //obtain the date @ which the IVs were saved
                            let currentTime = NSDate()
                            
                            healthKitConnection.getSampleQuantityFromHKStore(HealthKitConnection.heartRateType, unit: HealthKitConnection.beatsPerMinuteUnit, sampleLimit: nil, filters: [(PredicateComparators.GreaterThan, HealthKitProperties.EndDate, inputsTimeStamp), (PredicateComparators.LessThan, HealthKitProperties.EndDate, currentTime)], completion: { (let heartRates) in
                                if let rates = heartRates {
                                    if !(rates.isEmpty) {
                                        var count: Double = 0
                                        var total: Double = 0
                                        for rate in rates {
                                            total += rate
                                            count += 1
                                        }
                                        let average: Double = (total / count) //calculate avg
                                        self.mainDataObject = average
                                    }
                                }
                            })
                        } else {
                            print("No time stamp available for IV!")
                        }
                    default:
                        print("[populateDataObjectForAutoCap] Error - default in switch!")
                    }
                }
            case .Behavior_Weight: //get most recent weight from HK
                healthKitConnection.getSampleQuantityFromHKStore(HealthKitConnection.bodyMassType, unit: HKUnit.poundUnit(), sampleLimit: 1, filters: [], completion: { (let weights) in
                    if let wts = weights, wt = wts.first {
                        self.mainDataObject = wt
                    } else { //how do we handle when there are no objects in store?!? - @ this point, could throw an error to the VC that will generate a TV cell for this variable to enter its data into (error will add new item to TV data source for that session).
                        print("[BM - populateDataObj] Error - No Weight in HK Store!")
                    }
                })
            case .Behavior_Height: //get most recent height in HK
                healthKitConnection.getSampleQuantityFromHKStore(HealthKitConnection.heightType, unit: HKUnit.inchUnit(), sampleLimit: 1, filters: [], completion: { (let heights) in
                    if let hts = heights, ht = hts.first {
                        self.mainDataObject = ht
                    } else { //how do we handle when there are no objects in store?!? - @ this point, could throw an error to the VC that will generate a TV cell for this variable to enter its data into.
                        print("[BM - populateDataObj] Error - No Height in HK Store!")
                    }
                })
            case .Computation_BMI:
                //compute BMI from last height & weight - if there is a weight or height variable in the current project, wait until that reports before obtaining the value. If not, grab the last value in the HK store for that value.
                healthKitConnection.getSampleQuantityFromHKStore(HealthKitConnection.heightType, unit: HKUnit.meterUnit(), sampleLimit: 1, filters: [], completion: { (let heights) in
                    if let hts = heights, height = hts.first {
                        self.healthKitConnection.getSampleQuantityFromHKStore(HealthKitConnection.bodyMassType, unit: HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Kilo), sampleLimit: 1, filters: [], completion: { (let weights) in
                            if let wts = weights, weight = wts.first { //(weight in kg) / (ht ^ 2)
                                self.mainDataObject = weight / (height * height)
                            }
                        })
                    }
                })
            case .Computation_BiologicalSex:
                if let gender = healthKitConnection.getGenderFromHKStore() {
                    mainDataObject = gender.rawValue
                } else {
                    print("[BM - populateDataObj] Error - Could not obtain Gender from HK Store!")
                }
            case .Computation_Age:
                mainDataObject = healthKitConnection.getCurrentAgeFromHKStore()
            }
        }
    }
    
    func writeManualDataToHKStore() { //called by Project class during aggregation - instructs the manually entered variable to report its data to HK if it is of Biometric Class
        if let type = variableType {
            switch type {
            case .Behavior_Weight:
                if let weight = self.mainDataObject as? Double {
                    healthKitConnection.writeSampleQuantityToHKStore(HealthKitConnection.bodyMassType, quantity: weight, unit: HKUnit.poundUnit())
                }
            case .Behavior_Height:
                if let height = self.mainDataObject as? Double { //height is expressed in INCHES
                    healthKitConnection.writeSampleQuantityToHKStore(HealthKitConnection.heightType, quantity: height, unit: HKUnit.inchUnit())
                }
            case .Computation_BMI: //problem is that Project only calls this method for manual variables, which makes sense - if we are obtaining from Hk, we wouldn't want to write to it. This changes a bit for BMI. What happens if the BMI is already available in HK? User should be able to access directly from store w/o computation.
                if let bmi = self.mainDataObject as? Double { //BMI is in kg/m2
                    healthKitConnection.writeSampleQuantityToHKStore(HealthKitConnection.bmiType, quantity: bmi, unit: HealthKitConnection.bmiUnit)
                }
            default:
                break
            }
        }
    }
    
    // MARK: - Heart Rate Logic
    
    func obtainHeartRateForSelectedSample(sample: (Int, Int)) { //called by 'DataEntryCellWithPicker' class; input format is (minutes, seconds), based on user selection of sample size
        let sampleInSeconds: Double = Double((sample.0 * 60) + sample.1) //convert sampleTime -> seconds
        let timeInterval = NSDate(timeInterval: -sampleInSeconds, sinceDate: NSDate())
        
        //Obtain all HR values within the defined timeInterval from HK:
        healthKitConnection.getSampleQuantityFromHKStore(HealthKitConnection.heartRateType, unit: HealthKitConnection.beatsPerMinuteUnit, sampleLimit: nil, filters: [(PredicateComparators.GreaterThanOrEqual, HealthKitProperties.EndDate, timeInterval)]) { (let rates) in
            if let heartRates = rates {
                if !(heartRates.isEmpty) {
                    self.mainDataObject = heartRates
                } else {
                    print("[obtainHRForSelectedSample] No heart rates found!")
                }
            }
        }
    }
    
}

enum BiometricModuleVariableTypes: String { //*match each behavior/computation -> Configuration + DataEntry custom TV cells; for each new behavior/comp added, you must also add (1) Configuration logic, (2) Core Data storage logic (so the variable config can be preserved), (3) Unpacking logic (in the DataEntry initializer), & (4) DataEntry logic (enabling the user to report info).*
    
    //Available Behaviors:
    case Behavior_HeartRate = "Heart Rate" //sampling - utilize time stamps, user can configure the range of time for which to take the same (during the action makes the most sense - the system will access all values w/in that range & either compute an average of take 1 sample / time span).
    case Behavior_Height = "Height" //constant unless the person is (1) still growing, or (2) doing a very long time-span project. This variable should be auto-pulled from HK (last available measurement). If none exists, should give the user the opportunity to input a height into HK.
    case Behavior_Weight = "Weight" //access last available weight from HK; if none exists, allow the user to input the weight.
    
    //Available Computations:
    case Computation_BiologicalSex = "Biological Sex" //pull from HK (cannot set a characteristic externally, so value MUST exist in store); STORE in DB in its own table (so it can be correlated against any & all projects)
    case Computation_Age = "Current Age" //calculate from DOB -> current time; STORE in DB in its own table (so it can be correlated against any & all projects)
    case Computation_BMI = "BMI" //computes BMI using most recent weight & height available
    
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
            subscribedServices = [ServiceTypes.HealthKit] //depending on the selected device, this will change (e.g. FitBit will not subscribe to HK, whereas AppleWatch does); need to filter!
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
    case Calculate = "Calculate dynamically" //calculates value (for computations)
    case AppleWatch = "Apple Watch"
    case FitBit = "FitBit"
}

enum BiometricModule_HeartRateOptions: String { //sampling options for HR variable
    case MostRecent = "Most Recent Value" //grabs last measured HR from store
    case AverageOverAction = "Average Over Action" //**averages all HR measurements taken between IV time stamp & OM time stamp (i.e. averages values taken during action), ONLY available for OutcomeMeasures!!! (need to build in protection so selection is only enabled for OM)
    case ChooseSampleAtCollection = "Choose Sample at Data Collection Time" //**allows user to pick a period of time over which to sample HR (provides an array of HR)
}