//  AddActionViewController.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 7/31/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Allows addition & configuration of a project action.

import UIKit

class AddActionViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIPickerViewDelegate, UIPickerViewDataSource, SetupVariablesProtocol {
    
    @IBOutlet weak var addActionButton: UIButton!
    @IBOutlet weak var actionPicker: UIPickerView!
    @IBOutlet weak var actionConfigTableView: UITableView!
    @IBOutlet weak var actionConfigTVHeightConstraint: NSLayoutConstraint! //adjust as needed
    @IBOutlet weak var addQualifierButton: UIButton!
    @IBOutlet weak var actionQualifiersTableView: UITableView!
    
    private var actionPickerRowArray: [String] = ["", ActionTypes.Eat.rawValue, ActionTypes.Sleep.rawValue, ActionTypes.Exercise.rawValue, ActionTypes.Custom.rawValue]
    var actionConfigDataSource: [(ConfigurationOptionCellTypes, Dictionary<String, AnyObject>)] = [((ConfigurationOptionCellTypes.SelectFromOptions, [BMN_Configuration_CellDescriptorKey: BMN_Action_ActionLocationID, BMN_LEVELS_MainLabelKey: "Where in the measurement flow does the action occur?", BMN_SelectFromOptions_OptionsKey: [ActionLocations.BeforeInputs.rawValue, ActionLocations.BetweenInputsAndOutcomes.rawValue], BMN_SelectFromOptions_DefaultOptionsKey: [ActionLocations.BetweenInputsAndOutcomes.rawValue]]))] //TV dataSource starts w/ 1 cell - does action occur @ every measurement cycle; 2) [opt] does action occur before IV or between IV/OM
    var heightForCells = Dictionary<String, Int>() //object for TV's heightForRow()
    var defaultTVHeight: CGFloat = 170 //base height (for 1 cell); matches definition in storyboard!
    var expandedTVHeight: CGFloat = 250 //expanded height (for 2 cells)
    
    var actionType: (ActionTypes, String?)? { //selected actionType
        didSet {
            setProjectAction() //update action for selection
        }
    }
    var actionLocation: ActionLocations? { //selected ActionLocation
        didSet { //action can NOT be configured such that its location is between IV & OM but it occurs asynchronously
            var modificationOccurred: Bool = false //indicator
            if (self.actionLocation == ActionLocations.BeforeInputs) { //reveal 2nd TV config cell
                if (self.actionConfigDataSource.count == 1) { //safety check
                    self.actionConfigDataSource.append(((ConfigurationOptionCellTypes.SelectFromOptions, [BMN_Configuration_CellDescriptorKey: BMN_Action_ActionMeasurementRateID, BMN_LEVELS_MainLabelKey: "Does action occur at every measurement cycle?", BMN_SelectFromOptions_OptionsKey: ["YES", "NO"], BMN_SelectFromOptions_DefaultOptionsKey: ["YES"], BMN_SelectFromOptions_IsBooleanKey: true]))) //add 2nd option -> dataSource
                    modificationOccurred = true //set indicator
                }
            } else { //hide 2nd TV config cell & set value -> default
                if (self.actionConfigDataSource.count == 2) { //safety check
                    self.actionConfigDataSource.removeLast()
                    self.occursInEveryCycle = true //reset default value
                    modificationOccurred = true //set indicator
                }
            }
            setProjectAction() //update action for selection AFTER system checks are applied
            dispatch_async(dispatch_get_main_queue()) {
                if (modificationOccurred) { //only modify UI if something has changed
                    self.actionConfigTableView.reloadData() //update UI
                    if (self.actionConfigDataSource.count == 1) {
                        self.actionConfigTVHeightConstraint.constant = self.defaultTVHeight //shrink TV
                    } else if (self.actionConfigDataSource.count == 2) { //add in 2nd cell w/ default
                        self.actionConfigTVHeightConstraint.constant = self.expandedTVHeight //expand TV
                        if let cell = self.actionConfigTableView.cellForRowAtIndexPath(NSIndexPath.init(forRow: 1, inSection: 0)) as? SelectFromOptionsConfigurationCell {
                            cell.resetBinaryCellToDefault() //use builtin method to set 'YES' to selected
                        }
                    }
                    modificationOccurred = false //clear for next run
                }
            }
        }
    }
    var occursInEveryCycle: Bool? = true { //action config item
        didSet {
            setProjectAction() //update action for selection
        }
    }
    var actionQualifiers: [Module]? = [] { //qualifiersTV dataSource
        didSet {
            setProjectAction() //update action for qualifier addition/removal
            if let parent = self.parentViewController as? SetupVariablesViewController {
                parent.actionQualifiers = self.actionQualifiers //update parent variable
            }
        }
    }
    var projectAction: Action? {
        didSet {
            if let parent = self.parentViewController as? SetupVariablesViewController {
                parent.projectAction = self.projectAction //update parent variable
            }
        }
    }
    var ghostVariables: [String: [GhostVariable]]? { //KEY = parent computation, value = [Ghosts]
        didSet {
            if let parent = self.parentViewController as? SetupVariablesViewController {
                parent.ghostVariables = self.ghostVariables //update parent variable
            }
        }
    }
    
