//  Module.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/7/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Superclass containing basic behavior common to all modules. Each variable will be an object of the module class to which they are attached. This module will store the variable name & all associated behaviors. The module should also contain ALL information needed to configure the variable's behaviors & create the custom TV cell for reporting data.
// Note about a module's 'Behaviors' - all functionality should be described w/in the class itself. Externally, all the VC should be doing is determining which option was selected, setting the selected option for the module object, & then executing the returned function defined in the module object. This function will tell the VC how to lay out the interface, what information to store, etc. There should be no class-specific logic being executed in the View Controllers - the VC should describe a SINGLE method that knows what information to send & what info it will receive (always in consistent form) from the Module object! We might need to make an enum for each Module's behaviors & then construct the behaviors upon selection. Based on the 'selectedFunctionality', the app will communicate w/ the VC during configuration.

import Foundation
import UIKit

class Module: NSObject, NSCopying { //defines the behaviors that are common to all modules
    
    static let modules: [Modules] = [Modules.CustomModule, Modules.EnvironmentModule, Modules.FoodIntakeModule, Modules.ExerciseModule, Modules.BiometricModule, Modules.CarbonEmissionsModule] //list of available modules to display to user
    
    var configurationType: ModuleConfigurationTypes = .InputVariable { //see 'Modules.swift' for enum decl
        didSet {
            if (self.configurationType == .GhostVariable) {
                self.variableState = .Ghost //blocks setConfigLayoutObject from firing
            }
        }
    }
    var variableReportType = ModuleVariableReportTypes.Default //report type, default is 'default'
    var reportCount: Int? //# of times object reports to be complete (default = 1x); set @ config
    var reportLocations = Set<Int>() //indicates @ what points this var reports (stored in CoreData)
    private var variableState: ModuleVariableStates //state of THIS instance (Configuration or Reporting)
    internal let variableName: String //the name given to the variable attached to this module
    internal var moduleTitle: String = "" //overwrite w/ <> Module enum raw value in each class
    
    var moduleBlocker: Module_DynamicConfigurationFramework? { //class that handles variableType filtering
        didSet { //after setting the blocker, assign the behaviors & computations
            self.behaviors = setBehaviors()
            self.computations = setComputations()
            setSectionsForDisplay()
        }
    }
    private var behaviors: [String]? //list of available behaviors for user selection during config
    private var computations: [String]? //list of available comps for user selection during config
    internal var sectionsToDisplay: [String]? //used by ConfigModuleVC tableView for display
    
    internal func setBehaviors() -> [String]? { //OVERRIDE in subclasses, sets behavior list dynamically
        return nil //called when the moduleBlocker is set by VC
    }
    internal func setComputations() -> [String]? { //OVERRIDE in subclasses, sets comps list dynamically
        return nil //called when the moduleBlocker is set by VC
    }
    private func setSectionsForDisplay() { //sets sections to display in ConfigModuleVC
        //WARNING: can only be set AFTER behaviors & computations have been set!!!
        if let behavs = behaviors, comps = computations {
            if !(behavs.isEmpty) && !(comps.isEmpty) { //BOTH behaviors & comps available
                sectionsToDisplay = [BMN_BehaviorsKey, BMN_ComputationsKey]
            } else if !(behavs.isEmpty) { //ONLY behaviors
                sectionsToDisplay = [BMN_BehaviorsKey]
            } else if !(comps.isEmpty) { //ONLY computations
                sectionsToDisplay = [BMN_ComputationsKey]
            }
        }
    }
    
