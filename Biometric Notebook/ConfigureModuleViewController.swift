//  ConfigureModuleViewController.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/3/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Apply settings for the selected module - every bit of code in this VC should be applicable to every variable, regardless of the type of module that was selected. All logic for layout & rendering should be set in the Module class declaration & 1 generic template for applying it should be available here!

import UIKit

class ConfigureModuleViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var addButtonTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableViewTopConstraint: NSLayoutConstraint! //distance from TV -> top layout guide
    @IBOutlet weak var configureModuleNavItem: UINavigationItem!
    @IBOutlet weak var addOptionButton: UIButton!
    @IBOutlet weak var saveButton: UIBarButtonItem! //disable until config is complete
    @IBOutlet weak var configureModuleTableView: UITableView!
    
    var createdVariable: Module? //variable w/ completed configuration
    
    //var variablePrompt: String? //prompt for CustomModule
    
    // MARK: - View Configuration
    
    override func viewWillAppear(animated: Bool) { //layout buttons & TV appropriately
        if let buttons = createdVariable?.tableViewLayoutObject["buttons"] as? [String] {
            if (buttons.contains("add")) {
                if let rowsForSection = createdVariable?.tableViewLayoutObject["rowsForSection"] {
                    if let rows = (rowsForSection["behaviors"] as? [String]) {
                        let numberOfBehaviors = rows.count
                        //Constraint distance down = height of 'Behaviors' headerView (24) + # of behaviors + 48*(height of each row) + offset:
                        addButtonTopConstraint.constant = CGFloat(24 + 48 * numberOfBehaviors) + 4
                        print("Constant: \(addButtonTopConstraint.constant)")
                        addOptionButton.hidden = false //place the add button on the 'options section' header
                    }
                }
            } else {
                addOptionButton.hidden = true
            }
            if (buttons.contains("prompt")) {
                //display the prompt button
            }
        } else {
            //hide all buttons
            addOptionButton.hidden = true
        }
        
//        if (promptButton.hidden == true) { //adjust TV position depending on promptButton!
//            tableViewTopConstraint.constant = 0
//        } else {
//            tableViewTopConstraint.constant = promptButton.frame.height
//        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureModuleTableView.dataSource = self
        configureModuleTableView.delegate = self
        configureModuleNavItem.title = "Configure \(createdVariable!.moduleTitle) Var"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Table View
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        let numberOfSections = createdVariable?.sectionsToDisplay.count
        if let count = numberOfSections {
            return count
        }
        return 0
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let sectionView = createdVariable?.tableViewLayoutObject["viewForSection"] as? Dictionary<String, CustomTableViewHeader>, sectionTitle = createdVariable?.sectionsToDisplay[section] {
            if let headerView = sectionView[sectionTitle] {
                //When the user selects a pre-built or adds an option (& it removes the 'behaviors' section from display, we need to change the header title to 'Options').
                let height = headerView.frame.height
                headerView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: height) //recreate frame w/ view's width
                headerView.setNeedsDisplay()
                return headerView
            }
        }
        return nil
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let rowsForSection = createdVariable?.tableViewLayoutObject["rowsForSection"], sectionTitle = createdVariable?.sectionsToDisplay[section] {
            if let rows = (rowsForSection[sectionTitle] as? [String]) {
                return rows.count
            }
        }
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("configure_module_cell")!
        if let rowsForSection = createdVariable?.tableViewLayoutObject["rowsForSection"], sectionTitle = createdVariable?.sectionsToDisplay[indexPath.section] {
            if let rows = (rowsForSection[sectionTitle] as? [String]) {
                cell.textLabel?.text = rows[indexPath.row]
            }
        }
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 48 //used in calculation for positioning the + button
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let rowsForSection = createdVariable?.tableViewLayoutObject["rowsForSection"], sectionTitle = createdVariable?.sectionsToDisplay[indexPath.section] {
            if let rows = rowsForSection[sectionTitle] as? [String] {
                var alert = UIAlertController()
                let cancel = UIAlertAction(title: "Cancel", style: .Default) { (let cancel) -> Void in }
                var select = UIAlertAction()
                if (sectionTitle == "behaviors") {
                    let selectedBehavior = rows[indexPath.row]
                    
                    //Get alert message:
                    if let alertMessage = createdVariable?.tableViewLayoutObject["alertMessage"] as? [String: [String: String]] {
                        if let messageForBehavior = alertMessage[sectionTitle] {
                            let message = messageForBehavior[selectedBehavior]
                            alert = UIAlertController(title: "\(selectedBehavior) Behavior", message: message, preferredStyle: .Alert)
                            select = UIAlertAction(title: "Select", style: .Default) { (let ok) -> Void in
                                self.createdVariable?.selectedBehavior = selectedBehavior
                                self.configureModuleTableView.reloadData()
                                
                                //Later on, these should be automatically set when TV reloads:
                                self.addOptionButton.hidden = true //prevent further custom additions
                                self.saveButton.enabled = true //allow user to save variable
                            }
                        }
                    }
                } else if (sectionTitle == "computations") {
                    createdVariable?.selectedComputations?.append(rows[indexPath.row])
                    configureModuleTableView.reloadData()
                }
                alert.addAction(cancel)
                alert.addAction(select)
                presentViewController(alert, animated: true, completion: nil)
            }
        }
    }

    func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if let selectable = createdVariable?.tableViewLayoutObject["selectable"], sectionTitle = createdVariable?.sectionsToDisplay[indexPath.section] {
            if let canSelect = (selectable[sectionTitle] as? Bool) {//check if section rows are selectable
                if !(canSelect) { //not selectable -> don't allow highlighting
                    return false
                }
            }
        }
        return true
    }
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle { //only allow deleting variables from TV in CustomModule options
        if let deletable = createdVariable?.tableViewLayoutObject["deletable"], sectionTitle = createdVariable?.sectionsToDisplay[indexPath.section] {
            if let canDelete = (deletable[sectionTitle] as? Bool) {//check if section rows can be deleted
                if (canDelete) { //deletable
                    return UITableViewCellEditingStyle.Delete
                }
            }
        }
        return UITableViewCellEditingStyle.None
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            (createdVariable as! CustomModule).options.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            if let variable = (createdVariable as? CustomModule) {
                if (variable.options.isEmpty) { //if there are no more options & the 'behaviors' list is being displayed, move the plus button accordingly
                    if let rowsForSection = createdVariable?.tableViewLayoutObject["rowsForSection"] {
                        if let rows = (rowsForSection["behaviors"] as? [String]) {
                            let numberOfBehaviors = rows.count
                            //Constraint distance down = height of 'Behaviors' headerView (24) + # of behaviors + 48*(height of each row) + weird offset of 4:
                            addButtonTopConstraint.constant = CGFloat(24 + 48 * numberOfBehaviors) + 4
                            addOptionButton.hidden = false
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Button Actions
    
    @IBAction func addOptionButtonClick(sender: AnyObject) { //should only be active in CustomModule (ideally it should be visible ONLY when needed, i.e. not for other modules)
        let alert = UIAlertController(title: "New Option", message: "Type the name of the option you wish to add.", preferredStyle: .Alert)
        alert.addTextFieldWithConfigurationHandler { (let field) -> Void in
            field.autocapitalizationType = .Words
        }
        let cancel = UIAlertAction(title: "Cancel", style: .Default) { (let cancel) -> Void in }
        let add = UIAlertAction(title: "Add", style: .Default) { (let ok) -> Void in
            let input = alert.textFields?.first?.text
            if (input!.containsString("[prompt]")) {
                let index = input!.startIndex.advancedBy(8)
                //self.variablePrompt = input?.substringFromIndex(index)
                self.configureModuleTableView.reloadData()
            } else { //temporary location until 'Prompt' is figured out
                if (input != "") {
                    var error: Bool = false
                    let options = (self.createdVariable as! CustomModule).options
                    for option in options { //make sure input is not a duplicate
                        if (option.lowercaseString == input?.lowercaseString) {
                            error = true
                            break
                        }
                    }
                    if !(error) {
                        (self.createdVariable as! CustomModule).options.append(input!)
                        self.configureModuleTableView.reloadData()
                        self.addButtonTopConstraint.constant = 0
                        self.saveButton.enabled = true //enable button after 1 option is selected
                    } else {
                        print("Error: input option is a duplicate!")
                    }
                }
            }
//            if (input != "") {
//                var error: Bool = false
//                for option in self.customModuleOptions { //make sure input is not a duplicate
//                    if (option.lowercaseString == input?.lowercaseString) {
//                        error = true
//                        break
//                    }
//                }
//                if !(error) {
//                    self.customModuleOptions.append(input!.capitalizedString)
//                    self.configureModuleTableView.reloadData()
//                    self.saveButton.enabled = true //enable button after 1 option is selected
//                } else {
//                    print("Error: input option is a duplicate!")
//                }
//            }
        }
        alert.addAction(cancel)
        alert.addAction(add)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    @IBAction func saveButtonClick(sender: AnyObject) {
        performSegueWithIdentifier("unwindToVariablesVC", sender: self)
    }
    
}
