//  ProjectVariablesViewController.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/21/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Page to create & display input variables, project action (e.g. sleep, eat, exercise) between the IV & OM, and outcome measures.

import UIKit

class ProjectVariablesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIPickerViewDataSource, UIPickerViewDelegate {
    
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBOutlet weak var endpointPicker: UIPickerView!
    @IBOutlet weak var actionPicker: UIPickerView!
    
    var beforeActionRows: [Module] = [] //data source for rows before the 'Action'
    var afterActionRows: [Module] = [] //data source for rows after the 'Action'
    var projectTitle: String? //title (obtained from CreateProject VC)
    var projectQuestion: String? //question for investigation (obtained from CreateProject VC)
    var projectAction: Action? //action (obtained from CreateProject VC)
    var projectEndpoint: Endpoint? //endpoint (obtained from CreateProjectVC)
    var variableName: String? //the name of the variable entered by the user***
    var createdVariable: Module? //the completed variable created by the user
    
    var actionPickerRowArray: [String] = ["Eat", "Sleep", "Exercise"] //make sure these values match the 'rawValue' strings in the picker enum!
    var actionPickerSelection: String?
    var selectedAction: Action? //captures 'action' before segue
    
    // MARK: - View Configuration
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        actionPicker.dataSource = self
        actionPicker.delegate = self
        endpointPicker.dataSource = self
        endpointPicker.delegate = self
        
        //Initialize the actionPicker & endpointPicker selections w/ the first item in the array:
        actionPickerSelection = actionPickerRowArray.first
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Table View
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("")! //*
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //if user taps a cell, allow them to edit a variable's config (segue to ConfigModuleVC)
    }
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle { //user can delete variables from TV
        return UITableViewCellEditingStyle.Delete
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
    }
    
    func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        //support movement of variables between input & outcome TV:
        return false
    }
    
    func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        //
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
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) { //save current selection
        actionPickerSelection = actionPickerRowArray[row]
        print("Current Action: \(actionPickerSelection!)")
    }
    
    // MARK: - Button Actions
    
    @IBAction func addVariableButtonClick(sender: AnyObject) { //called by either TV
        let alert = UIAlertController(title: "New Variable", message: "Type the name of the variable you wish to add.", preferredStyle: .Alert)
        alert.addTextFieldWithConfigurationHandler { (let field) -> Void in
            field.autocapitalizationType = .Words //auto-capitalize words
        }
        let cancel = UIAlertAction(title: "Cancel", style: .Default) { (let cancel) -> Void in }
        let done = UIAlertAction(title: "Add", style: .Default) { (let ok) -> Void in
            let input = alert.textFields?.first?.text
            if (input != "") {
                var error: Bool = false
                for variable in self.beforeActionRows {
                    if (input?.lowercaseString == variable.variableName.lowercaseString) { //make sure name is unique
                        print("Error. Duplicate Name.")
                        error = true
                        break
                    }
                }
                for variable in self.afterActionRows {
                    if (input?.lowercaseString == variable.variableName.lowercaseString) { //make sure name is unique
                        print("Error. Duplicate Name.")
                        error = true
                        break
                    }
                }
                if !(error) { //make sure the variable is not a duplicate
                    self.variableName = input?.capitalizedString
                    self.performSegueWithIdentifier("showAttachModule", sender: nil)
                }
            }
        }
        alert.addAction(cancel)
        alert.addAction(done)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    @IBAction func doneButtonClick(sender: AnyObject) {
        //Disable this button until at least 1 beforeAction & 1 afterAction variable have been added.
        
        selectedAction = Action(action: actionPickerSelection!) //initializes the enum object w/ the string in the picker
        performSegueWithIdentifier("showSummary", sender: nil)
    }

    // MARK: - Navigation
    
    @IBAction func unwindToVariablesVC(sender: UIStoryboardSegue) { //unwind segue -> variable VC
        //Note: requires the '@IBAction' in the beginning to enable the click & drag from a button to the VC's 'Exit' button on the top-most bar.
        if let configureModuleVC = sender.sourceViewController as? ConfigureModuleViewController {
            //If sender is configureModuleVC, grab the input/outcome selection & module information:
            createdVariable = configureModuleVC.createdVariable
            if (configureModuleVC.beforeOrAfterAction == "before") {
                beforeActionRows.append(createdVariable!)
                //tableView.reloadData()
            } else if (configureModuleVC.beforeOrAfterAction == "after") {
                afterActionRows.append(createdVariable!)
                //tableView.reloadData()
            } else {
                print("Error in unwindToVariablesVC")
            }
        }
        if (beforeActionRows.count > 0) && (afterActionRows.count > 0) { //enable button when 1 of each var is added, disable if a variable is deleted or moved & there is no longer 1 of each
            doneButton.enabled = true
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "showSummary") {
            let destination = segue.destinationViewController as! ProjectSummaryViewController
            destination.projectTitle = self.projectTitle
            destination.projectQuestion = self.projectQuestion
            destination.projectEndpoint = self.projectEndpoint
            destination.projectAction = self.projectAction
            destination.beforeActionVariables = self.beforeActionRows
            destination.afterActionVariables = self.afterActionRows
        } else if (segue.identifier == "showAttachModule") { //send name of new variable
            let destination = segue.destinationViewController as! UINavigationController
            let attachModuleVC = destination.topViewController as! AttachModuleViewController
            attachModuleVC.variableName = self.variableName
        }
    }

}
