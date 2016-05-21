//  ConfigureModuleViewController.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/3/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Apply settings for the selected module - every bit of code in this VC should be applicable to every variable, regardless of the type of module that was selected. All logic for layout & rendering should be set in the Module class declaration & 1 generic template for applying it should be available here!

import UIKit

class ConfigureModuleViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableViewTopConstraint: NSLayoutConstraint! //distance from TV -> top layout guide, need this when we put in tutorial!
    @IBOutlet weak var configureModuleNavItem: UINavigationItem!
    @IBOutlet weak var configureModuleTableView: UITableView!
    
    var createdVariable: Module? //variable w/ completed configuration
    var cachedLayoutObject: Dictionary<String, AnyObject>? //caches the configModuleLayoutObj for the var
    var cachedSectionsDataSource: [String]? //caches 'sectionsToDisplay' for the var
    
    var currentVariables: [Module]? //**list of available vars (for computation config)
    
    // MARK: - View Configuration
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let variable = createdVariable {
            configureModuleNavItem.title = "\(variable.moduleTitle) Var"
            
            //Obtain layout objects from Module class:
            self.cachedLayoutObject = variable.getConfigureModuleLayoutObject()
            self.cachedSectionsDataSource = variable.sectionsToDisplay
        }
        configureModuleTableView.dataSource = self
        configureModuleTableView.delegate = self
    }

    // MARK: - Table View
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if let numberOfSections = cachedSectionsDataSource?.count {
            return numberOfSections
        }
        return 0
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let layoutObject = cachedLayoutObject, sectionView = layoutObject[BMN_ViewForSectionKey] as? Dictionary<String, CustomTableViewHeader>, sections = cachedSectionsDataSource {
            let sectionTitle = sections[section]
            if let headerView = sectionView[sectionTitle] {
                let height = headerView.frame.height
                headerView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: height) //recreate frame w/ the VC view's width
                headerView.setNeedsDisplay()
                return headerView
            }
        }
        return nil
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let layoutObject = cachedLayoutObject, rowsForSection = layoutObject[BMN_RowsForSectionKey], sectionsSource = cachedSectionsDataSource {
            let sectionTitle = sectionsSource[section]
            if let rows = (rowsForSection[sectionTitle] as? [String]) {
                return rows.count
            }
        }
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("configure_module_cell")!
        if let layoutObject = cachedLayoutObject, rowsForSection = layoutObject[BMN_RowsForSectionKey], sectionsSource = cachedSectionsDataSource {
            let sectionTitle = sectionsSource[indexPath.section]
            if let rows = (rowsForSection[sectionTitle] as? [String]) {
                cell.textLabel?.text = rows[indexPath.row]
            }
        }
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
        if let variable = createdVariable, layoutObject = cachedLayoutObject, rowsForSection = layoutObject[BMN_RowsForSectionKey], sectionsSource = cachedSectionsDataSource {
            let sectionTitle = sectionsSource[indexPath.section]
            if let rows = rowsForSection[sectionTitle] as? [String] {
                let selection = rows[indexPath.row]
                var msgTitle = ""
                if (sectionTitle == BMN_BehaviorsKey) {
                    msgTitle = "\(selection) Behavior"
                } else if (sectionTitle == BMN_ComputationsKey) {
                    msgTitle = "\(selection) Computation"
                }
                
                //Get the alert message corresponding w/ the selected row:
                if let alertDict = layoutObject[BMN_AlertMessageKey] as? [String: [String: String]], alertMsg = alertDict[sectionTitle], message = alertMsg[selection] {
                    let alert = UIAlertController(title: msgTitle, message: message, preferredStyle: .Alert)
                    let select = UIAlertAction(title: "Select", style: .Default) { (let ok) -> Void in
                        print("Selected Functionality: \(rows[indexPath.row])")
                        variable.selectedFunctionality = selection
                        if (variable.configurationOptionsLayoutObject != nil) { //-> ConfigOptionsVC if further config is needed
                            self.performSegueWithIdentifier("showConfigOptions", sender: nil)
                        } else { //otherwise, create variable & -> ProjectVariablesVC
                            self.performSegueWithIdentifier("unwindToVariablesVC", sender: nil)
                        }
                    }
                    let cancel = UIAlertAction(title: "Cancel", style: .Default) { (let cancel) -> Void in }
                    alert.addAction(cancel)
                    alert.addAction(select)
                    presentViewController(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let variable = createdVariable, layoutObject = cachedLayoutObject, sectionsSource = cachedSectionsDataSource, rowsForSection = layoutObject[BMN_RowsForSectionKey] {
            let sectionTitle = sectionsSource[indexPath.section]
            if let rows = rowsForSection[sectionTitle] as? [String] {
                print("Selected Functionality: \(rows[indexPath.row])")
                createdVariable?.selectedFunctionality = rows[indexPath.row] //save selection -> Module
                if (variable.configurationOptionsLayoutObject != nil) { //-> ConfigOptions if further config is needed
                    self.performSegueWithIdentifier("showConfigOptions", sender: nil)
                } else { //otherwise, create variable & -> ProjectVariablesVC
                    self.performSegueWithIdentifier("unwindToVariablesVC", sender: nil)
                }
            }
        }
    }

    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "showConfigOptions") { //show segue -> ConfigurationOptionsVC
            let destination = segue.destinationViewController as! ConfigurationOptionsViewController
            destination.createdVariable = self.createdVariable
            destination.currentVariables = self.currentVariables //*for computation cell
        }
    }
    
}