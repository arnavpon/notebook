//  ExM_WorkoutDataEntryCell.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 8/24/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Exercise Module > cell that allows for set-by-set reporting of workout data. 

import UIKit

enum ExerciseTypes: Int {
    case WeightTraining = 0
    case Cardio = 1
}

class ExM_WorkoutDataEntryCell: FreeformDataEntryCell, DataEntry_PopupConfigurationViewProtocol { //add new class -> enum!
    
    override class var numberOfLevels: Int { //default # of levels is ??
        return 3 //**
    }
    
    var sender: DataEntryProtocol_ConformingClasses? //indicates which object generated this cell
    var cellType: DataEntryCellTypes = DataEntryCellTypes.ExM_Workout //protocol property
    lazy var datastream = ExM_ExerciseDataStream.sharedInstance //get reference to Workout stream
    
    private let configurationView = DataEntry_PopupConfigurationView(frame: CGRectZero) //popup
    private var currentLocationInFlow: Int? { //controls which popups to generate - loc1 = cachePopup (ONLY for Project class); loc2 = exercise selection (Wt. Lift vs. Cardio); loc3+ = exercise config
        didSet {
            if let minimum = minimumLocation, currentLocation = currentLocationInFlow {
                if (currentLocation == minimum) { //hide backBtn
                    configurationView.shouldDisplayBackButton = false
                } else { //reveal backBtn
                    configurationView.shouldDisplayBackButton = true
                }
            }
        }
    }
    private var displayedOptions: [AnyObject]? //stores reference to presented options
    private var minimumLocation: Int? //min location in flow - depends on sender class
    private var currentExercise: String? //stores reference to active exercise
    private var currentExerciseType: ExerciseTypes? //maintains ref to current exercise type
    private lazy var weightTrainingExercises: [String] = ["Bicep Curl", "Tricep Extension", "Tricep Pulldown", "Shoulder Press", "Squat", "Standard Pushup", "Diamond Pushup", "Wide Grip Pullup", "Chinup", "Narrow Grip Pullup"] //datasource(1) for searchBar
    private lazy var cardioExercises: [String] = ["Run", "Treadmill", "Elliptical", "Stair Climbing", "Walk", "Row", "Swim"] //datasource(2) for searchBar
    
    private var heartRateSource: String? //stores HR source for workout w/ multiple Cardio exercises **
    
    // MARK: - Initializers
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        //Configure optionSelectionView:
        insetBackgroundView.addSubview(configurationView) //configView lies on TOP of freeform views
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func accessDataSource() {
        if let _ = self.module as? ExerciseModule, senderClass = sender { //set locationBounds for sender
            if let (exercise, exerciseType, (total, current)) = datastream.getCurrentExerciseFromDatastream() { //OPEN exercise - present Freeform data entry cells
                self.currentExerciseType = exerciseType
                self.currentExercise = exercise
                var mainLabelText = "" //text to set for mainlbl
                switch exerciseType { //generate label appropriate for exerciseType
                case .WeightTraining:
                    mainLabelText = "['\(exercise)' - Set #\(current)/\(total)] Enter weight lifted/# of reps after completing the set:"
                case .Cardio:
                    mainLabelText = "['\(exercise)'] Enter the time, distance traveled, and # of calories burned after completing the exercise:"
                }
                self.setMainLabelTitle(mainLabelText) //update main Lbl
                generateFreeformCellsForExerciseType() //draw freeform views
            } else { //NO currently open exercise - present ConfigView
                if (senderClass == .Project) { //sender is 'Project' class - ask user to select between cached object & opening a new stream
                    if let _ = self.datastream.temporaryStorageObject { //TSO EXISTS
                        self.minimumLocation = 2 //minimum starts @ 2 (exercise selection)
                    } else { //TSO does NOT exist
                        self.minimumLocation = 1 //minimum starts @ 1 (cache selection)
                    }
                } else if (senderClass == .Datastream) { //sender is 'Datastream' class - immediately open the new stream
                    self.minimumLocation = 2 //minimum starts @ 2 (exercise selection)
                }
                displayConfigurationViewForLocation(self.minimumLocation!) //show configView @ 1st loc
            }
        }
    }
    
    // MARK: - Visual Layout
    
    override func setNeedsLayout() {
        super.setNeedsLayout() //layout Freeform cell views
        
        //Layout optionSelectionView so that it covers the entire cell when visible:
        configurationView.frame = CGRectMake(0, 0, self.frame.width, self.frame.height)
    }
    
