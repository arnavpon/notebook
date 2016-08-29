//  ActiveProjectsViewController.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 4/4/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Displays a TV listing all of the active Counters (if any) & Projects (i.e. those projects for which data is still actively being reported). Allow user to navigate -> DataEntryVC or ProjectOverviewVC.

import UIKit
import CoreData

class ActiveProjectsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, LoginViewControllerDelegate {

    @IBOutlet weak var activeProjectsTableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var menuButton: UIButton!
    
    var activeCounters: [[Counter]] = [] //list of active counters (grouped according to Project) - index matches 'projects' index (i.e. index 0 = counters for Project @ index 0 of 'projects')
    var projects: [Project] = [] //list of activeProject objects (TV dataSource)
    var datastreamObjects: [Datastream]? //list of datastream objects
    var selectedObject: DataEntryProtocol? //object (Project or Datastream) to pass on segue
    var projectForOverview: Project? //Project object to pass on segue -> Project Overview VC
    
    var ip_was_set: Bool = false //**temp item
    
    // MARK: - View Configuration
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if (userDefaults.boolForKey(IS_LOGGED_IN_KEY) == true) { //check that user is logged in
            self.loggedIn = true //set indicator
        }
        
        //Register TV dataSource & delegate:
        activeProjectsTableView.dataSource = self
        activeProjectsTableView.delegate = self
        activeProjectsTableView.registerClass(CellForCounterBehavior.self, forCellReuseIdentifier: NSStringFromClass(CellForCounterBehavior)) //Counter cell type
        activeProjectsTableView.registerClass(CellWithGradientFill.self, forCellReuseIdentifier: NSStringFromClass(CellWithGradientFill)) //Project cell type
        activeProjectsTableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "datastream_cell") //Datastream cell type (== default UITableViewCell)
        activityIndicator.hidesWhenStopped = true
    }
    
    override func viewWillAppear(animated: Bool) { //update TV UI whenever view appears - the current user's projects are stored in CoreData & fetched when view appears
        if (loggedIn) { //only fire if user is loggedIn
            //(1) Obtain active projects:
            self.projects = getActiveProjects()
            if (self.projects.isEmpty) { //empty state
                configureActivityIndicator(true) //start spinning to indicate transition
                activeProjectsTableView.hidden = true //hide TV until a project is present
            } else { //default
                activeProjectsTableView.hidden = false
                
                //(2) Obtain active counters & assign them to their respective Projects:
                activeCounters = [] //clear dataSource before obtaining active Counters
                let counters = fetchObjectsFromCoreDataStore("Counter", filterProperty: nil, filterValue: nil) as! [Counter] //fetch counters from CD
                var idArray: [Int] = [] //array containing indexed counters
                for counter in counters { //index the counters by their IDs (used for matching below)
                    idArray.append(counter.id as Int)
                }
                for project in self.projects { //assign Counters -> Project
                    var groupedCounters: [Counter] = [] //initialize
                    if let projectCounters = project.counters.allObjects as? [Counter] { //project has cntrs
                        for item in projectCounters { //match each Counter in Project -> its CoreData obj
                            let uniqueID = item.id as Int
                            if let indexInArray = idArray.indexOf(uniqueID) { //find counterID in CD array
                                groupedCounters.append(counters[indexInArray]) //add CD counter -> group
                            }
                        }
                    }
                    activeCounters.append(groupedCounters) //add -> dataSource @ end of loop
                }
                
                //(3) Obtain dataStream objects (if they exist):
                self.datastreamObjects = nil //*clear array before checking for stream objects*
                if let streams = fetchObjectsFromCoreDataStore("Datastream", filterProperty: nil, filterValue: nil) as? [Datastream] { //obtain open streams
                    if !(streams.isEmpty) { //ONLY set source if there is at least 1 returned stream
                        self.datastreamObjects = streams //set sharedInstance object -> TV dataSource
                    }
                }
                activeProjectsTableView.reloadData() //reload UI w/ new project list (+ clears highlight!)
            }
            userJustLoggedIn = false //reset the variable
            
            //***
            let count = fetchObjectsFromCoreDataStore("DatabaseObject", filterProperty: nil, filterValue: nil).count //**temp
            menuButton.setTitle("Menu (\(count))", forState: UIControlState.Normal) //**temp
            //***
        }
    }
    
    override func viewDidAppear(animated: Bool) { //if user is not logged in, transition -> loginVC
        //*This code MUST be in viewDidAppear b/c view must load BEFORE transition takes place!*
        if (userDefaults.boolForKey(IS_LOGGED_IN_KEY) == true) { //check if user is logged in
            loggedIn = true //tell system that user is logged in
            if (self.projects.isEmpty) { //empty state - navigate to CreateProject Flow
                dispatch_async(dispatch_get_main_queue(), { 
                    let storyboard = UIStoryboard(name: "CreateProjectFlow", bundle: nil)
                    let controller = storyboard.instantiateInitialViewController()!
                    self.presentViewController(controller, animated: true, completion: nil)
                })
            } else { //reset notification observers
                NSNotificationCenter.defaultCenter().removeObserver(self) //1st clear old indicators
                NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.dataEntryButtonWasClicked(_:)), name: BMN_Notification_DataEntryButtonClick, object: nil)
                NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.cellDidDetectSwipe(_:)), name: BMN_Notification_EditExistingProject, object: nil) //detects swipe to edit project
                NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.serviceDidReportError(_:)), name: BMN_Notification_DataReportingErrorProtocol_ServiceDidReportError, object: nil) //**
                NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.dataTransmissionStatusDidChange(_:)), name: BMN_Notification_DatabaseConnection_DataTransmissionStatusDidChange, object: nil) //**
                
                //***Temp (until IP issue is resolved) -
                if !(self.ip_was_set) { //only fires 1x - enter current localhost IP
                    let alert = UIAlertController(title: "IP Address*", message: "Enter current IP end value", preferredStyle: UIAlertControllerStyle.Alert)
                    let ok = UIAlertAction(title: "Enter", style: .Default, handler: { (let action) in
                        if let text = alert.textFields?.first?.text {
                            if !(text.isEmpty) {
                                if let num = Int(text) {
                                    NSUserDefaults.standardUserDefaults().setInteger(num, forKey: IP_VALUE)
                                }
                            }
                            self.ip_was_set = true //set indicator to prevent further firing
                        }
                    })
                    alert.addTextFieldWithConfigurationHandler({ (let textField) in
                        textField.keyboardType = .NumberPad
                    })
                    alert.addAction(ok)
                    self.presentViewController(alert, animated: false, completion: nil)
                }
                //***
            }
        } else { //NOT logged in
            loggedIn = false //transition -> LoginVC
        }
    }
    
    override func viewWillDisappear(animated: Bool) { //clear notification observer
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewDidDisappear(animated: Bool) {
        configureActivityIndicator(false) //stop activity animation after disappearing
    }
    
    func getActiveProjects() -> [Project] { //obtains ACTIVE projects from store
        if let activeProjects = fetchObjectsFromCoreDataStore("Project", filterProperty: "isActive", filterValue: [true]) as? [Project] { //list of ACTIVE projects
            return activeProjects
        }
        return []
    }
    
    func configureActivityIndicator(animate: Bool) {
        if (animate) { //start animation
            activityIndicator.startAnimating()
            activeProjectsTableView.alpha = 0.3 //dimmed alpha
        } else { //stop animation
            activityIndicator.stopAnimating()
            activeProjectsTableView.alpha = 1 //restore alpha
        }
    }
    
    // MARK: - Notification Handling
    
    func dataEntryButtonWasClicked(notification: NSNotification) {
        if let dict = notification.userInfo, index = dict[BMN_CellWithGradient_CellIndexKey] as? Int {
            print("Data entry button clicked by cell #\(index).")
            if (index >= 0) {
                selectedObject = projects[index] //set selectedObject before segue
                performSegueWithIdentifier("showDataEntry", sender: nil)
            } else { //sent an error from the VC, refresh TV to remove expired project
                self.projects = getActiveProjects()
                activeProjectsTableView.reloadData()
            }
        }
    }
    
    func serviceDidReportError(notification: NSNotification) { //**temp fx until DB is online
        print("[APVC serviceDidReportError] Firing...")
        if let info = notification.userInfo, service = info[BMN_DataReportingErrorProtocol_ServiceTypeKey] as? String, erroredService = ServiceTypes(rawValue: service) {
            if (erroredService == ServiceTypes.Internet) { //throw an error
                let message = "Could not obtain an internet connection. Please check your internet connection and then retry."
                let alert = UIAlertController(title: "Connection Error", message: message, preferredStyle: .Alert)
                let ok = UIAlertAction(title: "OK", style: .Cancel, handler: nil)
                alert.addAction(ok)
                dispatch_async(dispatch_get_main_queue(), { //*present alert on main thread*
                    self.presentViewController(alert, animated: false, completion: nil)
                })
            } else if (erroredService == ServiceTypes.Localhost) { //***TEMPORARY error - must be deleted after DB is housed on website!
                let message = "**Could not access the server on localhost. Make sure server is running.**"
                let alert = UIAlertController(title: "Connection Error", message: message, preferredStyle: .Alert)
                let ok = UIAlertAction(title: "OK", style: .Cancel, handler: nil)
                alert.addAction(ok)
                dispatch_async(dispatch_get_main_queue(), { //*present alert on main thread*
                    self.presentViewController(alert, animated: false, completion: nil)
                })
            }
        }
    }
    
    func dataTransmissionStatusDidChange(notification: NSNotification) { //temp fx
        if let info = notification.userInfo, success = info[BMN_DatabaseConnection_TransmissionStatusKey] as? Bool {
            if (success) { //indicate successful completion
                let alert = UIAlertController(title: "Success!", message: "All data was successfully pushed to the database!", preferredStyle: .Alert)
                let ok = UIAlertAction(title: "OK", style: .Cancel, handler: { (let alert) in
                    let count = fetchObjectsFromCoreDataStore("DatabaseObject", filterProperty: nil, filterValue: nil).count
                    dispatch_async(dispatch_get_main_queue(), { //*present alert on main thread*
                        self.menuButton.setTitle("Menu (\(count))", forState: .Normal) //update btn title
                    })
                })
                alert.addAction(ok)
                dispatch_async(dispatch_get_main_queue(), { //*present alert on main thread*
                    self.presentViewController(alert, animated: true, completion: nil)
                })
            } else { //transmission failed - update UI
                let count = fetchObjectsFromCoreDataStore("DatabaseObject", filterProperty: nil, filterValue: nil).count
                dispatch_async(dispatch_get_main_queue(), { //*present alert on main thread*
                    self.menuButton.setTitle("Menu (\(count))", forState: .Normal) //update btn title
                })
            }
        }
    }
    
    func cellDidDetectSwipe(notification: NSNotification) { //segue -> EDIT PROJECT mode
        if let info = notification.userInfo, index = info[BMN_CellWithGradient_CellIndexKey] as? Int {
            if (index >= 0) { //allows user to modify an existing Project's variables
                let selection = projects[index] //get the selected project
                let projectType = ExperimentTypes(rawValue: selection.projectType)
                var projectAction: Action? = nil //action must always be set
                var inputVariables: [Module]?
                var outcomeMeasures: [Module] = [] //OM must always be set
                var actionQualifiers: [Module]?
                var ghostVariables: [String: [GhostVariable]]?
                var timeDifferences: [Module]?
                let moduleBlocker = Module_DynamicConfigurationFramework() //MUST be set
                
                var projectGroups: [(String, GroupTypes)] = [] //initialize
                for groupRaw in selection.groups { //reconstruct the Project groups
                    if let group = groupRaw as? Group, groupType = GroupTypes(rawValue: group.groupType) {
                        projectGroups.append((group.groupName, groupType))
                    }
                }
                
                if let aGroup = selection.groups.anyObject() as? Group {
                    for (varName, dict) in aGroup.variables { //setup the Project's variables
                        let variable = reconstructModuleObjectFromCoreDataDict(varName, configurationDict: dict) //reconstruct variable using shell
                        if let functionality = variable.selectedFunctionality {
                            switch variable.configurationType {
                            case .InputVariable:
                                if (inputVariables == nil) { //does NOT exist yet
                                    inputVariables = [] //initialize
                                }
                                inputVariables!.append(variable)
                                if let alternateValueForBlocker = variable.specialTypeForDynamicConfigFramework() { //use alternative
                                    moduleBlocker.variableWasCreated(.InputVariable, selectedFunctionalities: alternateValueForBlocker) //update
                                } else { //NO special type - use selectedFunctionality
                                    moduleBlocker.variableWasCreated(.InputVariable, selectedFunctionalities: [functionality])
                                }
                            case .OutcomeMeasure:
                                outcomeMeasures.append(variable)
                                if let alternateValueForBlocker = variable.specialTypeForDynamicConfigFramework() { //use alternative
                                    moduleBlocker.variableWasCreated(.OutcomeMeasure, selectedFunctionalities: alternateValueForBlocker) //update
                                } else { //NO special type - use selectedFunctionality
                                    moduleBlocker.variableWasCreated(.OutcomeMeasure, selectedFunctionalities: [functionality])
                                }
                            case .ActionQualifier:
                                if (actionQualifiers == nil) { //array does NOT exist yet
                                    actionQualifiers = [] //initialize
                                } //do NOT update blocker
                                actionQualifiers!.append(variable)
                            case .GhostVariable: //add -> GhostVariables
                                if let parent = variable.parentComputation {
                                    print("Found ghost [\(varName)] for parent [\(parent)].")
                                    let ghost = GhostVariable(computation: parent, name: varName, settings: dict)
                                    if let ghosts = ghostVariables, _ = ghosts[parent] { //check if array is initialized in dict against 'parent' key
                                        //*do not delete this conditional statement*
                                    } else if let _ = ghostVariables { //DICT exists - init array
                                        ghostVariables?.updateValue([], forKey: parent)
                                    } else { //dict does NOT exist - initialize dict & array
                                        ghostVariables = [parent: []]
                                    }
                                    ghostVariables![parent]!.append(ghost) //add ghost -> array
                                }
                            }
                        }
                    }
                    
                    if let timeDifferenceVars = aGroup.timeDifferenceVars { //check for existing TDs
                        for (varName, dict) in timeDifferenceVars {
                            let timeDifference = reconstructModuleObjectFromCoreDataDict(varName, configurationDict: dict) //reconstruct TD
                            if (timeDifferences == nil) { //array does NOT exist yet
                                timeDifferences = [] //initialize
                            }
                            timeDifferences!.append(timeDifference) //add TD -> array
                        }
                    }
                    projectAction = Action(settings: aGroup.action) //reconstruct the projectAction
                }
                
                let storyboard = UIStoryboard(name: "CreateProjectFlow", bundle: nil)
                let controller = storyboard.instantiateInitialViewController() as! UINavigationController
                if (projectType == .ControlComparison) { //CC project
                    let ccProjectVC = storyboard.instantiateViewControllerWithIdentifier("configureCCProject") as! ConfigureCCProjectViewController
                    ccProjectVC.isEditProjectFlow = true //set indicator
                    ccProjectVC.selectedAction = projectAction
                    ccProjectVC.projectTitle = selection.title
                    ccProjectVC.projectQuestion = selection.question
                    ccProjectVC.projectHypothesis = selection.hypothesis
                    ccProjectVC.projectType = projectType
                    ccProjectVC.projectGroups = projectGroups
                    ccProjectVC.projectToEdit = selection //pass CoreData object for deletion
                    ccProjectVC.outcomeMeasures = outcomeMeasures
                    ccProjectVC.timeDifferenceVariables = timeDifferences
                    controller.showViewController(ccProjectVC, sender: nil) //nav directly -> CCVC
                } else if (projectType == .InputOutput) { //IO project
                    let setupVarsVC = storyboard.instantiateViewControllerWithIdentifier("setupVarsVC") as! SetupVariablesViewController
                    setupVarsVC.isEditProjectFlow = true //set indicator
                    setupVarsVC.projectToEdit = selection //pass CoreData object for deletion
                    setupVarsVC.projectType = projectType
                    setupVarsVC.projectTitle = selection.title
                    setupVarsVC.projectQuestion = selection.question
                    setupVarsVC.projectHypothesis = selection.hypothesis
                    setupVarsVC.projectGroups = projectGroups
                    setupVarsVC.inputVariables = inputVariables
                    setupVarsVC.outcomeMeasures = outcomeMeasures
                    setupVarsVC.actionQualifiers = actionQualifiers
                    setupVarsVC.projectAction = projectAction
                    setupVarsVC.ghostVariables = ghostVariables
                    setupVarsVC.timeDifferenceVariables = timeDifferences
                    setupVarsVC.moduleBlocker = moduleBlocker
                    controller.showViewController(setupVarsVC, sender: nil) //nav directly -> SVVC
                }
                presentViewController(controller, animated: true, completion: nil) //show VC
            }
        }
    }
    
    // MARK: - TV Data Source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        var count = 0
        if let _ = self.datastreamObjects { //check if datastream is present
            count += 1 //add 1 section for the datastream
        }
        count += self.projects.count //each project has its own section in the TV
        return count
    }

    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var offset = 0 //offset for datastream section
        if let _ = self.datastreamObjects { //check if datastream exists
            offset = 1 //set offset to account for Datastream section
            if (section == 0) {
                return "Datastream" //set Datastream section title
            }
        }
        //DEFAULT title - indicates Project number & title:
        let projectTitle = projects[(section - offset)].title //*use the offset*
        return "Project #\(section - offset + 1) = '\(projectTitle)'"
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var offset = 0 //offsets section # if there are datastream objects
        if let streamObjects = self.datastreamObjects { //check if datastream exists
            offset = 1 //set offset to account for Datastream section
            if (section == 0) {
                return streamObjects.count //1 row per stream object
            }
        }
        //DEFAULT - for each section, there are 1 + (# of Counters in Project) cells:
        var total = 1 //default = 1 (for Project cell)
        total += projects[(section - offset)].counters.count //*remove offset from section #!*
        return total
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var offset = 0 //offset for Datastream section
        if let streamObjects = datastreamObjects { //DATASTREAM cell
            offset = 1 //Datastream exists - set offset
            if (indexPath.section == 0) { //check for 'Datastream' section (0)
                let streamObject = streamObjects[indexPath.row] //get stream object
                let cell = tableView.dequeueReusableCellWithIdentifier("datastream_cell")!
                cell.selectionStyle = .None //prevents highlighting of cell on selection
                cell.contentView.backgroundColor = UIColor.whiteColor() //reset background
                if let streamID = DatastreamIdentifiers(rawValue: streamObject.streamID) {
                    switch streamID { //set title depending on type of stream object
                    case .ExM_Workout:
                        cell.textLabel?.text = "Workout Datastream"
                    case .FIM_FoodIntake:
                        cell.textLabel?.text = "Food Intake Datastream"
                    }
                }
                return cell
            }
        }
        if (indexPath.row == 0) { //PROJECT cell - access dataSource using the SECTION #
            let project = projects[(indexPath.section - offset)] //offset the indexPath.section
            var currentlyReportingLocation = 1 //set -> default location in cycle (1)
            if let tempObject = project.temporaryStorageObject, timeStampsArray = tempObject[BMN_DBO_TimeStampKey] as? [NSDate] { //check for location in tempObject
                currentlyReportingLocation = timeStampsArray.count + 1 //overwrite currentLocation if it can be inferred from tempObject
            }
            let cell = tableView.dequeueReusableCellWithIdentifier(NSStringFromClass(CellWithGradientFill)) as! CellWithGradientFill
            cell.selectionStyle = .None //prevents highlighting of cell on selection
            cell.backgroundImageView.backgroundColor = UIColor.whiteColor() //resets bckgrd -> default
            cell.cellIndex = (indexPath.section - offset) //offset the indexPath's section
            let title = project.title
            cell.textLabel?.text = "[Currently @ \(currentlyReportingLocation)] \(title)"
            cell.dataSource = project
            return cell
        } else { //COUNTER cell
            let cell = tableView.dequeueReusableCellWithIdentifier(NSStringFromClass(CellForCounterBehavior)) as! CellForCounterBehavior
            cell.tabLevel = 3 //set indentation for Counter cells
            let counter = activeCounters[(indexPath.section - offset)][indexPath.row - 1] //use offset + subtract 1 from row (to account for 1st cell being Project cell)
            let dataSource: [String: AnyObject] = [BMN_LEVELS_MainLabelKey: "\(counter.variableName.uppercaseString)", BMN_LEVELS_HideRightViewKey: true]
            cell.dataSource = dataSource //set cell's mainLabel w/ name & hide completionIndicator
            cell.counterDataSource = counter //set counter as dataSource
            return cell
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 80 + BMN_DefaultBottomSpacer
    }
    
    func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if (self.datastreamObjects != nil) && (indexPath.section == 0) { //DATASTREAM: segue -> DEVC
            return true //allow selection of dataStream object
        }
        if (indexPath.row != 0) { //DEFAULT logic - 1st cell is always Project cell
            return false //for all other cells (Counters), disable highlighting/selection
        }
        if let cell = tableView.cellForRowAtIndexPath(indexPath) as? CellWithGradientFill {
            cell.backgroundImageView.backgroundColor = UIColor(red: 239/255, green: 239/255, blue: 244/255, alpha: 1) //highlight selected cell
        }
        configureActivityIndicator(true) //start activity animation
        return true
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let streamObjects = datastreamObjects { //if datastream cell is tapped, segue -> DEVC
            if (indexPath.section == 0) { //make sure 'Datastream' section was tapped
                selectedObject = streamObjects[indexPath.row] //set object for segue
                performSegueWithIdentifier("showDataEntry", sender: nil) //segue -> DEVC
                return
            }
        }
        //DEFAULT - tapping a cell brings up the data visualization flow for that Project:
        self.projectForOverview = projects[indexPath.row] //set segue object for OverviewVC
        performSegueWithIdentifier("showProjectOverview", sender: nil) //segue -> ProjectOverviewVC
    }
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle { //allow deletion of projects from here??
        return UITableViewCellEditingStyle.None
    }
    
    // MARK: - Button Actions
    
    @IBAction func addProjectButtonClick(sender: AnyObject) { //navigate to CreateProject flow
        configureActivityIndicator(true) //start animation
        let storyboard = UIStoryboard(name: "CreateProjectFlow", bundle: nil)
        let controller = storyboard.instantiateInitialViewController()!
        presentViewController(controller, animated: true, completion: nil)
    }
    
    @IBAction func menuButtonClick(sender: AnyObject) { //display menu
        if let dbConnection = DatabaseConnection() { //push Cloud backups/reported data -> DB
            dbConnection.pushAllDataToDatabase(0) //**
        }
    }
    
    // MARK: - Login Logic
    
    let userDefaults = NSUserDefaults.standardUserDefaults()
    var userJustLoggedIn: Bool = false
    var loggedIn: Bool = false {
        didSet {
            if !(loggedIn) { //user logged out
                userDefaults.setBool(false, forKey: IS_LOGGED_IN_KEY) //adjust defaults
                performSegueWithIdentifier("showLogin", sender: nil)
            }
        }
    }
    
    func didLoginSuccessfully(email: String) { //store email & dismiss LoginVC
        userDefaults.setObject(email, forKey: EMAIL_KEY) //save email -> preferences
        userDefaults.setBool(true, forKey: IS_LOGGED_IN_KEY)
        loggedIn = true
        let success = userDefaults.synchronize() //update the store
        print("Sync successful?: \(success)")
        
        //Pull the active projects from the DB for the current user:
        if let dbConnection = DatabaseConnection() { //call AFTER saving email -> defaults
            dbConnection.retrieveProjectModelsFromCloud({ (complete) in
                if (complete) {
                    dispatch_async(dispatch_get_main_queue(), { //update TV w/ new data
                        self.projects = self.getActiveProjects()
                        self.activeProjectsTableView.reloadData()
                    })
                }
                dispatch_async(dispatch_get_main_queue(), { //dismiss LoginVC
                    self.dismissViewControllerAnimated(true, completion: nil) //call LAST
                })
            })
        }
    }
    
    @IBAction func logoutButtonClick(sender: AnyObject) {
        logout()
    }
    
    func logout() { //clear CoreData store for Project, Counter, DBO, & Datastream entities
        loggedIn = false
        clearCoreDataStoreForEntity(entity: "Project")
        clearCoreDataStoreForEntity(entity: "Counter")
        clearCoreDataStoreForEntity(entity: "DatabaseObject")
        clearCoreDataStoreForEntity(entity: "Datastream")
        NSUserDefaults.standardUserDefaults().removeObjectForKey(EDITED_PROJECTS_KEY) //remove edits
    }
    
    // MARK: - Navigation
    
    @IBAction func unwindToActiveProjectsVC(sender: UIStoryboardSegue) { } //unwind segue
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "showProjectOverview") { //pass the selected PROJECT
            let destination = segue.destinationViewController as! ProjectOverviewViewController
            destination.selectedProject = self.projectForOverview
            destination.sender = NSStringFromClass(ActiveProjectsViewController) //pass class name
        } else if (segue.identifier == "showDataEntry") { //pass the selected DataEntryProtocol object
            let destination = segue.destinationViewController as! DataEntryViewController
            destination.selectedObject = self.selectedObject
        } else if (segue.identifier == "showLogin") { //set delegate for LoginVC
            let destination = segue.destinationViewController as! LoginViewController
            destination.delegate = self
        }
    }
    
}