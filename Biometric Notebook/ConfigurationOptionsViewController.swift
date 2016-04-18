//  ConfigurationOptionsViewController.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 3/28/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Offers more specific configuration options after the user has selected a behavior or computation for the variable.

import UIKit

class ConfigurationOptionsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var doneButton: UIBarButtonItem! //disable until ALL options are set
    @IBOutlet weak var optionsTableView: UITableView!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint! //TV bottom -> bottom layout guide
    
    var createdVariable: Module? //variable w/ completed configuration (sent from ConfigModuleVC)
    var reportedDataObject = Dictionary<String, AnyObject>() //contains all config data
    var dataSource: [(ConfigurationOptionCellTypes, Dictionary<String, AnyObject>)] {
        get {
            if let variable = createdVariable, object = variable.configurationOptionsLayoutObject {
                return object
            } else { //no object found
                return []
            }
        }
    }
    var numberOfConfiguredCells: Int = 0 { //keeps track of the current # of configured cells
        didSet { //adjust 'doneButton' status appropriately
            configureDoneButton()
        }
    }
    var customOptionsCellLevels: Int? //indicator for heightForRow() for CustomOptionsConfigCell
    var computationCellLevels: Int? //indicator for heightForRow() for BaseComputationConfigCell
    var selectFromOptionsCellLevels: Int? //indicator for heightForRow() for SelectFromOptsConfigCell
    
    var currentVariables: [Module]? //list of existing variables (for computation)**
    
    // MARK: - View Configuration
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Add gesture recognizer for tap (to dismiss open textFields):
        let gesture = UITapGestureRecognizer(target: self, action: #selector(self.tableViewWasTapped))
        optionsTableView.addGestureRecognizer(gesture)
        
        //Add notification observers:
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.cellCompletionStatusDidChange(_:)), name: BMN_Notification_CompletionIndicatorDidChange, object: nil) //add observer for LEVELS Cell notification BEFORE configuring TV!
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.cellDidReportData(_:)), name: BMN_Notification_CellDidReportData, object: nil) //update report obj w/ data
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.adjustHeightForConfigurationCell(_:)), name: BMN_Notification_AddOptionButtonWasClicked, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.adjustHeightForConfigurationCell(_:)), name: BMN_Notification_AdjustHeightForComputationCell, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.adjustHeightForConfigurationCell(_:)), name: BMN_Notification_AdjustHeightForSelectFromOptionsCell, object: nil)
        
        //Keyboard notifications:
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.keyboardDidAppearWithFrame(_:)), name: UIKeyboardDidChangeFrameNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.keyboardDidHide(_:)), name: UIKeyboardDidHideNotification, object: nil)
        
        optionsTableView.delegate = self
        optionsTableView.dataSource = self //set the # of prototype cells to 0 in IB!
        registerConfigurationCellTypes() //register TV for all config cell types
    }
    
    func registerConfigurationCellTypes() { //register ALL possible custom configuration cell types
        optionsTableView.registerClass(SimpleTextConfigurationCell.self, forCellReuseIdentifier: NSStringFromClass(SimpleTextConfigurationCell)) //simple txt
        optionsTableView.registerClass(SimpleNumberConfigurationCell.self, forCellReuseIdentifier: NSStringFromClass(SimpleNumberConfigurationCell)) //simple #
        optionsTableView.registerClass(BooleanConfigurationCell.self, forCellReuseIdentifier: NSStringFromClass(BooleanConfigurationCell)) //boolean
        optionsTableView.registerClass(SelectFromOptionsConfigurationCell.self, forCellReuseIdentifier: NSStringFromClass(SelectFromOptionsConfigurationCell)) //select from available options
        optionsTableView.registerClass(CustomOptionsConfigurationCell.self, forCellReuseIdentifier: NSStringFromClass(CustomOptionsConfigurationCell)) //custom options
        optionsTableView.registerClass(BaseComputationConfigurationCell.self, forCellReuseIdentifier: NSStringFromClass(BaseComputationConfigurationCell)) //computations cell
        optionsTableView.registerClass(ExampleConfigurationCell.self, forCellReuseIdentifier: NSStringFromClass(ExampleConfigurationCell)) //example
    }
    
    override func viewWillDisappear(animated: Bool) { //remove observer befor exiting this VC
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func didReceiveMemoryWarning() { //save current config state?
        super.didReceiveMemoryWarning()
    }
    
    func tableViewWasTapped() { //dismisses keyboard when TV is tapped
        self.view.endEditing(true)
    }
    
    func configureDoneButton() { //controls whether the 'doneButton' is enabled or not
        let total = dataSource.count
        if (numberOfConfiguredCells != total) { //some cells haven't been configured yet
            doneButton.enabled = false
            if (numberOfConfiguredCells > total) { //error check
                print("[configureDoneButton] Error - # of configured cells exceeds total # of cells!")
            }
        } else { //all cells have been configured
            doneButton.enabled = true
        }
    }
    
    func cellDidReportData(notification: NSNotification) { //each time a cell reports data, update the report object against its descriptor
        print("Cell did report data...") 
        if let dict = notification.userInfo { //search through each type of cellDescriptor to get data
            if let data = dict[BMN_CustomModule_CustomOptions_PromptID] { //PROMPT
                reportedDataObject[BMN_CustomModule_CustomOptions_PromptID] = data
                print("Prompt: '\(data as? String)'.")
            } else if let data = dict[BMN_CustomModule_CustomOptions_OptionsID] { //CUSTOM OPTS
                reportedDataObject[BMN_CustomModule_CustomOptions_OptionsID] = data
                let dat = data as! [String]
                for opt in dat { //**
                    print("Option: '\(opt)'.")
                }
            } else if let data = dict[BMN_CustomModule_CustomOptions_MultipleSelectionAllowedID] { //check if multiple selection is allowed
                print("Mult Select Allowed?: \(data as? Bool).")
                reportedDataObject[BMN_CustomModule_CustomOptions_MultipleSelectionAllowedID] = data
            } else if let data = dict[BMN_CustomModule_RangeScale_MinimumID] { //RangeScale - Min
                reportedDataObject[BMN_CustomModule_RangeScale_MinimumID] = data
                print("RS Minimum: \(data as? Int).")
            } else if let data = dict[BMN_CustomModule_RangeScale_MaximumID] { //RangeScale - Max
                reportedDataObject[BMN_CustomModule_RangeScale_MaximumID] = data
                print("RS Maximum: \(data as? Int).")
            } else if let data = dict[BMN_CustomModule_RangeScale_IncrementID] { //RangeScale - Inc
                reportedDataObject[BMN_CustomModule_RangeScale_IncrementID] = data
                print("RS Increment: \(data as? Int).")
            } else if let data = dict[BMN_EnvironmentModule_Weather_OptionsID] { //EM - WeatherOptions
                reportedDataObject[BMN_EnvironmentModule_Weather_OptionsID] = data
                let dat = data as! [String]
                for opt in dat { //*
                    print("[EM-WeatherOpts] '\(opt)'.")
                }
            }
        }
    }
    
    func cellCompletionStatusDidChange(notification: NSNotification) {
        if let info = notification.userInfo, status = info[BMN_LEVELS_CompletionIndicatorStatusKey] as? Bool { //obtain current status & update the counter variable accordingly
            if (status) { //status was set -> COMPLETE (add 1 to the counter)
                self.numberOfConfiguredCells += 1
            } else { //status was set -> INCOMPLETE (subtract 1 from the counter)
                self.numberOfConfiguredCells -= 1
            }
        }
    }
    
    func adjustHeightForConfigurationCell(notification: NSNotification) { //adjusts ht for cell
        if let info = notification.userInfo {
            if let numberOfLevels = info[BMN_CustomOptionsConfigCell_NumberOfLevelsKey] as? Int { //value is for CustomOptions cell
                customOptionsCellLevels = numberOfLevels //set indicator w/ new # of levels
            }
            if let levels = info[BMN_BaseComputationConfigCell_NumberOfLevelsKey] as? Int { //value is for BaseComputation cell
                computationCellLevels = levels
            }
            if let levels = info[BMN_SelectFromOptionsConfigCell_NumberOfLevelsKey] as? Int { //value is for SelectFromOptions cell
                selectFromOptionsCellLevels = levels
            }
            optionsTableView.reloadData() //redraw w/ new height
        }
    }
    
    // MARK: - Keyboard Logic
    
    var blockKeyboardDidAppear: Bool = false //blocker
    
    func keyboardDidAppearWithFrame(notification: NSNotification) {
        if !(blockKeyboardDidAppear) { //suppress if blocker is TRUE
            if let dict = notification.userInfo, keyboardFrame = dict[UIKeyboardFrameEndUserInfoKey] as? NSValue {
                let height = keyboardFrame.CGRectValue().height
                bottomConstraint.constant = height //shift up TV to allow scrolling
            }
        }
    }
    
    func keyboardWillHide(notification: NSNotification) { //reset bottom constraint
        bottomConstraint.constant = 0
        blockKeyboardDidAppear = true //block fx from firing
    }
    
    func keyboardDidHide(notification: NSNotification) { //clear blocker for next cycle
        blockKeyboardDidAppear = false //reset
    }
    
    // MARK: - Table View 
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Configuration"
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat { //this function is called BEFORE the cell obj is set (so we cannot query cell for height here)!
        //Obtain cell height from ConfigurationCellTypes (enum) function:
        let cellType = dataSource[indexPath.row].0
        switch cellType {
        case .CustomOptions: //modified height determination based on notification obj
            if let levels = customOptionsCellLevels { //check if height was defined
                return CGFloat(levels) * 40 + BMN_DefaultBottomSpacer
            } else { //default height
                return cellType.getHeightForConfigurationCellType()
            }
        case .Computation:
            if let levels = computationCellLevels { //check if height was defined
                return CGFloat(levels) * 40 + BMN_DefaultBottomSpacer
            } else { //default height
                return cellType.getHeightForConfigurationCellType()
            }
        case .SelectFromOptions:
            if let levels = selectFromOptionsCellLevels { //check if height was defined
                return CGFloat(levels) * 40 + BMN_DefaultBottomSpacer
            } else { //default height
                return cellType.getHeightForConfigurationCellType()
            }
        default:
            return cellType.getHeightForConfigurationCellType()
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cellType = dataSource[indexPath.row].0 //get cell type from data source
        var cell = BaseConfigurationCell()
        switch cellType { //obtain cell based on type
        case .SimpleNumber:
            cell = tableView.dequeueReusableCellWithIdentifier(NSStringFromClass(SimpleNumberConfigurationCell)) as! SimpleNumberConfigurationCell
        case .SimpleText:
            cell = tableView.dequeueReusableCellWithIdentifier(NSStringFromClass(SimpleTextConfigurationCell)) as! SimpleTextConfigurationCell
        case .Boolean:
            cell = tableView.dequeueReusableCellWithIdentifier(NSStringFromClass(BooleanConfigurationCell)) as! BooleanConfigurationCell
        case .SelectFromOptions:
            cell = tableView.dequeueReusableCellWithIdentifier(NSStringFromClass(SelectFromOptionsConfigurationCell)) as! SelectFromOptionsConfigurationCell
        case .CustomOptions:
            cell = tableView.dequeueReusableCellWithIdentifier(NSStringFromClass(CustomOptionsConfigurationCell)) as! CustomOptionsConfigurationCell
        case .Computation:
            cell = tableView.dequeueReusableCellWithIdentifier(NSStringFromClass(BaseComputationConfigurationCell)) as! BaseComputationConfigurationCell
            (cell as! BaseComputationConfigurationCell).availableVariables = self.currentVariables //pass all existing variables -> cell
        case .Example:
            cell = tableView.dequeueReusableCellWithIdentifier(NSStringFromClass(ExampleConfigurationCell)) as! ExampleConfigurationCell
        }
        cell.dataSource = dataSource[indexPath.row].1 //set cell's dataSource
        return cell
    }
    
    // MARK: - Button Actions
    
    @IBAction func doneButtonClick(sender: AnyObject) { //save configuration options & return to Vars
        //Report config data -> the Module object (where it will be used to set Module properties):
        if let variable = createdVariable {
            let (success, msg, flags) = variable.matchConfigurationItemsToProperties(reportedDataObject)
            if (success) { //operation was successful
                performSegueWithIdentifier("unwindToVariablesVC", sender: nil)
            } else { //unsuccessful operation, display alert
                let alert = UIAlertController(title: "Error!", message: msg, preferredStyle: UIAlertControllerStyle.Alert)
                let ok = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (let ok) in
                    if let flaggedCells = flags {
                        for i in 0..<self.dataSource.count {
                            let cell = self.optionsTableView.cellForRowAtIndexPath(NSIndexPath(forRow: i, inSection: 0)) as! BaseConfigurationCell //get reference to each cell
                            let descriptor = cell.cellDescriptor //check descriptor for match w/ flag
                            if (flaggedCells.contains(descriptor)) { //if cell is flagged, set flag var
                                cell.flagged = true
                            }
                        }
                    }
                })
                alert.addAction(ok)
                presentViewController(alert, animated: true, completion: nil)
            }
        } else {
            print("[doneButtonClick] Error! Could not find a variable!")
        }
    }

}