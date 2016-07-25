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
    
    var activeCounters: [Counter] = [] //list of active counters (TV dataSource)
    var projects: [Project] = [] //list of activeProject objects (TV dataSource)
    var selectedProject: Project? //project object to pass on segue
    
    // MARK: - View Configuration
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if (userDefaults.boolForKey(IS_LOGGED_IN_KEY) == true) { //user is logged in
            self.loggedIn = true
        }
        
        //Register TV dataSource & delegate:
        activeProjectsTableView.dataSource = self
        activeProjectsTableView.delegate = self
        activeProjectsTableView.registerClass(CellForCounterBehavior.self, forCellReuseIdentifier: NSStringFromClass(CellForCounterBehavior)) //counter cell type
        activeProjectsTableView.registerClass(CellWithGradientFill.self, forCellReuseIdentifier: NSStringFromClass(CellWithGradientFill)) //project cell type
        activityIndicator.hidesWhenStopped = true
    }
    
    override func viewWillAppear(animated: Bool) { //update TV UI whenever view appears - the current user's projects are stored in CoreData & fetched when view appears
        if (loggedIn) { //only fire if user is loggedIn
            self.activeCounters = fetchObjectsFromCoreDataStore("Counter", filterProperty: nil, filterValue: nil) as! [Counter] //fetch counters
            self.projects = getActiveProjects()
            if (self.projects.isEmpty) { //empty state
                configureActivityIndicator(true) //start spinning to indicate transition
                activeProjectsTableView.hidden = true //hide TV until a project is present
            } else {
                activeProjectsTableView.hidden = false
            }
            activeProjectsTableView.reloadData() //reload UI w/ new project list (also clears highlight!)
            userJustLoggedIn = false //reset the variable
            
            //***
            let count = fetchObjectsFromCoreDataStore("DatabaseObject", filterProperty: nil, filterValue: nil).count //**temp
            menuButton.setTitle("Menu (\(count))", forState: UIControlState.Normal) //**temp
            //***
        }
    }
    
    func getActiveProjects() -> [Project] { //obtains ACTIVE projects from store
        if let activeProjects = fetchObjectsFromCoreDataStore("Project", filterProperty: "isActive", filterValue: [true]) as? [Project] { //list of ACTIVE projects
            return activeProjects
        }
        return []
    }
    
    var ip_was_set: Bool = false //**temp item
    
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
                selectedProject = projects[index] //set selectedProject before segue
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
                let storyboard = UIStoryboard(name: "CreateProjectFlow", bundle: nil)
                let controller = storyboard.instantiateInitialViewController() as! UINavigationController
                let projectVarsVC = storyboard.instantiateViewControllerWithIdentifier("setupVariablesVC") as! ProjectVariablesViewController
                
                var inputVariables: [String: [Module]] = [BMN_InputOutput_InputVariablesKey: [], BMN_ControlComparison_ControlKey: [], BMN_ControlComparison_ComparisonKey: []]
                var outcomeVariables: [Module] = []
                var ghostVariables: [String: [GhostVariable]]?
                var action: Action? = nil
                let moduleBlocker = Module_DynamicConfigurationFramework() //needs to be sent -> PVVC in Control group state for CC projects
                var uniqueNames = Set<String>() //avoid duplication of OM (CC project)
                
                var fireCounter: Int = 0 //used to switch moduleBlocker state (CC project)
                for groupRaw in selection.groups { //handle for IO & CC projects - for each group, make variables & use to construct the action & inputs & outputs dicts for SetVariables.
                    if let group = groupRaw as? Group, groupType = GroupTypes(rawValue: group.groupType) {
                        var navState: CCProjectNavigationState? = nil //for ghosts
                        if (projectType == .ControlComparison) { //set navigation state
                            if (groupType == .Control) {
                                navState = .Control
                                if (fireCounter != 0) { //swap state if Control is in 2nd loop run
                                    moduleBlocker.ccProjectWillSwitchState()
                                }
                            } else if (groupType == .Comparison) {
                                navState = .Comparison
                                moduleBlocker.ccProjectWillSwitchState() //always swap state for Comp
                            }
                            fireCounter += 1 //increment to indicate pass through loop
                        }
                        
                        for (variable, dict) in group.beforeActionVariables { //BEFORE ACTION vars
                            if let moduleRaw = dict[BMN_ModuleTitleKey] as? String, module = Modules(rawValue: moduleRaw) {
                                let inputVar = createModuleObjectFromModuleName(moduleType: module, variableName: variable, configurationDict: dict)
                                if !(inputVar.isGhost) && (inputVar.selectedFunctionality != nil) {
                                    if (projectType == .InputOutput) { //add -> IO data source
                                        inputVariables[BMN_InputOutput_InputVariablesKey]!.append(inputVar)
                                    } else if (projectType == .ControlComparison) {
                                        if (groupType == .Control) {
                                            inputVariables[BMN_ControlComparison_ControlKey]!.append(inputVar)
                                        } else if (groupType == .Comparison) {
                                            inputVariables[BMN_ControlComparison_ComparisonKey]!.append(inputVar)
                                        }
                                    }
                                    moduleBlocker.variableWasCreated(.BeforeAction, typeName: inputVar.selectedFunctionality!) //update blocker
                                } else { //GHOST - add -> ghost array
                                    if let parent = inputVar.parentComputation {
                                        let ghost = GhostVariable(groupType: navState, location: .BeforeAction, computation: parent, name: variable, settings: dict)
                                        if let _ = ghostVariables { //array already exists
                                            ghostVariables![parent]!.append(ghost)
                                        } else { //array does NOT exist - initialize
                                            ghostVariables = Dictionary<String, [GhostVariable]>()
                                            ghostVariables![parent]!.append(ghost)
                                        }
                                    }
                                }
                            }
                        }
                        
                        for (variable, dict) in group.afterActionVariables { //AFTER ACTION vars
                            if !(uniqueNames.contains(variable)) { //only perform for UNIQUE vars
                                uniqueNames.insert(variable) //add var name -> set
                                if let moduleRaw = dict[BMN_ModuleTitleKey] as? String, module = Modules(rawValue: moduleRaw) {
                                    let outcomeVar = createModuleObjectFromModuleName(moduleType: module, variableName: variable, configurationDict: dict)
                                    if !(outcomeVar.isGhost) && (outcomeVar.selectedFunctionality != nil) { //NOT a ghost
                                        outcomeVariables.append(outcomeVar)
                                        moduleBlocker.variableWasCreated(.AfterAction, typeName: outcomeVar.selectedFunctionality!)
                                    } else { //GHOST - add to ghost array
                                        if let parent = outcomeVar.parentComputation {
                                            let ghost = GhostVariable(groupType: navState, location: .AfterAction, computation: parent, name: variable, settings: dict)
                                            if let _ = ghostVariables { //exists
                                                ghostVariables![parent]!.append(ghost)
                                            } else { //does NOT exist - initialize
                                                ghostVariables = Dictionary<String, [GhostVariable]>()
                                                ghostVariables![parent]!.append(ghost)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        if let enumObj = Actions(rawValue: group.action) { //STANDARD action
                            action = Action(action: enumObj, actionName: nil)
                        } else { //does NOT match enum - CUSTOM action
                            action = Action(action: .Custom, actionName: group.action)
                        }
                    }
                }
                
                projectVarsVC.isEditProjectFlow = true //set indicator
                projectVarsVC.projectToEdit = selection //pass CoreData object for deletion
                projectVarsVC.projectType = projectType
                projectVarsVC.projectTitle = selection.title
                projectVarsVC.projectQuestion = selection.question
                projectVarsVC.projectHypothesis = selection.hypothesis
                projectVarsVC.inputVariablesDict = inputVariables
                projectVarsVC.outcomeVariableRows = outcomeVariables
                projectVarsVC.selectedAction = action
                projectVarsVC.ghostVariables = ghostVariables
                projectVarsVC.moduleBlocker = moduleBlocker //**
                
                controller.showViewController(projectVarsVC, sender: nil) //nav directly -> PVVC
                presentViewController(controller, animated: true, completion: nil) //show VC
            }
        }
    }
    
    private func createModuleObjectFromModuleName(moduleType module: Modules, variableName: String, configurationDict: [String: AnyObject]) -> Module { //init Module obj w/ its name & config dict
        var object: Module = Module(name: variableName)
        
        //Pass the var's name & dictionary -> specific module subclass' CoreData initializer:
        switch module {
        case .CustomModule:
            object = CustomModule(name: variableName, dict: configurationDict)
        case .EnvironmentModule:
            object = EnvironmentModule(name: variableName, dict: configurationDict)
        case .FoodIntakeModule:
            object = FoodIntakeModule(name: variableName, dict: configurationDict)
        case .ExerciseModule:
            object = ExerciseModule(name: variableName, dict: configurationDict)
        case .BiometricModule:
            object = BiometricModule(name: variableName, dict: configurationDict)
        case .CarbonEmissionsModule:
            object = CarbonEmissionsModule(name: variableName, dict: configurationDict)
        case .RecipeModule:
            break //cannot edit a Recipe Module var
        }
        return object
    }
    
    // MARK: - TV Data Source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if (self.activeCounters.isEmpty) { //if no counters are active, only 1 section
            return 1
        }
        return 2 //1 section for counters, 1 for projects
        //eventually, we may want to organize projects more clearly & arrange counters w/ projects
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if (self.activeCounters.isEmpty) { //no section headers if there is only 1 section
            return nil
        }
        if (section == 0) { //Counters section
            return "Active Counters"
        } else { //Projects section
            return "Project List"
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if !(self.activeCounters.isEmpty) && (section == 0) {
            return activeCounters.count
        } else {
            return projects.count
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if !(activeCounters.isEmpty) && (indexPath.section == 0) { //Counter cells
            let cell = tableView.dequeueReusableCellWithIdentifier(NSStringFromClass(CellForCounterBehavior)) as! CellForCounterBehavior
            let counter = activeCounters[indexPath.row]
            let dataSource: [String: AnyObject] = [BMN_LEVELS_MainLabelKey: counter.variableName, BMN_LEVELS_HideRightViewKey: true]
            cell.dataSource = dataSource //set cell's mainLabel w/ name & hide completionIndicator
            cell.counterDataSource = counter //set counter as dataSource
            return cell
        } else { //Project cells
            let cell = tableView.dequeueReusableCellWithIdentifier(NSStringFromClass(CellWithGradientFill)) as! CellWithGradientFill
            cell.selectionStyle = .None //prevents highlighting of cell on selection
            cell.backgroundImageView.backgroundColor = UIColor.whiteColor() //**reset -> default
            cell.cellIndex = indexPath.row
            let project = projects[indexPath.row]
            let title = project.title
            if let projectType = project.getProjectTypeForDisplay() {
                cell.textLabel?.text = "\(title.uppercaseString): \(projectType)"
            } else {
                cell.textLabel?.text = title
            }
            cell.dataSource = project
            return cell
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 80 + BMN_DefaultBottomSpacer
    }
    
    func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if !(activeCounters.isEmpty) && (indexPath.section == 0) { //prevent selection of Counter cells
            return false
        }
        if let cell = tableView.cellForRowAtIndexPath(indexPath) as? CellWithGradientFill {
            cell.backgroundImageView.backgroundColor = UIColor(red: 239/255, green: 239/255, blue: 244/255, alpha: 1) //highlight selected cell
        }
        configureActivityIndicator(true) //start activity animation
        return true
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //Tapping a cell brings up the data visualization flow for that project:
        selectedProject = projects[indexPath.row]
        performSegueWithIdentifier("showProjectOverview", sender: nil) //segue -> ProjectOverviewVC
    }
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle { //allow deletion of projects from here?
        return UITableViewCellEditingStyle.None
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.Delete) { //*
            //Project must be removed from TV dataSource, core data, DB must be removed from web, etc.!
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
        }
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
            print("Pushing data to DB...")
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
    
    func logout() { //clear CoreData store for Project, Group, Counter entities
        loggedIn = false
        clearCoreDataStoreForEntity(entity: "Project")
        clearCoreDataStoreForEntity(entity: "Counter")
        clearCoreDataStoreForEntity(entity: "DatabaseObject")
        NSUserDefaults.standardUserDefaults().removeObjectForKey(EDITED_PROJECTS_KEY) //remove edits
    }
    
    // MARK: - Navigation
    
    @IBAction func unwindToActiveProjectsVC(sender: UIStoryboardSegue) { } //unwind segue
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "showProjectOverview") { //pass the selected project
            let destination = segue.destinationViewController as! ProjectOverviewViewController
            destination.selectedProject = self.selectedProject
            destination.sender = NSStringFromClass(ActiveProjectsViewController) //pass class name
        } else if (segue.identifier == "showDataEntry") { //pass the selected project
            let destination = segue.destinationViewController as! DataEntryViewController
            destination.selectedProject = self.selectedProject
        } else if (segue.identifier == "showLogin") { //set delegate for LoginVC
            let destination = segue.destinationViewController as! LoginViewController
            destination.delegate = self
        }
    }
    
}