    internal func getConfigureModuleLayoutObject() -> Dictionary<String, AnyObject> { //called by ConfigureModuleVC; OVERRIDE in subclasses
        //Constructs dataObject for laying out the available behaviors & computations in the ConfigureModuleVC (called by VC):
        var tempObject = Dictionary<String, AnyObject>()
        if let sections = sectionsToDisplay {
            var viewForSection = Dictionary<String, CustomTableViewHeader>()
            for section in sections { //assign headerViews to their respective sections
                switch section {
                case BMN_BehaviorsKey:
                    viewForSection[section] = CustomTableViewHeader(frame: CGRect(x: 0, y: 0, width: 0, height: 24), text: "Available Behaviors")
                case BMN_ComputationsKey:
                    viewForSection[section] = CustomTableViewHeader(frame: CGRect(x: 0, y: 0, width: 0, height: 24), text: "Available Computations")
                default:
                    print("[Custom - TVLayout viewForSection] error: default switch")
                }
            }
            tempObject[BMN_ViewForSectionKey] = viewForSection
            
            var rowsForSection = Dictionary<String, [String]>()
            for section in sections { //assign behaviors & computations to their respective sections
                switch section {
                case BMN_BehaviorsKey:
                    rowsForSection[section] = behaviors
                case BMN_ComputationsKey:
                    rowsForSection[section] = computations
                default:
                    print("[Module - TVLayout] error: default switch")
                }
            }
            tempObject[BMN_RowsForSectionKey] = rowsForSection
        }
        return tempObject
    }
    
    // MARK: - Initializers
    
    init(name: String) { //initializer for variable during SET-UP
        self.variableName = name
        self.variableState = ModuleVariableStates.VariableConfiguration
        self.reportCount = 1 //defaults to 1 unless changed by user or system
    }
    
    init(name: String, dict: [String: AnyObject]) { //initializer for variable during RECONSTRUCTION from CoreData dict
        self.variableName = name
        self.variableState = ModuleVariableStates.DataReporting
        if let configTypeRaw = dict[BMN_ConfigurationTypeKey] as? Int, configType = ModuleConfigurationTypes(rawValue: configTypeRaw) { //set configType
            self.configurationType = configType
        }
        if let prompt = dict[BMN_DataEntry_MainLabelPromptKey] as? String { //check if cell has a prompt
            self.cellPrompt = prompt //set prompt (used in place of varType in mainLabel of TV cell)
            //this is used ONLY when the USER sets the prompt (NOT when the system sets the prompt)!
        }
        if let reportTypeRaw = dict[BMN_VariableReportTypeKey] as? Int, reportType = ModuleVariableReportTypes(rawValue: reportTypeRaw) { //reset the report type
            print("[Module superclass init()] Report type raw = \(reportTypeRaw).")
            self.variableReportType = reportType
        }
        if let parent = dict[BMN_ComputationFramework_ComputationNameKey] as? String { //for GHOST vars
            self.parentComputation = parent //store parentComputation for ghost
        }
        if let locations = dict[BMN_VariableReportLocationsKey] as? [Int] { //reset report locations
            self.reportLocations = Set<Int>() //clear before adding back values
            for location in locations { //add each item in array -> set
                self.reportLocations.insert(location)
            }
        }
    }
    
    func copyWithZone(zone: NSZone) -> AnyObject { //OVERRIDE in subclasses
        print("[Module superclass] ERROR - calling copyWithZone in superclass!")
        return Module(name: self.variableName) //this should never be called
    }
    
    // MARK: - Variable Configuration
    
    internal var selectedFunctionality: String? { //the behavior OR computation (picked from the enum defined in each module object) that the user selected for this variable
        didSet { //set configurationOptions based on selection
            if (self.variableState == ModuleVariableStates.VariableConfiguration) { //ONLY set-up the configurationOptionsLayoutObject if the variable is being set-up
                setConfigurationOptionsForSelection()
            }
        }
    }
    
    internal var configurationOptionsLayoutObject: [(ConfigurationOptionCellTypes, Dictionary<String, AnyObject>)]? //object that handles layout of ConfigurationOptionsVC TV cells
    
