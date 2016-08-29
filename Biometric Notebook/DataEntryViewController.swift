//  DataEntryViewController.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 4/4/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Offers an interface within which to input information for a specific project & its variables.

import UIKit
import CoreData

class DataEntryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var dataEntryTV: UITableView!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint! //TV bottom -> bottom layout guide*
    @IBOutlet weak var collectionView: UICollectionView! //view for selecting from options list
    @IBOutlet weak var groupSelectionView: UIView!
    @IBOutlet weak var groupSelectionViewLabel: UILabel!
    
    @IBOutlet weak var smallAIView: UIView!
    @IBOutlet weak var smallAIViewLabel: UILabel!
    @IBOutlet weak var smallAIViewCheck: UIImageView!
    @IBOutlet weak var smallActivityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var largeAIView: UIView!
    @IBOutlet weak var largeAIViewLabel: UILabel!
    @IBOutlet weak var largeAIViewCheck: UIImageView!
    @IBOutlet weak var largeActivityIndicator: UIActivityIndicatorView!
    
//    var selectedProject: Project?
    var selectedObject: DataEntryProtocol? //selection conforms to protocol
    var variablesArray: [Module]? //TV data source containing all variables that need to report
    var numberOfConfiguredCells: Int = 0 { //controls whether 'Done' btn is enabled
        didSet {
            print("[DataEntryVC] # of configured cells: \(numberOfConfiguredCells).")
            configureDoneButton()
        }
    }
    var erroredServices = Set<ServiceTypes>() { //used for reporting service connection errors
        didSet { //when obj changes, fire alert if view is visible & alertController is NOT alrdy active
            if !(erroredServices.isEmpty) && (viewIsVisible) && !(isPresentingAlert) {
                displayAlertForServiceError() //fire alert
            }
        }
    }
    var viewIsVisible: Bool = false //indicator that VC's view is on screen (for alert presentation)
    var isPresentingAlert: Bool = false //indicator that VC is currently presenting alertController
    var customCellHeights: [Int: Int]? //KEY = cell's indexPath.row; VALUE = # of levels for cell
    
    // MARK: - View Configuration
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //(1) Register for general notifications:
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.cellCompletionStatusDidChange(_:)), name: BMN_Notification_CompletionIndicatorDidChange, object: nil) //manual var reporting
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.autoCaptureVarCompletionStatusDidChange(_:)), name: BMN_Notification_AutoCapVarCompletionStatusDidChange, object: nil) //auto cap var reporting
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.serviceDidReportError(_:)), name: BMN_Notification_DataReportingErrorProtocol_ServiceDidReportError, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.adjustCellHeightForNotification(_:)), name: BMN_Notification_AdjustHeightForConfigCell, object: nil) //allows custom height control
        
        //Keyboard notifications:
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.keyboardDidAppearWithFrame(_:)), name: UIKeyboardDidChangeFrameNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.keyboardDidHide(_:)), name: UIKeyboardDidHideNotification, object: nil)
        
        //Add gesture recognizer for tap (to dismiss open textFields):
        let gesture = UITapGestureRecognizer(target: self, action: #selector(self.tableViewWasTapped))
        dataEntryTV.addGestureRecognizer(gesture)
        
        //(2) Populate TV w/ variables:
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(self.manualMeasurementCycleRefresh))
        dataEntryTV.dataSource = self
        dataEntryTV.delegate = self
        dataEntryTV.addGestureRecognizer(longPress) //add manual refresh gesture recognizer
        self.view.addGestureRecognizer(longPress) //add gesture to main view (in case TV is hidden)
        registerCustomTVCells() //register ALL possible custom cell types
        getTableViewDataSource() //set data source for TV
        
        //(3) Configure collectionView:
        collectionView.dataSource = self
        collectionView.delegate = self
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.groupSelectionViewOptionWasSelected(_:)), name: BMN_Notification_DataEntry_GroupSelection_OptionWasSelected, object: nil)
        
