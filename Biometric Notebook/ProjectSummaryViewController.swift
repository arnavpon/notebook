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
    var ghostParents: Set<String>? //temporary reference set (used for ghost creation)
    
    var projectToEdit: Project? //EDIT PROJECT flow - project to delete from CD store
    var ccProjectControls: [String]? //TV dataSource for CC project
    var ccProjectComparisons: [String]? //TV dataSource for CC project
    
    lazy var measurementCycleLength: Int = 0 //final length of measurement cycle (for group creation)
    var measurementTimelineDataSource: [(MeasurementTimeline_CardTypes, Int?, [MeasurementTimelineVariable])] = [] //dataSource for collectionView cells = (cardType, locationInCycle?, [variables])
    var measurementTimelineLocationIndex: [Int] = [] //indexes LOCATIONS in timeline dataSource
    var projectVariables: [Module] = [] //list of all vars (IV, OM, AQ, ghost) for Project
    var projectVariablesIndex: [String] = [] //indexes names of projectVars (SAME order as projectVars)
    var timeDifferenceVariables: [Module]? { //user-created TD vars
        didSet {
            generateMeasurementTimeline() //update UI for changes
        }
    }
    var deferDataSourceConstruction: Bool = true //*blocker must start @ TRUE*
    var actionCardIndex: Int? //index of action card
    
    var computations: Set<String>? //stores reference to variables that are part of computations (either the parent or the feed-in)
    var computationsReference: [String: [String]]? //KEY = variable name; VALUE = [variables linked to key as part of a computation]
    
    // MARK: - View Configuration
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Set TV & collectionView dataSource/delegate (draws timeline):
        summaryTableView.dataSource = self
        summaryTableView.delegate = self
        summaryTableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "summary_cell")
        measurementTimeline.dataSource = self
        measurementTimeline.delegate = self
        
        //Add notification observers for collectionView notifications:
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.measurementTimelineTimeDifferenceButtonWasClicked(_:)), name: BMN_Notification_MeasurementTimeline_TimeDifferenceButtonWasClicked, object: nil) //TD button
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.measurementTimelineVariableWasSelected(_:)), name: BMN_Notification_MeasurementTimeline_VariableWasSelected, object: nil) //variable selection
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.measurementTimelineShouldDeleteTimeDifferenceVariable(_:)), name: BMN_Notification_MeasurementTimeline_ShouldDeleteTimeDifferenceVariable, object: nil)
        
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
        if let _ = projectToEdit { //EDIT PROJECT flow - change 'Create' btn title -> 'Update'
            createButton.title = "Update"
            self.tableViewTitles[3] = "End Date".uppercaseString
        }
        
        //(1) Set the parentsArray for ghostVariables:
        if let ghostDict = ghostVariables {
            for (parent, _) in ghostDict {
                print("GHOST PARENT = [\(parent)]")
                if (ghostParents == nil) { //reference set does NOT exist
                    ghostParents = [] //initialize
                }
                ghostParents!.insert(parent) //add computation parent -> set
            }
        }
        
        if let action = projectAction, outcomes = outcomeMeasures { //project must have action & OM
            //(2) Find the max reportCount values for IV, OM, & AQ:
            var qualifiersMax: Int = 0 //max # of reports for qualifiers
            if let qualifiers = actionQualifiers {
                qualifiersMax = getMaxReportLocationForVariables(qualifiers)
            }
            
            var inputsMax: Int = 0 //max # of reports for IV
            if let inputs = inputVariables {
                inputsMax = getMaxReportLocationForVariables(inputs)
            }
            let outcomesMax: Int = getMaxReportLocationForVariables(outcomes)
            
            //(3) Assign variables to their appropriate reportLocations:
            var endLocation: Int = 0 //*start of measurement cycle is @ location #1*
            switch (action.actionLocation) {
            case .BeforeInputs: //action is @ location #1 in measurement cycle
                actionCardIndex = 0 //action card is set @ initial position in dataSource
                if let qualifiers = actionQualifiers {
                    endLocation += qualifiersMax
                    setReportLocationsForVariables(qualifiers, endLocation: endLocation)
                    actionQualifiers = nil //clear AQ (vars were added -> projectVariables)
                }
                if let inputs = inputVariables {
                    endLocation += inputsMax
                    setReportLocationsForVariables(inputs, endLocation: endLocation)
                    inputVariables = nil //clear (vars were added -> projectVariables)
                }
            case .BetweenInputsAndOutcomes: //action comes after IV in measurement cycle
                if let inputs = inputVariables {
                    endLocation += inputsMax
                    setReportLocationsForVariables(inputs, endLocation: endLocation)
                    inputVariables = nil //clear (vars were added -> projectVariables)
                }
                actionCardIndex = endLocation //set action card index after IV
                if let qualifiers = actionQualifiers {
                    endLocation += qualifiersMax
                    setReportLocationsForVariables(qualifiers, endLocation: endLocation)
                    actionQualifiers = nil //clear (vars were added -> projectVariables)
                }
            }
            endLocation += outcomesMax
            setReportLocationsForVariables(outcomes, endLocation: endLocation) //set for OM
            outcomeMeasures = nil //clear (vars were added -> projectVariables)
            ghostParents = nil //clear temporary reference set
            ghostVariables = nil //clear (vars were added -> projectVariables)
            matchFeedInLocationsToParentComputationLocations() //match locations for computation vars
            self.deferDataSourceConstruction = false //*remove blocker!*
            self.generateMeasurementTimeline() //LAST - set timeline dataSource
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self) //clear notification observer!
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
        for variable in variables { //set location in reverse from endLocation -> start
            //(1) Assign report locations for the variable:
            let reportCount: Int
            if let count = variable.reportCount {
                reportCount = count
            } else { //no reportCount (edit project flow) - use reportLocations.count
                reportCount = variable.reportLocations.count
            }
            variable.reportLocations.removeAll() //*clear set before overwriting*
            for i in 0..<reportCount { //NON-inclusive generator (0 -> [count - 1])
                let locationInCycle = endLocation - i
                variable.reportLocations.insert(locationInCycle) //set staggered locations from the END of the measurement cycle backwards
            }
            print("Variable [\(variable.variableName)]. Report Count = [\(variable.reportCount)]. Locations = \(variable.reportLocations).")
            projectVariables.append(variable) //add variable -> master dataSource
            projectVariablesIndex.append(variable.variableName) //add var name -> index array
            
            //(2) If the variable is a ghostParent, set the ghosts -> the same location as the parent:
            if let parents = ghostParents, ghostDict = ghostVariables { //check if var is ghostParent
                if (parents.contains(variable.variableName)) {
                    print("Variable [\(variable.variableName)] is a ghost PARENT!")
                    if let ghosts = ghostDict[variable.variableName] { //add ghosts -> vars array
                        for ghost in ghosts { //reconstruct Module obj
                            let reconstructedGhost = reconstructModuleObjectFromCoreDataDict(ghost.name, configurationDict: ghost.settings)
                            projectVariables.append(reconstructedGhost) //add ghost -> array
                            projectVariablesIndex.append(reconstructedGhost.variableName) //add -> index
                            print("Added ghost [\(ghost.name)] to variables array.")
                        }
                    }
                }
            }
            
            //(3) Check if the variable is a PARENT COMPUTATION:
            if (variable.computationInputs.count > 0) { //COMP PARENT variable
                if (computations == nil) { //set does NOT exist yet
                    computations = [] //initialize
                }
                if (computationsReference == nil) { //reference dict does NOT exist yet
                    computationsReference = [:] //initialize
                }
                var feedIns: [String] = [] //array containing ALL feed-ins for parent
                for (_, name) in variable.computationInputs {
                    feedIns.append(name)
                }
                print("\nFound PARENT COMPUTATION [\(variable.variableName)] with FEED-INS \(feedIns).")
                computations!.insert(variable.variableName) //add to watch list
                computationsReference!.updateValue(feedIns, forKey: variable.variableName) //overwrite
            }
        }
    }
    
    private func matchFeedInLocationsToParentComputationLocations() { //AFTER computations & computationsReference objects have been filled, modifies projectVariables such that all feed-in locations EXACTLY match parent locations
        print("\nMatching feedIn locations -> parent computation locations...")
        if let _ = self.computations, compsReference = self.computationsReference {
            for (key, feedIns) in compsReference { //check if the KEY is a parent or feed-In
                if let index = projectVariablesIndex.indexOf(key) {
                    let variable = projectVariables[index]
                    if (variable.computationInputs.count > 0) { //PARENT COMPUTATION - update feed-ins
                        print("PARENT COMPUTATION = [\(key)]. Feed-In Count = [\(variable.computationInputs.count)].")
                        let parentLocations = variable.reportLocations
                        print("PARENT locations = \(parentLocations).")
                        for feedIn in feedIns { //match feedIn location -> parent
                            if let feedInIndex = projectVariablesIndex.indexOf(feedIn) {
                                projectVariables[feedInIndex].reportLocations = parentLocations
                                print("Updated FEED IN [\(feedIn)] locations -> \(projectVariables[feedInIndex].reportLocations).")
                                
                                //If feed-In is NOT a ghost (i.e. it is an independent variable that can be moved in the timeline), add -> computations set:
                                if (projectVariables[feedInIndex].configurationType != .GhostVariable) {
                                    print("\nFeed-In [\(feedIn)] is NOT a ghost. Updating ref. obj...")
                                    computations!.insert(feedIn) //add -> watch list
                                    var objectsToMove: [String] = [key] //create array for reference dict
                                    for item in feedIns { //add other linkedVars -> reference array
                                        if (item != feedIn) { //make sure item != the CURRENT feedIn
                                            objectsToMove.append(item) //add item -> list of obj to move
                                        }
                                    }
                                    computationsReference!.updateValue(objectsToMove, forKey: feedIn)
                                    print("WATCH LIST = \(computations!).\nREFERENCE DICT = \(computationsReference!).")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func updateLocationsForLinkedVariables(modifiedVariable: String, atLocations: Set<Int>) -> Int { //for the input variable, updates the locations for any linked variables so they are the SAME
        print("\nUpdating linkedVar locations for modifiedVar [\(modifiedVariable.uppercaseString)]...")
        var updateCount = 0 //counts # of items that were updated
        if let computationsDict = computationsReference, linkedVariables = computationsDict[modifiedVariable] { //access linked variables for input
            for linkedVariable in linkedVariables { //for each linked var, get index in master array
                if let index = projectVariablesIndex.indexOf(linkedVariable) {
                    updateCount += 1 //add 1 to counter
                    projectVariables[index].reportLocations = atLocations //equate locations
                    print("Updated linked variable [\(linkedVariable)] with loc = \(projectVariables[index].reportLocations).")
                }
            }
        }
        return updateCount
    }
    
    private func generateMeasurementTimeline() { //constructs dataSource for collectionView
        if !(deferDataSourceConstruction) { //make sure blocker is not set
            print("\nGenerating measurement timeline dataSource...")
            measurementTimelineDataSource = [] //clear before running function
            measurementTimelineLocationIndex = [] //clear index
            
            //(1) Separate variables in master list according to reportLocation:
            var variablesForLocation = Dictionary<Int, [MeasurementTimelineVariable]>()
            var locations = Set<Int>() //set of sorted location #s
            var actionQualifiersExist: Bool = false //indicates if AQ exist
            for variable in projectVariables {
                for location in variable.reportLocations {
                    locations.insert(location) //add location -> set
                    var timelineVariables: [MeasurementTimelineVariable] = []
                    if let existingVars = variablesForLocation[location] {
                        timelineVariables = existingVars //check if vars exist for location
                    }
                    let timelineVariable: MeasurementTimelineVariable
                    switch variable.configurationType {
                    case .InputVariable:
                        timelineVariable = MeasurementTimelineVariable(name: variable.variableName, type: .InputVariable)
                    case .OutcomeMeasure:
                        timelineVariable = MeasurementTimelineVariable(name: variable.variableName, type: .OutcomeMeasure)
                    case .ActionQualifier:
                        timelineVariable = MeasurementTimelineVariable(name: variable.variableName, type: .ActionQualifier)
                        actionQualifiersExist = true //set indicator
                    case .GhostVariable:
                        timelineVariable = MeasurementTimelineVariable(name: variable.variableName, type: .GhostVariable)
                    }
                    timelineVariables.append(timelineVariable)
                    variablesForLocation.updateValue(timelineVariables, forKey: location)
                }
            }
            
            //(2) Construct cell dataSource objects & add to timeline dataSource:
            let sortedLocations = locations.sort() //obtain sorted array
            for orderedLocation in sortedLocations { //obtain set of variables for each location
                if let timelineVariables = variablesForLocation[orderedLocation] {
                    measurementTimelineDataSource.append((.Default, orderedLocation, timelineVariables)) //add obj -> dataSource
                    measurementTimelineLocationIndex.append(orderedLocation) //add loc -> index
                }
            }
            if let actionIndex = actionCardIndex {
                if (actionQualifiersExist) { //action card alrdy exists - UPDATE cardType in source
                    let (_, loc, variables) = measurementTimelineDataSource[actionIndex]
                    measurementTimelineDataSource[actionIndex] = (.Action, loc, variables) //overwrite
                } else { //ADD action card @ its index ONLY if no AQ exist (b/c otherwise the card will have already been added)
                    measurementTimelineDataSource.insert((.Action, nil, []), atIndex: actionIndex) //use empty array for variables in card
                    measurementTimelineLocationIndex.insert(-1, atIndex: actionIndex) //add dummy loc
                }
            }
            
            //(3) Handle timeDifference variables if they exist:
            if let timeDifferences = timeDifferenceVariables { //add TD card @ the end
                var variables: [MeasurementTimelineVariable] = []
                var arrayIndex = 0
                var indexesToRemove: [Int] = [] //list of TD vars to delete
                for timeDifference in timeDifferences { //create timeline variables
                    if let tdVar = timeDifference as? CustomModule, setup = tdVar.timeDifferenceSetup, (tdLocation1, tdLocation2) = setup.1 { //safety check TD var stored locs
                        if (sortedLocations.contains(tdLocation1)) && (sortedLocations.contains(tdLocation2)) { //BOTH locations exist in timeline!
                            variables.append(MeasurementTimelineVariable(name: timeDifference.variableName, type: MeasurementTimeline_VariableTypes.TimeDifference)) //add TD -> timelineVariables
                        } else { //1 or both locations DO NOT exist - delete tdVar from array
                            print("[generateTimeline] TD [\(tdVar.variableName)] no longer fits!")
                            indexesToRemove.append(arrayIndex) //add index -> deletion array
                        }
                    }
                    arrayIndex += 1
                }
                let reverseSortedArray = indexesToRemove.sort().reverse() //sort indexes in desc. order
                deferDataSourceConstruction = true //*block fx from firing*
                for deletionIndex in reverseSortedArray { //remove from back -> front
                    print("Deleted TD var [\(timeDifferenceVariables![deletionIndex].variableName)] @ index [\(deletionIndex)].")
                    timeDifferenceVariables!.removeAtIndex(deletionIndex)
                }
                deferDataSourceConstruction = false //remove blocker
                if !(variables.isEmpty) { //make sure there is at least 1 remaining TD
                    self.measurementTimelineDataSource.append((.TimeDifference, nil, variables)) //add last card -> source
                    measurementTimelineLocationIndex.append(-1) //add dummy location -> index
                }
            }
            dispatch_async(dispatch_get_main_queue(), {
                self.measurementTimeline.reloadData() //update UI after dataSource is updated
            })
        }
    }
    
    // MARK: - Collection View
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.measurementTimelineDataSource.count
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("location_card", forIndexPath: indexPath) as! MeasurementTimeline_CollectionViewCell
        cell.cellIndex = indexPath.row //set cellIndex BEFORE the dataSource
        if (indexPath.row == actionCardIndex) { //ACTION card
            if let action = projectAction { //store the project Action in the cell (for display)
                if let custom = action.customActionName { //CUSTOM action
                    cell.projectAction = custom
                } else { //DEFAULT action
                    cell.projectAction = action.action.rawValue
                }
            }
        }
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
        if let cellIndex = notification.object as? Int, info = notification.userInfo, variable = info[BMN_MeasurementTimeline_VariableForSelectionKey] as? String, locationInCycle = info[BMN_MeasurementTimeline_LocationInCycleKey] as? Int { //present alert
            presentMoveVariablePopup(variable, atIndex: cellIndex, fromLocation: locationInCycle)
        }
    }
    
    private func presentMoveVariablePopup(variable: String, atIndex: Int, fromLocation: Int) { //when user selects a cell in collectionView, provide interface to swap reportLocation
        if let indexInSource = projectVariablesIndex.indexOf(variable) { //get array index
            let projectVariable = projectVariables[indexInSource] //reference variable
            let alert = UIAlertController(title: "Change Report Location", message: "Enter the location in the measurement cycle where you would like to move this variable.", preferredStyle: .Alert)
            let cancel = UIAlertAction(title: "Cancel", style: .Cancel, handler: { (let cancel) in
                dispatch_async(dispatch_get_main_queue(), {
                    self.measurementTimeline.reloadData() //reload to refresh views
                })
            })
            let move = UIAlertAction(title: "Move", style: .Default) { (let move) in
                if let text = alert.textFields?.first?.text, number = Int(text) { //make sure input # is an existing location in measurement cycle & is > 1
                    if (number > 0) && !(projectVariable.reportLocations.contains(number)) && (self.doesLocationExistInTimeline(number)) { //make sure the variable is not already reporting @ input location & that input location exists
                        print("Swapping variable [\(projectVariable.variableName)] in cell #\(atIndex) from location [\(fromLocation)] to location [\(number)]...")
                        self.updateLocationsForSwap(indexInSource, atCardIndex: atIndex, fromLocation: fromLocation, toLocation: number) //update locations accordingly
                        self.generateMeasurementTimeline() //update UI for modifications
                    } else { //criteria are NOT met - do NOT swap locations
                        dispatch_async(dispatch_get_main_queue(), {
                            self.measurementTimeline.reloadData() //reload to refresh views
                        })
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
    }
    
    private func doesLocationExistInTimeline(location: Int) -> Bool { //checks if entered loc can be found in the timeline
        var index = 0
        for (_, loc, _) in self.measurementTimelineDataSource {
            if (location == loc) { //match - location EXISTS in cycle!
                return true //return match found
            }
            index += 1
        }
        return false //default is FALSE
    }
    
    private func updateLocationsForSwap(indexForVariable: Int, atCardIndex: Int, fromLocation: Int, toLocation: Int) {
        //(1) Update the location of the variable (@ the given index) that was swapped:
        var moveCount = 1 //counts # of variables that moved during the swap
        let projectVariable = projectVariables[indexForVariable] //get reference to swapped variable
        print("OLD report locations = \(projectVariable.reportLocations).")
        projectVariable.reportLocations.remove(fromLocation) //remove old location
        projectVariable.reportLocations.insert(toLocation) //insert new location
        print("NEW report locations = \(projectVariable.reportLocations).")
        if let comps = self.computations {
            if (comps.contains(projectVariable.variableName)) { //var is part of computation
                moveCount += self.updateLocationsForLinkedVariables(projectVariable.variableName, atLocations: projectVariable.reportLocations) //update linked variable locations
            }
        }
        
        //(2) Update the locations of any DOWNSTREAM cards iff the fromCard is now empty:
        var shiftedDownstream: Bool = false //indicator
        if let index = measurementTimelineLocationIndex.indexOf(fromLocation) {
            if (measurementTimelineDataSource[index].2.count == moveCount) { //loc is EMPTY after swap
                print("Card for location \(fromLocation) = EMPTY after swap! Shifting downstream...")
                shiftedDownstream = true //set indicator
                for (_, location, variables) in measurementTimelineDataSource {
                    if let loc = location {
                        if (loc > fromLocation) { //downstream location
                            print("Found downstream card @ location \(loc)! Shifting variable locs...")
                            for variable in variables { //update locations for vars
                                if let varIndex = projectVariablesIndex.indexOf(variable.name) {
                                    print("BEFORE LOCS = \(projectVariables[varIndex].reportLocations).")
                                    projectVariables[varIndex].reportLocations.remove(loc) //remove old
                                    projectVariables[varIndex].reportLocations.insert(loc-1) //add new
                                    print("AFTER LOCS = \(projectVariables[varIndex].reportLocations).")
                                }
                            }
                        }
                    }
                }
                if let actionIndex = actionCardIndex { //if needed, adjust actionCardIndex
                    if (actionIndex > atCardIndex) { //actionCard is downstream
                        actionCardIndex = actionIndex - 1 //reduce index by 1
                    }
                }
            }
        }
        
        //(3) Update the location of the ORIGINAL var that moved (+ feed-ins) if there was a shift:
        if (shiftedDownstream) && (toLocation > fromLocation) {
            projectVariable.reportLocations.remove(toLocation) //remove old location
            projectVariable.reportLocations.insert((toLocation - 1)) //insert old location - 1
            if let comps = self.computations { //update feed-in/parent locations as well
                if (comps.contains(projectVariable.variableName)) { //var is part of computation
                    self.updateLocationsForLinkedVariables(projectVariable.variableName, atLocations: projectVariable.reportLocations) //update linked variable locations
                }
            }
        }
    }
    
    // MARK: - Time Difference Logic
    
    var selectedTimeDifferenceButtons: (Int?, Int?)? { //holds selections
        didSet {
            if let selections = selectedTimeDifferenceButtons, loc1 = selections.0, loc2 = selections.1 {
                self.presentTimeDifferenceConfigPopup((loc1, loc2)) //generate popup when 2 locs are sel
            }
        }
    }
    
    func measurementTimelineTimeDifferenceButtonWasClicked(notification: NSNotification) {
        if let info = notification.userInfo, cellIndex = notification.object as? Int, selected = info[BMN_MeasurementTimeline_TDButtonStateKey] as? Bool {
            if (selectedTimeDifferenceButtons == nil) { //object is nil
                selectedTimeDifferenceButtons = (nil, nil) //initialize w/ nil locations
            }
            if (selected) { //TD button was SELECTED - add to tuple
                if let _ = selectedTimeDifferenceButtons?.0 { //1st location is already set
                    selectedTimeDifferenceButtons!.1 = cellIndex //set loc2 in object
                } else { //either object is empty OR 2nd location is alrdy set
                    selectedTimeDifferenceButtons!.0 = cellIndex //set loc1 in object
                }
            } else { //TD btn was deselected - clear btn index from tuple
                if let loc1 = selectedTimeDifferenceButtons?.0 {
                    if (loc1 == cellIndex) { //MATCH - remove loc1 from tuple
                        selectedTimeDifferenceButtons!.0 = nil
                    }
                }
                if let loc2 = selectedTimeDifferenceButtons?.1 {
                    if (loc2 == cellIndex) { //MATCH - remove loc2 from tuple
                        selectedTimeDifferenceButtons!.1 = nil
                    }
                }
            }
        }
    }
    
    private func presentTimeDifferenceConfigPopup(locations: (Int, Int)) { //when user selects 2 TD buttons from collection view, this function fires & is used to create a TD var
        if (self.areTimeDifferenceLocationsUnique(locations)) { //create TD ONLY if locs are unique!
            let alert = UIAlertController(title: "Time Difference Variable", message: "Would you like this time difference variable to be an input or outcome measure?", preferredStyle: .Alert)
            let (temp1, temp2) = locations
            let loc1: Int
            let loc2: Int
            if (temp1 < temp2) { //sort such that loc1 < loc2
                loc1 = temp1
                loc2 = temp2
            } else {
                loc1 = temp2
                loc2 = temp1
            }
            let input = UIAlertAction(title: "Input", style: .Default) { (let input) in
                self.createTimeDifferenceVariableWithName("TD: (\(loc1)->\(loc2))", configType: .InputVariable, locations: locations)
            }
            let outcome = UIAlertAction(title: "Outcome", style: .Default) { (let outcome) in
                self.createTimeDifferenceVariableWithName("TD: (\(loc1)->\(loc2))", configType: .OutcomeMeasure, locations: locations)
            }
            alert.addAction(input)
            alert.addAction(outcome)
            presentViewController(alert, animated: true, completion: nil)
        } else { //selections are NOT unique - refresh view
            dispatch_async(dispatch_get_main_queue(), { 
                self.measurementTimeline.reloadData() //reload to refresh views
            })
        }
        self.selectedTimeDifferenceButtons = nil //*clear for next cycle*
    }
    
    private func createTimeDifferenceVariableWithName(name: String, configType: ModuleConfigurationTypes, locations: (Int, Int)) { //locations = (loc1, loc2) between which TD is measured
        let tdVar = CustomModule(timeDifferenceName: name, locations: locations, configType: configType)
        if (timeDifferenceVariables == nil) { //variable does NOT exist yet
            deferDataSourceConstruction = true //block dataSource generation
            timeDifferenceVariables = [] //initialize
            deferDataSourceConstruction = false //unblock after initializing
        }
        timeDifferenceVariables!.append(tdVar) //add new item -> array
    }
    
    private func areTimeDifferenceLocationsUnique(locations: (Int, Int)) -> Bool { //checks if combination of entered locations for a TD var is unique
        if let tdVars = timeDifferenceVariables {
            for tdVar in tdVars {
                if let castVar = tdVar as? CustomModule, setup = castVar.timeDifferenceSetup, existingLocs = setup.1 {
                    let existingLocations = [existingLocs.0, existingLocs.1]
                    if (existingLocations.contains(locations.0)) && (existingLocations.contains(locations.1)) {
                        print("Entered locations [\(locations.0, locations.1)] are already set for another TD!")
                        return false //a TD var contains BOTH of the entered locations
                    }
                }
            }
        }
        return true
    }
    
    private func isNameUnique(name: String) -> Bool { //check if entered name is unique
        for variable in projectVariables { //search in master list
            if (variable.variableName.lowercaseString == name.lowercaseString) {
                return false
            }
        }
        return true //default return option
    }
    
    func measurementTimelineShouldDeleteTimeDifferenceVariable(notification: NSNotification) {
        if let index = notification.object as? Int, _ = self.timeDifferenceVariables { //get index of TD that was selected
            let alert = UIAlertController(title: "Delete Time Difference?", message: "Do you want to delete this time difference variable?", preferredStyle: .Alert)
            let cancel = UIAlertAction(title: "Cancel", style: .Cancel, handler: { (let cancel) in
                dispatch_async(dispatch_get_main_queue(), {
                    self.measurementTimeline.reloadData() //reload to refresh views
                })
            })
            let delete = UIAlertAction(title: "Delete", style: .Destructive, handler: { (let delete) in
                self.timeDifferenceVariables!.removeAtIndex(index) //delete item
            })
            alert.addAction(cancel)
            alert.addAction(delete)
            presentViewController(alert, animated: false, completion: nil)
        }
    }
    
    private func deleteTimeDifferencesAtLocation(location: Int) { //removes all TD vars that are connected to the input location
        print("Removing TD vars linked to input location [\(location)]...")
        if let tdVars = timeDifferenceVariables {
            var indicesToRemove: [Int] = [] //stores indices of TD vars to remove
            var loopCount = 0
            for tdVar in tdVars {
                if let castVar = tdVar as? CustomModule, setup = castVar.timeDifferenceSetup, existingLocs = setup.1 {
                    if (existingLocs.0 == location) || (existingLocs.1 == location) {
                        print("TD var [\(castVar.variableName)] will be removed!")
                        indicesToRemove.append(loopCount) //add index -> array for deletion
                    }
                }
                loopCount += 1 //increment
            }
            let reverseSortedIndices = indicesToRemove.sort().reverse() //get indices in desc. order
            self.deferDataSourceConstruction = true //block fx until AFTER all deletions are complete
            for index in reverseSortedIndices { //remove TD vars from last -> first
                timeDifferenceVariables!.removeAtIndex(index) //delete TD var from array
                print("Removed TD var @ index \(index)!")
            }
            self.deferDataSourceConstruction = false //remove blocker
        }
    }
    
    // MARK: - Table View
    
    var tableViewTitles = ["Project Title".uppercaseString, "Research Question".uppercaseString, "Project Hypothesis".uppercaseString, "Endpoint".uppercaseString, "Control Group(s)".uppercaseString, "Comparison Group(s)".uppercaseString] //header dataSource
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if (projectType == .ControlComparison) { //CC project - add 2 extra sections
            return 6 //last 2 sections are to list control & comparison groups
        }
        return 4
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return tableViewTitles[section]
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
            print("[TV #OfRowsInSection] Error - default in switch!")
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
        case 3: //project Endpoint
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
        case 4: //names of Control groups
            if let controls = ccProjectControls {
                cell.textLabel?.text = controls[indexPath.row]
            }
        case 5: //names of Comparison groups
            if let comparisons = ccProjectComparisons {
                cell.textLabel?.text = comparisons[indexPath.row]
            }
        default: //should NOT trigger
            print("[TV cellForRow] Error - default in switch.")
        }
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) { //allow user to edit setup directly by clicking on the cell
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
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        if (indexPath.row == 4) { //allow deletion of Control groups (except last)
            return .Delete //count # of items in source
        } else if (indexPath.row == 5) { //allow Comparison deletion (except last)
            return .Delete //count # of items in source
        }
        return .None
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if (indexPath.row == 4) { //allow deletion of Control groups (except last)
            //update dataSource
        } else if (indexPath.row == 5) { //allow Comparison deletion (except last)
            //update dataSource
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
        
        //(2) Construct Project & its Groups:
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
                    if let action = projectAction {
                        let variablesDict = createCoreDataDictionary(projectVariables, project: project)
                        var timeDifferenceDict = Dictionary<String, [String: AnyObject]>()
                        if let timeDifferenceVars = timeDifferenceVariables { //check for TD vars
                            timeDifferenceDict = createCoreDataDictionary(timeDifferenceVars, project: project) //construct CD representation
                        }
                        let _ = Group(groupName: groupName, groupType: groupType, project: project, action: action, variables: variablesDict, cycleLength: measurementCycleLength, timeDifferenceVars: timeDifferenceDict, insertIntoManagedObjectContext: context) //create group
                        print("Created group [\(groupName)] of type [\(groupType)].")
                    }
                }
            }
            saveManagedObjectContext() //save new project & group(s) -> CoreData
            
            //(3) Create cloud backup for the new project & add it to queue:
            if let dbConnection = DatabaseConnection() {
                if (isEditProjectFlow) { //EDIT PROJECT flow - update project's DB information
//                    dbConnection.commitProjectEditToDatabase(project) //create update cmd
                } else { //DEFAULT flow - create Cloud backup
//                    dbConnection.createCloudModelForProject(project) //create backup & save to CD
                }
            }
        }
        
        //(4) Return to homescreen after operation is complete:
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