    internal func setConfigurationOptionsForSelection() { //override in subclasses
        //Assigns configurationOptions based on the user's selection of a behavior/computation
        if (configurationType != .ActionQualifier) { //qualifiers can report ONLY 1x (when action occurs)
            configurationOptionsLayoutObject = [] //initialize
            configurationOptionsLayoutObject!.append((ConfigurationOptionCellTypes.SimpleNumber, [BMN_Configuration_CellDescriptorKey: BMN_Configuration_ReportCountID, BMN_LEVELS_MainLabelKey: "How many times will this variable report in 1 measurement cycle?", BMN_SimpleNumberConfigCell_DefaultKey: 1])) //cell to obtain report count
        }
    }
    
    internal func matchConfigurationItemsToProperties(configurationData: [String: AnyObject]) -> (Bool, String?, [String]?) {
        //Matches reportedData from configurationCells -> properties in the Module object & returns TRUE if operation was successful, (FALSE + an error message) if the operation failed; the 3rd part of the return object is an optional FLAG (that tells the VC to visually mark the cell w/ the corresponding DESCRIPTOR in the data source, b/c that is where the problem has occurred).
        if let count = configurationData[BMN_Configuration_ReportCountID] as? Int { //match # of reports
            if (count < 1) { //return error & flag cell - measurement count must be >= 1
                return (false, "Report count must be at least 1!", [BMN_Configuration_ReportCountID])
            } else if (count > 1) {
                self.reportCount = count //only set value if count > 1
            }
        }
        return (true, nil, nil)
    }
    
    internal func specialTypeForDynamicConfigFramework() -> [String]? { //override in subclasses
        //based on selectedFunctionality, provides alternative type(s) to add to the moduleBlocker in lieu of the selectedFunctionality
        return nil
    }
    
    // MARK: - Core Data Logic
    
    internal func createDictionaryForCoreDataStore() -> Dictionary<String, AnyObject> { //generates dictionary to be saved by CoreData (this dict will allow full reconstruction of the object)
        var persistentDictionary: [String: AnyObject] = [BMN_ModuleTitleKey: self.moduleTitle, BMN_VariableReportTypeKey: self.variableReportType.rawValue, BMN_ConfigurationTypeKey: self.configurationType.rawValue, BMN_VariableReportLocationsKey: self.reportLocations.sort()] //*save reportLocations as [Int] instead of Set b/c JSON can't serialize sets!*
        if let prompt = cellPrompt { //if prompt has been set, store it
            persistentDictionary[BMN_DataEntry_MainLabelPromptKey] = prompt
        }
        if (self.configurationType == .GhostVariable) { //var is ghost - store parent computation in dict
            persistentDictionary[BMN_ComputationFramework_ComputationNameKey] = parentComputation
        }
        return persistentDictionary
    }
    
    // MARK: - Data Entry Logic
    
    var cellPrompt: String? //an alternative mainLabel title for DataEntry TV cells w/ a prompt
    
    // Configuration variables - used to customize DataEntry TV cells (e.g. for freeform data entry):
    var FreeformCell_labelBeforeField: Bool? //specifies whether TF lbl is before or after field
    var FreeformCell_configurationObject: [(String?, ProtectedFreeformTypes?, String?, Int?, (Double?, Double?)?, String?)]? //tuple specifies all config for FreeformCell - indicates # of TFs (via the array's count) + (1) label? for each TF; (2) type? of data in TF (corresponds w/ ProtectedFreeformTypes enum); (3) defaultValue?; (4) characterLimit?; (5) (if text is numerical) an upper/lower bound in format (Int? <-lower, Int? <-upper)?; (6) textField placeholder?
    
    func getDataEntryCellTypeForVariable() -> DataEntryCellTypes? { //indicates to DataEntryVC what kind of DataEntry cell should be used for this variable (OVERRIDE in subclasses)
        return nil
    }
    
    func performConversionOnUserEnteredData(input: AnyObject) -> AnyObject? { //OVERRIDE in subclasses - allows modules to perform conversions on user-entered data before storing it to the reportObject
        return nil
    }
    
    var cellHeightUserInfo: [String: AnyObject]? { //dictionary containing information used by DataEntryCellTypes enum to calculate cell height for the variable, accessed externally; for cells that have VARIABLE HEIGHTS (e.g. CustomModule options cell)
        return nil
    }
    
