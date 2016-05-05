//  Module.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/7/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Superclass containing basic behavior common to all modules. Each variable will be an object of the module class to which they are attached. This module will store the variable name & all associated behaviors. The module should also contain ALL information needed to configure the variable's behaviors & create the custom TV cell for reporting data.
// Note about a module's 'Behaviors' - all functionality should be described w/in the class itself. Externally, all the VC should be doing is determining which option was selected, setting the selected option for the module object, & then executing the returned function defined in the module object. This function will tell the VC how to lay out the interface, what information to store, etc. There should be no class-specific logic being executed in the View Controllers - the VC should describe a SINGLE method that knows what information to send & what info it will receive (always in consistent form) from the Module object! We might need to make an enum for each Module's behaviors & then construct the behaviors upon selection. Based on the 'selectedFunctionality', the app will communicate w/ the VC during configuration.

import Foundation
import UIKit

class Module { //defines the behaviors that are common to all modules
    static let modules: [Modules] = [Modules.CustomModule, Modules.EnvironmentModule, Modules.FoodIntakeModule, Modules.ExerciseModule, Modules.BiometricModule, Modules.CarbonEmissionsModule] //list of available modules, update whenever a new one is added
    
    //***Testing ground for external interaction to dynamically alter the Behaviors/Computations displayed in ConfigureModuleVC for selection:
    var blockers: [String]? //array of blocker indicators for comp/behavior display, set by ConfigVC
    var locationInFlow: VariableLocations? //indicates whether var is input or output
    //***
    
    var isOutcomeMeasure: Bool = false //externally set to indicate that this variable is an OM
    var isAutomaticallyCaptured: Bool = false //set after functionality is selected (manual vs. auto-cap)
    private let variableState: ModuleVariableStates //state of THIS instance (Configuration or Reporting)
    internal let variableName: String //the name given to the variable attached to this module
    internal var moduleTitle: String = "" //overwrite w/ <> Module enum raw value in each class
    internal var sectionsToDisplay: [String] { //sections to display in ConfigureModuleVC
        if !(behaviors.isEmpty) && !(computations.isEmpty) { //BOTH behaviors & comps are available
            return [BMN_BehaviorsKey, BMN_ComputationsKey]
        } else if !(behaviors.isEmpty) { //ONLY behaviors
            return [BMN_BehaviorsKey]
        } else if !(computations.isEmpty) { //ONLY computations
            return [BMN_ComputationsKey]
        }
        return []
    }
    
