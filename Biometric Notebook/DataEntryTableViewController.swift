//  DataEntryTableViewController.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/19/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Offers an interface within which to input information for a specific project & its variables.

import UIKit
import CoreData

class DataEntryTableViewController: UITableViewController {
    
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBOutlet weak var resetEntryModeButton: UIBarButtonItem!
    @IBOutlet weak var toolbarSpacer: UIBarButtonItem!
    
    var selectedProject: Project?
    var currentSectionToDisplay: Bool = false //set by project overview, false = inputs, true = outputs
    var variablesArray: [Module]? //data source for sections
    var arrayOfCellsForSection: [Int: NSIndexPath] = Dictionary<Int, NSIndexPath>() //dictionary containing the indexPath of the HIGHLIGHTED cell within a given section
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        toolbarSpacer.width = view.frame.width - resetEntryModeButton.width //space to R edge
        if (currentSectionToDisplay) { //OM being displayed
            resetEntryModeButton.enabled = true //enable button
        }
        
        //Reconstruct variables & set them as TV data source:
        selectedProject!.reconstructProjectFromPersistentRepresentation() //reconstruct variables
        if (currentSectionToDisplay == false) { //construct inputVars array
            variablesArray = selectedProject!.getBeforeActionVariablesArray()
        } else { //construct outcomeMeasures array
            variablesArray = selectedProject!.getAfterActionVariablesArray()
        }
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        registerCustomTVCells() //register all possible cell types
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func registerCustomTVCells() { //registers all possible custom cell types
        //        tableView.registerClass(BaseTableViewCell.self, forCellReuseIdentifier: NSStringFromClass(BaseTableViewCell))
        //        tableView.registerClass(CustomWithCounterTableViewCell.self, forCellReuseIdentifier: NSStringFromClass(CustomWithCounterTableViewCell))
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
//                let variableWithType = variable as! CustomModule
//                let numberOfRows = variableWithType.getOptionsForVariable().count
//                if (variableWithType.getPromptForVariable() != nil) { //check if user has created a prompt
//                    return (numberOfRows + 1) //add row for prompt
//                }
//                return numberOfRows
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
                let variableWithType = variable as! CustomModule
//                let options: [String] = variableWithType.getOptionsForVariable()
                if (indexPath.row == 0) { //first row
                    if (variableWithType.getPromptForVariable() != nil) { //user has created a prompt
                        //Prompt should be 1st row under Custom Variable (& non-selectable):
                        cell.textLabel?.text = variableWithType.getPromptForVariable()
                        cell.backgroundColor = UIColor.greenColor() //format cell differently
                        cell.textLabel?.textColor = UIColor.blueColor()
                    } else { //no prompt, 1st row is just a normal cell
//                        cell.textLabel?.text = options[indexPath.row]
                    }
                } else { //not first row, lay out options
                    if (variableWithType.getPromptForVariable() != nil) { //there was a prompt, shift index back by 1
//                        cell.textLabel?.text = options[indexPath.row - 1]
                    } else { //no prompt, don't change index
//                        cell.textLabel?.text = options[indexPath.row]
                    }
                }
            } else {
                //custom behavior for each type of module
            }
        }
        return cell
    }
    
    override func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        //Prevent prompt row from being selected in custom module:
        if let variables = variablesArray {
            let variableForCell = variables[indexPath.section] //get variable for selection
            if (variableForCell is CustomModule) {
                let variableWithType = variableForCell as! CustomModule
                if (variableWithType.getPromptForVariable() != nil) { //check if there is a prompt
                    if (indexPath.row == 0) {
                        return false //prevent 1st row from being selected if there is a prompt
                    }
                }
            }
        
            //Option selection/highlighting logic:
            let variable = variables[indexPath.section]
            if (variable is CustomModule) { //selection behavior for CustomModule vars
                let selectedCellSection = indexPath.section
                let selectedCellRow = indexPath.row
                if let previouslySelectedCellIndexPath = arrayOfCellsForSection[selectedCellSection] { //check if another row in the same section has been selected previously
                    if (previouslySelectedCellIndexPath.row != selectedCellRow) { //check if it is the same cell
                        print("Unhighlighted cell: Section - \(previouslySelectedCellIndexPath.section), Row - \(previouslySelectedCellIndexPath.row)")
                        tableView.cellForRowAtIndexPath(previouslySelectedCellIndexPath)?.selected = false
                    }
                }
                return true
            }
        }
        return false
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let section = indexPath.section
        if let variables = variablesArray {
            var count = 0 //for now, 'count' ONLY applies to CustomModule vars (later we want to account for all variables [to make sure something is selected for each])
            for variable in variables {
                if (variable is CustomModule) { //get # of CustomModule vars
                    count += 1
                }
            }
            //let count = variables.count //counts # of entries that SHOULD be in arrayOfCells object (normally it counts ALL variables in array, for now we will make it count ONLY the CustomModule variables
            let variable = variables[indexPath.section] //current selection
            if (variable is CustomModule) { //selection behavior for CustomModule vars
                arrayOfCellsForSection[section] = indexPath //stores currently selected cell's index
                if (arrayOfCellsForSection.count == count) { //check that # of selected items matches # of CustomModule variables for this data entry flow
                    doneButton.enabled = true
                }
            }
        }
        print("Currently selected rows: ")
        for item in arrayOfCellsForSection {
            print("Section \(item.0): Highlighted Cell @ Row - \(item.1.row)")
        }
    }
    
    override func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        let section = indexPath.section
        if let variables = variablesArray {
            let variable = variables[indexPath.section] //current selection
            if (variable is CustomModule) { //logic for CustomModule items
                arrayOfCellsForSection[section] = nil //clear array value for that section on deselection
                doneButton.enabled = false //disable 'Done' if all variables don't have entries
            }
        }
        print("Currently selected rows: ")
        for item in arrayOfCellsForSection {
            print("Section \(item.0): Highlighted Cell @ Row - \(item.1.row)")
        }
    }
    
    // MARK: - Button Actions
    
    @IBAction func doneButtonClick(sender: AnyObject) {
        //Construct data object containing values stored for the variable & send information -> the DB:
        //dataObject should contain the variable & values entered against it. First check to see that it is a CustomModule object before proceeding. Other modules have different capture behaviors.
        var dataObjectToDatabase = Dictionary<String, [String: String]>()
        let timeStamp = DateTime().getFullTimeStamp() //get current date/time as of recording
        if let variables = variablesArray {
            for (entryInArray, index) in arrayOfCellsForSection {
                let variable = variables[entryInArray]
                let selectedOption = (tableView.cellForRowAtIndexPath(index)?.textLabel?.text)!
                dataObjectToDatabase[variable.variableName] = Dictionary<String, String>()
                dataObjectToDatabase[variable.variableName]!["timeStamp"] = timeStamp
                dataObjectToDatabase[variable.variableName]!["selectedOption"] = selectedOption
                arrayOfCellsForSection[entryInArray] = nil //clear each dict item
            }
        }
        print("Data points captured: \(dataObjectToDatabase.count).") //add animation here
        for (variable, dict) in dataObjectToDatabase {
            let option = dict["selectedOption"]
            let time = dict["timeStamp"]
            print("Variable name: \(variable). Selected option: \(option!). Time: \(time!)")
        }
        
        if !(currentSectionToDisplay) { //IV data was entered, set var -> true
            selectedProject!.inputVariableDataHasBeenEntered = true
        } else { //OM data was entered, reset variable to prepare for next set of reports
            selectedProject!.inputVariableDataHasBeenEntered = false
        }
        saveManagedObjectContext()
        performSegueWithIdentifier("returnToOverview", sender: self) //return to project overview or home screen?
    }
    
    @IBAction func resetEntryModeButtonClick(sender: AnyObject) {
        //Resets project's tracker variable -> 'False' so that IV entry will be displayed (in case user missed the 2nd part of the entry). Do we need to dump the associated data for the first measurement (or still send it -> DB)?
        currentSectionToDisplay = false //reset to IV (needed for doneButtonClick)
        selectedProject!.inputVariableDataHasBeenEntered = false
        saveManagedObjectContext()
        variablesArray = selectedProject!.getBeforeActionVariablesArray() //reset TV data source
        tableView.reloadData()
        resetEntryModeButton.enabled = false
    }
    
    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        //
    }

}
