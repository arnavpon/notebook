//  ConfigurationOptionsViewController.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 3/28/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Offers more specific configuration options after the user has selected a behavior or computation for the variable.

import UIKit

class ConfigurationOptionsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var doneButton: UIBarButtonItem! //disable until ALL options are set
    @IBOutlet weak var topBarHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var topBarInstructionLabel: UILabel!
    @IBOutlet weak var topBarAddButton: UIButton!
    @IBOutlet weak var optionsTableView: UITableView!
    
    var createdVariable: Module? //variable w/ completed configuration (sent from ConfigModuleVC)
    var numberOfSections: Int = 1
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
            print("[ConfigOptionsVC] Current # of completed cells: \(numberOfConfiguredCells). Total #: \(dataSource.count).")
            configureDoneButton()
        }
    }
    var userAddedOptions: [String] = [] { //user added options for CustomModule > Custom Options behavior
        didSet { //adjust 'doneButton' status appropriately
            configureDoneButton()
        }
    }
    
    // MARK: - View Configuration
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.cellCompletionStatusDidChange(_:)), name: "BMNCompletionIndicatorDidChange", object: nil) //add observer for Configuration Cell notification BEFORE configuring TV!
        
        optionsTableView.delegate = self
        optionsTableView.dataSource = self //set the # of prototype cells to 0 in IB!
        optionsTableView.registerClass(SimpleTextConfigurationCell.self, forCellReuseIdentifier: NSStringFromClass(SimpleTextConfigurationCell))
        optionsTableView.registerClass(SimpleNumberConfigurationCell.self, forCellReuseIdentifier: NSStringFromClass(SimpleNumberConfigurationCell))
        
        if let variable = createdVariable { //configure the topBar
            if let topBarText = variable.topBarPrompt {
                numberOfSections = 2 //add extra section for items added via topBar
                optionsTableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: NSStringFromClass(UITableViewCell))
                topBarInstructionLabel.text = topBarText
                configureVisualsForTopBar(true)
            } else {
                configureVisualsForTopBar(false)
            }
        }
    }
    
    override func viewWillDisappear(animated: Bool) { //remove observer befor exiting this VC
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func didReceiveMemoryWarning() { //save current config sate?
        super.didReceiveMemoryWarning()
    }
    
    func configureVisualsForTopBar(visible: Bool) {
        if (visible) { //display top bar (default option, no need to set constant)
            topBarAddButton.enabled = true //enable just in case
        } else { //hide top bar
            topBarHeightConstraint.constant = 0
            topBarAddButton.enabled = false //disable just in case
        }
    }
    
    func configureDoneButton() { //controls whether the 'doneButton' is enabled or not
        let total = dataSource.count
        if (numberOfConfiguredCells != total) { //some cells haven't been configured yet
            doneButton.enabled = false
        } else { //all cells have been configured
            if let variable = createdVariable as? CustomModule { //check if this is a CustomModule object
                if (variable.selectedFunctionality == CustomModuleVariableTypes.Behavior_CustomOptions.rawValue) {
                    if (userAddedOptions.isEmpty) { //no options, disable doneButton
                        self.doneButton.enabled = false
                    } else { //options have been entered, enable doneButton
                        self.doneButton.enabled = true
                    }
                } else { //NOT a CustomOptions behavior, enable button
                    doneButton.enabled = true
                }
            } else { //NOT a CustomModule object, enable button
                doneButton.enabled = true
            }
        }
    }
    
    @IBAction func cellCompletionStatusDidChange(notification: NSNotification) {
        if let info = notification.userInfo, status = info[BMN_Configuration_CompletionIndicatorStatusKey] as? Bool { //obtain current status & update the counter variable accordingly
            if (status) { //status was set -> COMPLETE (add 1 to the counter)
                self.numberOfConfiguredCells += 1
            } else { //status was set -> INCOMPLETE (subtract 1 from the counter)
                self.numberOfConfiguredCells -= 1
            }
        }
    }
    
    // MARK: - Table View 
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return numberOfSections
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if (numberOfSections > 1) { //only set titles when there are multiple sections
            if (section == 0) {
                return "Configuration"
            } else if (section == 1) {
                return "Custom Options"
            }
        }
        return nil
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (section == 1) { //user added cells
            if (userAddedOptions.count > 0) { //make sure options have been entered before enabling 'Done'
                doneButton.enabled = true
            }
            return userAddedOptions.count
        }
        return dataSource.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if (indexPath.section == 1) { //user added cells
            let cell = tableView.dequeueReusableCellWithIdentifier(NSStringFromClass(UITableViewCell))!
            cell.textLabel?.text = userAddedOptions[indexPath.row]
            return cell
        }
        let cellType = dataSource[indexPath.row].0 //get cell type from data source
        var cell = BaseConfigurationCell()
        switch cellType { //obtain cell based on type
        case .SimpleNumber:
            cell = tableView.dequeueReusableCellWithIdentifier(NSStringFromClass(SimpleNumberConfigurationCell)) as! SimpleNumberConfigurationCell
        case .SimpleText:
            cell = tableView.dequeueReusableCellWithIdentifier(NSStringFromClass(SimpleTextConfigurationCell)) as! SimpleTextConfigurationCell
        }
        cell.dataSource = dataSource[indexPath.row].1 //set cell's dataSource
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if (indexPath.section == 1) {
            return 40 //user added cells
        }
        return 70
    }
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        if (indexPath.section == 1) { //only enable deletion for section #2 (user added options)
            return UITableViewCellEditingStyle.Delete
        }
        return UITableViewCellEditingStyle.None
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete { //if deletion is allowed, remove from data source
            let row = indexPath.row
            userAddedOptions.removeAtIndex(row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
    }
    
    // MARK: - Button Actions
    
    @IBAction func addButtonClick(sender: AnyObject) { //only available for specific behaviors/comps
        //When the user adds an option, it is sent -> the variable's 'options' dictionary:
        let alert = UIAlertController(title: "Add Custom Option", message: "Enter a unique option name.", preferredStyle: UIAlertControllerStyle.Alert)
        let add = UIAlertAction(title: "Add", style: UIAlertActionStyle.Default) { (let add) in
            if let text = alert.textFields?.first?.text {
                if (text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) != "") {
                    var lowerCaseOptions: [String] = []
                    for option in self.userAddedOptions { //create array w/ lowercase options
                        lowerCaseOptions.append(option.lowercaseString)
                    }
                    if !(lowerCaseOptions.contains(text.lowercaseString)) { //make sure option is unique
                        self.userAddedOptions.append(text.capitalizedString) //add option -> data source
                        self.optionsTableView.reloadData()
                    }
                }
            }
        }
        let cancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)
        alert.addAction(cancel)
        alert.addAction(add)
        alert.addTextFieldWithConfigurationHandler { (let textField) in }
        presentViewController(alert, animated: true, completion: nil)
    }
    
    @IBAction func doneButtonClick(sender: AnyObject) { //save configuration options & return to Vars
        //Gather up the information in the configurationCells & construct a master dictionary that is reported -> the Module object (where it will be used to set Module properties).
        var reportedData: [String: AnyObject] = Dictionary<String, AnyObject>() //captured config items
        for i in 0..<dataSource.count {
            let cell = optionsTableView.cellForRowAtIndexPath(NSIndexPath(forRow: i, inSection: 0)) as! BaseConfigurationCell //get reference to each cell
            let descriptor = cell.cellDescriptor
            if let data = cell.reportData() {
                reportedData[descriptor] = data
            }
        }
        
        //If the variable is CustomModule > CustomOptions, grab the user-entered options:
        if (createdVariable?.selectedFunctionality == CustomModuleVariableTypes.Behavior_CustomOptions.rawValue) {
            reportedData[BMN_CustomModule_CustomOptions_OptionsID] = self.userAddedOptions
        }
        
        if let variable = createdVariable {
            let (success, msg, flags) = variable.matchConfigurationItemsToProperties(reportedData)
            if (success) { //operation was successful
                performSegueWithIdentifier("unwindToVariablesVC", sender: nil)
            } else { //unsuccessful operation, display alert
                let alert = UIAlertController(title: "Error!", message: msg, preferredStyle: UIAlertControllerStyle.Alert)
                let ok = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (let ok) in
                    if let flaggedCells = flags {
                        for i in 0..<self.dataSource.count {
                            let cell = self.optionsTableView.cellForRowAtIndexPath(NSIndexPath(forRow: i, inSection: 0)) as! BaseConfigurationCell //get reference to each cell
                            if (flaggedCells.contains(i)) { //if cell is flagged, set the flag variable
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