    internal var configureModuleLayoutObject: Dictionary<String, AnyObject> { //dataObject for laying out the available behaviors & computations in the ConfigureModuleVC
        var tempObject = Dictionary<String, AnyObject>()
        
        var viewForSection = Dictionary<String, CustomTableViewHeader>()
        for section in sectionsToDisplay { //assign headerViews to their respective sections
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
        for section in sectionsToDisplay { //assign behaviors & computations to their respective sections
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
        
        return tempObject
    }
    
    internal var behaviors: [String] { //override w/ behaviors for each module
        get { //can only GET, not set
            return []
        }
    }
    
    internal var computations: [String] { //override w/ computations for each module
        get { //can only GET, not set
            return []
        }
    }
    
    // MARK: - Initializers
    
    init(name: String) { //initializer for variable during SET-UP
        self.variableName = name
        self.variableState = ModuleVariableStates.VariableConfiguration
    }
    
    init(name: String, dict: [String: AnyObject]) { //initializer for variable during RECONSTRUCTION from CoreData dict
        self.variableName = name
        self.variableState = ModuleVariableStates.DataReporting
        if let auto = dict[BMN_VariableIsAutomaticallyCapturedKey] as? Bool { //chck if auto or manual cap
            self.isAutomaticallyCaptured = auto
        }
    }
    
    // MARK: - Variable Configuration
    
    internal var selectedFunctionality: String? { //the behavior OR computation (picked from the enum defined in each module object) that the user selected for this variable
        didSet { //set configurationOptions based on selection
            if (self.variableState == ModuleVariableStates.VariableConfiguration) { //ONLY set-up the configurationOptionsLayoutObject if the variable is being set-up
                print("User selected behavior: '\(selectedFunctionality!)'.")
                setConfigurationOptionsForSelection()
            }
        }
    }
    
    internal var configurationOptionsLayoutObject: [(ConfigurationOptionCellTypes, Dictionary<String, AnyObject>)]? //object that handles layout of ConfigurationOptionsVC TV cells
    
    internal func setConfigurationOptionsForSelection() { //override in subclasses
        //Assigns configurationOptions based on the user's selection of a behavior/computation
        print("setConfigOptions - Superclass Module")
        configurationOptionsLayoutObject = nil
    }
    
    internal func matchConfigurationItemsToProperties(configurationData: [String: AnyObject]) -> (Bool, String?, [String]?) {
        //Matches reportedData from configurationCells -> properties in the Module object & returns TRUE if operation was successful, (FALSE + an error message) if the operation failed; the 3rd part of the return object is an optional FLAG (that tells the VC to visually mark the cell w/ the corresponding DESCRIPTOR in the data source, b/c that is where the problem has occurred).
        return (false, "Superclass matchConfiguration fx call!", nil)
    }
    
    // MARK: - Core Data Logic
    
    internal func createDictionaryForCoreDataStore() -> Dictionary<String, AnyObject> { //generates dictionary to be saved by CoreData (this dict will allow full reconstruction of the object)
        let persistentDictionary: [String: AnyObject] = [BMN_ModuleTitleKey: self.moduleTitle, BMN_VariableIsOutcomeMeasureKey: self.isOutcomeMeasure, BMN_VariableIsAutomaticallyCapturedKey : self.isAutomaticallyCaptured] //'moduleTitle' matches switch case in 'Project' > 'createModuleObjectFromModuleName' func
        return persistentDictionary
    }
    
    // MARK: - Data Entry Logic
    
    // Configuration variables - used to customize DataEntry TV cells (e.g. for freeform data entry):
//    var FreeformCell_defaultValue: String? //default value for cell's textField
//    var FreeformCell_characterLimit: Int?
//    var FreeformCell_dataType: ProtectedFreeformTypes? //enum defined in 'FreeformCell'.swift
    var FreeformCell_configurationObject: [(String?, ProtectedFreeformTypes?, String?, Int?, (Int?, Int?)?)]? //tuple specifies all config for FreeformCell - indicates (1) # of TFs (via the array's count); (2) label? for each TF; (3) type? of data in TF (corresponds w/ ProtectedFreeformTypes enum); (4) defaultValue?; (5) characterLimit?; (6) (if text is numerical) an upper/lower bound in format (Int? <-lower, Int? <-upper)?.
    var FreeformCell_labelBeforeField: Bool? //specifies whether TF lbl is before or after field
    
    func getDataEntryCellTypeForVariable() -> DataEntryCellTypes? { //indicates to DataEntryVC what kind of DataEntry cell should be used for this variable (OVERRIDE in subclasses)
        return nil
    }
    
    var cellHeightUserInfo: [String: AnyObject]? { //dictionary containing information needed to calculate cell height for the variable, accessed externally by VC
        return nil
    } //For cells that have VARIABLE HEIGHTS (e.g. Custom Module options cell), we will need to include in the data source a custom cell height (which we can calculate beforehand b/c we know everything about how the cell needs to be configured, e.g. if the CustomOptions cell has 3 answer choices, we can calculate the height w/ a function, add that height to the data source; the VC TV delegate method should check for custom height & set to default if one is not found.)
    
    // MARK: - Data Aggregation Logic
    
    internal var mainDataObject: AnyObject? { //main object to report -> DataEntryVC, set by TV cells
        didSet {
            print("[mainDataObjWasSet] Var: [\(variableName)]. Value: \(mainDataObject).")
        }
    }
    
    func reportDataForVariable() -> [String: AnyObject]? { //called by Project class during aggregation
        var reportObject = Dictionary<String, AnyObject>()
        reportObject[BMN_Module_ReportedDataKey] = mainDataObject //main data object to report (unique to each type of Custom DataEntry cell)
        return reportObject
        //Note - timeStamps are generated @ time of aggregation in DataEntryVC; a SINGLE time stamp is generated for IVs & another for OMs (b/c all IVs have same time stamp as other IVs, & all OMs have same time stamp as other OMs). This may vary for auto-captured data!
    }
    
    func populateDataObjectForAutoCapturedVariable() { //OVERRIDE in subclasses; custom reporting behavior for AUTO-CAPTURED data; called by Project object containing this variable
        //end result is to set the 'mainDataObject' for the variable!
    }
    
    func isSubscribedToService(service: ServiceTypes) -> Bool { //OVERRIDE in subclasses (as needed); checks if variable is subscribed to the specified service (called by Project object containing this variable during re-population of data object [in event of a service failure])
        return false //default is FALSE
    }
    
//    array.append((ConfigurationOptionCellTypes.Computation, [BMN_Configuration_CellDescriptorKey: "BMI", BMN_LEVELS_MainLabelKey: "Click and drag over 2 variable labels:", BMN_Configuration_AllowedVariableTypesForComputationKey: [CustomModuleVariableTypes.Behavior_BinaryOptions.rawValue]])) //computation default config logic
    
}