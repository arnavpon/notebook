//  ConfigureCCProjectViewController.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 8/1/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Allows the user to add control/comparison groups & an action to a CC project.

import UIKit

class ConfigureCCProjectViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var addGroupButton: UIButton!
    @IBOutlet weak var ccGroupsTableView: UITableView!
    @IBOutlet weak var addActionButton: UIButton!
    @IBOutlet weak var actionPicker: UIPickerView!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBOutlet weak var completionStatusView: UIView!
    
    var projectGroups: [(String, GroupTypes)] = [] { //(name, type) - TV dataSource
        didSet { //update completion status as needed
            self.configureDoneButton()
        }
    }
    var currentGroupType: GroupTypes? //temp storage for groupType during group creation
    var selectedAction: Action? {
        didSet {
            configureDoneButton() //adjust 'Done' btn accordingly
        }
    }
    
    var projectTitle: String? //title (obtained from CreateProjectVC)
    var projectQuestion: String? //question for investigation (obtained from CreateProjectVC)
    var projectHypothesis: String? //hypothesis for project (obtained from CreateProjectVC)
    var projectEndpoint: Endpoint? //endpoint (obtained from CreateProjectVC)
    var projectType: ExperimentTypes? //type of project (IO vs. CC)
    
    var isEditProjectFlow: Bool = false //indicator for edit project flow
    var projectToEdit: Project? //CoreData object that will be updated
    var outcomeMeasures: [Module]? //only for editProject flow
    
    private var actionPickerRowArray: [String] = ["", ActionTypes.Eat.rawValue, ActionTypes.Sleep.rawValue, ActionTypes.Exercise.rawValue, ActionTypes.Custom.rawValue]
    
    // MARK: - View Configuration

    override func viewDidLoad() {
        super.viewDidLoad()
        ccGroupsTableView.delegate = self
        ccGroupsTableView.dataSource = self
        actionPicker.delegate = self
        
        if (isEditProjectFlow) { //block editation of Action
            addActionButton.enabled = false //block selection
            doneButton.enabled = false //disable initially
            if let defaultTitle = selectedAction?.action.rawValue {
                addActionButton.setTitle(defaultTitle, forState: .Normal)
            } else if let customTitle = selectedAction?.customActionName {
                addActionButton.setTitle(customTitle, forState: .Normal)
            }
        }
    }

    private func configureDoneButton() { //enables/disables doneBtn
        var comparisonExists: Bool = false
        var controlExists: Bool = false
        for (_, type) in projectGroups {
            switch type {
            case .Control:
                controlExists = true
            case .Comparison:
                comparisonExists = true
            default:
                break
            }
        }
        dispatch_async(dispatch_get_main_queue()) { 
            if (self.selectedAction != nil) && (comparisonExists) && (controlExists) { //check if action is set & at least 1 control/comparison group was added
                self.doneButton.enabled = true
            } else { //incomplete -> DISABLE
                self.doneButton.enabled = false
            }
        }
    }
    
    // MARK: - Table View
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return projectGroups.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("group")!
        cell.textLabel?.text = projectGroups[indexPath.row].0 //group name
        switch projectGroups[indexPath.row].1 {
        case .Control:
            cell.detailTextLabel?.text = "Control"
        case .Comparison:
            cell.detailTextLabel?.text = "Comparison"
        default:
            print("[ConfigureCC - cellForRow] Error - default in switch.")
        }
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        let groupType = projectGroups[indexPath.row].1
        if (isEditProjectFlow) && (groupType == .Control) {
            return .None //cannot delete controls in edit project mode
        }
        return .Delete
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        projectGroups.removeAtIndex(indexPath.row)
        tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
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
                            self.selectedAction = Action(action: .Custom, customName: input, location: .BeforeInputs, occursInEachCycle: true, qualifiersCount: 0)
                            self.shouldShowPickerView(showPicker: false, action: self.selectedAction!)
                        } else { //incomplete entry, keep picker visible & cycle picker to start
                            self.actionPicker.selectRow(0, inComponent: 0, animated: true)
                            self.selectedAction = nil
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
                    selectedAction = Action(action: action, customName: nil, location: .BeforeInputs, occursInEachCycle: true, qualifiersCount: 0)
                    shouldShowPickerView(showPicker: false, action: selectedAction!)
                } else {
                    self.actionPicker.selectRow(0, inComponent: 0, animated: true)
                    selectedAction = nil
                }
            }
        } else { //first item in the picker (the blank) was selected
            selectedAction = nil
        }
    }
    
    private func shouldShowPickerView(showPicker show: Bool, action: Action?) { //controls picker display
        if (show) { //show picker
            actionPicker.hidden = false
            for subview in view.subviews {
                if (subview != actionPicker) { //hide non-picker views
                    subview.hidden = true
                }
            }
        } else { //hide picker & set 'actionButton' title
            if let setAction = action { //check if an action was input (else leave btn as is)
                setActionButtonTitleForAction(setAction)
            }
            actionPicker.hidden = true
            for subview in view.subviews {
                if (subview != actionPicker) { //reveal non-picker views
                    subview.hidden = false
                }
            }
        }
    }
    
    private func setActionButtonTitleForAction(action: Action) {
        addActionButton.setTitleColor(UIColor.blackColor(), forState: .Normal)
        if let name = action.customActionName { //CUSTOM action - update btn w/ name
            addActionButton.setTitle("Action = \(name)", forState: .Normal)
        } else { //DEFAULT action - update btn w/ name
            addActionButton.setTitle("Action = \(action.action.rawValue)", forState: .Normal)
        }
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) { //if user taps on view when picker is visible, dismiss picker
        if (actionPicker.hidden == false) { //only fires when pickerView is visible
            shouldShowPickerView(showPicker: false, action: nil) //dismiss picker
        }
    }

    // MARK: - Button Actions
    
    @IBAction func addGroupButtonClick(sender: AnyObject) {
        //(1) Construct textField alert:
        let nameAlert = UIAlertController(title: "Group Name", message: "Create a unique name for your group. It may help to provide distinguishing features of the group in the name.", preferredStyle: .Alert)
        let create = UIAlertAction(title: "Create Group", style: .Default, handler: { (let ok) in
            if let text = nameAlert.textFields?.first?.text, type = self.currentGroupType {
                if (text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) != "") { //make sure value is not an empty string & is unique
                    var error: Bool = false //error indicator
                    for group in self.projectGroups {
                        if (text.lowercaseString == group.0.lowercaseString) { //NOT unique
                            error = true
                            break
                        }
                    }
                    if !(error) { //NO error - add new group to array
                        self.projectGroups.append((text, type))
                        dispatch_async(dispatch_get_main_queue(), {
                            self.ccGroupsTableView.reloadData() //update UI on main thread
                        })
                    } else {
                        print("Error - duplicate group name!")
                    }
                    self.currentGroupType = nil //reset indicator for next run
                }
            }
        })
        nameAlert.addAction(create)
        nameAlert.addTextFieldWithConfigurationHandler { (let textField) in
            textField.autocapitalizationType = .Words
        }
        
        //(2) Construct typeSelection alert:
        let typeSelection = UIAlertController(title: "Select a Group Type", message: "Is this a control or a comparison group?", preferredStyle: .Alert)
        let control = UIAlertAction(title: "Control", style: .Default, handler: { (let ok) in
            self.currentGroupType = .Control
            self.presentViewController(nameAlert, animated: false, completion: nil)
        })
        let comparison = UIAlertAction(title: "Comparison", style: .Default, handler: { (let cancel) in
            self.currentGroupType = .Comparison
            self.presentViewController(nameAlert, animated: false, completion: nil)
        })
        typeSelection.addAction(control)
        typeSelection.addAction(comparison)
        if !(isEditProjectFlow) { //default mode - present typeSelection alert
            presentViewController(typeSelection, animated: false, completion: nil)
        } else { //EDIT PROJECT - only comparison groups can be added
            self.currentGroupType = .Comparison
            presentViewController(nameAlert, animated: false, completion: nil) //present nameAlert
        }
    }
    
    @IBAction func addActionButtonClick(sender: AnyObject) { //reveal actionPicker
        actionPicker.selectRow(0, inComponent: 0, animated: false) //start picker @ empty value
        shouldShowPickerView(showPicker: true, action: nil) //show picker
    }
    
    @IBAction func doneButtonClick(sender: AnyObject) {
        if !(isEditProjectFlow) { //default - nav -> SetupVarsVC
            performSegueWithIdentifier("showVariables", sender: nil)
        } else { //EDIT PROJECT flow: nav directly -> SummaryVC
            performSegueWithIdentifier("showSummary", sender: nil)
        }
    }
    
    @IBAction func backButtonClick(sender: AnyObject) {
        if !(isEditProjectFlow) { //default - return to CreateProjectVC
            performSegueWithIdentifier("unwindToCreateProject", sender: nil)
        } else { //EDIT PROJECT flow - dismiss VC & return -> ActiveProjects
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let controller = storyboard.instantiateInitialViewController()!
            presentViewController(controller, animated: true, completion: nil)
        }
    }
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "showVariables") { //pass over action & groups
            let tabBarController = segue.destinationViewController as! SetupVariablesViewController
            tabBarController.isCCProject = true //set indicator
            tabBarController.projectAction = self.selectedAction
            tabBarController.projectTitle = self.projectTitle
            tabBarController.projectQuestion = self.projectQuestion
            tabBarController.projectHypothesis = self.projectHypothesis
            tabBarController.projectEndpoint = self.projectEndpoint
            tabBarController.projectType = self.projectType
            tabBarController.projectGroups = self.projectGroups
                
            if let controllers = tabBarController.viewControllers {
                var index = 0
                for controller in controllers { //find the index # for AVVC
                    if (controller is AddVariablesViewController) {
                        break //terminate loop run
                    }
                    index += 1 //increment
                }
                tabBarController.selectedIndex = index //*present AVVC*
            }
        } else if (segue.identifier == "showSummary") { //EDIT PROJECT flow
            let destination = segue.destinationViewController as! ProjectSummaryViewController
            destination.outcomeMeasures = self.outcomeMeasures
            destination.projectAction = self.selectedAction
            destination.projectTitle = self.projectTitle
            destination.projectQuestion = self.projectQuestion
            destination.projectHypothesis = self.projectHypothesis
            destination.projectType = self.projectType
            destination.projectGroups = self.projectGroups
            destination.projectToEdit = self.projectToEdit
        }
    }

}