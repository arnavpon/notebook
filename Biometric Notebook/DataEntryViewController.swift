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
    var numberOfConfiguredCells: Int = 0 { //controls whether 'Done' btn is enabled
        didSet {
            print("[DataEntryVC] # of configured cells: \(numberOfConfiguredCells).")
            configureDoneButton()
        }
    }
    
    // MARK: - View Configuration
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(self.manualMeasurementCycleRefresh))
        dataEntryTV.dataSource = self
        dataEntryTV.delegate = self
        dataEntryTV.addGestureRecognizer(longPress) //add manual refresh gesture recognizer
        registerCustomTVCells() //register ALL possible custom cell types
        getTableViewDataSource() //set data source for TV
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.configureDoneButton), name: BMN_Notification_CompletionIndicatorDidChange, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.cellCompletionStatusDidChange(_:)), name: BMN_Notification_CompletionIndicatorDidChange, object: nil)
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
    
    func getTableViewDataSource() { //picks TV dataSource array for the selectedProject (**@ some point in future, when the interaction is more clearly defined, wrap this up in the 'Project' class)
        //First, check how many groups the selectedProject contains (> 1 => user must select which one they are filling data for):
        if let project = selectedProject, groups = project.groups.allObjects as? [Group] {
            if (groups.isEmpty) { //ERROR
                print("Error! Selected project contains NO GROUPS!")
            } else if (groups.count == 1) { //project contains only 1 group
                let group = groups.first!
                variablesArray = group.getVariablesArrayForTV() //initialize TV dataSource
                dataEntryTV.reloadData() //update UI
            } else { //provide interface for user to select which group to report data for
                //If the temporary object already exists, see which group inputs were reported for:
                if let temp = project.temporaryStorageObject {
                    if let groupDict = temp[BMN_CurrentlyReportingGroupKey] {
                        for (key, _) in groupDict { //Key & Value BOTH equal the groupType's rawValue
                            if let group = GroupTypes(rawValue: key) {
                                getTableViewDataSourceForGroup(group) //auto-set data source for group
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
    
    func manualMeasurementCycleRefresh() { //resets project's tempDataObject so IV entry will be displayed (in case user missed 2nd part of the entry) & dumps the associated data for the 1st measurement
        if let project = selectedProject, _ = project.temporaryStorageObject { //function can only fire if the user has input IV data (i.e. is in 2nd half of measurement cycle)
            let alert = UIAlertController(title: "Warning", message: "If you choose to refresh the cycle, it will permanently delete the data collected for the input variables during this cycle.", preferredStyle: .Alert) ////send the user a warning that data will be deleted!
            let cancel = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
            let ok = UIAlertAction(title: "I'm Sure", style: .Destructive) { (let ok) in
                project.refreshMeasurementCycle() //refresh
                self.getTableViewDataSource() //get TV's new dataSource
            }
            alert.addAction(cancel)
            alert.addAction(ok)
            presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    func configureGroupSelectionView(show: Bool) { //configures pop-up view for group selection
        groupSelectionView.hidden = !show
        dataEntryTV.hidden = show
    }
    
    func cellCompletionStatusDidChange(notification: NSNotification) {
        if let info = notification.userInfo, status = info[BMN_LEVELS_CompletionIndicatorStatusKey] as? Bool { //obtain current status & update the counter variable accordingly
            if (status) { //status was set -> COMPLETE (add 1 to the counter)
                self.numberOfConfiguredCells += 1
            } else { //status was set -> INCOMPLETE (subtract 1 from the counter)
                self.numberOfConfiguredCells -= 1
            }
        }
    }
    
    func configureDoneButton() { //handles 'Done' button enablement
        if let variables = variablesArray {
            let totalCells = variables.count
            if (self.numberOfConfiguredCells == totalCells) { //all cells have been reported
                doneButton.enabled = true
            } else { //some cells have not been reported
                doneButton.enabled = false
                if (numberOfConfiguredCells > totalCells) { //safety check
                    print("[configureDoneButton] ERROR - # of configured cells is > than total!")
                }
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
                if let heightInfo = module.cellHeightUserInfo { //check if there is additional height info
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
                    cell = tableView.dequeueReusableCellWithIdentifier(NSStringFromClass(CustomWithOptionsCell), forIndexPath: indexPath) as! CustomWithOptionsCell
                case .CustomWithCounter:
                    cell = tableView.dequeueReusableCellWithIdentifier(NSStringFromClass(CustomWithCounterCell), forIndexPath: indexPath) as! CustomWithCounterCell
                case .CustomWithRangeScale:
                    cell = tableView.dequeueReusableCellWithIdentifier(NSStringFromClass(CustomWithRangeScaleCell), forIndexPath: indexPath) as! CustomWithRangeScaleCell
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
        var dataObjectToDatabase = Dictionary<String, [String: AnyObject]>()
        if let variables = variablesArray, project = selectedProject { //obtain each var's data
            //(1) Obtain the data stored in the variables currently being reported:
            for variable in variables { //each Module obj reports entered data -> VC to construct dict
                dataObjectToDatabase[variable.variableName] = variable.reportDataForVariable()
            }
            for (variableName, dict) in dataObjectToDatabase { //**
                for (key, value) in dict {
                    print("DB Object: VAR = '\(variableName)'. KEY: '\(key)'. VALUE: [\(value)].")
                }
                print("\n") //*
            }
            
            //(2) If IV are being reported, store data -> tempObj, else send data -> DB:
            if let temp = project.temporaryStorageObject { //tempObject EXISTS (send combined data -> DB)
                if let timeStamps = temp[BMN_Module_MainTimeStampKey], inputsReportTime = timeStamps[BMN_Module_InputsTimeStampKey] as? NSDate { //get inputTime from dict
                    let outputsReportTime = NSDate() //get CURRENT time for outputs timeStamp
                    
                    //Check if project contains a TimeDifference variable:
                    if let tdInfo = temp[BMN_ProjectContainsTimeDifferenceKey], name =  tdInfo[BMN_CustomModule_TimeDifferenceKey] as? String { //calculate TD if it exists
                        let difference = outputsReportTime.timeIntervalSinceReferenceDate - inputsReportTime.timeIntervalSinceReferenceDate
                        project.temporaryStorageObject![BMN_ProjectContainsTimeDifferenceKey] = nil //clear indicator in tempObject
                        dataObjectToDatabase[name] = [BMN_Module_ReportedDataKey: difference] //save time difference in var's 'reportedDataKey'
                    }
                    project.temporaryStorageObject![BMN_Module_MainTimeStampKey] = nil //clear item
                    
                    //Update dataObject's input & output NSDate timeStamps w/ STRING timeStamps:
                    let outputsTimeStamp = DateTime(date: outputsReportTime).getFullTimeStamp() //string
                    dataObjectToDatabase[BMN_Module_MainTimeStampKey]?.updateValue(outputsTimeStamp, forKey: BMN_Module_OutputsTimeStampKey)
                    dataObjectToDatabase[BMN_Module_MainTimeStampKey] = [BMN_Module_OutputsTimeStampKey: outputsTimeStamp]
                    let inputsTimeStamp = DateTime(date: inputsReportTime).getFullTimeStamp() //string
                    dataObjectToDatabase[BMN_Module_MainTimeStampKey]?.updateValue(inputsTimeStamp, forKey: BMN_Module_InputsTimeStampKey)
                }
                
                //Obtain data from tempDataObject:
                if let updatedTemp = project.temporaryStorageObject { //get UPDATED temp object
                    for (key, value) in updatedTemp { //add all items in temp object -> DB data object
                        dataObjectToDatabase.updateValue(value, forKey: key)
                    }
                }
                
                //**send combined dict -> DB
                
                for (variableName, dict) in dataObjectToDatabase { //**
                    for (key, value) in dict {
                        print("DB Object: VAR = '\(variableName)'. KEY: '\(key)'. VALUE: [\(value)].")
                    }
                }
                print("\n") //**
                
                project.refreshMeasurementCycle() //set tempObj -> nil & refresh counters after reporting
            } else { //tempObject does NOT exist (save dict -> tempObject until outputs are reported)
                dataObjectToDatabase[BMN_Module_MainTimeStampKey] = [BMN_Module_InputsTimeStampKey: NSDate()] //set single time stamp for ALL of the IVs - *this timeStamp must initially be set as an NSDATE obj so that it can be used to calculate time differences*
                let numberOfGroups = project.groups.count
                if (numberOfGroups > 1) { //multiple groups (save a groupType in the tempObject)
                    if let group = groupType {
                        dataObjectToDatabase[BMN_CurrentlyReportingGroupKey] = [group.rawValue: group.rawValue] //store Group type in dict
                    }
                }
                project.temporaryStorageObject = dataObjectToDatabase //store obj -> temp
                saveManagedObjectContext()
            }
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
                        groupType = group //set groupType indicator for doneButtonClick()
                        break
                    }
                }
            }
        }
    }

}