//  ConfigureModuleViewController.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/3/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Apply settings for the selected module.

import UIKit

class ConfigureModuleViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var titleBar: UINavigationBar!
    @IBOutlet weak var saveButton: UIBarButtonItem! //disable until config is complete
    @IBOutlet weak var addOptionButton: UIBarButtonItem!
    @IBOutlet weak var configureModuleTableView: UITableView!
    
    var createdVariable: Module? //variable w/ completed configuration
    var variableName: String?
    var selectedModule: Modules?
    var beforeOrAfterAction: String?
    var availableComputationsArray: [String] = [] //computations available for given module
    var customModuleOptions: [String] = [] //data source for custom module
    var variablePrompt: String? //prompt for CustomModule
    
    // MARK: - View Configuration
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureModuleTableView.dataSource = self
        configureModuleTableView.delegate = self
        if (selectedModule == Modules.CustomModule) {
            titleBar.topItem?.title = "Custom Module"
        } else {
            titleBar.topItem?.title = "Different Module"
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table View
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if (selectedModule == Modules.CustomModule) { //custom module
            return 3 //in a custom module, the user can either enter a prompt (to replace the variable), their own options, or select an option from a pre-built list
        }
        return 1
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if (selectedModule == Modules.CustomModule) { //custom module
            let headerView: CustomTableViewHeader
            if (section == 0) { //prompt entry
                headerView = CustomTableViewHeader(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 24), text: "If you want, enter a prompt for your variable (replaces the variable name during data entry).")
            } else if (section == 1) {
                headerView = CustomTableViewHeader(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 24), text: "Please add options for your variable")
            } else { //section w/ computations
                headerView = CustomTableViewHeader(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 24), text: "Or select a pre-built configuration")
            }
            return headerView
        } else { //computations
            let headerView = CustomTableViewHeader(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 48), text: "Please select the computations you wish to add to the variable")
            return headerView
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (selectedModule == Modules.CustomModule) { //custom module
            if (section == 0) {
                return 1
            } else if (section == 1) {
                return customModuleOptions.count
            } else {
                return CustomModule.configurations.count
            }
        } else { //display computations
            return availableComputationsArray.count
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("configure_module_cell")!
        if (selectedModule == Modules.CustomModule) { //custom module
            if (indexPath.section == 0) {
                cell.textLabel?.text = variablePrompt
            } else if (indexPath.section == 1) {
                cell.textLabel?.text = customModuleOptions[indexPath.row]
            } else {
                cell.textLabel?.text = CustomModule.configurations[indexPath.row]
            }
        } else { //display computations
            cell.textLabel?.text = availableComputationsArray[indexPath.row]
        }
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if (selectedModule == Modules.CustomModule) { //custom module
            if (indexPath.section == 2) {
                if (customModuleOptions.count == 0) { //only available if options are empty!
                    let alert = UIAlertController(title: "Boolean Configuration", message: "A boolean configuration offers two options - 'Yes' and 'No'. Useful for variables with only two possibilities.", preferredStyle: .Alert)
                    let cancel = UIAlertAction(title: "Cancel", style: .Default) { (let cancel) -> Void in }
                    let select = UIAlertAction(title: "Select", style: .Default) { (let ok) -> Void in
                        self.customModuleOptions.append("Yes")
                        self.customModuleOptions.append("No")
                        self.configureModuleTableView.reloadData()
                        self.saveButton.enabled = true
                    }
                    alert.addAction(cancel)
                    alert.addAction(select)
                    presentViewController(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if (selectedModule == Modules.CustomModule) { //custom module
            if (indexPath.section == 0) || (indexPath.section == 1) {
                return false //prevent selection of the option rows & the prompt
            }
        }
        return true
    }
    
    // MARK: - Button Actions
    
    @IBAction func addOptionButtonClick(sender: AnyObject) { //should only be active in CustomModule (ideally it should be visible ONLY when needed, i.e. not for other modules)
        let alert = UIAlertController(title: "New Option", message: "Type the name of the option you wish to add.", preferredStyle: .Alert)
        alert.addTextFieldWithConfigurationHandler { (let field) -> Void in
            field.autocapitalizationType = .Words
        }
        let cancel = UIAlertAction(title: "Cancel", style: .Default) { (let cancel) -> Void in }
        let done = UIAlertAction(title: "Add", style: .Default) { (let ok) -> Void in
            let input = alert.textFields?.first?.text
            if (input!.containsString("[prompt]")) {
                let index = input!.startIndex.advancedBy(8)
                self.variablePrompt = input?.substringFromIndex(index)
                self.configureModuleTableView.reloadData()
            } else { //temporary location until 'Prompt' is figured out
                if (input != "") {
                    var error: Bool = false
                    for option in self.customModuleOptions { //make sure input is not a duplicate
                        if (option.lowercaseString == input?.lowercaseString) {
                            error = true
                            break
                        }
                    }
                    if !(error) {
                        self.customModuleOptions.append(input!.capitalizedString)
                        self.configureModuleTableView.reloadData()
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
        alert.addAction(done)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    @IBAction func saveButtonClick(sender: AnyObject) {
        switch self.selectedModule! { //check which module was attached
        case .CustomModule:
            self.createdVariable = CustomModule(name: self.variableName!, options: customModuleOptions)
            if let prompt = variablePrompt { //set the prompt -> the Custom Variable
                (createdVariable as! CustomModule).setPromptForVariable(prompt)
            }
        case .TemperatureHumidityModule:
            self.createdVariable = TemperatureHumidityModule(name: self.variableName!)
        case .WeatherModule:
            self.createdVariable = WeatherModule(name: self.variableName!)
        case .ExerciseModule:
            self.createdVariable = ExerciseModule(name: self.variableName!)
        case .FoodIntakeModule:
            self.createdVariable = FoodIntakeModule(name: self.variableName!)
        case .BiometricModule:
            self.createdVariable = BiometricModule(name: self.variableName!)
        }
        performSegueWithIdentifier("unwindToVariablesVC", sender: self)
    }
    

}
