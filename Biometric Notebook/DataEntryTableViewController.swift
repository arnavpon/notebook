//  DataEntryTableViewController.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/19/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Handles input of information for a specific project

import UIKit

class DataEntryTableViewController: UITableViewController {
    
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    var selectedProject: Project?
    var currentSectionToDisplay: Bool = false //set by project overview, false = inputs, true = outputs
    var variablesArray: [Module]? //data source for sections
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Reconstruct variables & set them as TV data source:
        selectedProject!.reconstructProjectFromPersistentRepresentation() //reconstruct variables
        if (currentSectionToDisplay == false) { //construct inputVars array
            variablesArray = selectedProject!.getBeforeActionVariablesArray()
        } else { //construct outcomeMeasures array
            variablesArray = selectedProject!.getAfterActionVariablesArray()
        }
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - TV Data Source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if let variables = variablesArray {
            return variables.count
        }
        return 0
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        //Display variable name + module type
        if let variables = variablesArray {
            let variable = variables[section]
            let title = "\(variable.variableName) (\(variable.moduleTitle) Module)"
            return title
        }
        return nil
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let variables = variablesArray {
            let variable = variables[section]
            if (variable is CustomModule) { //for CustomModule, each row is an option
                let numberOfRows = (variable as! CustomModule).getOptionsForVariable().count
                return numberOfRows
            } else {
                return 1
            }
        }
        return 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("variable_cell", forIndexPath: indexPath)
        if let variables = variablesArray {
            let variable = variables[indexPath.section]
            if (variable is CustomModule) { //for CustomModule, each row is an option
                let options: [String] = (variable as! CustomModule).getOptionsForVariable()
                cell.textLabel?.text = options[indexPath.row]
            } else {
                //custom behavior for each type of module
            }
        }
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //enable 'Done' button if all variables are entered
    }
    
    override func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        //Disable 'Done' if all variables don't have entries
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */
    
    // MARK: - Button Actions
    
    @IBAction func doneButtonClick(sender: AnyObject) {
        //return to project overview or home screen?
        performSegueWithIdentifier("returnToOverview", sender: self)
    }

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        //
    }

}