    private func displayConfigurationViewForLocation(location: Int) -> Int { //updates configView based on the input location; returnObject = # of levels required for the configured view
        var numberOfLevels: Int = 0 //indicates height for returned view
        switch location {
        case 1: //allow user to select between opening a new stream or using cached data - ONLY displayed for Project sender class & if stream's TSO is nil
            if let cache = self.datastream.cachedData {
                if !(cache.isEmpty) { //cached objects exist - present collectionView
                    var source = ["Start New Workout!"] //options to display in collectionView
                    var cacheOptions: [NSDate] = []
                    for (workoutDate, _) in cache { //get date of each workout in cache
                        let formattedDate = DateTime(date: workoutDate).getFullTimeStamp()
                        let option = "Workout on \(formattedDate)"
                        source.append(option) //add -> options
                        cacheOptions.append(workoutDate) //add NSDate -> cacheOptions
                    }
                    self.displayedOptions = cacheOptions //set temporary reference
                    self.configurationView.configurePopupViewWithDataSource(DataEntry_PopupConfigurationViewTypes.CollectionView, dataSource: source, instructions: "Start a new workout OR use a previous workout's data")
                    numberOfLevels = 3 //**
                } else { //no cached objects - automatically open a new stream
                    self.valueWasReturnedByUser(0) //return index of 1st option in source
                }
            }
        case 2: //exerciseType selection
            var source = ["Weight Lifting Exercise", "Cardio Exercise"]
            var instructions = "Choose a new exercise type"
            if let _ = self.datastream.temporaryStorageObject { //user also has option to CLOSE stream @ this point IFF some data has already been entered
                source.append("End Current Workout!")
                instructions.appendContentsOf(" OR end the workout at this time")
            }
            self.configurationView.configurePopupViewWithDataSource(DataEntry_PopupConfigurationViewTypes.CollectionView, dataSource: source, instructions: instructions)
            numberOfLevels = 3 //**
        case 3: //exercise NAME selection
            if let exerciseType = currentExerciseType {
                let source: [String]
                switch exerciseType { //set the dataSource based on the exerciseType
                case .WeightTraining:
                    source = self.weightTrainingExercises
                case .Cardio:
                    source = self.cardioExercises
                }
                self.configurationView.configurePopupViewWithDataSource(DataEntry_PopupConfigurationViewTypes.SearchBar, dataSource: source, instructions: "Search for an exercise")
                numberOfLevels = 4 //**
            }
        case 4: //Wt. Lift - enter the # of sets; Cardio - select the HR source(?)
            if let exerciseType = currentExerciseType {
                switch exerciseType {
                case .WeightTraining:
                    self.configurationView.configurePopupViewWithDataSource(DataEntry_PopupConfigurationViewTypes.SimpleNumberEntry, dataSource: nil, instructions: "Enter the number of sets for the exercise")
                    numberOfLevels = 2 //**
                case .Cardio:
                    let hrOptions = [BiometricModule_DataSourceOptions.AppleWatch.rawValue, BiometricModule_DataSourceOptions.FitBit.rawValue]
                    self.configurationView.configurePopupViewWithDataSource(DataEntry_PopupConfigurationViewTypes.CollectionView, dataSource: hrOptions, instructions: "Select a HR source???")
                    numberOfLevels = 4 //**
                }
            }
            numberOfLevels = 3 //**
        default:
            print("[displayConfigView] Error - default in switch!")
            break //should never be called
        }
        self.currentLocationInFlow = location //LAST - set new location
        return numberOfLevels
    }
    
    private func generateFreeformCellsForExerciseType() { //generates appropriate view for DataEntry
        if let currentType = self.currentExerciseType {
            self.currentLocationInFlow = nil //update indicator; nil => FREEFORM display
            var configurationObject: [(String?, ProtectedFreeformTypes?, String?, Int?, (Double?, Double?)?, String?)] = []
            switch currentType {
            case .WeightTraining: //need fields for weight lifted & # of reps
                configurationObject.append(("lbs.", ProtectedFreeformTypes.Decimal, nil, 6, (0, 999), nil)) //weight cell
                configurationObject.append(("Reps", ProtectedFreeformTypes.Int, nil, 2, (0, 99), nil)) //# of reps cell
            case .Cardio: //need fields for time, distance, & calories
                configurationObject.append(("Time", ProtectedFreeformTypes.Timing, nil, 11, nil, "HH:MM:SS.ms")) //time cell
                configurationObject.append(("miles", ProtectedFreeformTypes.Decimal, nil, 5, (0, 99), nil)) //distance cell
                configurationObject.append(("kCal", ProtectedFreeformTypes.Decimal, nil, 6, (0, 1999), nil)) //calories cell
            }
            self.labelBeforeField = false //set indicator FIRST - lbl comes AFTER field
            self.freeformViewsConfigObject = configurationObject //set config object (triggers layout fx)
        }
    }
    
    private func adjustHeightForCell(numberOfLevels: Int) { //adjusts # of levels for cell
        //Support dynamic height adjustment for DEVC - this view can have variable # of Freeform objects + the selection options take up different amount of space. Change the dictionary object in the enum object switch & then indicate to VC to redraw cells w/ new height?
        let notification = NSNotification(name: BMN_Notification_AdjustHeightForConfigCell, object: nil, userInfo: [BMN_AdjustHeightForConfigCell_UniqueIDKey: "", BMN_AdjustHeightForConfigCell_NumberOfLevelsKey: numberOfLevels]) //**
        NSNotificationCenter.defaultCenter().postNotification(notification)
    }
    