//        //(3) Obtain timeStamp if it exists for userDefaults (utilized by some variables):
//        if let project = selectedProject, dict = project.temporaryStorageObject, timeEntry = dict[BMN_Module_MainTimeStampKey], inputsTimeStamp = timeEntry[BMN_Module_InputsTimeStampKey] as? NSDate { //pass to user defaults
//            print("[DEVC] Inputs Time Stamp: \(DateTime(date: inputsTimeStamp).getFullTimeStamp()).")
//            NSUserDefaults.standardUserDefaults().setObject(inputsTimeStamp, forKey: INPUTS_TIME_STAMP)
//        } else { //clear the user defaults value for the timeStamp
//            NSUserDefaults.standardUserDefaults().setObject(nil, forKey: INPUTS_TIME_STAMP)
//        }
    }
    
    func registerCustomTVCells() { //registers all possible custom cell types
        dataEntryTV.registerClass(FreeformDataEntryCell.self, forCellReuseIdentifier: NSStringFromClass(FreeformDataEntryCell))
        dataEntryTV.registerClass(DataEntryCellWithPicker.self, forCellReuseIdentifier: NSStringFromClass(DataEntryCellWithPicker))
        dataEntryTV.registerClass(CustomWithOptionsCell.self, forCellReuseIdentifier: NSStringFromClass(CustomWithOptionsCell))
        dataEntryTV.registerClass(CustomWithCounterCell.self, forCellReuseIdentifier: NSStringFromClass(CustomWithCounterCell))
        dataEntryTV.registerClass(CustomWithRangeScaleCell.self, forCellReuseIdentifier: NSStringFromClass(CustomWithRangeScaleCell))
        dataEntryTV.registerClass(ExM_WorkoutDataEntryCell.self, forCellReuseIdentifier: NSStringFromClass(ExM_WorkoutDataEntryCell))
        dataEntryTV.registerClass(FIM_FoodIntakeDataEntryCell.self, forCellReuseIdentifier: NSStringFromClass(FIM_FoodIntakeDataEntryCell))
    }
    
    override func viewDidAppear(animated: Bool) {
        viewIsVisible = true //set visibility indicator
        displayAlertForServiceError() //check for any connection errors
    }
    
    override func viewWillDisappear(animated: Bool) { //clear notification observer
        viewIsVisible = false //clear visibility indicator
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func manualMeasurementCycleRefresh() { //resets project's tempDataObject so IV entry will be displayed (in case user missed 2nd part of the entry) & dumps the associated data for the 1st measurement
        if let object = selectedObject, _ = object.temporaryStorageObject { //refresh only works if the storage object exists (NOT @ location 1 in cycle)
            let alert = UIAlertController(title: "Warning", message: "If you choose to refresh the cycle, it will permanently delete the data collected for the input variables during this cycle.", preferredStyle: .Alert) //send the user a warning that data will be deleted!
            let cancel = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
            let ok = UIAlertAction(title: "I'm Sure", style: .Destructive) { (let ok) in
                self.selectedObject!.refreshMeasurementCycle() //refresh project settings 1st
                
                //Reset doneButton, AI view cache, & visuals:
                self.cachedView = nil
                self.cachedBlocker = false
                self.autoCapVarCount = nil //clear
                self.numberOfConfiguredCells = 0 //start @ 0 again
                self.autoCapVarReportCount = 0 //start @ 0 again
                dispatch_async(dispatch_get_main_queue(), { //*update visuals on main thread*
                    self.smallAIView.hidden = true
                    self.smallActivityIndicator.stopAnimating()
                    self.largeAIView.hidden = true
                    self.largeActivityIndicator.stopAnimating()
                    self.doneButton.enabled = false
                })
                self.getTableViewDataSource() //get TV's new dataSource @ END of fx
            }
            alert.addAction(cancel)
            alert.addAction(ok)
            presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    func tableViewWasTapped() { //dismisses keyboard when TV is tapped
        self.view.endEditing(true)
    }
    
    // MARK: - Keyboard Logic
    
    var blockKeyboardDidAppear: Bool = false //blocker
    
    func keyboardDidAppearWithFrame(notification: NSNotification) {
        if !(blockKeyboardDidAppear) { //suppress if blocker is TRUE
            if let dict = notification.userInfo, keyboardFrame = dict[UIKeyboardFrameEndUserInfoKey] as? NSValue {
                let height = keyboardFrame.CGRectValue().height
                bottomConstraint.constant = height //shift up TV to allow scrolling
            }
        }
    }
    
    func keyboardWillHide(notification: NSNotification) { //reset bottom constraint
        bottomConstraint.constant = 0
        blockKeyboardDidAppear = true //block fx from firing
    }
    
    func keyboardDidHide(notification: NSNotification) { //clear blocker for next cycle
        blockKeyboardDidAppear = false //reset
    }
    
    // MARK: - Collection View
    
    var collectionViewDataSource: [String]?
    
    func getTableViewDataSource() { //obtains TV dataSource array from the selectedProject
        if let object = selectedObject { //check if Project requires that user select a Group option
            if let groups = object.getOptionsForGroupSelectionView() { //show groupSelectionView
                configureGroupSelectionView(groups)
            } else { //obtain variablesArray directly from Project class
                self.variablesArray = object.getVariablesForSelectedGroup(nil)
                dataEntryTV.hidden = false //need this in case TV was previously hidden
                dataEntryTV.reloadData() //update UI
                configureActivityIndicatorView(false) //display AI view if needed
            }
        }
    }
    
    func configureGroupSelectionView(viewInputs: (String, [String])?) { //configures pop-up view for group selection (inputs = (lblTitle, selectionOptions)); if groups = nil, hide the view & reveal TV
        if let (labelTitle, options) = viewInputs {
            groupSelectionViewLabel.text = labelTitle //set instruction label
            collectionViewDataSource = options //set collectionView dataSource
            collectionView.reloadData() //update UI
            groupSelectionView.hidden = false
            dataEntryTV.hidden = true
        } else { //no groups - hide groupSelectionView
            groupSelectionView.hidden = true
            dataEntryTV.hidden = false
        }
    }
    
    func groupSelectionViewOptionWasSelected(notification: NSNotification) {
        if let index = notification.object as? Int, object = selectedObject { //get index of selection
            variablesArray = object.getVariablesForSelectedGroup(index) //set dataSource w/ variables
            dispatch_async(dispatch_get_main_queue(), { //*update visuals on main thread*
                self.dataEntryTV.reloadData() //update TV
            })
            configureActivityIndicatorView(false) //display AI view if needed
            configureGroupSelectionView(nil) //hide selectionView
        }
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let source = collectionViewDataSource {
            return source.count
        }
        return 0 //pass # of groups to display
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("option_cell", forIndexPath: indexPath) as! GroupSelectionView_CollectionViewCell
        if let source = collectionViewDataSource {
            cell.cellIndex = indexPath.row //set indicator for cell #
            cell.optionButton.setTitle(source[indexPath.row], forState: .Normal)
        }
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSize(width: 180, height: 120) //rectangular view
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        let insetValue: CGFloat = 15 //inset the cells from the L & R edges of the container
        return UIEdgeInsets(top: 0, left: insetValue, bottom: 0, right: insetValue)
    }
    
    // MARK: - Completion Status Logic
    
    var autoCapVarCount: Int? //# of auto-cap vars in reporting group (used for AI view display)
    var autoCapVarReportCount: Int = 0 {
        didSet {
            if let count = autoCapVarCount {
                print("[AUTO-CAP] TOTAL: \(count). CURRENT COUNT: \(autoCapVarReportCount).")
                if (count == autoCapVarReportCount) { //counts match, set AI view -> COMPLETE
                    configureActivityIndicatorView(true)
                } else { //counts do NOT match, set AI view -> INCOMPLETE
                    configureActivityIndicatorView(false)
                }
            }
        }
    }
    var cachedView: UIView? //caches AI view for currently reporting project (to save computations)
    var cachedBlocker: Bool = false //for Project w/o auto-cap variables, blocks configAIView from firing
    
    func configureActivityIndicatorView(completed: Bool) {
        if !(cachedBlocker) { //only run if block is passed
//            if let AIView = cachedView { //views have been cached (2nd run onward)
//                setVisualsForAIView(AIView, completed: completed)
//            } else if let displayedVars = variablesArray, project = selectedProject, reportingGroup = project.reportingGroup {
//                let totalCount = reportingGroup.reportCount
//                let manualCount = displayedVars.count
//                self.autoCapVarCount = totalCount - manualCount //set the auto-cap var count
//                if (manualCount != 0) { //MANUAL variables exist => SMALL reporting view
//                    if (displayedVars.count != totalCount) { //NOT all vars are MANUAL (AI view is needed)
//                        cachedView = smallAIView //cache SMALL view
//                        setVisualsForAIView(smallAIView, completed: completed) //set visuals
//                    } else { //ALL vars are manual (cache the blocker)
//                        cachedBlocker = true //prevents fx from firing again (NO AI view for manual vars)
//                    }
//                } else { //NO manual vars, check if there are auto-cap vars
//                    if (totalCount > 0) { //AUTO-cap vars exist, show large AI view, hide TV
//                        cachedView = largeAIView //cache LARGE view
//                        setVisualsForAIView(largeAIView, completed: completed) //set visuals
//                    } else { //NO auto cap vars OR manual vars => 1 TD var @ location
//                        cachedView = largeAIView //cache LARGE view
//                        setVisualsForAIView(largeAIView, completed: true) //set visuals
//                        largeAIView.hidden = false //reveal AI view
//                        dataEntryTV.hidden = true //hide TV
//                        doneButton.enabled = true //manually enable doneButton
//                    }
//                }
//            }
            if let AIView = cachedView { //views have been cached (2nd run onward)
                setVisualsForAIView(AIView, completed: completed)
            } else if let displayedVars = variablesArray, object = selectedObject, totalCount = object.getReportCountForCurrentLocationInCycle() {
                let manualCount = displayedVars.count
                self.autoCapVarCount = totalCount - manualCount //set the auto-cap var count
                if (manualCount != 0) { //MANUAL variables exist => SMALL reporting view
                    if (displayedVars.count != totalCount) { //NOT all vars are MANUAL (AI view is needed)
                        cachedView = smallAIView //cache SMALL view
                        setVisualsForAIView(smallAIView, completed: completed) //set visuals
                    } else { //ALL vars are manual (cache the blocker)
                        cachedBlocker = true //prevents fx from firing again (NO AI view for manual vars)
                    }
                } else { //NO manual vars, check if there are auto-cap vars
                    if (totalCount > 0) { //AUTO-cap vars exist, show large AI view, hide TV
                        cachedView = largeAIView //cache LARGE view
                        setVisualsForAIView(largeAIView, completed: completed) //set visuals
                    } else { //NO auto cap vars OR manual vars => 1 TD var @ location
                        cachedView = largeAIView //cache LARGE view
                        setVisualsForAIView(largeAIView, completed: true) //set visuals
                        largeAIView.hidden = false //reveal AI view
                        dataEntryTV.hidden = true //hide TV
                        doneButton.enabled = true //manually enable doneButton
                    }
                }
            }
        }
    }
    
    private func setVisualsForAIView(aiView: UIView, completed: Bool) {
        let incompleteText = "Capturing Data From APIs"
        let completeText = "API Data Was Captured!"
        dispatch_async(dispatch_get_main_queue(), { //*update visuals on main thread*
            if (aiView == self.smallAIView) { //SMALL view
                if !(completed) { //incomplete mode
                    self.smallAIView.hidden = false
                    self.smallAIViewLabel.text = incompleteText
                    self.smallActivityIndicator.startAnimating() //reveal activity indicator
                    self.smallAIViewCheck.hidden = true //hide check mark
                } else { //complete mode
                    self.smallAIViewLabel.text = completeText
                    self.smallActivityIndicator.stopAnimating() //hide activity indicator
                    self.smallAIViewCheck.hidden = false //reveal check mark
                }
            } else if (aiView == self.largeAIView) { //LARGE view
                if !(completed) { //incomplete mode
                    self.dataEntryTV.hidden = true
                    self.largeAIView.hidden = false
                    self.largeAIViewLabel.text = incompleteText
                    self.largeActivityIndicator.startAnimating() //reveal activity indicator
                    self.largeAIViewCheck.hidden = true //hide check mark
                } else { //complete mode
                    self.largeAIViewLabel.text = completeText
                    self.largeActivityIndicator.stopAnimating() //hide activity indicator
                    self.largeAIViewCheck.hidden = false //reveal check mark
                }
            }
        })
    }
    
    // MARK: - Notification Handling
    
    func cellCompletionStatusDidChange(notification: NSNotification) { //MANUAL var reporting
        if let info = notification.userInfo, status = info[BMN_LEVELS_CompletionIndicatorStatusKey] as? Bool { //obtain current status & update the counter variable accordingly
            if (status) { //status was set -> COMPLETE (add 1 to the counter)
                self.numberOfConfiguredCells += 1
            } else { //status was set -> INCOMPLETE (subtract 1 from the counter)
                self.numberOfConfiguredCells -= 1
            }
        }
    }
    
    func autoCaptureVarCompletionStatusDidChange(notification: NSNotification) { //AUTO-cap reporting
        if let info = notification.userInfo, status = info[BMN_Module_AutoCapVarCompletionStatusKey] as? Bool { //obtain current status & update the counter variable accordingly
            if (status) { //status was set -> COMPLETE (add 1 to the counter)
                self.numberOfConfiguredCells += 1
                self.autoCapVarReportCount += 1 //update auto-cap report count (for AI view display)
            } else { //status was set -> INCOMPLETE (subtract 1 from the counter)
                self.numberOfConfiguredCells -= 1
                self.autoCapVarReportCount -= 1 //update auto-cap report count (for AI view display)
            }
        }
    }
    
    func configureDoneButton() { //handles 'Done' button enablement
//        if let project = selectedProject, reportingGroup = project.reportingGroup {
//            let total = reportingGroup.reportCount
//            if (self.numberOfConfiguredCells == total) { //ALL cells have been reported
//                dispatch_async(dispatch_get_main_queue(), { //*update visuals on main thread*
//                    self.doneButton.enabled = true //enable
//                })
//            } else { //some cells have NOT been reported
//                dispatch_async(dispatch_get_main_queue(), { //*update visuals on main thread*
//                    self.doneButton.enabled = false //disable
//                })
//                if (numberOfConfiguredCells > total) { //safety check
//                    print("[configureDoneButton] ERROR - # of configured cells is > than total!")
//                }
//            }
//        }
        if let object = selectedObject, total = object.getReportCountForCurrentLocationInCycle() {
            if (self.numberOfConfiguredCells == total) { //ALL cells have been reported
                dispatch_async(dispatch_get_main_queue(), { //*update visuals on main thread*
                    self.doneButton.enabled = true //enable
                })
            } else { //some cells have NOT been reported
                dispatch_async(dispatch_get_main_queue(), { //*update visuals on main thread*
                    self.doneButton.enabled = false //disable
                })
                if (numberOfConfiguredCells > total) { //safety check
                    print("[configureDoneButton] ERROR - # of configured cells is > than total!")
                }
            }
        }
    }
    
    func serviceDidReportError(notification: NSNotification) { //unable to connect -> service
        print("[serviceDidReportError] Firing...")
        if let info = notification.userInfo, service = info[BMN_DataReportingErrorProtocol_ServiceTypeKey] as? String, erroredService = ServiceTypes(rawValue: service) {
            if !(erroredServices.contains(erroredService)) { //make sure item is not already in set
                erroredServices.insert(erroredService) //add service -> set
            }
        }
    }
    
    func displayAlertForServiceError() { //only fires when view is visible!
        print("[displayAlertForServiceError()] Firing...")
        if let service = erroredServices.first, object = selectedObject {
            //(1) Construct error message:
            var message: String = "" //error msg
            switch service { //generate error message based on specified service
            case .CoreLocation:
                message = "Could not access Location Services. Please make sure Location Services is enabled and then tap 'Retry'."
            case .Internet:
                message = "Could not obtain an internet connection. Please check your internet connection and then tap 'Retry'."
            case .HealthKit:
                message = "App does not have permission to interact with HealthKit. Please grant the appropriate permissions and then tap 'Retry'."
            case .Localhost:
                message = "Localhost error - should not show here!"
            }
            
            //(2) Construct & present alertViewController:
            let alert = UIAlertController(title: "Connection Error", message: message, preferredStyle: .Alert)
            let cancel = UIAlertAction(title: "Cancel", style: .Default, handler: { (let cancel) in
                self.performSegueWithIdentifier("unwindToActiveProjects", sender: nil) //exit VC
            })
            let retry = UIAlertAction(title: "Retry", style: .Default, handler: { (let retry) in
                self.isPresentingAlert = false //clear indicator (indicating alert dismissal)
                self.erroredServices.remove(service) //remove service from error set
                object.repopulateDataObjectForSubscribedVariables(erroredService: service) //re-report data for variables subscribed to the specified service
                
                if !(self.erroredServices.isEmpty) && !(self.isPresentingAlert) { //any remaining errors?
                    self.displayAlertForServiceError() //errors exist! - fire fx again!
                }
            })
            alert.addAction(cancel)
            alert.addAction(retry)
            dispatch_async(dispatch_get_main_queue(), { //*present alert on main thread*
                self.presentViewController(alert, animated: true, completion: nil)
            })
            self.isPresentingAlert = true //set indicator (indicate alert is active)
        }
    }
    
    func adjustCellHeightForNotification(notification: NSNotification) {
        print("Received notification to adjust cell height!")
        if let info = notification.userInfo, index = info[BMN_AdjustHeightForConfigCell_UniqueIDKey] as? Int, numberOfLevels = info[BMN_AdjustHeightForConfigCell_NumberOfLevelsKey] as? Int { //get the index of the cell to change + the # of lvls
            print("New # of levels = [\(numberOfLevels)] for cell @ index = [\(index)]")
            if (self.customCellHeights == nil) { //object does NOT exist
                self.customCellHeights = [:]
            }
            self.customCellHeights!.updateValue(numberOfLevels, forKey: index) //add lvls -> obj
            self.dataEntryTV.reloadData() //update TV w/ custom heights for cells
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
        if let customHeights = self.customCellHeights, levels = customHeights[indexPath.row] { //(1) check for CUSTOM defined height
            print("TV height for cell - # of levels for cell @ index [\(indexPath.row)] = \(levels).")
            return LevelsFrameworkCell.levelHeight * CGFloat(levels) + BMN_DefaultBottomSpacer
        }
        if let variables = variablesArray { //(2) use DataEntryCellTypes to calculate height for cell
            let module = variables[indexPath.row]
            if let cellType = module.getDataEntryCellTypeForVariable() {
                var info = Dictionary<String, AnyObject>() //initialize
                if let heightInfo = module.cellHeightUserInfo { //check if there is additional height info
                    info = heightInfo //set heightInfo -> object
                }
                return cellType.getHeightForDataEntryCell(info) //calculate height
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
                case .Freeform:
                    cell = tableView.dequeueReusableCellWithIdentifier(NSStringFromClass(FreeformDataEntryCell), forIndexPath: indexPath) as! FreeformDataEntryCell
                case .Picker:
                    cell = tableView.dequeueReusableCellWithIdentifier(NSStringFromClass(DataEntryCellWithPicker), forIndexPath: indexPath) as! DataEntryCellWithPicker
                case .CustomWithOptions:
                    cell = tableView.dequeueReusableCellWithIdentifier(NSStringFromClass(CustomWithOptionsCell), forIndexPath: indexPath) as! CustomWithOptionsCell
                case .CustomWithCounter:
                    cell = tableView.dequeueReusableCellWithIdentifier(NSStringFromClass(CustomWithCounterCell), forIndexPath: indexPath) as! CustomWithCounterCell
                case .CustomWithRangeScale:
                    cell = tableView.dequeueReusableCellWithIdentifier(NSStringFromClass(CustomWithRangeScaleCell), forIndexPath: indexPath) as! CustomWithRangeScaleCell
                case .ExM_Workout:
                    cell = tableView.dequeueReusableCellWithIdentifier(NSStringFromClass(ExM_WorkoutDataEntryCell), forIndexPath: indexPath) as! ExM_WorkoutDataEntryCell
                    (cell as! ExM_WorkoutDataEntryCell).sender = self.selectedObject?.sender
                case .FIM_FoodIntake:
                    cell = tableView.dequeueReusableCellWithIdentifier(NSStringFromClass(FIM_FoodIntakeDataEntryCell), forIndexPath: indexPath) as! FIM_FoodIntakeDataEntryCell
                }
            }
            cell.cellIndex = indexPath.row //set reference to indexPath.row AFTER setting class
            if let object = self.selectedObject, temp = object.temporaryStorageObject, timeStampsArray = temp[BMN_DBO_TimeStampKey] as? [NSDate] { //check for location in tempObject
                cell.currentlyReportingLocation = timeStampsArray.count + 1 //set current location in measurement flow BEFORE assigning dataSource
            } else { //tempObject = nil (new measurement cycle)
                cell.currentlyReportingLocation = 1 //default -> 1st location in cycle
            }
            cell.module = moduleForCell //assign dataSource -> cell
        }
        return cell
    }
    
    // MARK: - Button Actions
    
    @IBAction func backButtonClick(sender: AnyObject) { //unwind -> ActiveProjectsVC
        performSegueWithIdentifier("unwindToActiveProjects", sender: nil)
    }
    
    @IBAction func doneButtonClick(sender: AnyObject) { //store reported data as appropriate
        if let object = selectedObject { //call method in protocol to aggregate data
            object.constructDataObjectForReportedData()
        }
        performSegueWithIdentifier("unwindToActiveProjects", sender: nil) //return -> home screen
    }

}