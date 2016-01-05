//  ConfigureModuleViewController.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/3/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Apply settings for the selected module.

import UIKit

class ConfigureModuleViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var titleBar: UINavigationBar!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var addOptionButton: UIBarButtonItem!
    @IBOutlet weak var configureModuleTableView: UITableView!
    
    var variableName: String?
    var selectedModule: Int?
    var beforeOrAfterAction: String?
    var availableComputationsArray: [String] = [] //computations available for given module
    var customModuleOptions: [String] = [] //data source for custom module
    
    // MARK: - View Configuration
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureModuleTableView.dataSource = self
        configureModuleTableView.delegate = self
        if (selectedModule == 0) {
            titleBar.topItem?.title = "Custom Module"
        } else {
            print("Different Module")
            titleBar.topItem?.title = "Different Module"
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table View
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if (selectedModule == 0) { //custom module
            let headerView = CustomTableViewHeader(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 24), text: "Please add options for your variable")
            return headerView
        } else { //computations
            let headerView = CustomTableViewHeader(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 48), text: "Please select the computations you wish to add to the variable")
            return headerView
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (selectedModule == 0) { //custom module
            return customModuleOptions.count
        } else { //display computations
            return availableComputationsArray.count
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("configure_module_cell")!
        if (selectedModule == 0) { //custom module
            cell.textLabel?.text = customModuleOptions[indexPath.row]
        } else { //display computations
            cell.textLabel?.text = availableComputationsArray[indexPath.row]
        }
        return cell
    }
    
    // MARK: - Button Actions
    
    @IBAction func addOptionButtonClick(sender: AnyObject) {
        let alert = UIAlertController(title: "New Option", message: "Type the name of the option you wish to add.", preferredStyle: .Alert)
        alert.addTextFieldWithConfigurationHandler { (let field) -> Void in
            //configure TF
        }
        let cancel = UIAlertAction(title: "Cancel", style: .Default) { (let cancel) -> Void in }
        let done = UIAlertAction(title: "Add", style: .Default) { (let ok) -> Void in
            let input = alert.textFields?.first?.text
            if (input != "") {
                self.customModuleOptions.append(input!)
                self.configureModuleTableView.reloadData()
            }
        }
        alert.addAction(cancel)
        alert.addAction(done)
        presentViewController(alert, animated: true, completion: nil)
    }

}
