//  BiometricModule.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/19/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Module for entering biometric data into HK (e.g. height, weight, etc.)

import Foundation
import HealthKit

class BiometricModule: Module {
    
    override func getConfigureModuleLayoutObject() -> Dictionary<String, AnyObject> {
        var tempObject = super.getConfigureModuleLayoutObject() //obtain superclass' dict & ADD TO IT
        
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
    
    private let biometricModuleBehaviors: [BiometricModuleVariableTypes] = [BiometricModuleVariableTypes.Behavior_HeartRate, BiometricModuleVariableTypes.Behavior_Height, BiometricModuleVariableTypes.Behavior_Weight]
    override func setBehaviors() -> [String]? { //dynamically assigns behaviors to list
        var behaviorTitles: [String] = []
        
        //(1) Set filters (i.e. exclude certain computations based on 'blockers' & 'locationInFlow'):
        var filteredTypes = Set<BiometricModuleVariableTypes>() //set containing types to be filtered
        if let blocker = moduleBlocker {
            let filters = blocker.getFilteredTypesForModule(Modules.BiometricModule)
            for filter in filters {
                if let enumValue = BiometricModuleVariableTypes(rawValue: filter) {
                    filteredTypes.insert(enumValue)
                }
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
    override func setComputations() -> [String]? { //dynamically assigns comps to list
        var computationTitles: [String] = []
        
        //(1) Set filters (i.e. exclude certain computations based on 'blockers' & 'locationInFlow'):
        var filteredTypes = Set<BiometricModuleVariableTypes>() //set containing types to be filtered
        if let blocker = moduleBlocker {
            let filters = blocker.getFilteredTypesForModule(Modules.BiometricModule)
            for filter in filters {
                if let enumValue = BiometricModuleVariableTypes(rawValue: filter) {
                    filteredTypes.insert(enumValue)
                }
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
                        self.cellPrompt = "Choose a time span of heart rates:" //set cell prompt
                    }
                }
            case .Behavior_Weight: //unpack data entry option (manual or HK extraction)
                //If source is MANUAL entry, set the freeform cell configObject:
                if (self.dataSourceOption == BiometricModule_DataSourceOptions.Manual) {
                    self.FreeformCell_configurationObject = [] //initialize
                    FreeformCell_configurationObject!.append((nil, ProtectedFreeformTypes.Decimal, nil, 6, (0, 999), nil)) //lone view for weight entry
                    self.cellPrompt = "Enter your current weight:" //mainLbl for cell
                }
            case .Behavior_Height:
                //If source is MANUAL entry, set the freeform cell configObject:
                if (self.dataSourceOption == BiometricModule_DataSourceOptions.Manual) {
                    self.FreeformCell_configurationObject = [] //initialize
                    self.FreeformCell_labelBeforeField = false //label goes AFTER field
                    FreeformCell_configurationObject!.append(("feet", ProtectedFreeformTypes.Int, nil, 1, nil, nil)) //view 1 (for # of feet)
                    FreeformCell_configurationObject!.append(("inches", ProtectedFreeformTypes.Int, nil, 2, (0, 11), nil)) //view 2 (for # of inches)
                    self.cellPrompt = "Enter your current height:" //mainLbl for TV cell
                }
            case .Computation_BMI: //access the packed computationsInput dict
                if let inputsDict = dict[BMN_BiometricModule_ComputationInputsKey] as? [String: String] {
                    self.computationInputs = inputsDict
                }
            case .Computation_BiologicalSex, .Computation_Age:
                break
            }
        } else {
            print("[EnvironModule > CoreData initializer] Error! Could not find a type for the object.")
        }
    }
    
    init(ghostName: String, type: BiometricModuleVariableTypes) { //GHOST init
        super.init(name: ghostName)
        self.moduleTitle = Modules.BiometricModule.rawValue //set title
        
        self.isGhost = true //mark as ghost
        self.variableReportType = .AutoCapture //mark as auto-captured from API
        switch type { //set appropriate variable type
        case .Behavior_Height:
            self.selectedFunctionality = BiometricModuleVariableTypes.Behavior_Height.rawValue
        case .Behavior_Weight:
            self.selectedFunctionality = BiometricModuleVariableTypes.Behavior_Weight.rawValue
        default:
            break
        }
    }
    
    override func copyWithZone(zone: NSZone) -> AnyObject { //creates copy of variable (this is required to reset the settings if the user moves back in navigation!)
        let copy = BiometricModule(name: self.variableName)
        copy.existingVariables = self.existingVariables
        copy.moduleBlocker = self.moduleBlocker
        return copy
    }
    
    // MARK: - Variable Configuration
    
    internal override func setConfigurationOptionsForSelection() { //handles ALL configuration for ConfigOptionsVC - (1) Sets the 'options' value as needed; (2) Constructs the configuration TV cells if required; (3) Sets 'isAutoCaptured' var if var is auto-captured.
        if let type = variableType { //make sure behavior/computation was selected & ONLY set the configOptionsObject if further configuration is required
            var array: [(ConfigurationOptionCellTypes, Dictionary<String, AnyObject>)] = [] //pass -> VC (CustomCellType, cell's dataSource)
            switch type {
            case .Behavior_HeartRate:
                
                //(1) User needs to select the SUPPORTED device they will be using to measure the HR (AppleWatch, FitBit, etc.):
                let sourceOptions = [BiometricModule_DataSourceOptions.AppleWatch.rawValue, BiometricModule_DataSourceOptions.FitBit.rawValue]
                array.append((ConfigurationOptionCellTypes.SelectFromOptions, [BMN_Configuration_CellDescriptorKey: BMN_BiometricModule_DataSourceOptionsID, BMN_LEVELS_MainLabelKey: "Select the device you will be using to measure your heart rate: ", BMN_SelectFromOptions_OptionsKey: sourceOptions, BMN_SelectFromOptions_DefaultOptionsKey: [sourceOptions[0]]])) //device options
                
                //Set filters (exclude config options using ModuleBlocker class):
                let availableOptions = [BiometricModule_HeartRateOptions.MostRecent, BiometricModule_HeartRateOptions.ChooseSampleAtCollection, BiometricModule_HeartRateOptions.AverageOverAction] //list of ALL possible opts
                var sampleOptions: [String] = [] //used by ConfigOptions object
        
                var filteredTypes = Set<BiometricModule_HeartRateOptions>()
                if let blocker = moduleBlocker {
                    let filters = blocker.getFilteredTypesForModule(Modules.BiometricModule)
                    for filter in filters {
                        if let enumValue = BiometricModule_HeartRateOptions(rawValue: filter) {
                            filteredTypes.insert(enumValue)
                        }
                    }
                }
                for option in availableOptions {
                    if !(filteredTypes.contains(option)) { //exclude filtered varTypes
                        sampleOptions.append(option.rawValue)
                    }
                }
                
                //(2) User must define the HR sampling parameters:
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
                
                self.variableReportType = ModuleVariableReportTypes.Computation //*set var as comp*
                var heightOptions = [BiometricModule_DataSourceOptions.HealthKit.rawValue]
                var weightOptions = [BiometricModule_DataSourceOptions.HealthKit.rawValue]
                var noHeight = false
                var noWeight = false
                
                //(1) Check if existingVars contains a height/weight var & if so add it as an option:
                if let existingVars = existingVariables {
                    for variable in existingVars {
                        if (variable.variableType == BiometricModuleVariableTypes.Behavior_Height.rawValue) { //HEIGHT var exists
                            heightOptions.append(variable.name) //add to list of options
                        } else if (variable.variableType == BiometricModuleVariableTypes.Behavior_Weight.rawValue) { //WEIGHT var exists
                            weightOptions.append(variable.name) //add to list of options
                        }
                    }
                }
                
                //(2) ONLY add height & weight TV cells to configuration if there is > 1 choice; otherwise, omit that TV cell from the layout object:
                if (heightOptions.count > 1) { //offer 1 config cell for height source
                    array.append((ConfigurationOptionCellTypes.SelectFromOptions, [BMN_Configuration_CellDescriptorKey: BMN_BiometricModule_DataSourceOptionsID, BMN_LEVELS_MainLabelKey: "How will you be obtaining your HEIGHT (used to calculate BMI)?", BMN_SelectFromOptions_OptionsKey: heightOptions, BMN_SelectFromOptions_DefaultOptionsKey: [heightOptions.last!]])) //HEIGHT options, default is HK
                } else { //NO height vars, value will be taken from API so create GHOST
                    noHeight = true
                }
                if (weightOptions.count > 1) { //offer 1 config cell for weight source
                    array.append((ConfigurationOptionCellTypes.SelectFromOptions, [BMN_Configuration_CellDescriptorKey: BMN_BiometricModule_DataSourceOptions2ID, BMN_LEVELS_MainLabelKey: "How will you be obtaining your WEIGHT (used to calculate BMI)?", BMN_SelectFromOptions_OptionsKey: weightOptions, BMN_SelectFromOptions_DefaultOptionsKey: [weightOptions.last!]])) //WEIGHT options, default is HK
                } else { //NO weight vars, value will be taken from API so create ghost
                    noWeight = true
                }
                
                if (noHeight) && (noWeight) { //NEITHER var needs config
                    configurationOptionsLayoutObject = nil //set layoutObject -> nil
                    self.createGhostForBiometricVariable(.Behavior_Weight) //create ghosts for BOTH vars
                    self.createGhostForBiometricVariable(.Behavior_Height)
                } else { //at least 1 object needs configuration - set layout object
                    configurationOptionsLayoutObject = array
                }
            
            case .Computation_BiologicalSex, .Computation_Age:
                configurationOptionsLayoutObject = nil //no further config needed
                self.variableReportType = ModuleVariableReportTypes.AutoCapture //auto-cap from HK store
            }
        } else { //no selection, set configOptionsObj -> nil
            configurationOptionsLayoutObject = nil
        }
        print("AFTER selection of var - rawValue of report type is \(self.variableReportType.rawValue).")
    }
    
    private func createGhostForBiometricVariable(type: BiometricModuleVariableTypes) { //constructs GHOST variable of specified type, names it according to parent computation, & sends notification -> VC
        switch type {
        case .Behavior_Height:
            let ghost = BiometricModule(ghostName: "\(variableName)_height_ghost", type: type)
            self.computationInputs[BMN_ComputationFramework_BM_BMI_HeightID] = ghost.variableName
            self.createGhostForVariable(ghost)
        case .Behavior_Weight:
            let ghost = BiometricModule(ghostName: "\(variableName)_weight_ghost", type: type)
            self.computationInputs[BMN_ComputationFramework_BM_BMI_WeightID] = ghost.variableName
            self.createGhostForVariable(ghost)
        default:
            break
        }
    }
    
    internal override func matchConfigurationItemsToProperties(configurationData: [String: AnyObject]) -> (Bool, String?, [String]?) {
        //(1) Takes as INPUT the data that was entered into each config TV cell. (2) Given the variableType, matches configuration data -> properties in the Module object by accessing specific configuration cell identifiers (defined in 'HelperFx' > 'Dictionary Keys').
        if let type = variableType {
            if (type == BiometricModuleVariableTypes.Computation_BMI) { //computations lie outside main framework
                //Check how the height & weight were configured to be obtained:
                if let heightOptions = configurationData[BMN_BiometricModule_DataSourceOptionsID] as? [String], heightOption = heightOptions.first {
                    if (heightOption == BiometricModule_DataSourceOptions.HealthKit.rawValue) { //ghost
                        self.createGhostForBiometricVariable(.Behavior_Height)
                    } else { //set the VALUE to the input's NAME
                        self.computationInputs[BMN_ComputationFramework_BM_BMI_HeightID] = heightOption
                    }
                } else { //no height config object (create ghost)
                    self.createGhostForBiometricVariable(.Behavior_Height)
                }
                if let weightOptions = configurationData[BMN_BiometricModule_DataSourceOptions2ID] as? [String], weightOption = weightOptions.first {
                    if (weightOption == BiometricModule_DataSourceOptions.HealthKit.rawValue) { //ghost
                        self.createGhostForBiometricVariable(.Behavior_Weight)
                    } else { //set the VALUE to the input's NAME
                        self.computationInputs[BMN_ComputationFramework_BM_BMI_WeightID] = weightOption
                    }
                } else {
                    self.createGhostForBiometricVariable(.Behavior_Weight)
                }
                return (true, nil, nil)
            }
            
            if let options = configurationData[BMN_BiometricModule_DataSourceOptionsID] as? [String], rawOption = options.first, selectedOption = BiometricModule_DataSourceOptions(rawValue: rawOption) { //all BiometricMod variables require a DataSource
                self.dataSourceOption = selectedOption
                
                switch type { //only needed for sections that require configuration
                case .Behavior_HeartRate:
                    if let samplingOpts = configurationData[BMN_BiometricModule_HeartRateSamplingOptionsID] as? [String], rawOption = samplingOpts.first, selectedOption = BiometricModule_HeartRateOptions(rawValue: rawOption) { //check for HR sampling
                        self.heartRateSamplingOption = selectedOption
                        switch selectedOption {
                        case .ChooseSampleAtCollection: //MANUAL var - user selects sample @ collection!
                            break //leave reportType as default
                        default: //for other options, capture is automatic
                            self.variableReportType = ModuleVariableReportTypes.AutoCapture
                        }
                        return (true, nil, nil)
                    } else {
                        return (false, "No sampling option was found!", nil)
                    }
                case .Behavior_Weight, .Behavior_Height:
                    if (selectedOption == BiometricModule_DataSourceOptions.HealthKit) {
                        self.variableReportType = ModuleVariableReportTypes.AutoCapture //set -> auto-cap
                    }
                    return (true, nil, nil) //no further config aside from data source
                case .Computation_BMI:
                    break
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
                if let samplingOption = heartRateSamplingOption { //store sampling option
                    persistentDictionary[BMN_BiometricModule_HeartRateSamplingOptionKey] = samplingOption.rawValue
                }
            case .Computation_BMI: //store computation's inputs dict
                persistentDictionary[BMN_BiometricModule_ComputationInputsKey] = self.computationInputs
            default:
                break
            }
        }
        return persistentDictionary
    }
    
    // MARK: - Data Entry Logic
    
    lazy var healthKitConnection = HealthKitConnection() //handles interaction w/ HK
    
    func getTypeForVariable() -> BiometricModuleVariableTypes? { //external type access
        return self.variableType
    }
    
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
    
    override func reportDataForVariable() -> [String: AnyObject]? {
        let reportDict = super.reportDataForVariable() //use superclass functionality, but first...
        writeManualDataToHKStore() //before reporting, write data -> HKStore as needed
        return reportDict
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
                healthKitConnection.getSampleQuantityFromHKStore(HealthKitConnection.bodyMassType, unit: measurementUnit, sampleLimit: 1, filters: [], completion: { (let weights) in
                    if let wts = weights, wt = wts.first {
                        self.mainDataObject = wt
                    } else { //how do we handle when there are no objects in store?!? - @ this point, could throw an error to the VC that will generate a TV cell for this variable to enter its data into (error will add new item to TV data source for that session).
                        print("[BM - populateDataObj] Error - No Weight in HK Store!")
                    }
                })
            case .Behavior_Height: //get most recent height in HK
                healthKitConnection.getSampleQuantityFromHKStore(HealthKitConnection.heightType, unit: measurementUnit, sampleLimit: 1, filters: [], completion: { (let heights) in
                    if let hts = heights, ht = hts.first {
                        self.mainDataObject = ht
                    } else { //how do we handle when there are no objects in store?!? - @ this point, could throw an error to the VC that will generate a TV cell for this variable to enter its data into.
                        print("[BM - populateDataObj] Error - No Height in HK Store!")
                    }
                })
            case .Computation_BMI: //handled by computation framework
                print("[BM - populateDataObj] Error - calling fx for COMPUTATION!")
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
    
    // MARK: - HealthKit Interaction Logic
    
    func writeManualDataToHKStore() { //called by Project class during aggregation - instructs the manually entered variable to report its data to HK if it is of Biometric Class
        if let type = variableType {
            switch type {
            case .Behavior_Weight:
                if let weight = self.mainDataObject as? Double {
                    if (self.variableReportType == ModuleVariableReportTypes.Default) { //only write values entered by user (i.e. don't write value to HK store when it has just been obtained from there!)
                        healthKitConnection.writeSampleQuantityToHKStore(HealthKitConnection.bodyMassType, quantity: weight, unit: HKUnit.poundUnit())
                    }
                }
            case .Behavior_Height:
                if let height = self.mainDataObject as? Double { //height is expressed in INCHES
                    if (self.variableReportType == ModuleVariableReportTypes.Default) {
                        healthKitConnection.writeSampleQuantityToHKStore(HealthKitConnection.heightType, quantity: height, unit: HKUnit.inchUnit())
                    }
                }
            case .Computation_BMI:
                if let bmi = self.mainDataObject as? Double { //write bmi to store if BMN is calc'ing it
                    if (self.dataSourceOption == BiometricModule_DataSourceOptions.Calculate) {
                        healthKitConnection.writeSampleQuantityToHKStore(HealthKitConnection.bmiType, quantity: bmi, unit: HealthKitConnection.bmiUnit)
                    }
                }
            default:
                break
            }
        }
    }
    
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
    
    //***unit conversions***
    var measurementUnit: HKUnit { //unit being used for this variable
        if let type = self.variableType {
            switch type {
            case .Behavior_Height:
                return HKUnit.inchUnit()
            case .Behavior_Weight:
                return HKUnit.poundUnit()
            default:
                break
            }
        }
        print("[measurementUnit] ERROR - Utilizing dummy unit...")
        return HKUnit.countUnit() //don't want this to be optional so use this as default
    }
    
    func getReportObjectInUnits(unit: HealthKitUnits) -> Double? { //**something isn't right about this setup, rewrite in a better way. Goal is to protect units such that we always know what unit the report data will be expressed in, and have a means to convert from 1 unit to another.
        if let data = self.mainDataObject as? Double {
            switch unit {
            case .Kilogram: //conversion for WEIGHT unit
                if (measurementUnit == HKUnit.poundUnit()) { //convert pounds -> kilograms
                    return (data / 2.2)
                }
            case .Meter: //conversion for HEIGHT unit
                if (measurementUnit == HKUnit.inchUnit()) { //convert inches -> meters
                    return (data * 2.54)/100
                }
            }
        }
        return nil
    }
    //***
    
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
    //These variables should be stored in the DB & cross-referenced against any project! In the app, they should be added to the user defaults as well.
    
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

enum HealthKitUnits { //object allowing for interconversion between different kinds of HK units
    
    case Kilogram
    case Meter
    
}