    var didSendSegue: Bool = false //indicator (for ghost notification routing)
    var variableName: String? //the name of the variable entered by the user
    var createdVariable: Module? //the completed variable created by the user
    var moduleBlocker = Module_DynamicConfigurationFramework() //class that handles blocking
    var isEditProjectFlow: Bool = false //indicator for edit project mode
    
    // MARK: - View Configuration

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (isEditProjectFlow) { //EDIT PROJECT flow - update addAction btnTitle & hide configTV
            if let defaultTitle = self.projectAction?.action.rawValue { //set btn title
                addActionButton.setTitle(defaultTitle, forState: .Normal)
            } else if let customTitle = self.projectAction?.customActionName {
                addActionButton.setTitle(customTitle, forState: .Normal)
            }
            addActionButton.enabled = false //disable btn to prevent editing
            actionConfigTableView.hidden = true //hide TV (prevent editing)
            actionConfigTVHeightConstraint.constant = 0 //remove TV height constraint
        }
        
        //Configure actionConfigTV:
        actionConfigTableView.dataSource = self
        actionConfigTableView.delegate = self
        actionConfigTableView.registerClass(SelectFromOptionsConfigurationCell.self, forCellReuseIdentifier: NSStringFromClass(SelectFromOptionsConfigurationCell)) //select from available options (cell used to configure action)
        
