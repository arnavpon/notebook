//  ProjectVariablesTableViewController.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/3/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Page to display input variables, project action (e.g. sleep, eat, exercise) between the IV & OM, and outcome measures.

import UIKit

class ProjectVariablesTableViewController: UITableViewController {
    
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBOutlet weak var spacingItem: UIBarButtonItem! //used to space the 'doneButton' to far right
    
    var beforeActionRows: [Module] = [] //data source for rows before the 'Action'
    var afterActionRows: [Module] = [] //data source for rows after the 'Action'
    var projectTitle: String? //title (obtained from CreateProject VC)
    var projectQuestion: String? //question for investigation (obtained from CreateProject VC)
    var projectAction: Action? //action (obtained from CreateProject VC)
    var projectEndpoint: Endpoint? //endpoint (obtained from CreateProjectVC)
    var variableName: String? //the name of the variable entered by the user***
    var createdVariable: Module? //the completed variable created by the user
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table View

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if (section == 0) { //'before action' section
            return "Input Variables (variables that are measured before the action is performed)"
        } else if (section == 2) { //'after action' section
            return "Output Variables (variables that are measured after the action is performed)"
        } else { //intermediate section which contains the 'Action'
            return "Project Action"
        }
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if (section == 0) || (section == 2) {
            return 50
        } else { //'Action' title should be smaller
            return 24
        }
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if (section == 1) {
            let view = CustomTableViewHeader(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 24), text: "Project Action")
            return view
        } else if (section == 0) {
            let view = CustomTableViewHeader(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 48), text: "Input Variables (variables that are measured before the action is performed)")
            return view
        } else {
            let view = CustomTableViewHeader(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 48), text: "Output Variables (variables that are measured after the action is performed)")
            return view
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (section == 0) { //'before action' section
            return beforeActionRows.count
        } else if (section == 2) { //'after action' section
            return afterActionRows.count
        } else { //intermediate section which contains the 'Action'
            return 1
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("variable_cell", forIndexPath: indexPath)
        if (indexPath.section == 0) { //before Action section
            cell.textLabel?.text = beforeActionRows[indexPath.row].variableName
        } else if (indexPath.section == 2) { //after Action section
            cell.textLabel?.text = afterActionRows[indexPath.row].variableName
        } else if (indexPath.section == 1) {
            cell.backgroundColor = UIColor.blackColor()
            cell.textLabel?.textColor = UIColor.whiteColor()
            cell.textLabel?.text = projectAction!.action.rawValue
        }
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //Display screen that enables editing of attached module
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
    }

    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) { //rearranging TV, don't allow movement into 'Action' section

    }

    // MARK: - Button Actions
    
    @IBAction func addVariableButtonClick(sender: AnyObject) {
        let alert = UIAlertController(title: "New Variable", message: "Type the name of the variable you wish to add.", preferredStyle: .Alert)
        alert.addTextFieldWithConfigurationHandler { (let field) -> Void in
            //configure TF
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
                    self.variableName = input
                    self.performSegueWithIdentifier("showAttachModule", sender: nil)
                }
            }
        }
        alert.addAction(cancel)
        alert.addAction(done)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    @IBAction func doneButtonClick(sender: AnyObject) {
        //Disable this button until at least 1 beforeAction & 1 afterAction variable have been added
        performSegueWithIdentifier("showSummary", sender: nil)
    }
    
    // MARK: - Navigation
    
    @IBAction func unwindToVariablesVC(sender: UIStoryboardSegue) { //unwind segue -> variable VC
        //Note: requires the '@IBAction' in the beginning to enable the click & drag from a button to the VC's 'Exit' button on the top-most bar.
        if let configureModuleVC = sender.sourceViewController as? ConfigureModuleViewController {
            //If sender is configureModuleVC, grab the input/outcome selection & module information:
            createdVariable = configureModuleVC.createdVariable
            if let newVar = createdVariable as? CustomModule {
                print("Number of options: \(newVar.getOptionsForVariable())")
            }
            if (configureModuleVC.beforeOrAfterAction == "before") {
                beforeActionRows.append(createdVariable!)
                tableView.reloadData()
            } else if (configureModuleVC.beforeOrAfterAction == "after") {
                afterActionRows.append(createdVariable!)
                tableView.reloadData()
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
