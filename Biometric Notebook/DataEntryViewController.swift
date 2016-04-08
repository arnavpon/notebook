//  DataEntryViewController.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 4/4/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Offers an interface within which to input information for a specific project & its variables.

import UIKit
import CoreData

class DataEntryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var dataEntryTV: UITableView!
    
    var selectedProject: Project?
    var variablesArray: [Module]? //TV data source
    var currentSectionToDisplay: Bool = false //**set by project overview, false = inputs, true = outputs
    
    // MARK: - View Configuration
    
    override func viewDidLoad() {
        super.viewDidLoad()
        doneButton.enabled = false
        dataEntryTV.dataSource = self
        dataEntryTV.delegate = self
        
        //Reconstruct variables & set them as TV data source:
        print("Selected Project: '\(selectedProject?.title)'.")
        selectedProject!.reconstructProjectFromPersistentRepresentation() //reconstruct variables
        if (currentSectionToDisplay == false) { //construct inputVars array
            variablesArray = selectedProject!.getBeforeActionVariablesArray()
        } else { //construct outcomeMeasures array
            variablesArray = selectedProject!.getAfterActionVariablesArray()
        }
        
        registerCustomTVCells() //register ALL possible custom cell types
    }
    
    override func didReceiveMemoryWarning() { //save current entries?
        super.didReceiveMemoryWarning()
    }
    
    func registerCustomTVCells() { //registers all possible custom cell types
        dataEntryTV.registerClass(CustomWithOptionsCell.self, forCellReuseIdentifier: NSStringFromClass(CustomWithOptionsCell))
        dataEntryTV.registerClass(CustomWithCounterCell.self, forCellReuseIdentifier: NSStringFromClass(CustomWithCounterCell))
        dataEntryTV.registerClass(CustomWithRangeScaleCell.self, forCellReuseIdentifier: NSStringFromClass(CustomWithRangeScaleCell))
    }
    
    func refreshMeasurementCycle() {
        //Resets project's tracker variable -> 'False' so that IV entry will be displayed (in case user missed the 2nd part of the entry) & dumps the associated data for the first measurement:
        //Send the user a warning that data will be deleted! Only works when we are in OM reporting mode!
        currentSectionToDisplay = false //reset to IV (needed for doneButtonClick)
        selectedProject!.inputVariableDataHasBeenEntered = false
        saveManagedObjectContext()
        variablesArray = selectedProject!.getBeforeActionVariablesArray() //reset TV data source
        dataEntryTV.reloadData()
    }
    
    // MARK: - Table View
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let variables = variablesArray {
            return variables.count
        }
        return 0
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if let variables = variablesArray { //use DataEntryCellTypes to calculate height for cell
            let module = variables[indexPath.row]
            if let cellType = module.getDataEntryCellTypeForVariable() {
                var userInfo = Dictionary<String, AnyObject>()
                if let heightInfo = module.cellHeightUserInfo { //check if there is additional ht info
                    userInfo = heightInfo
                }
                let height = cellType.getHeightForDataEntryCell(userInfo) //calculate height
                return height
            }
        }
        return 80 + BMN_DefaultBottomSpacer //default
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = BaseDataEntryCell()
        if let variables = variablesArray {
            let moduleForCell = variables[indexPath.row] //module obj is dataSource for TV cell
            if let cellType = moduleForCell.getDataEntryCellTypeForVariable() { //get cell type
                switch cellType {
                case .CustomWithOptions:
                    cell = tableView.dequeueReusableCellWithIdentifier(NSStringFromClass(CustomWithOptionsCell)) as! CustomWithOptionsCell
                case .CustomWithCounter:
                    cell = tableView.dequeueReusableCellWithIdentifier(NSStringFromClass(CustomWithCounterCell)) as! CustomWithCounterCell
                case .CustomWithRangeScale:
                    cell = tableView.dequeueReusableCellWithIdentifier(NSStringFromClass(CustomWithRangeScaleCell)) as! CustomWithRangeScaleCell
                }
            }
            cell.module = moduleForCell //assign dataSource -> cell
        }
        return cell
    }
    
    // MARK: - Button Actions
    
    @IBAction func backButtonClick(sender: AnyObject) { //unwind -> ActiveProjectsVC
        performSegueWithIdentifier("unwindToActiveProjects", sender: nil)
    }
    
    @IBAction func doneButtonClick(sender: AnyObject) { //**
        //Construct data object containing values stored for the variable & send information -> the DB:
        //dataObject should contain the variable & values entered against it. First check to see that it is a CustomModule object before proceeding. Other modules have different capture behaviors.
        var dataObjectToDatabase = Dictionary<String, [String: String]>()
        let timeStamp = DateTime().getFullTimeStamp() //get current date/time as of recording
        var arrayOfCellsForSection: [Int: NSIndexPath] = Dictionary<Int, NSIndexPath>() //dictionary containing the indexPath of the HIGHLIGHTED cell within a given section
        if let variables = variablesArray {
            for (entryInArray, index) in arrayOfCellsForSection {
                let variable = variables[entryInArray]
                let selectedOption = (dataEntryTV.cellForRowAtIndexPath(index)?.textLabel?.text)!
                dataObjectToDatabase[variable.variableName] = Dictionary<String, String>()
                dataObjectToDatabase[variable.variableName]!["timeStamp"] = timeStamp
                dataObjectToDatabase[variable.variableName]!["selectedOption"] = selectedOption
                arrayOfCellsForSection[entryInArray] = nil //clear each dict item
            }
        }
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

}