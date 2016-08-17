//  AddVariablesViewController.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 8/13/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Allows addition & configuration of input variables & outcome measures - every project must have at least 1 OM; IV are optional.

import UIKit

class AddVariablesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, SetupVariablesProtocol {
    
    @IBOutlet weak var topLabel: UILabel! //contains instructions for user
    @IBOutlet weak var addVariableButton: UIButton!
    @IBOutlet weak var variablesTableView: UITableView!
    
    var inputVariables: [Module]? = [] { //dataSource #1
        didSet {
            if let parent = parentViewController as? SetupVariablesViewController {
                parent.inputVariables = self.inputVariables
            }
        }
    }
    var outcomeMeasures: [Module]? = [] { //dataSource #2
        didSet {
            if let parent = parentViewController as? SetupVariablesViewController {
                parent.outcomeMeasures = self.outcomeMeasures
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
    var variableConfigType: ConfigurationTypes? //type (IV vs. OM) of variable created
    var createdVariable: Module? //the completed variable created by the user
    var moduleBlocker = Module_DynamicConfigurationFramework() //class that handles blocking
    
    var isCCProject: Bool = false //indicator for CC project type
    var isEditProjectFlow: Bool = false //indicator for edit project flow
    
    // MARK: - View Configuration
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        variablesTableView.delegate = self
        variablesTableView.dataSource = self
        
        if let parent = parentViewController as? SetupVariablesViewController, type = parent.projectType {
            if (type == .ControlComparison) { //project is CC
                self.isCCProject = true //set indicator
                topLabel.text = "Add at least 1 outcome measure to your project." //update lbl txt
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        self.didSendSegue = false //reset indicator (for ghost variable creation) - if VC is reappearing, segue MUST be complete
        NSNotificationCenter.defaultCenter().removeObserver(self) //clear observers FIRST
    }
    
    override func viewWillDisappear(animated: Bool) { //remove notification observers
        NSNotificationCenter.defaultCenter().removeObserver(self)
        
        //Register for ghost variable notification. De-registers when view reappears or is unloaded:
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.systemDidCreateGhostVariable(_:)), name: BMN_Notification_ComputationFramework_DidCreateGhostVariable, object: nil)
    }
    
    // MARK: - Notification Handling
    
    func systemDidCreateGhostVariable(notification: NSNotification) { //responds to Module object's request to create a ghost for a computation variable
        if (didSendSegue) { //ONLY respond to notification if this VC created the variable
            if let info = notification.userInfo, sender = info[BMN_ComputationFramework_ComputationNameKey] as? String, ghostName = info[BMN_ComputationFramework_GhostNameKey] as? String, settings = info[BMN_ComputationFramework_GhostConfigDictKey] as? [String: AnyObject] {
                if (ghostVariables == nil) { //initialize array if it doesn't yet exist
                    ghostVariables = Dictionary<String, [GhostVariable]>()
                }
                if (ghostVariables![sender] == nil) { //check if entry already exists for sender computation
                    ghostVariables![sender] = [] //initialize an array
                }
                let ghost = GhostVariable(computation: sender, name: ghostName, settings: settings)
                ghostVariables![sender]!.append(ghost)
            }
        }
    }
    
    // MARK: - Table View
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if !(isCCProject) { //IO project
            return 2 //1 section for IV, 1 for OM
        } else { //CC project
            return 1 //show only 1 section for OM
        }
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if (section == 0) && !(isCCProject) { //IO project - 1st section = IV
            return "Input Variables"
        } else {
            return "Outcome Measures"
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (section == 0) && !(isCCProject) { //IO project - 1st section = IV
            if let inputs = inputVariables {
                return inputs.count
            }
        } else {
            if let outcomes = outcomeMeasures { //all other rows are for OM cells
                return outcomes.count
            }
        }
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("variable")!
        cell.textLabel?.backgroundColor = UIColor.clearColor()
        cell.detailTextLabel?.backgroundColor = UIColor.clearColor()
        if (indexPath.section == 0) && !(isCCProject) { //IO project - 1st section = IV cells
            if let inputs = inputVariables {
                cell.backgroundColor = UIColor(red: 255/255, green: 0, blue: 0, alpha: 0.3)
                cell.textLabel?.textColor = UIColor.blackColor() //differentiate from OM
                cell.textLabel?.text = inputs[indexPath.row].variableName
                if let functionality = inputs[indexPath.row].selectedFunctionality {
                    cell.detailTextLabel?.text = functionality
                }
            }
        } else { //all other cells are OM
            if let outcomes = outcomeMeasures {
                cell.backgroundColor = UIColor(red: 0, green: 255/255, blue: 55/255, alpha: 0.3)
                cell.textLabel?.textColor = UIColor.blueColor() //differentiate from IV
                cell.textLabel?.text = outcomes[indexPath.row].variableName
                if let functionality = outcomes[indexPath.row].selectedFunctionality {
                    cell.detailTextLabel?.text = functionality
                }
            }
        }
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false //block highlighting
    }
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        if (self.isEditProjectFlow) && ((isCCProject) || (indexPath.section == 1)) {
            return .None //block deletion of OM in edit project mode
        }
        return .Delete
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if (editingStyle == .Delete) { //delete row from data source
            if (indexPath.section == 0) && !(isCCProject) { //IO project - 1st section = IV
                if let inputs = inputVariables {
                    let varToDelete = inputs[indexPath.row] //variable that is about to be deleted
                    if let functionality = varToDelete.selectedFunctionality { //update blocker/ghosts
                        if let _ = ghostVariables { //delete all ghosts associated w/ the variable
                            print("Deleting ghosts for variable: [\(varToDelete.variableName)]. Number of ghosts: \(ghostVariables![varToDelete.variableName]?.count).")
                            ghostVariables![varToDelete.variableName] = nil
                        }
                        if let alternateValueForBlocker = varToDelete.specialTypeForDynamicConfigFramework() { //use alternate value
                            moduleBlocker.variableWasDeleted(.Input, selectedFunctionality: alternateValueForBlocker)
                        } else { //NO special type - use selectedFunctionality
                            moduleBlocker.variableWasDeleted(.Input, selectedFunctionality: functionality)
                        }
                    }
                    inputVariables!.removeAtIndex(indexPath.row)
                    tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                }
            } else { //all other rows are for OM
                if let outcomes = outcomeMeasures {
                    let varToDelete = outcomes[indexPath.row] //variable that is about to be deleted
                    if let functionality = varToDelete.selectedFunctionality { //update blocker/ghosts
                        if let _ = ghostVariables { //delete all ghosts associated w/ the variable
                            print("Deleting ghosts for variable: [\(varToDelete.variableName)]. Number of ghosts: \(ghostVariables![varToDelete.variableName]?.count).")
                            ghostVariables![varToDelete.variableName] = nil
                        }
                        if let alternateValueForBlocker = varToDelete.specialTypeForDynamicConfigFramework() { //use alternate value
                            moduleBlocker.variableWasDeleted(.OutcomeMeasure, selectedFunctionality: alternateValueForBlocker)
                        } else { //NO special type - use selectedFunctionality
                            moduleBlocker.variableWasDeleted(.OutcomeMeasure, selectedFunctionality: functionality)
                        }
                    }
                    outcomeMeasures!.removeAtIndex(indexPath.row)
                    tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                }
            }
        }
    }
    
    // MARK: - Button Actions
    
    @IBAction func addVariableButtonClick(sender: AnyObject) {
        //(1) Construct variable name alert:
        let nameAlert = UIAlertController(title: "New Variable", message: "Type the unique name of the variable you wish to add.", preferredStyle: .Alert)
        nameAlert.addTextFieldWithConfigurationHandler { (let field) -> Void in
            field.autocapitalizationType = .Words //auto-capitalize words
        }
        let cancel = UIAlertAction(title: "Cancel", style: .Default) { (let cancel) -> Void in }
        let done = UIAlertAction(title: "Add", style: .Default) { (let ok) -> Void in
            let input = nameAlert.textFields?.first?.text?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            if (input != "") {
                var error: Bool = false
                if let inputs = self.inputVariables {
                    for variable in inputs { //make sure name is unique
                        if (input?.lowercaseString == variable.variableName.lowercaseString) {
                            error = true
                            break
                        }
                    }
                }
                if let outcomes = self.outcomeMeasures {
                    for variable in outcomes { //make sure name is unique
                        if (input?.lowercaseString == variable.variableName.lowercaseString) {
                            error = true
                            break
                        }
                    }
                }
                if let parent = self.parentViewController as? SetupVariablesViewController, qualifiers = parent.actionQualifiers {
                    for variable in qualifiers { //make sure name is unique
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
        nameAlert.addAction(cancel)
        nameAlert.addAction(done)
        
        //(2) Construct initial alert to select variable type (IV or OM):
        if !(isCCProject) && !(isEditProjectFlow) { //IO project - user must select IV vs. OM
            let typeSelection = UIAlertController(title: "Select Variable Type", message: "Is your variable an input or an outcome measure?", preferredStyle: .Alert)
            let input = UIAlertAction(title: "Input", style: .Default, handler: { (let ok) in
                self.variableConfigType = .Input
                self.presentViewController(nameAlert, animated: false, completion: nil)
            })
            let outcome = UIAlertAction(title: "Outcome", style: .Default, handler: { (let cancel) in
                self.variableConfigType = .OutcomeMeasure
                self.presentViewController(nameAlert, animated: false, completion: nil)
            })
            typeSelection.addAction(input)
            typeSelection.addAction(outcome)
            presentViewController(typeSelection, animated: false, completion: nil)
        } else if !(isCCProject) && (isEditProjectFlow) { //IO Project - edit project flow
            self.variableConfigType = .Input //indicate var is IV
            presentViewController(nameAlert, animated: true, completion: nil)
        } else { //CC project has only OM - present 2nd view controller immediately
            self.variableConfigType = .OutcomeMeasure //indicate var is OM
            presentViewController(nameAlert, animated: true, completion: nil)
        }
    }
    
    // MARK: - Navigation
    
    @IBAction func unwindToAddVariablesVC(sender: UIStoryboardSegue) { //unwind segue -> AddVarsVC
        if let senderVC = sender.sourceViewController as? ConfigureModuleViewController {
            createdVariable = senderVC.copiedVariable //grab the COPIED var
        } else if let senderVC = sender.sourceViewController as? ConfigurationOptionsViewController {
            createdVariable = senderVC.createdVariable
        }
        if let variable = createdVariable, typeName = variable.selectedFunctionality { //add the incoming variable -> appropriate section in TV
            if (variable.configurationType == .OutcomeMeasure) { //OM -> OM dataSource
                outcomeMeasures!.append(variable)
                if let alternateValueForBlocker = variable.specialTypeForDynamicConfigFramework() {
                    self.moduleBlocker.variableWasCreated(.OutcomeMeasure, selectedFunctionality: alternateValueForBlocker) //use alternate type for blocker if it exists
                } else { //NO special type - used selectedFunctionality
                    self.moduleBlocker.variableWasCreated(.OutcomeMeasure, selectedFunctionality: typeName)
                }
            } else if (variable.configurationType == .Input) { //IV -> IV dataSource
                inputVariables!.append(variable)
                if let alternateValueForBlocker = variable.specialTypeForDynamicConfigFramework() {
                    self.moduleBlocker.variableWasCreated(.Input, selectedFunctionality: alternateValueForBlocker) //use alternate type for blocker if it exists
                } else { //NO special type - used selectedFunctionality
                    self.moduleBlocker.variableWasCreated(.Input, selectedFunctionality: typeName)
                }
            }
            variablesTableView.reloadData()
            createdVariable = nil //reset for next run
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "showAttachModule") {
            let destination = segue.destinationViewController as! UINavigationController
            let attachModuleVC = destination.topViewController as! AttachModuleViewController
            attachModuleVC.variableName = self.variableName
            moduleBlocker.currentVarConfigType = self.variableConfigType //update blocker
            attachModuleVC.moduleBlocker = self.moduleBlocker //pass over existing varTypes
            self.didSendSegue = true //set indicator on segue -> AttachModuleVC
            
            //Create a list of existing vars w/in the selected part of the cycle (used by Module object):
            var existingVars: [ComputationFramework_ExistingVariables] = []
            if (self.variableConfigType == .Input) { //pull from IV
                if let inputs = inputVariables {
                    for variable in inputs {
                        let structObject = ComputationFramework_ExistingVariables(variable: variable)
                        existingVars.append(structObject)
                    }
                }
            } else if (self.variableConfigType == .OutcomeMeasure) { //pull from OM
                if let outcomes = outcomeMeasures {
                    for variable in outcomes {
                        let structObject = ComputationFramework_ExistingVariables(variable: variable)
                        existingVars.append(structObject)
                    }
                }
            }
            attachModuleVC.existingVariables = existingVars
            attachModuleVC.segueSender = self //set indicator indicating sender VC
        }
    }
    
}