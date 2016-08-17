//  ProjectSummaryViewController.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/3/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Provide summary of project setup before finalizing creation, showing each item & the project's object corresponding to that item. Allow user to edit as needed.

import UIKit

class ProjectSummaryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var summaryTableView: UITableView!
    @IBOutlet weak var createButton: UIBarButtonItem!
    @IBOutlet weak var measurementTimeline: UICollectionView!
    
    let context = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    
    var projectTitle: String? //title (obtained from ProjectVariablesVC)
    var projectQuestion: String? //question for investigation (obtained from ProjectVariablesVC)
    var projectHypothesis: String? //hypothesis for project (obtained from ProjectVariablesVC)
    var projectAction: Action? //action (obtained from ProjectVariablesVC)
    var projectEndpoint: Endpoint? //endpoint (obtained from ProjectVariablesVC)
    var projectType: ExperimentTypes? //project type (obtained from ProjectVariablesVC)
    var projectGroups: [(String, GroupTypes)]? //list of project group names (= 1 for IO project)
    var actionQualifiers: [Module]?
    var inputVariables: [Module]?
    var outcomeMeasures: [Module]?
    var ghostVariables: [String: [GhostVariable]]? //vars that feed in to computations (system-created)
    
    var projectToEdit: Project? //EDIT PROJECT flow - project to delete from CD store
    var ccProjectControls: [String]? //TV dataSource for CC project
    var ccProjectComparisons: [String]? //TV dataSource for CC project
    
    var measurementCycleLength: Int = 0 //final length of measurement cycle (for group creation)
    var measurementTimelineDataSource: [([String: AnyObject], [Module])] = [] //dataSource for collectionView cells
    var ghostParents: [String]? //parent computations for ghosts - any time the reportLocation of a parent changes, its ghosts must move with it
    
    // MARK: - View Configuration
    
    override func viewDidLoad() {
        super.viewDidLoad()
        summaryTableView.dataSource = self
        summaryTableView.delegate = self
        summaryTableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "summary_cell")
        measurementTimeline.dataSource = self
        measurementTimeline.delegate = self
        if let _ = projectToEdit { //EDIT PROJECT flow - change 'Create' btn title -> 'Update'
            createButton.title = "Update"
        }
        
        //Add notification observers for collectionView notifications:
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.measurementTimelineTimeDifferenceButtonWasClicked(_:)), name: BMN_Notification_MeasurementTimeline_TimeDifferenceButtonWasClicked, object: nil) //TD button
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.measurementTimelineVariableWasSelected(_:)), name: BMN_Notification_MeasurementTimeline_VariableWasSelected, object: nil) //variable selection
        
        if (projectType == .ControlComparison) { //set TV control/comparison group dataSource
            ccProjectControls = [] //initialize
            ccProjectComparisons = [] //initialize
            if let groups = projectGroups {
                for group in groups {
                    if (group.1 == .Control) {
                        ccProjectControls!.append(group.0)
                    } else if (group.1 == .Comparison) {
                        ccProjectComparisons!.append(group.0)
                    }
                }
            }
        }
        
        //(1) Set the parentsArray for ghostVariables:
        if let ghostDict = ghostVariables {
            print("Ghost variables...")
            for (parent, ghosts) in ghostDict {
                print("PARENT = [\(parent)]")
                if let _ = ghostParents { //array already exists
                    ghostParents!.append(parent)
                } else { //not yet set - initialize
                    ghostParents = [] //initialize
                    ghostParents!.append(parent)
                }
                for ghost in ghosts {
                    print("GHOST = [\(ghost.name)].")
                }
            }
        }
        
        if let action = projectAction, outcomes = outcomeMeasures { //project must have action & OM
            //(2) Find the max reportCount values for IV, OM, & AQ:
            var qualifiersMax: Int = 0 //max # of reports for qualifiers
            if let qualifiers = actionQualifiers {
                print("\nSorting action qualifiers...")
                qualifiersMax = getMaxReportLocationForVariables(qualifiers)
                print("Action Qualifiers - max report # = \(qualifiersMax).")
            }
            
            var inputsMax: Int = 0 //max # of reports for IV
            if let inputs = inputVariables {
                print("\nSorting input variables...")
                inputsMax = getMaxReportLocationForVariables(inputs)
                print("IV - max report # = \(inputsMax).")
            }
            
            print("\nSorting outcome measures...")
            let outcomesMax: Int = getMaxReportLocationForVariables(outcomes)
            print("OM - max report # = \(outcomesMax).")
            
            //(3) Assign variables to their appropriate reportLocations:
            print("\nAssigning report locations...")
            var endLocation: Int = 0 //*start of measurement cycle is @ location #1*
            switch (action.actionLocation) {
            case .BeforeInputs: //action is @ location #1 in measurement cycle
                if let qualifiers = actionQualifiers {
                    endLocation += qualifiersMax
                    setReportLocationsForVariables(qualifiers, endLocation: endLocation)
                } else { //no qualifiers - generate a plain action card
                    constructCardForLocation([endLocation: []], cardType: MeasurementTimeline_CardTypes.Action) //**
                }
                if let inputs = inputVariables {
                    endLocation += inputsMax
                    setReportLocationsForVariables(inputs, endLocation: endLocation)
                }
            case .BetweenInputsAndOutcomes: //action comes after IV in measurement cycle
                if let inputs = inputVariables {
                    endLocation += inputsMax
                    setReportLocationsForVariables(inputs, endLocation: endLocation)
                }
                if let qualifiers = actionQualifiers {
                    endLocation += qualifiersMax
                    setReportLocationsForVariables(qualifiers, endLocation: endLocation)
                } else { //no qualifiers, generate a plain action card
                    constructCardForLocation([endLocation: []], cardType: MeasurementTimeline_CardTypes.Action) //**
                }
            }
            endLocation += outcomesMax
            setReportLocationsForVariables(outcomes, endLocation: endLocation) //set for OM
            self.measurementCycleLength = endLocation //cannot be changed?
            print("[VDL] Final measurement cycle length = \(endLocation).")
            
            //(3) Generate measurement timeline using the var's reportLocations by setting dataSource for collection view
            //Color code IV vs. OM vs. AQ. Ghosts should also be color coded differently (grayish/white color) and should not be moveable manually - they follow their parent variable around. Need a way to match an item w/ its ghosts!
            //The measurement timeLine should ONLY be a visual way of presenting the information. The actual dataSource (the variables arrays) should be modified ONLY on the VC side. When communicating back & forth w/ the collectionView, the system should only pass the bare minimum of information - which cell was clicked, what the name of the variable is & @ what location, etc. It should not be passing the full variables.
            //Create a minimal struct for communicating w/ the view.
        }
    }
    
    private func getMaxReportLocationForVariables(variables: [Module]) -> Int {
        var maxValue: Int = 0
        for variable in variables { //get the max report location
            if let count = variable.reportCount { //default
                if (count > maxValue) {
                    maxValue = count //overwrite w/ new maximum
                }
            } else if !(variable.reportLocations.isEmpty) { //edit project flow
                if (variable.reportLocations.count > maxValue) { //use existing reportLocations
                    maxValue = variable.reportLocations.count
                }
            }
        }
        return maxValue
    }

    private func setReportLocationsForVariables(variables: [Module], endLocation: Int) {
        var varsForLocation = Dictionary<Int, [Module]>() //KEY = location, VALUE = vars @ location
        for variable in variables { //set location in reverse from endLocation -> start
            if !(variable.isGhost) { //shouldn't be any ghosts in 'vars', but just in case
                let reportCount: Int
                if let count = variable.reportCount {
                    reportCount = count
                } else { //no reportCount (edit project flow) - use reportLocations
                    reportCount = variable.reportLocations.count
                }
                variable.reportLocations.removeAll() //*clear set before overwriting*
                for i in 0..<reportCount { //NON-inclusive generator (0 -> [count - 1])
                    let locationInCycle = endLocation - i
                    variable.reportLocations.insert(locationInCycle) //set staggered locations from the END of the measurement cycle backwards
                    if (varsForLocation[locationInCycle] == nil) { //entry does NOT exist
                        varsForLocation[locationInCycle] = [] //initialize
                    }
                    varsForLocation[locationInCycle]!.append(variable) //add var -> location
                }
                print("Variable [\(variable.variableName)]. Report Count = [\(variable.reportCount)]. Locations = \(variable.reportLocations).")
                
                if let parents = ghostParents {
                    if (parents.contains(variable.variableName)) { //check if var is a ghostParent
                        print("Variable [\(variable.variableName)] is a ghost PARENT!")
                        updateGhostLocationsForParent(variable.variableName, parentLocation: variable.reportLocations) //set ghost locations
                        
                        //Construct variable for ghost & add -> dictionary:
                        if let ghostDict = ghostVariables, ghosts = ghostDict[variable.variableName] {
                            for ghost in ghosts { //reconstruct Module obj
                                let reconstructedGhost = Module(name: ghost.name, dict: ghost.settings)
                                for location in variable.reportLocations { //add ghost @ all parent locs
                                    varsForLocation[location]!.append(reconstructedGhost)
                                }
                            }
                        }
                    }
                }
            }
        }
        constructCardForLocation(varsForLocation, cardType: .Default) //use locations/vars to make card
    }
    
    private func constructCardForLocation(varsForLocation: [Int: [Module]], cardType: MeasurementTimeline_CardTypes) { //constructs a card for collectionView & adds it to dataSource
        for (location, variables) in varsForLocation {
            var infoDictionary = Dictionary<String, AnyObject>()
            infoDictionary[BMN_MeasurementTimeline_LocationNumberKey] = location
            infoDictionary[BMN_MeasurementTimeline_CellIndexKey] = 0 //??set by collectionView
            infoDictionary[BMN_MeasurementTimeline_CardTypeKey] = cardType.rawValue
            measurementTimelineDataSource.append((infoDictionary, variables)) //add object -> source
        }
    }
    
    private func updateGhostLocationsForParent(parent: String, parentLocation: Set<Int>) {
        if let ghostDict = ghostVariables, ghosts = ghostDict[parent] {
            var updatedGhosts: [GhostVariable] = []
            for ghost in ghosts { //update the ghost's settings dict w/ the parent location
                var updatedSettings = ghost.settings
                updatedSettings.updateValue(parentLocation, forKey: BMN_VariableReportLocationsKey)
                let updatedGhost = GhostVariable(computation: ghost.computation, name: ghost.name, settings: updatedSettings)
                updatedGhosts.append(updatedGhost)
                print("Updated ghost [\(ghost.name)] for parent [\(parent)] @ loc = \(parentLocation).")
            }
            ghostVariables![parent] = updatedGhosts
            for ghost in ghostVariables![parent]! {
                print("Ghost Location in Dict = [\(ghost.settings[BMN_VariableReportLocationsKey])]")
            }
        }
    }
    
    // MARK: - Collection View
    
    var selectedTimeDifferenceButtons: (Int?, Int?)? { //holds selections
        didSet {
            if let selections = selectedTimeDifferenceButtons, loc1 = selections.0, loc2 = selections.1 {
                self.presentTimeDifferenceConfigPopup((loc1, loc2)) //generate popup when 2 locs are sel
            }
        }
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.measurementCycleLength //# of cards that must be generated = cycle length + an action card (?) + time diff card (?)
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("location_card", forIndexPath: indexPath) as! MeasurementTimeline_CollectionViewCell
        cell.dataSource = self.measurementTimelineDataSource[indexPath.row] //set dataSource
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let viewHeight = self.measurementTimeline.frame.height * 0.82
        return CGSize(width: viewHeight, height: viewHeight) //square view centered in container
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        let insetValue: CGFloat = 18 //inset the cells from the L & R edges of the container
        return UIEdgeInsets(top: 0, left: insetValue, bottom: 0, right: insetValue)
    }
    
    func measurementTimelineVariableWasSelected(notification: NSNotification) {
        print("Timeline variable was selected...")
        if let info = notification.userInfo { //get location of variable & generate popup
//            presentMoveVariablePopup(<#T##variable: Module##Module#>, atLocation: <#T##Int#>)
        }
    }
    
    private func presentMoveVariablePopup(variable: Module, atIndex: Int, fromLocation: Int) { //when user selects a cell in collection view corresponding w/ a variable that can move, provide interface for movement
        let alert = UIAlertController(title: "Move Variable to New Location", message: "Enter the location in the measurement cycle where you would like to move the variable.", preferredStyle: .Alert)
        let cancel = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil) //do nothing
        let move = UIAlertAction(title: "Move", style: .Default) { (let move) in
            if let text = alert.textFields?.first?.text, number = Int(text) { //make sure input # is an existing location in measurement cycle & is > 1
                if (number > 1) && !(variable.reportLocations.contains(number)) { //make sure the variable is not already reporting @ the entered location
                    //check if that position exists currently**
                    print("OLD report locations = [\(variable.reportLocations)]")
                    print("Swapping variable [\(variable.variableName)] in cell #\(atIndex) from location [\(fromLocation)] to location [\(number)]...")
                    variable.reportLocations.remove(fromLocation) //remove old location
                    variable.reportLocations.insert(number) //insert new location
                    print("NEW report locations = [\(variable.reportLocations)]")
                    //update dataSource & UI accordingly...
                }
            }
        }
        alert.addTextFieldWithConfigurationHandler { (let textField) in
            textField.keyboardType = .NumberPad
        }
        alert.addAction(cancel)
        alert.addAction(move)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func measurementTimelineTimeDifferenceButtonWasClicked(notification: NSNotification) {
        print("Timeline TD button was clicked")
        if let info = notification.userInfo {
            if let buttons = selectedTimeDifferenceButtons, loc1 = buttons.0 {
                selectedTimeDifferenceButtons = (loc1, 2) //set loc2 in object
            } else { //object does not exist (empty)
                selectedTimeDifferenceButtons = (1, nil) //set loc1 in object
            }
            //if objects were unhighlighted, clear object
        }
    }
    
    private func presentTimeDifferenceConfigPopup(locations: (Int, Int)) { //when user selects 2 TD buttons from collection view, this function fires & is used to create a TD var
        let alert = UIAlertController(title: "Time Difference Variable", message: "Please provide a unique name for the variable and indicate if it is an input variable or outcome measure", preferredStyle: .Alert)
        let input = UIAlertAction(title: "Input", style: .Default) { (let input) in
            if let text = alert.textFields?.first?.text {
                let trimmedText = text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                if (trimmedText != "") && (self.isNameUnique(trimmedText)) {
                    self.createTimeDifferenceVariableWithName(trimmedText, configType: .Input, locations: locations)
                } else {
                    print("ERROR - name is NOT unique")
                }
            }
        }
        let outcome = UIAlertAction(title: "Outcome", style: .Default) { (let outcome) in
            if let text = alert.textFields?.first?.text {
                let trimmedText = text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                if (trimmedText != "") && (self.isNameUnique(trimmedText)) {
                    self.createTimeDifferenceVariableWithName(trimmedText, configType: .OutcomeMeasure, locations: locations)
                } else {
                    print("ERROR - name is NOT unique")
                }
            }
        }
        alert.addTextFieldWithConfigurationHandler { (let textField) in
            //
        }
        alert.addAction(input)
        alert.addAction(outcome)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    private func isNameUnique(name: String) -> Bool { //check if entered name is unique
        if let qualifiers = actionQualifiers {
            for variable in qualifiers {
                if (variable.variableName.lowercaseString == name.lowercaseString) {
                    return false
                }
            }
        }
        if let inputs = inputVariables {
            for variable in inputs {
                if (variable.variableName.lowercaseString == name.lowercaseString) {
                    return false
                }
            }
        }
        if let outcomes = outcomeMeasures {
            for variable in outcomes {
                if (variable.variableName.lowercaseString == name.lowercaseString) {
                    return false
                }
            }
        }
        return true
    }
    
    private func createTimeDifferenceVariableWithName(name: String, configType: ConfigurationTypes, locations: (Int, Int)) { //locations = (loc1, loc2) between which TD is measured
        let tdVar = CustomModule(timeDifferenceName: name, locations: locations)
        switch configType { //add variable -> appropriate dataSource
        case .Input: //add to IV array
            if (inputVariables == nil) { //array does NOT exist
                inputVariables = [] //initialize
            }
            inputVariables!.append(tdVar)
        case .OutcomeMeasure: //add to OM array
            if (outcomeMeasures == nil) { //array does NOT exist
                outcomeMeasures = [] //initialize
            }
            outcomeMeasures!.append(tdVar)
        default: //should NOT be called
            break
        }
    }
    
    // MARK: - Table View
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if (projectType == .ControlComparison) { //CC project - add 2 extra sections
            return 6 //last 2 sections are to list control & comparison groups
        }
        return 4
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
            return "Control Group(s)".uppercaseString
        case 5:
            return "Comparison Group(s)".uppercaseString
        default:
            return "Error! Switch Case Default"
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0, 1, 2, 3: //1 row each for project settings
            return 1
        case 4: //return the # of control groups
            if let controls = ccProjectControls {
                return controls.count
            }
        case 5: //return the # of comparison groups
            if let comparisons = ccProjectComparisons {
                return comparisons.count
            }
        default: //should not trigger
            print("[TV #RowsInSection] Error - default in switch!")
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
            if let project = projectToEdit, end = project.endDate { //(1) check for edit project
                cell.textLabel?.text = DateTime(date: end).getDateString()
            } else if let endpoint = projectEndpoint { //(2) check for normal endpoint
                if let numberOfDays = endpoint.getEndpointInDays() {
                    cell.textLabel?.text = "Project ends \(numberOfDays) days from now"
                } else { //continuous project
                    cell.textLabel?.text = "Continuous project (indefinite length)"
                }
            } else { //continuous project
                cell.textLabel?.text = "Continuous project (indefinite length)"
            }
        case 4: //input variables
            if let controls = ccProjectControls {
                cell.textLabel?.text = controls[indexPath.row]
            }
        case 5: //project action
            if let comparisons = ccProjectComparisons {
                cell.textLabel?.text = comparisons[indexPath.row]
            }
        default: //should NOT trigger
            print("[TV cellForRow] Error - default in switch.")
        }
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) { //allow user to go to correct location to edit setup
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
        default:
            print("[didSelectRow] Error - default in switch")
        }
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
            
            if let groups = projectGroups {
                for group in groups { //create 1 group for each obj in projectGroups
                    let (groupName, groupType) = (group.0, group.1)
                    if let outputs = outcomeMeasures, action = projectAction {
                        var variablesDict = createCoreDataDictionary(outputs, project: project) //OM
                        if (projectType == .InputOutput) { //IO Project - add IV & AQ
                            if let inputs = inputVariables {
                                let dict = createCoreDataDictionary(inputs, project: project)
                                for (key, value) in dict { //add inputVars -> Group
                                    variablesDict.updateValue(value, forKey: key)
                                }
                            }
                            if let qualifiers = actionQualifiers { //add qualifiers -> Group
                                let dict = createCoreDataDictionary(qualifiers, project: project)
                                for (key, value) in dict {
                                    variablesDict.updateValue(value, forKey: key)
                                }
                            }
                            if let ghostDict = ghostVariables { //if ghosts exist, add them -> varsDict
                                for (_, ghosts) in ghostDict {
                                    for ghost in ghosts {
                                        variablesDict.updateValue(ghost.settings, forKey: ghost.name)
                                    }
                                }
                            }
                        }
                        
                        print("Creating group [\(groupName)] of type [\(groupType)]...")
                        let _ = Group(groupName: groupName, groupType: groupType, project: project, action: action, variables: variablesDict, cycleLength: measurementCycleLength, timeDifferenceVars: nil, insertIntoManagedObjectContext: context) //create group
                    }
                }
            }
            saveManagedObjectContext() //save new project & group(s) -> CoreData
            
            //Create cloud backup for the new project & add it to queue:
            if let dbConnection = DatabaseConnection() {
                if (isEditProjectFlow) { //EDIT PROJECT flow - update project's DB information
//                    dbConnection.commitProjectEditToDatabase(project) //create update cmd
                } else { //DEFAULT flow - create Cloud backup
//                    dbConnection.createCloudModelForProject(project) //create backup & save to CD
                }
            }
        }
        
        //Return to homescreen after operation is complete:
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateInitialViewController()!
        presentViewController(controller, animated: true, completion: nil)
    }
    
    private func createCoreDataDictionary(variableArray: [Module], project: Project) -> Dictionary<String, [String: AnyObject]> { //construct master dict for CoreData given array of user-created variables
        var dictionary = Dictionary<String, [String: AnyObject]>()
        for variable in variableArray { //construct dict for each variable, KEY is variable's unique name
            if let maxLocation = variable.reportLocations.maxElement() {
                if (maxLocation > measurementCycleLength) {
                    print("[createCoreDataDict] New max location = \(maxLocation)")
                    measurementCycleLength = maxLocation //overwrite w/ new max
                }
            }
            if let custom = variable as? CustomModule { //check for Counter variables
                if (custom.getTypeForVariable() == CustomModuleVariableTypes.Behavior_Counter) {
                    let _ = Counter(linkedVar: custom, project: project, insertIntoManagedObjectContext: context) //create Counter obj for persistence
                }
            }
            dictionary[variable.variableName] = variable.createDictionaryForCoreDataStore()
        }
        return dictionary
    }

}