        //Configure actionQualifierTV & actionPicker:
        actionQualifiersTableView.dataSource = self
        actionQualifiersTableView.delegate = self
        actionPicker.dataSource = self
        actionPicker.delegate = self
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.adjustHeightForConfigurationCell(_:)), name: BMN_Notification_AdjustHeightForConfigCell, object: nil) //updates height for specified config cell; must be in VDL b/c of tabBar!
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.cellDidReportData(_:)), name: BMN_Notification_CellDidReportData, object: nil) //update report obj w/ data
    }
    
    override func viewWillAppear(animated: Bool) { //register for notifications
        self.didSendSegue = false //reset indicator (for ghost variable creation)
        NSNotificationCenter.defaultCenter().removeObserver(self) //clear observers FIRST
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.cellDidReportData(_:)), name: BMN_Notification_CellDidReportData, object: nil) //update report obj w/ data
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.adjustHeightForConfigurationCell(_:)), name: BMN_Notification_AdjustHeightForConfigCell, object: nil) //updates height for specified config cell
    }
    
    override func viewWillDisappear(animated: Bool) { //remove notification observers
        NSNotificationCenter.defaultCenter().removeObserver(self)
        
        //Register for ghost variable notification. De-registers when view is unloaded:
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.systemDidCreateGhostVariable(_:)), name: BMN_Notification_ComputationFramework_DidCreateGhostVariable, object: nil)
    }
    
    private func setProjectAction() { //sets the action based on current configuration
        if !(isEditProjectFlow) { //ONLY fires in default mode
            if let type = actionType, location = actionLocation, inEveryCycle = occursInEveryCycle {
                var qualifiers: [String] = []
                if let vars = actionQualifiers {
                    for qualifier in vars {
                        qualifiers.append(qualifier.variableName)
                    }
                }
                self.projectAction = Action(action: type.0, customName: type.1, location: location, occursInEachCycle: inEveryCycle, qualifiersCount: qualifiers.count)
            } else { //not all parameters have been set
                self.projectAction = nil //*remove action*
            }
        }
    }
    
    // MARK: - Notification Handling
    
    func cellDidReportData(notification: NSNotification) {
        if let info = notification.userInfo {
            for (k, v) in info { //obtain reported data & modify Action config
                if let key = k as? String {
                    if (key == BMN_Action_ActionLocationID) {
                        if let value = v as? [String] {
                            if let locationRaw = value.first, location = ActionLocations(rawValue: locationRaw) { //value was selected
                                self.actionLocation = location
                            } else { //value was removed - set to NIL
                                self.actionLocation = nil
                            }
                        }
                    } else if (key == BMN_Action_ActionMeasurementRateID) {
                        if let value = v as? [String] {
                            if let stringVal = value.first { //value was set
                                if (stringVal.lowercaseString == "yes") { //set -> TRUE
                                    self.occursInEveryCycle = true
                                } else if (stringVal.lowercaseString == "no") { //set -> FALSE
                                    self.occursInEveryCycle = false
                                }
                            } else { //value was removed - set to NIL
                                self.occursInEveryCycle = nil
                            }
                        }
                    }
                }
            }
        }
    }
    
    func adjustHeightForConfigurationCell(notification: NSNotification) { //adjusts ht for cell
        if let info = notification.userInfo, uniqueId = info[BMN_AdjustHeightForConfigCell_UniqueIDKey] as? String, numberOfLevels = info[BMN_AdjustHeightForConfigCell_NumberOfLevelsKey] as? Int { //assign the # of levels according to the cell's unique ID object
            heightForCells.updateValue(numberOfLevels, forKey: uniqueId) //update indicator object
            actionConfigTableView.reloadData() //redraw cell w/ new height
        }
    }
    
    func systemDidCreateGhostVariable(notification: NSNotification) { //responds to Module object's request to create a ghost for a computation variable
        if (didSendSegue) { //ONLY respond to notification if this VC created the variable
            if let info = notification.userInfo, sender = info[BMN_ComputationFramework_ComputationNameKey] as? String, ghostName = info[BMN_ComputationFramework_GhostNameKey] as? String, settings = info[BMN_ComputationFramework_GhostConfigDictKey] as? [String: AnyObject] {
                if (ghostVariables == nil) { //initialize array if it doesn't yet exist
                    ghostVariables = Dictionary<String, [GhostVariable]>()
                }
                if (ghostVariables![sender] == nil) { //check if entry exists for sender computation
                    ghostVariables![sender] = [] //initialize an array
                }
                let ghost = GhostVariable(computation: sender, name: ghostName, settings: settings)
                ghostVariables![sender]!.append(ghost)
            }
        }
    }
    
    // MARK: - Table View
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (tableView == actionConfigTableView) {
            return actionConfigDataSource.count
        } else if (tableView == actionQualifiersTableView) {
            if let qualifiers = actionQualifiers {
                return qualifiers.count
            }
        }
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = UITableViewCell()
        if (tableView == actionConfigTableView) {
            cell = BaseConfigurationCell()
            let cellType = actionConfigDataSource[indexPath.row].0 //get cell type from data source
            switch cellType { //obtain cell based on type
            case .SelectFromOptions:
                cell = tableView.dequeueReusableCellWithIdentifier(NSStringFromClass(SelectFromOptionsConfigurationCell)) as! SelectFromOptionsConfigurationCell
            default:
                print("[AddActionVC] Error - default in TV cell switch.")
                break
            }
            (cell as! BaseConfigurationCell).dataSource = actionConfigDataSource[indexPath.row].1 //set cell's dataSource
            return cell
        } else if (tableView == actionQualifiersTableView) {
            cell = tableView.dequeueReusableCellWithIdentifier("qualifier")!
            if let qualifiers = actionQualifiers {
                cell.textLabel?.text = qualifiers[indexPath.row].variableName
                cell.textLabel?.backgroundColor = UIColor.clearColor()
                cell.detailTextLabel?.backgroundColor = UIColor.clearColor()
                cell.textLabel?.textColor = UIColor.orangeColor()
                cell.backgroundColor = UIColor(red: 35/255, green: 171/255, blue: 254/255, alpha: 0.3)
                if let functionality = qualifiers[indexPath.row].selectedFunctionality {
                    cell.detailTextLabel?.text = functionality
                }
            }
        }
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat { //this function is called BEFORE the cell obj is set (so we cannot query cell for height here)!
        if (tableView == actionConfigTableView) {
            if let cellDescriptor = actionConfigDataSource[indexPath.row].1[BMN_Configuration_CellDescriptorKey] as? String, numberOfLevels = heightForCells[cellDescriptor] { //check for custom definition
                return CGFloat(numberOfLevels) * 40 + BMN_DefaultBottomSpacer
            }
            let cellType = actionConfigDataSource[indexPath.row].0
            return cellType.getHeightForConfigurationCellType() //default height definition
        } else if (tableView == actionQualifiersTableView) {
            return 60
        }
        return 0
    }
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        if (tableView == actionQualifiersTableView) { //only allow deletion of created variables
            return .Delete
        } else {
            return .None
        }
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if (editingStyle == .Delete) { //delete row from data source
            if let qualifiers = actionQualifiers {
                let varToDelete = qualifiers[indexPath.row] //variable that is about to be deleted
                if let _ = ghostVariables { //delete all ghosts associated w/ the variable
                    print("Deleting ghosts for variable: [\(varToDelete.variableName)]. Number of ghosts: \(ghostVariables![varToDelete.variableName]?.count).")
                    ghostVariables![varToDelete.variableName] = nil
                }
                actionQualifiers!.removeAtIndex(indexPath.row)
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            }
        }
    }
    
    // MARK: - Picker View
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return actionPickerRowArray.count
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return actionPickerRowArray[row]
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if let actionType = ActionTypes(rawValue: actionPickerRowArray[row]) {
            switch actionType {
            case .Custom:
                let alert = UIAlertController(title: "Add Custom Action", message: "Please enter a custom action", preferredStyle: UIAlertControllerStyle.Alert)
                let cancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: { (let cancel) -> Void in
                    self.actionPicker.selectRow(0, inComponent: 0, animated: true) //cycle picker -> ""
                })
                let add = UIAlertAction(title: "Add Action", style: UIAlertActionStyle.Default, handler: { (let add) -> Void in
                    if let input = alert.textFields?.first?.text {
                        let text = input.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                        if (text != "") { //create a custom action from the input
                            self.actionType = (.Custom, input)
                            self.shouldShowPickerView(showPicker: false)
                        } else { //incomplete entry, keep picker visible & cycle picker to start
                            self.actionPicker.selectRow(0, inComponent: 0, animated: true)
                            self.actionType = nil //clear type
                        }
                    }
                })
                alert.addTextFieldWithConfigurationHandler({ (let textField) -> Void in
                    textField.autocapitalizationType = .Words
                })
                alert.addAction(cancel)
                alert.addAction(add)
                presentViewController(alert, animated: true, completion: nil)
            default: //if any other action is selected, set selectedAction & hide picker
                if let action = ActionTypes(rawValue: actionPickerRowArray[row]) {
                    self.actionType = (action, nil)
                    shouldShowPickerView(showPicker: false)
                } else {
                    self.actionPicker.selectRow(0, inComponent: 0, animated: true)
                    self.actionType = nil
                }
            }
        } else { //first item in the picker (the blank) was selected
            self.actionType = nil
        }
    }
    
    private func shouldShowPickerView(showPicker show: Bool) { //controls picker display
        if (show) { //show picker
            actionPicker.hidden = false
            for subview in view.subviews {
                if (subview != actionPicker) { //hide non-picker views
                    subview.hidden = true
                }
            }
        } else { //hide picker & set 'actionButton' title
            if let type = self.actionType { //check if an actionType exists (else leave btn as is)
                setActionButtonTitleForAction(type)
            }
            actionPicker.hidden = true
            for subview in view.subviews {
                if (subview != actionPicker) { //reveal non-picker views
                    subview.hidden = false
                }
            }
        }
    }
    
    private func setActionButtonTitleForAction(action: (ActionTypes, String?)) {
        addActionButton.setTitleColor(UIColor.blackColor(), forState: .Normal)
        if let customName = action.1 { //CUSTOM action - update btn w/ entered name
            addActionButton.setTitle("Action = \(customName)", forState: .Normal)
        } else { //DEFAULT action - update btn w/ name
            addActionButton.setTitle("Action = \(action.0.rawValue)", forState: .Normal)
        }
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) { //if user taps on view when picker is visible, dismiss picker
        if (actionPicker.hidden == false) { //only fires when pickerView is visible
            shouldShowPickerView(showPicker: false) //dismiss picker
        }
    }
    
    // MARK: - Button Actions
    
    @IBAction func addActionButtonClick(sender: AnyObject) {
        actionPicker.selectRow(0, inComponent: 0, animated: false) //start picker @ empty value
        shouldShowPickerView(showPicker: true) //show picker
    }
    
    @IBAction func addQualifierButtonClick(sender: AnyObject) {
        let alert = UIAlertController(title: "New Variable", message: "Type the name of the variable you wish to add. The variable's name must be unique.", preferredStyle: .Alert)
        alert.addTextFieldWithConfigurationHandler { (let field) -> Void in
            field.autocapitalizationType = .Words //auto-capitalize words
        }
        let cancel = UIAlertAction(title: "Cancel", style: .Default) { (let cancel) -> Void in }
        let done = UIAlertAction(title: "Add", style: .Default) { (let ok) -> Void in
            let input = alert.textFields?.first?.text?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            if (input != "") {
                var error: Bool = false
                if let qualifiers = self.actionQualifiers {
                    for variable in qualifiers { //make sure name is unique
                        if (input?.lowercaseString == variable.variableName.lowercaseString) {
                            error = true
                            break
                        }
                    }
                }
                if let parent = self.parentViewController as? SetupVariablesViewController, inputs = parent.inputVariables {
                    for variable in inputs { //make sure name is unique
                        if (input?.lowercaseString == variable.variableName.lowercaseString) {
                            error = true
                            break
                        }
                    }
                }
                if let parent = self.parentViewController as? SetupVariablesViewController, outcomes = parent.outcomeMeasures {
                    for variable in outcomes { //make sure name is unique
                        if (input?.lowercaseString == variable.variableName.lowercaseString) {
                            error = true
                            break
                        }
                    }
                }
                if !(error) { //make sure the variable is not a duplicate
                    self.variableName = input?.capitalizedString
                    self.performSegueWithIdentifier("showAttachModule", sender: nil)
                } else {
                    print("Error. Duplicate Name.")
                }
            }
        }
        alert.addAction(cancel)
        alert.addAction(done)
        presentViewController(alert, animated: true, completion: nil)
    }

    // MARK: - Navigation
    
    @IBAction func unwindToAddActionVC(sender: UIStoryboardSegue) { //unwind segue -> AddActionVC
        //Note: requires the '@IBAction' in the beginning to enable the click & drag from a button to the VC's 'Exit' button on the top-most bar.
        if let senderVC = sender.sourceViewController as? ConfigureModuleViewController {
            createdVariable = senderVC.copiedVariable //grab the COPIED var
        } else if let senderVC = sender.sourceViewController as? ConfigurationOptionsViewController {
            createdVariable = senderVC.createdVariable
        }
        if let variable = createdVariable { //add the incoming variable -> TV
            actionQualifiers!.append(variable)
            actionQualifiersTableView.reloadData()
            createdVariable = nil //reset for next run
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "showAttachModule") {
            let destination = segue.destinationViewController as! UINavigationController
            let attachModuleVC = destination.topViewController as! AttachModuleViewController
            attachModuleVC.variableName = self.variableName
            moduleBlocker.currentVarConfigType = .ActionQualifier //update blocker
            attachModuleVC.moduleBlocker = self.moduleBlocker //pass over existing varTypes
            self.didSendSegue = true //set indicator on segue -> AttachModuleVC
            
            //Create a list of existing vars w/in the selected part of the cycle (used by Module object):
            var existingVars: [ComputationFramework_ExistingVariables] = []
            if let qualifiers = actionQualifiers {
                for variable in qualifiers {
                    let structObject = ComputationFramework_ExistingVariables(variable: variable)
                    existingVars.append(structObject)
                }
            }
            attachModuleVC.existingVariables = existingVars
            attachModuleVC.segueSender = self //set indicator indicating sender VC
        }
    }

}