    // MARK: - Protocol Logic
    
    func backButtonWasClicked() { //navigate to the previous location in flow
        if let currentLocation = self.currentLocationInFlow, minLocation = minimumLocation {
            if !(currentLocation <= minLocation) { //safety check
                displayConfigurationViewForLocation((currentLocation - 1)) //move 1 spot back in flow
            }
        }
    }
    
    func valueWasReturnedByUser(value: AnyObject) {
        print("[ExM_Cell] Returned value = [\(value)].")
        if let currentLocation = self.currentLocationInFlow { //handling of value depends on loc
            switch currentLocation { //cast value according to location
            case 1: //returnValue is INDEX of selected option in dataSource
                if let index = value as? Int, options = self.displayedOptions as? [NSDate] { //0 => start new workout, index > 0 => pick item from cache
                    if (index > 0) { //obtain item from cache
                        if let cache = self.datastream.cachedData {
                            let indexInArray = index - 1 //shift indices down by 1
                            let selectedWorkout = options[indexInArray] //get date
                            self.module?.mainDataObject = cache[selectedWorkout] //set data -> module
                            self.configureCompletedCellVisuals() //complete cell
                        }
                    } else { //open new stream (happens naturally as user proceeds through flow)
                        self.displayConfigurationViewForLocation((currentLocation + 1)) //move -> next
                    }
                    self.displayedOptions = nil //clear reference
                }
            case 2: //returnValue is INDEX of selected option in dataSource
                if let index = value as? Int { //0 => Weight Training, 1 => Cardio, 2? => End Workout
                    if let exerciseType = ExerciseTypes(rawValue: index) {
                        self.currentExerciseType = exerciseType
                        self.displayConfigurationViewForLocation((currentLocation + 1)) //move -> next
                    } else { //user chose to end workout - close stream & store full data
                        self.module?.mainDataObject = self.datastream.closeCurrentDatastream()
                        self.configureCompletedCellVisuals() //complete cell
                    }
                }
            case 3: //return value is selected exercise's name (STRING)
                if let exercise = value as? String {
                    self.currentExercise = exercise //set reference
                    self.displayConfigurationViewForLocation((currentLocation + 1)) //move -> next
                }
            case 4: //logic depends on exercise type
                if let type = self.currentExerciseType { //create CURRENT exercise & display Freeform clls
                    switch type {
                    case .WeightTraining: //get the # of sets
                        if let number = value as? Int, exercise = self.currentExercise, type = self.currentExerciseType {
                            self.datastream.setCurrentlyOpenExerciseInStream(exercise, type: type, numberOfSets: number) //create new exercise in stream
                        }
                    case .Cardio: //get the HR source
                        if let optionRaw = value as? String, _ = BiometricModule_DataSourceOptions(rawValue: optionRaw), exercise = self.currentExercise, type = self.currentExerciseType { //**how to use HR source???
                            self.datastream.setCurrentlyOpenExerciseInStream(exercise, type: type, numberOfSets: 1) //create new exercise in stream
                        }
                    }
                    self.configurationView.hidden = true //hide popup view
                    self.generateFreeformCellsForExerciseType() //generate freeform views
                }
            default: //should never be called
                print("[valueWasReturned] Error - default in switch!")
                break
            }
        }
    }
    
    private func configureCompletedCellVisuals() { //called when user either selects from the cache or manually closes the datastream
        self.configurationView.hidden = true //hide configView
        self.setMainLabelTitle("Cell is COMPLETE!") //set visuals in mainLbl
        self.adjustHeightForCell(1) //shrink cell
        self.configureCompletionIndicator(true) //enable 'Done' btn
    }
    
    // MARK: - Data Reporting
    
    override func updateModuleReportObject() { //updates the Module dataSource's report object
        if let mod = self.module, type = self.currentExerciseType {
            var reportObject = Dictionary<String, AnyObject>()
            switch type { //construct a dict using the reported values
            case .WeightTraining: //1 = weight lifted, 2 = # of reps
                reportObject["weightLifted"] = self.moduleReportObject[0]
                reportObject["numberOfRepetitions"] = self.moduleReportObject[1]
                mod.mainDataObject = reportObject //update w/ converted value
            case .Cardio: //1 = time, 2 = distance, 3 = calories burned
                reportObject["time"] = self.moduleReportObject[0]
                reportObject["distance"] = self.moduleReportObject[1]
                reportObject["calories"] = self.moduleReportObject[2]
                mod.mainDataObject = reportObject //update w/ converted value
            }
        }
    }
    
}