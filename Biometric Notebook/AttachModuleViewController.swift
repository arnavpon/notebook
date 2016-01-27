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
    
    let moduleArray: [Modules] = Module.modules
    var variableName: String? //user-entered variable name
    var selectedModule: Modules? //matches TV selection -> enum containing the defined module types
    var createdVariable: Module? //attach a type to this variable & initialize it before -> ConfigureVC
    
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
        let moduleTitle = "\(moduleArray[indexPath.row].rawValue) Module"
        cell.textLabel?.text = moduleTitle
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //Grab the current selection:
        let alert: UIAlertController
        selectedModule = moduleArray[indexPath.row] //set selectedModule based on data source
        switch selectedModule! { //check which module was selected
        case .CustomModule:
            alert = UIAlertController(title: "Module Description", message: "A custom module allows you to add a variable and a set of options pertaining to that variable.", preferredStyle: .Alert)
        case .EnvironmentModule:
            alert = UIAlertController(title: "Module Description", message: "A module that allows you to capture aspects of the ambient environment, such as temperature and humidity.", preferredStyle: .Alert)
        case .ExerciseModule:
            alert = UIAlertController(title: "Module Description", message: "A module that allows you to track exercise-related statistics.", preferredStyle: .Alert)
        case .FoodIntakeModule:
            alert = UIAlertController(title: "Module Description", message: "A module that allows you to track food intake.", preferredStyle: .Alert)
        case .BiometricModule:
            alert = UIAlertController(title: "Module Description", message: "A module that allows you to track biometric data like height and weight.", preferredStyle: .Alert)
        }
        let cancel = UIAlertAction(title: "Cancel", style: .Default) { (let cancel) -> Void in
            self.selectedModule = nil //clear selection
            tableView.cellForRowAtIndexPath(indexPath)?.highlighted = false //remove highlighting if module is not attached
            tableView.reloadData()
        }
        let attach = UIAlertAction(title: "Attach", style: .Default) { (let ok) -> Void in
            switch self.selectedModule! { //create the variable object w/ the appropriate class
            case .CustomModule:
                self.createdVariable = CustomModule(name: self.variableName!)
            case .EnvironmentModule:
                self.createdVariable = EnvironmentModule(name: self.variableName!)
            case .FoodIntakeModule:
                self.createdVariable = FoodIntakeModule(name: self.variableName!)
            case .ExerciseModule:
                self.createdVariable = ExerciseModule(name: self.variableName!)
            case .BiometricModule:
                self.createdVariable = BiometricModule(name: self.variableName!)
            }
            self.performSegueWithIdentifier("showConfigureModule", sender: nil)
        }
        alert.addAction(cancel)
        alert.addAction(attach)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        //If you return false for this function, it does not register the user clicking the TV cell at all (nothing happens when the cell is tapped)!
        return true
    }
    
    // MARK: - Button Actions
    
    
    
    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "showConfigureModule") { //pass created variable over
            let destination = segue.destinationViewController as! ConfigureModuleViewController
            destination.createdVariable = self.createdVariable
        }
    }

}