    // MARK: - Data Aggregation Logic
    
    private var cellIsComplete: Bool = false //keeps track of cell's completion status for notif firing
    
    internal var mainDataObject: AnyObject? { //main object to report -> DataEntryVC, set by TV cells
        didSet {
            print("[mainDataObjWasSet] Var: [\(variableName)]. Value: \(mainDataObject).")
            
            //Only fire completion notification -> VC for AUTO-CAP variables & only if status has changed (i.e. complete -> incomplete or vice versa):
            if (self.variableReportType == ModuleVariableReportTypes.AutoCapture) {
                if let _ = mainDataObject { //data obj was SET
                    if !(cellIsComplete) { //cell was NOT previously complete, fire notification
                        let notification = NSNotification(name: BMN_Notification_AutoCapVarCompletionStatusDidChange, object: nil, userInfo: [BMN_Module_AutoCapVarCompletionStatusKey: true])
                        NSNotificationCenter.defaultCenter().postNotification(notification)
                        cellIsComplete = true //update internal completion status -> COMPLETE
                    }
                } else { //data object was CLEARED
                    if (cellIsComplete) { //cell WAS previously complete, fire notification
                        let notification = NSNotification(name: BMN_Notification_AutoCapVarCompletionStatusDidChange, object: nil, userInfo: [BMN_Module_AutoCapVarCompletionStatusKey: false])
                        NSNotificationCenter.defaultCenter().postNotification(notification)
                        cellIsComplete = false //update internal status -> INCOMPLETE
                    }
                }
            }
        }
    }
    
    func reportDataForVariable() -> [String: AnyObject]? { //called by Project class during aggregation
        var reportObject = Dictionary<String, AnyObject>()
        reportObject[BMN_Module_ReportedDataKey] = mainDataObject //main data object to report (unique to each type of Custom DataEntry cell)
        return reportObject
        //Note - timeStamps are generated @ time of aggregation; a SINGLE time stamp is generated for each location in the measurement cycle (b/c all variables w/in a single portion of the cycle have same time stamp as other variables). This may vary for auto-captured data!
    }
    
    func populateDataObjectForAutoCapturedVariable() { //OVERRIDE in subclasses - custom reporting behavior for AUTO-CAPTURED data; called by Project object containing this variable
        //end result is to set the 'mainDataObject' for the variable!
    }
    
    func isSubscribedToService(service: ServiceTypes) -> Bool { //OVERRIDE in subclasses (as needed); checks if variable is subscribed to the specified service (called by Project object containing this variable during re-population of data object [in event of a service failure])
        return false //default is FALSE
    }
    
    // MARK: - Computation Logic
    
    var parentComputation: String? //for ghosts, maintains reference to parent computation
    lazy var computationInputs = Dictionary<String, String>() //used to define configuration for computation; KEY = the unique ID for the input, VALUE = the NAME of the input var or ghost
    var existingVariables: [ComputationFramework_ExistingVariables]? //list of created vars
    
    internal func createGhostForVariable(variable: Module) { //used by computations; creates a ghost variable & sends notification -> ProjectVarsVC so ghost is added to the Project
        print("[Module] creating ghost for variable [\(variable.variableName)]...")
        let settings = variable.createDictionaryForCoreDataStore()
        let name = variable.variableName
        let info: [String: AnyObject] = [BMN_ComputationFramework_ComputationNameKey: self.variableName, BMN_ComputationFramework_GhostNameKey: name, BMN_ComputationFramework_GhostConfigDictKey: settings]
        let notification = NSNotification(name: BMN_Notification_ComputationFramework_DidCreateGhostVariable, object: nil, userInfo: info)
        NSNotificationCenter.defaultCenter().postNotification(notification)
    }
    
    // MARK: - Data Stream Logic
    
    var linkedDatastream: DatastreamIdentifiers? //for variables that utilize datastream, indicates which datastream object to use
        
}