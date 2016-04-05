//  ProjectSummaryViewController.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/3/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Provide summary of project setup before finalizing creation, showing each item & the project's object corresponding to that item. Allow user to edit as needed.

import UIKit

class ProjectSummaryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var summaryTableView: UITableView!
    
    let context = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    
    var projectTitle: String? //title (obtained from ProjectVariablesVC)
    var projectQuestion: String? //question for investigation (obtained from ProjectVariablesVC)
    var projectHypothesis: String? //hypothesis for project (obtained from ProjectVariablesVC)
    var projectAction: Action? //action (obtained from ProjectVariablesVC)
    var projectEndpoint: Endpoint? //endpoint (obtained from ProjectVariablesVC)
    var inputVariables: [Module]? //obtained from ProjectVariablesVC
    var outcomeVariables: [Module]? //obtained from ProjectVariablesVC
    
    // MARK: - View Configuration
    
    override func viewDidLoad() {
        super.viewDidLoad()
        summaryTableView.dataSource = self
        summaryTableView.delegate = self
        summaryTableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "summary_cell")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Table View
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 6
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Project Title".uppercaseString
        case 1:
            return "Research Question".uppercaseString
        case 2:
            return "Endpoint".uppercaseString
        case 3:
            return "Input Variables".uppercaseString
        case 4:
            return "Action".uppercaseString
        case 5:
            return "Outcome Variables".uppercaseString
        default:
            return "Error! Switch Case Default"
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return 1
        case 2:
            return 1
        case 3:
            if let variables = inputVariables {
                return variables.count
            }
        case 4:
            return 1
        case 5:
            if let variables = outcomeVariables {
                return variables.count
            }
        default:
            return 0
        }
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("summary_cell")!
        switch indexPath.section {
        case 0:
            cell.textLabel?.text = projectTitle
        case 1:
            cell.textLabel?.text = projectQuestion
        case 2: //project's endpoint
            if let endpoint = projectEndpoint {
                if let numberOfDays = endpoint.endpointInDays {
                    cell.textLabel?.text = "Project ends \(numberOfDays) days from now"
                } else { //continuous project
                    cell.textLabel?.text = "Continuous project (indefinite length)"
                }
            } else {
                print("Error - projectEndpoint is nil")
                cell.textLabel?.text = ""
            }
        case 3: //input variables
            if let variables = inputVariables {
                cell.textLabel?.text = variables[indexPath.row].variableName
                cell.detailTextLabel?.text = variables[indexPath.row].moduleTitle
            }
        case 4: //project action
            if let action = projectAction {
                if let customAction = action.customAction { //custom action
                    cell.textLabel?.text = customAction
                } else { //pre-defined action
                    cell.textLabel?.text = action.action.rawValue
                }
            } else {
                print("Error - projectAction is nil")
                cell.textLabel?.text = ""
            }
        case 5: //outcome variables, 
            if let variables = outcomeVariables {
                cell.textLabel?.text = variables[indexPath.row].variableName
                cell.detailTextLabel?.text = variables[indexPath.row].moduleTitle
            }
        default: //should NOT trigger
            print("[cellForRow] Error - default in switch.")
            cell.textLabel?.text = ""
        }
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //Allow user to go to correct location to edit.
        switch indexPath.section { //control navigation based on the selected SECTION
        case 0:
            print("")
        case 1:
            print("")
        case 2:
            print("")
        case 3:
            print("")
        case 4:
            print("")
        case 5:
            print("")
        default:
            print("[didSelectRow] Error - default in switch")
        }
    }
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        if (indexPath.section == 3) || (indexPath.section == 5) { //enable deletion for project vars
            return .Delete
        } else {
            return .None
        }
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if (indexPath.section == 3) {
            inputVariables?.removeAtIndex(indexPath.row)
        } else if (indexPath.section == 5) {
            outcomeVariables?.removeAtIndex(indexPath.row)
        }
        tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
    }
    
    // MARK: - Button Actions
    
    @IBAction func doneButtonClick(sender: AnyObject) {
        //Add before & after variable arrays to the current object & then save it -> persistent store before returning to homescreen:
        //**In the future, this project will be sent -> the web for DB configuration, cloud backup, etc.
        let beforeActionVariablesDict = self.createDictionaryForCoreData(inputVariables)
        let afterActionVariablesDict = self.createDictionaryForCoreData(outcomeVariables)
        let _ = Project(title: projectTitle!, question: projectQuestion!, endPoint: projectEndpoint?.endpointInDays, action: (projectAction?.action.rawValue)!, beforeVariables: beforeActionVariablesDict, afterVariables: afterActionVariablesDict, insertIntoManagedObjectContext: context)
        saveManagedObjectContext() //save new project -> CoreData
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateInitialViewController()!
        presentViewController(controller, animated: true, completion: nil)
    }
    
    func createDictionaryForCoreData(variableArray: [Module]?) -> Dictionary<String, [String: AnyObject]> { //construct the master dictionary for CoreData given the array of user-created variables
        var dictionary = Dictionary<String, [String: AnyObject]>()
        if let variables = variableArray {
            for variable in variables { //construct dict for each variable, KEY is variable's unique name
                dictionary[variable.variableName] = variable.createDictionaryForCoreDataStore()
            }
        }
        return dictionary
    }
    
    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        //pass related data when going back to an old view to edit something?
    }

}
