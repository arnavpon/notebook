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
    var variablesArray: [Module]? { //TV data source
        didSet {
            configureDoneButton() //if an empty array is set as dataSource, enable 'Done' btn
            if let variables = variablesArray {
                if (variables.isEmpty) {
                    //hide TV & display a message to the user that vars have been auto-capped
                }
            }
        }
    }
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
    
    func getTableViewDataSource() { //obtains TV dataSource array from the selectedProject
        //First, check how many groups the selectedProject contains (> 1 => user must select which one they are filling data for):
        if let project = selectedProject {
            if (project.shouldDisplayGroupSelectionView()) { //show groupSelectionView
                configureGroupSelectionView(true)
            } else { //obtain variablesArray directly from Project class
                self.variablesArray = project.getVariablesForGroup(nil) //no groupType needed
                dataEntryTV.reloadData() //update UI
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
        if let project = selectedProject { //call method in project to generate & send data -> DB
            project.constructDataObjectForDatabase()
            //**when clicked, call method in Project class that handles ALL data aggregation logic appropriately & transition -> VC. Variables are all part of the project's group, so data should be stored in the Var object when set by the TV cell. Access the entered data from this var object when aggregating.
        }
        performSegueWithIdentifier("unwindToActiveProjects", sender: nil) //return -> home screen
    }
    
    @IBAction func controlGroupButtonClick(sender: AnyObject) { //selects 'Control' for data entry
        getTableViewDataSourceForGroup(.Control)
    }
    
    @IBAction func comparisonGroupButtonClick(sender: AnyObject) { //selects 'Comparison' for data entry
        getTableViewDataSourceForGroup(.Comparison)
    }
    
    func getTableViewDataSourceForGroup(group: GroupTypes) { //gets TV dataSource for selectedGroup
        if let project = selectedProject {
            variablesArray = project.getVariablesForGroup(group) //set dataSource
            dataEntryTV.reloadData() //update UI
            configureGroupSelectionView(false) //hide selectionView
        }
    }

}