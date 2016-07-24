//  ProjectSummaryViewController.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/3/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Provide summary of project setup before finalizing creation, showing each item & the project's object corresponding to that item. Allow user to edit as needed.

import UIKit

class ProjectSummaryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var summaryTableView: UITableView!
    @IBOutlet weak var createButton: UIBarButtonItem!
    
    let context = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    
    var projectTitle: String? //title (obtained from ProjectVariablesVC)
    var projectQuestion: String? //question for investigation (obtained from ProjectVariablesVC)
    var projectHypothesis: String? //hypothesis for project (obtained from ProjectVariablesVC)
    var projectAction: Action? //action (obtained from ProjectVariablesVC)
    var projectEndpoint: Endpoint? //endpoint (obtained from ProjectVariablesVC)
    var projectType: ExperimentTypes? //project type (obtained from ProjectVariablesVC)
    var inputVariables = Dictionary<String, [Module]>() //obtained from ProjectVariablesVC
    var outcomeVariables: [Module]? //obtained from ProjectVariablesVC
    var ghostVariables: [String: [GhostVariable]]? //vars that feed in to computations (system-created)
    var projectToEdit: Project? //EDIT PROJECT flow - project to delete from CD store
    
    // MARK: - View Configuration
    
    override func viewDidLoad() {
        super.viewDidLoad()
        summaryTableView.dataSource = self
        summaryTableView.delegate = self
        summaryTableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "summary_cell")
        if let _ = projectToEdit { //EDIT PROJECT flow - change 'Create' btn title -> 'Update'
            createButton.title = "Update"
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Table View
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 7
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Project Title".uppercaseString
        case 1:
            return "Research Question".uppercaseString
        case 2:
            return "Project Hypothesis".uppercaseString
        case 3:
            if let _ = projectToEdit { //EDIT PROJECT flow
                return "End Date".uppercaseString
            } else { //DEFAULT flow
                return "Endpoint".uppercaseString
            }
        case 4:
            return "Input Variables".uppercaseString
        case 5:
            return "Action".uppercaseString
        case 6:
            if (projectType == .ControlComparison) {
                return "Outcome Measure(s)".uppercaseString
            }
            return "Outcome Variables".uppercaseString //default
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
            return 1
        case 4:
            if let type = projectType {
                if (type == .InputOutput) {
                    if let variables = inputVariables[BMN_InputOutput_InputVariablesKey] {
                        return variables.count
                    }
                } else if (type == .ControlComparison) { //display comparison & control group
                    return 2 //**
                }
            }
        case 5:
            return 1
        case 6:
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
        case 2:
            if let hypothesis = projectHypothesis {
                cell.textLabel?.text = hypothesis
            } else {
                cell.textLabel?.text = "N/A"
            }
        case 3: //project's endpoint
            if let endpoint = projectEndpoint {
                if let numberOfDays = endpoint.getEndpointInDays() {
                    cell.textLabel?.text = "Project ends \(numberOfDays) days from now"
                } else { //continuous project
                    cell.textLabel?.text = "Continuous project (indefinite length)"
                }
            } else if let project = projectToEdit, end = project.endDate {
                cell.textLabel?.text = DateTime(date: end).getDateString()
            } else { //continuous project
                cell.textLabel?.text = "Continuous project (indefinite length)"
            }
        case 4: //input variables
            if let type = projectType {
                if (type == .InputOutput) {
                    if let variables = inputVariables[BMN_InputOutput_InputVariablesKey] {
                        cell.textLabel?.text = variables[indexPath.row].variableName
                        cell.detailTextLabel?.text = variables[indexPath.row].moduleTitle
                    }
                } else if (type == .ControlComparison) { //display comparison & control group side by side
                    if (indexPath.row == 0) { //**
                        cell.textLabel?.text = "Control Group"
                    } else if (indexPath.row == 1) { //**
                        cell.textLabel?.text = "Comparison Group"
                    }
                }
            }
        case 5: //project action
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
        case 6: //outcome variables
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
        //Allow user to go to correct location to edit:
        switch indexPath.section { //control navigation based on the selected SECTION
        case 0:
            break
        case 1:
            break
        case 2:
            break
        case 3:
            break
        case 4:
            break
        case 5:
            break
        case 6:
            break
        default:
            print("[didSelectRow] Error - default in switch")
        }
    }
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        if (indexPath.section == 4) && (projectType == .InputOutput) { //enable deletion for project vars
            if let inputs = inputVariables[BMN_InputOutput_InputVariablesKey] {
                if (inputs.count > 1) {
                    return .Delete //DO NOT allow deletion of ALL inputs (1 must exist!)
                }
            }
        } else if (indexPath.section == 6) { //DO NOT allow deletion of ALL outcomes (1 must be present)
            if (outcomeVariables?.count > 1) {
                return .Delete
            }
        }
        return .None
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if (indexPath.section == 4) {
            if let _ = inputVariables[BMN_InputOutput_InputVariablesKey] {
                inputVariables[BMN_InputOutput_InputVariablesKey]!.removeAtIndex(indexPath.row)
            }
        } else if (indexPath.section == 6) {
            outcomeVariables?.removeAtIndex(indexPath.row)
        }
        tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
    }
    
    // MARK: - Button Actions
    
    @IBAction func createProjectButtonClick(sender: AnyObject) { //construct CoreData objects for the input & output variables, then construct the Project/Group objects & save -> persistent store
        var isEditProjectFlow: Bool = false //indicator for EDIT PROJECT flow
        var startDate: NSDate?
        var endDate: NSDate?
        if let oldProject = self.projectToEdit { //EDIT PROJECT flow - delete old project from CD
            startDate = oldProject.startDate //must NOT be nil
            endDate = oldProject.endDate //can be nil
            isEditProjectFlow = true //set indicator
            deleteManagedObject(oldProject) //remove old project
        }
        
        if let type = projectType, title = projectTitle, question = projectQuestion {
            let project: Project
            if let start = startDate { //EDIT PROJECT flow - use custom 'edit' init
                project = Project(type: type, title: title, question: question, hypothesis: projectHypothesis, startDate: start, endDate: endDate, insertIntoManagedObjectContext: context)
            } else { //normal flow
                project = Project(type: type, title: title, question: question, hypothesis: projectHypothesis, endPoint: projectEndpoint?.endpointInSeconds, insertIntoManagedObjectContext: context)
            }
            
            if (projectType == .ControlComparison) { //for CC type, create 2 groups
                if let controlInputs = inputVariables[BMN_ControlComparison_ControlKey], comparisonInputs = inputVariables[BMN_ControlComparison_ComparisonKey], outcomes = outcomeVariables, action = projectAction?.action.rawValue { //construct control & comparison groups
                    var controlBeforeActionVariables = createCoreDataDictionary(controlInputs, project: project)
                    var comparisonBeforeActionVariables = createCoreDataDictionary(comparisonInputs, project: project)
                    var afterActionVariablesDict = createCoreDataDictionary(outcomes, project: project)
                    if let ghostDict = ghostVariables {
                        for (_, ghosts) in ghostDict {
                            for ghost in ghosts {
                                if (ghost.locationInFlow == VariableLocations.BeforeAction) {
                                    if (ghost.groupType == .Control) {
                                        controlBeforeActionVariables.updateValue(ghost.settings, forKey: ghost.name)
                                    } else if (ghost.groupType == .Comparison) {
                                        comparisonBeforeActionVariables.updateValue(ghost.settings, forKey: ghost.name)
                                    }
                                } else if (ghost.locationInFlow == VariableLocations.AfterAction) {
                                    afterActionVariablesDict.updateValue(ghost.settings, forKey: ghost.name)
                                }
                            }
                        }
                    }
                    
                    let _ = Group(type: GroupTypes.Control, project: project, action: action, beforeVariables: controlBeforeActionVariables, afterVariables: afterActionVariablesDict, insertIntoManagedObjectContext: context) //control grp
                    let _ = Group(type: GroupTypes.Comparison, project: project, action: action, beforeVariables: comparisonBeforeActionVariables, afterVariables: afterActionVariablesDict, insertIntoManagedObjectContext: context) //comparison
                }
            } else if (projectType == .InputOutput) { //for IO type, there is only 1 group
                if let inputs = inputVariables[BMN_InputOutput_InputVariablesKey], outputs = outcomeVariables, action = projectAction?.action.rawValue {
                    var beforeActionVariablesDict = createCoreDataDictionary(inputs, project: project)
                    var afterActionVariablesDict = createCoreDataDictionary(outputs, project: project)
                    if let ghostDict = ghostVariables { //if ghosts exist, add them -> project
                        for (_, ghosts) in ghostDict {
                            for ghost in ghosts {
                                if (ghost.locationInFlow == VariableLocations.BeforeAction) {
                                    beforeActionVariablesDict.updateValue(ghost.settings, forKey: ghost.name)
                                } else if (ghost.locationInFlow == VariableLocations.AfterAction) {
                                    afterActionVariablesDict.updateValue(ghost.settings, forKey: ghost.name)
                                }
                            }
                        }
                    }
                    let _ = Group(type: GroupTypes.LoneGroup, project: project, action: action, beforeVariables: beforeActionVariablesDict, afterVariables: afterActionVariablesDict, insertIntoManagedObjectContext: context) //create group
                }
            }
            saveManagedObjectContext() //save new project & group(s) -> CoreData
            
            //Create cloud backup for the new project & add it to queue:
            if let dbConnection = DatabaseConnection() {
                if (isEditProjectFlow) { //EDIT PROJECT flow - update project's DB information
                    dbConnection.commitProjectEditToDatabase(project)
                } else { //DEFAULT flow - create Cloud backup
                    dbConnection.createCloudModelForProject(project) //create backup & save to CD
                }
            }
        }
        
        //Return to homescreen after operation is complete:
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateInitialViewController()!
        presentViewController(controller, animated: true, completion: nil)
    }
    
    func createCoreDataDictionary(variableArray: [Module], project: Project) -> Dictionary<String, [String: AnyObject]> { //construct master dict for CoreData given array of user-created variables
        var dictionary = Dictionary<String, [String: AnyObject]>()
        for variable in variableArray { //construct dict for each variable, KEY is variable's unique name
            if let custom = variable as? CustomModule { //check for Counter variables
                if (custom.getTypeForVariable() == CustomModuleVariableTypes.Behavior_Counter) {
                    let _ = Counter(linkedVar: custom, project: project, insertIntoManagedObjectContext: context) //create Counter obj for persistence
                }
            }
            dictionary[variable.variableName] = variable.createDictionaryForCoreDataStore()
        }
        return dictionary
    }
    
    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        //pass related data when going back to an old view to edit something?
    }

}