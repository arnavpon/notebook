//  AttachModuleViewController.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/3/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Attach a module to an input variable or outcome measure.

import UIKit

class AttachModuleViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var descriptionViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var descriptionViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var descriptionView: UIView!
    @IBOutlet weak var descriptionViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var descriptionViewLabel: UILabel!
    @IBOutlet weak var descriptionViewButton: UIButton!
    @IBOutlet weak var moduleTableView: UITableView!
    
    let moduleArray: [Modules] = Module.modules
    var variableName: String? //user-entered variable name
    var selectedModule: Modules? //matches TV selection -> enum containing the defined module types
    var createdVariable: Module? //attach a type to this variable & initialize it before -> ConfigureVC
    
    var segueSender: UIViewController? //indicates which VC called the segue
    var moduleBlocker: Module_DynamicConfigurationFramework? //allows dynamic config
    var existingVariables: [ComputationFramework_ExistingVariables]? //list of existing vars (for computs)
    
    // MARK: - View Configuration 
    
    override func viewWillAppear(animated: Bool) {
        setDescriptionViewVisuals() //handle rendering of descriptionView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        moduleTableView.dataSource = self
        moduleTableView.delegate = self
    }
    
    func setDescriptionViewVisuals() { //hides or reveals description card
        let userDefaults = NSUserDefaults.standardUserDefaults()
        if let _ = userDefaults.valueForKey(SHOW_ATTACH_DESCRIPTION) { //EXISTS
            moduleTableView.alpha = 1
            moduleTableView.userInteractionEnabled = true //re-enable interaction
            for subview in descriptionView.subviews { //clear tutorialView from VC
                let constraints = subview.constraints
                subview.removeConstraints(constraints)
                subview.hidden = true
                subview.removeFromSuperview()
            }
            descriptionViewTopConstraint.constant = 0
            descriptionViewBottomConstraint.constant = 0
            descriptionViewHeightConstraint.constant = 0 //hide view AFTER constraints are removed
        } else { //key does NOT exist (1st run) - show view
            createCardForView(descriptionView, color: UIColor.blackColor().CGColor, borderWidth: 3, radius: 20)
            moduleTableView.alpha = 0.3
            moduleTableView.userInteractionEnabled = false //disable interaction
            userDefaults.setBool(false, forKey: SHOW_ATTACH_DESCRIPTION) //set blocker
        }
    }

    // MARK: - Table View
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return moduleArray.count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 75
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("module_cell") as! AttachModuleTableViewCell
        let moduleTitle = "\(moduleArray[indexPath.row].rawValue) Module".uppercaseString
        cell.centeredTextLabel.text = moduleTitle
        cell.layer.borderWidth = 1.5
        cell.backgroundImageView.image = setBackgroundForCell(indexPath.row)
        return cell
    }
    
    func setBackgroundForCell(row: Int) -> UIImage { //adds background view for each row
        let image = UIImage()
        return image
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        selectedModule = moduleArray[indexPath.row] //grab the current selection
        attachSelectedModule(selectedModule!)
    }
    
    func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
        let alert: UIAlertController
        selectedModule = moduleArray[indexPath.row] //set selectedModule based on data source
        switch selectedModule! { //check which module was selected
        case .CustomModule:
            alert = UIAlertController(title: "Module Description", message: "A custom module has several unique behaviors - you can add custom options, a counter, or even a scale (e.g. from 1 - 10).", preferredStyle: .Alert)
        case .EnvironmentModule:
            alert = UIAlertController(title: "Module Description", message: "A module that allows you to capture aspects of the ambient environment, such as temperature and humidity.", preferredStyle: .Alert)
        case .ExerciseModule:
            alert = UIAlertController(title: "Module Description", message: "A module that allows you to track exercise-related statistics or create a workout schedule.", preferredStyle: .Alert)
        case .FoodIntakeModule:
            alert = UIAlertController(title: "Module Description", message: "A module that allows you to track food intake.", preferredStyle: .Alert)
        case .BiometricModule:
            alert = UIAlertController(title: "Module Description", message: "A module that allows you to track biometric data like height and weight.", preferredStyle: .Alert)
        case .CarbonEmissionsModule:
            alert = UIAlertController(title: "Module Description", message: "A module that allows you to track your carbon emissions.", preferredStyle: .Alert)
        default: //Recipe module - cannot be selected
            alert = UIAlertController()
        }
        let cancel = UIAlertAction(title: "Cancel", style: .Default) { (let cancel) -> Void in
            self.selectedModule = nil //clear selection
            tableView.cellForRowAtIndexPath(indexPath)?.highlighted = false //remove highlighting if module is not attached
            tableView.reloadData()
        }
        let attach = UIAlertAction(title: "Attach", style: .Default) { (let ok) -> Void in
            self.attachSelectedModule(self.selectedModule!)
        }
        alert.addAction(cancel)
        alert.addAction(attach)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    private func attachSelectedModule(selectedModule: Modules) {
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
        case .CarbonEmissionsModule:
            self.createdVariable = CarbonEmissionsModule(name: self.variableName!)
        default: //Recipe module - cannot be selected
            print("[attachSelectedModule] Error - default in switch.")
        }
        self.createdVariable?.configurationType = moduleBlocker?.currentVarConfigType //set type indicator
        self.performSegueWithIdentifier("showConfigureModule", sender: nil)
    }
    
    // MARK: - Button Actions
    
    @IBAction func cancelButtonClick(sender: AnyObject) { //return to sender VC
        if (self.segueSender is AddActionViewController) {
            self.performSegueWithIdentifier("unwindToAddAction", sender: nil)
        } else if (self.segueSender is AddVariablesViewController) {
            self.performSegueWithIdentifier("unwindToAddVariables", sender: nil)
        }
    }
    
    @IBAction func descriptionViewButtonClick(sender: AnyObject) { //hide description view
        setDescriptionViewVisuals()
    }
    
    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "showConfigureModule") { //pass created variable over
            let destination = segue.destinationViewController as! ConfigureModuleViewController
            createdVariable?.moduleBlocker = self.moduleBlocker //FIRST, set blocker in variable...
            createdVariable?.existingVariables = self.existingVariables //NEXT, set existing vars...
            destination.createdVariable = self.createdVariable //THEN pass var over
            destination.existingVariables = self.existingVariables
            destination.segueSender = self.segueSender
        }
    }

}