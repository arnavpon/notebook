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
    @IBOutlet weak var groupSelectionView: UIView!
    
    var selectedProject: Project?
    var variablesArray: [Module]? //TV data source
    
    // MARK: - View Configuration
    
    override func viewDidLoad() {
        super.viewDidLoad()
        doneButton.enabled = true //**should auto-enable when all completionIndicators are set
        
        dataEntryTV.dataSource = self
        dataEntryTV.delegate = self
        registerCustomTVCells() //register ALL possible custom cell types
        
        print("Selected Project: '\(selectedProject?.title)'.")
        getTableViewDataSource() //set data source for TV
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.configureDoneButton), name: BMN_Notification_CompletionIndicatorDidChange, object: nil)
    }
    
    override func didReceiveMemoryWarning() { //save current entries?
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillDisappear(animated: Bool) { //clear notification observer
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func registerCustomTVCells() { //registers all possible custom cell types
        dataEntryTV.registerClass(CustomWithOptionsCell.self, forCellReuseIdentifier: NSStringFromClass(CustomWithOptionsCell))
        dataEntryTV.registerClass(CustomWithCounterCell.self, forCellReuseIdentifier: NSStringFromClass(CustomWithCounterCell))
        dataEntryTV.registerClass(CustomWithRangeScaleCell.self, forCellReuseIdentifier: NSStringFromClass(CustomWithRangeScaleCell))
    }
    
    func getTableViewDataSource() { //picks TV dataSource array for the selectedProject
        //First, check how many groups the selectedProject contains (> 1 means user must select which one they are filling data for):
        if let project = selectedProject, groups = project.groups.allObjects as? [Group] {
            if (groups.count == 1) { //project contains only 1 group
                let group = groups.first!
                variablesArray = group.getVariablesArrayForTV() //initialize TV dataSource
                dataEntryTV.reloadData() //update UI
            } else if (groups.count == 0) { //ERROR
                print("Error! Selected project contains NO GROUPS!")
            } else { //provide interface for user to select which group to report data for
                //If the temporary object already exists, see which group inputs were reported for:
                if let temp = project.temporaryStorageObject {
                    if let groupDict = temp[BMN_CurrentlyReportingGroupKey] {
                        for (key, _) in groupDict { //Key & Value BOTH equal the groupType's rawValue
                            if let group = GroupTypes(rawValue: key) {
                                getTableViewDataSourceForGroup(group)
                                break //only needs to run 1x (only 1 key/value pair in this dict)
                            }
                        }
                    } //**both groups in CC project have EXACT SAME outputs, so it doesn't matter which group we get the variables for, both will be the same! This is redundant now, but may come in handy in the future!
                } else {
                    configureGroupSelectionView(true) //present view to allow user to choose a group
                }
            }
        }
    }
    
    func refreshMeasurementCycle() {
        //Resets project's temporary data object so that IV entry will be displayed (in case user missed the 2nd part of the entry) & dumps the associated data for the first measurement:
        //Send the user a warning that data will be deleted! Only works when we are in OM reporting mode!
        let alert = UIAlertController(title: "Warning", message: "If you choose to refresh the cycle, it will permanently delete the first half of the data collected.", preferredStyle: .Alert) //*reword
        let cancel = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        let ok = UIAlertAction(title: "I'm Sure", style: .Destructive) { (let ok) in
            if let project = self.selectedProject {
                project.temporaryStorageObject = nil //delete data in temporary storage
            }
            saveManagedObjectContext()
            self.getTableViewDataSource() //get TV's new dataSource
        }
        alert.addAction(cancel)
        alert.addAction(ok)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func configureGroupSelectionView(show: Bool) { //configures pop-up view for group selection
        groupSelectionView.hidden = !show
        dataEntryTV.hidden = show
    }
    
    func configureDoneButton(notification: NSNotification) { //handles Done button enablement
        if let info = notification.userInfo, complete = info[BMN_LEVELS_CompletionIndicatorStatusKey] as? Bool, cellCount = variablesArray?.count {
            if (complete) { //status changed -> COMPLETE
                
            } else { //status changed -> INCOMPLETE
                
            }
        }
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
    
    @IBAction func doneButtonClick(sender: AnyObject) { //construct dataObject to report -> DB
        print("doneButtonClick firing...")
        var dataObjectToDatabase = Dictionary<String, [String: AnyObject]>()
        if let variables = variablesArray { //obtain each var's data
            for variable in variables { //each Module obj reports entered data -> VC to construct dict
                dataObjectToDatabase[variable.variableName] = variable.reportDataForVariable()
            }
        }
        
        if let project = selectedProject {
            if let temp = project.temporaryStorageObject { //tempObject EXISTS (send combined data -> DB)
                for (key, value) in temp {
                    print("[doneButtonClick] DB Object BEFORE Count: \(dataObjectToDatabase.count).")
                    print("[doneButtonClick] Temp Object Count: \(temp.count).")
                    dataObjectToDatabase.updateValue(value, forKey: key)
                    print("[doneButtonClick] DB Object AFTER Count: \(dataObjectToDatabase.count).")
                    
                    //**send combined dict -> DB
                    
                    project.refreshProjectCounters() //efresh all the project's counters (if they exist)
                }
                project.temporaryStorageObject = nil //clear temp object AFTER reporting
            } else { //tempObject does NOT exist (save dict -> tempObject until outputs are reported)
                let numberOfGroups = project.groups.count
                if (numberOfGroups > 1) { //multiple groups (save a groupType in the tempObject)
                    if let group = groupType {
                        dataObjectToDatabase[BMN_CurrentlyReportingGroupKey] = [group.rawValue: group.rawValue] //store Group type in dict
                    }
                }
                project.temporaryStorageObject = dataObjectToDatabase //store obj -> temp
            }
            saveManagedObjectContext()
        }
        performSegueWithIdentifier("unwindToActiveProjects", sender: nil) //return -> home screen
    }
    
    @IBAction func controlGroupButtonClick(sender: AnyObject) { //selects 'Control' for data entry
        getTableViewDataSourceForGroup(.Control)
    }
    
    @IBAction func comparisonGroupButtonClick(sender: AnyObject) { //selects 'Comparison' for data entry
        getTableViewDataSourceForGroup(.Comparison)
    }
    
    var groupType: GroupTypes? //keeps track of currently reporting group
    
    func getTableViewDataSourceForGroup(group: GroupTypes) { //sets TV dataSource for group
        if let project = selectedProject {
            for obj in project.groups {
                if let grp = obj as? Group {
                    if (grp.groupType == group.rawValue) { //check if input type matches obj type
                        variablesArray = grp.getVariablesArrayForTV()
                        dataEntryTV.reloadData()
                        configureGroupSelectionView(false) //show TV again
                        groupType = group //set indicator
                        break
                    }
                }
            }
        }
    }

}