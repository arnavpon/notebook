//  AttachModuleViewController.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/3/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Attach a module to an input variable or outcome measure.

import UIKit

class AttachModuleViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBOutlet weak var inputVariableCheckbox: CheckBox!
    @IBOutlet weak var outcomeVariableCheckbox: CheckBox!
    @IBOutlet weak var moduleTableView: UITableView!
    
    let moduleArray: [String] = ["Custom Module", "Temperature/Humidity Module", "Weather Module", "Exercise Module", "Food Intake Module"]
    var variableName: String? //user-entered variable name
    var selectedModule: Modules? //matches TV selection -> enum containing the defined module types
    var beforeOrAfterAction: String? //determines where to put variable in flow (before or after action)
    
    // MARK: - View Configuration 
    
    override func viewDidLoad() {
        super.viewDidLoad()
        moduleTableView.dataSource = self
        moduleTableView.delegate = self
        moduleTableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "module_cell")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table View
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return moduleArray.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("module_cell")!
        cell.textLabel?.text = moduleArray[indexPath.row]
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //Grab the current selection:
        if (beforeOrAfterAction != nil) { //make sure a checkbox is selected before proceeding
            let alert: UIAlertController
            var errorCheck = false //makes sure the 'default' statement was not triggered
            switch indexPath.row { //check which module was selected
            case 0: //first item in 'moduleArray'
                selectedModule = Modules.CustomModule
                alert = UIAlertController(title: "Module Description", message: "A custom module allows you to add a variable and a set of options pertaining to that variable.", preferredStyle: .Alert)
            case 1: //T&H module (2nd item in 'moduleArray')
                selectedModule = Modules.TemperatureHumidityModule
                alert = UIAlertController(title: "Module Description", message: "A module that allows you to track temperature and humidity.", preferredStyle: .Alert)
            case 2: //Weather module (3rd item in 'moduleArray')
                selectedModule = Modules.WeatherModule
                alert = UIAlertController(title: "Module Description", message: "A module that allows you to capture the current weather.", preferredStyle: .Alert)
            case 3: //Exercise module (4th item in 'moduleArray')
                selectedModule = Modules.ExerciseModule
                alert = UIAlertController(title: "Module Description", message: "A module that allows you to track exercise-related statistics.", preferredStyle: .Alert)
            case 4: //FoodIntake module (5th item in 'moduleArray')
                selectedModule = Modules.FoodIntakeModule
                alert = UIAlertController(title: "Module Description", message: "A module that allows you to track food intake.", preferredStyle: .Alert)
            default:
                errorCheck = true
                selectedModule = nil
                alert = UIAlertController(title: "Error!", message: "Default in switch statement.", preferredStyle: .Alert)
            }
            if (errorCheck == false) { //no errors
                let cancel = UIAlertAction(title: "Cancel", style: .Default) { (let cancel) -> Void in
                    self.selectedModule = nil
                    tableView.cellForRowAtIndexPath(indexPath)?.highlighted = false //remove highlighting if module is not attached
                    tableView.reloadData()
                }
                let attach = UIAlertAction(title: "Attach", style: .Default) { (let ok) -> Void in
                    //Create the variable object w/ the appropriate class:
                    self.performSegueWithIdentifier("showConfigureModule", sender: nil)
                }
                alert.addAction(cancel)
                alert.addAction(attach)
            } else { //error (default statement triggered)
                let cancel = UIAlertAction(title: "Cancel", style: .Default) { (let cancel) -> Void in
                    self.selectedModule = nil
                    tableView.cellForRowAtIndexPath(indexPath)?.highlighted = false
                    tableView.reloadData()
                }
                alert.addAction(cancel)
            }
            presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        //If you return false for this function, it does not register the user clicking the TV cell at all (nothing happens when the cell is tapped)!
        if (beforeOrAfterAction != nil) { //only highlight if a checkbox is currently selected
            return true
        } else { //don't highlight if no checkbox is selected
            let alert = UIAlertController(title: "Oops!", message: "Please click on a checkbox to indicate whether the variable is an input or outcome before trying to attach a module.", preferredStyle: .Alert)
            let ok = UIAlertAction(title: "Got It!", style: .Default) { (let ok) -> Void in }
            alert.addAction(ok)
            presentViewController(alert, animated: true, completion: nil)
            return false
        }
    }
    
    // MARK: - Button Actions
    
    @IBAction func inputVariableCheckboxClicked(sender: AnyObject) {
        if !(inputVariableCheckbox.isChecked) { //box is NOT currently checked
            beforeOrAfterAction = "before" //set value for variable
        } else { //box is currently checked & is being unchecked (so NO boxes will be selected)
            beforeOrAfterAction = nil
        }
        if (outcomeVariableCheckbox.isChecked) { //uncheck other box if checked
            outcomeVariableCheckbox.isChecked = false
        }
    }
    
    @IBAction func outcomeVariableCheckboxClicked(sender: AnyObject) {
        if !(outcomeVariableCheckbox.isChecked) { //box is NOT currently checked
            beforeOrAfterAction = "after" //set value for variable
        } else { //box is currently checked & is being unchecked (so NO boxes will be selected)
            beforeOrAfterAction = nil
        }
        if (inputVariableCheckbox.isChecked) { //uncheck other box if checked
            inputVariableCheckbox.isChecked = false
        }
    }
    
    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "showConfigureModule") { //pass selected module
            let destination = segue.destinationViewController as! ConfigureModuleViewController
            destination.variableName = self.variableName
            destination.selectedModule = self.selectedModule
            destination.beforeOrAfterAction = self.beforeOrAfterAction
        }
    }

}
