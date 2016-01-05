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
    
    let moduleArray: [String] = ["Custom Module", "Temperature/Humidity Module", "Weather Module", "Exercise Module", "Food Module"]
    var variableName: String? //user-entered variable name
    var selectedModule: Int? //int or enum?
    var beforeOrAfterAction: String? //determines where to put variable in flow
    
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
            selectedModule = indexPath.row //indicate selected module
            let alert: UIAlertController
            let selection: Int
            switch indexPath.row { //check which module was selected
            case 0:
                selection = 0
                alert = UIAlertController(title: "Module Description", message: "A custom module allows you to add a variable and a set of options pertaining to that variable.", preferredStyle: .Alert)
            default:
                selection = -1 
                alert = UIAlertController(title: "Error!", message: "Default in switch statement.", preferredStyle: .Alert)
            }
            let cancel = UIAlertAction(title: "Cancel", style: .Default) { (let cancel) -> Void in
                tableView.cellForRowAtIndexPath(indexPath)?.highlighted = false //remove highlighting if module is not attached
                tableView.reloadData()
            }
            let attach = UIAlertAction(title: "Attach", style: .Default) { (let ok) -> Void in
                self.selectedModule = selection
                self.performSegueWithIdentifier("showConfigureModule", sender: nil)
            }
            alert.addAction(cancel)
            alert.addAction(attach)
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
