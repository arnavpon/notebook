//  ExM_WorkoutConfigurationCell.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 7/16/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Exercise Module - cell that allows for configuration of a single workout (allows addition of individual exercises to the workout).

import UIKit

enum ExerciseTypes: Int {
    case WeightTraining = 0
    case Cardio = 1
}

class ExM_WorkoutConfigurationCell: BaseConfigurationCell, UITableViewDelegate, UITableViewDataSource { //add new class -> enum!
    
    override class var numberOfLevels: Int { //default # of levels is 1
        return 1 //for each available option in dataSource, add 1 level (unless cell is Bool type)
    }
    
    private var popupView: PopupView? {
        didSet {
            popupView?.removeFromSuperview()
            if let popup = popupView {
                self.insetBackgroundView.addSubview(popup)
            }
        }
    }
    private let exercisesTableView = UITableView(frame: CGRectZero)
    private var exercises: [[String: AnyObject]] = [] { //return object = ARRAY of Dicts
        didSet {
            if !(exercises.isEmpty) { //cell requires at least 1 exercise to be complete
                configureCompletionIndicator(true)
            } else { //INCOMPLETE
                configureCompletionIndicator(false)
            }
        }
    }
    private let defaultBackgroundColor = UIColor(red: 248/255, green: 1, blue: 235/255, alpha: 1)
    
    // MARK: - Initializers
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        //Configure R side button:
        firstLevelRightButton = UIButton()
        firstLevelRightButton!.addTarget(self, action: #selector(self.addExerciseButtonClick(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        firstLevelRightButton?.setImage(UIImage(named: "plus_square"), forState: .Normal)
        insetBackgroundView.addSubview(firstLevelRightButton!)
        
        //Configure TV:
        insetBackgroundView.addSubview(exercisesTableView)
        exercisesTableView.delegate = self
        exercisesTableView.dataSource = self
        exercisesTableView.scrollEnabled = false //block scrolling
        exercisesTableView.registerClass(ExerciseTableViewCell.self, forCellReuseIdentifier: NSStringFromClass(ExerciseTableViewCell))
        
        //Register for notification:
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.popupViewActionWasTriggered(_:)), name: BMN_Notification_PopupViewActionWasTriggered, object: self.popupView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Visual Layout
    
    override func setNeedsLayout() {
        super.setNeedsLayout()
        
        //Layout TV according to the # of items in exercises:
        let count = exercises.count
        exercisesTableView.frame = getViewFrameForLevel(viewLevel: (2, HorizontalLevels.FullLevel, count))
    }
    
    // MARK: - Table View
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return exercises.count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 40 //height matches height of 1 level
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(NSStringFromClass(ExerciseTableViewCell)) as! ExerciseTableViewCell
        print("Count = \(exercises.count)")
        var exerciseSettings = exercises[indexPath.row]
        print("Settings: \(exerciseSettings["name"]).")
        let count = indexPath.row + 1
        exerciseSettings.updateValue(count, forKey: "count") //add count -> dataSource
        cell.dataSource = exerciseSettings //set dataSource
        cell.linkedCell = self //link to parent cell
        cell.backgroundColor = defaultBackgroundColor
        return cell
    }
    
    func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        //enable editing of the settings (bring up popup view)
        return false //block selection
    }
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return .Delete
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        print("Deleting at index: \(indexPath.row).")
        exercises.removeAtIndex(indexPath.row) //update data source
        tableView.reloadData()
        
        //Update cell height:
        let notification = NSNotification(name: BMN_Notification_AdjustHeightForConfigCell, object: nil, userInfo: [BMN_AdjustHeightForConfigCell_UniqueIDKey: self.cellDescriptor, BMN_AdjustHeightForConfigCell_NumberOfLevelsKey: (exercises.count + 1)]) //# of levels = tableView cells + 1
        NSNotificationCenter.defaultCenter().postNotification(notification)
    }
    
    // MARK: - Button Actions
    
    var formingObject: (String, Int?, AnyObject?)? //sequentially built exercise object
    
    @IBAction func addExerciseButtonClick(sender: UIButton) { //configure pop-up to add exercise
        //(1) Configure popup to enter exercise name:
        let popupLevels = 3 //# of levels for popupView
        let popupFrame = CGRectMake(0, 0, insetBackgroundView.frame.width, (CGFloat(popupLevels) * 40 + BMN_DefaultBottomSpacer))
        self.popupView = PopupView(frame: popupFrame, type: .StringInput, settings: ["prompt": "Enter the exercise name"])
        let notification = NSNotification(name: BMN_Notification_AdjustHeightForConfigCell, object: nil, userInfo: [BMN_AdjustHeightForConfigCell_UniqueIDKey: self.cellDescriptor, BMN_AdjustHeightForConfigCell_NumberOfLevelsKey: popupLevels]) //when popup is active, constrain levels
        NSNotificationCenter.defaultCenter().postNotification(notification)
    }
    
    func popupViewActionWasTriggered(notification: NSNotification) {
        let popupFrame = CGRectMake(0, 0, insetBackgroundView.frame.width, insetBackgroundView.frame.height)
        if let popup = popupView, output = popup.getDataForPopupView() {
            self.popupView?.removeFromSuperview() //clear previous popup
            self.popupView = nil //clear popup
            if let object = formingObject {
                if let rawType = object.1, type = ExerciseTypes(rawValue: rawType) { //(3) inc. setting
                    switch type {
                    case .WeightTraining:
                        if let setsRaw = output as? String, sets = Int(setsRaw) {
                            exercises.append(["name": object.0, "type": rawType, "sets": sets])
                        }
                    case .Cardio:
                        if let hrSource = output as? String {
                            exercises.append(["name": object.0, "type": rawType, "hrSource": hrSource])
                        }
                    }
                    formingObject = nil //clear for next set
                    exercisesTableView.reloadData()

                    //Update cell height:
                    let notification = NSNotification(name: BMN_Notification_AdjustHeightForConfigCell, object: nil, userInfo: [BMN_AdjustHeightForConfigCell_UniqueIDKey: self.cellDescriptor, BMN_AdjustHeightForConfigCell_NumberOfLevelsKey: (exercises.count + 1)]) //# of levels = tableView cells + 1
                    NSNotificationCenter.defaultCenter().postNotification(notification)
                } else { //(2) incoming exercise TYPE
                    if let rawType = output as? String {
                        let type: ExerciseTypes
                        if (rawType == "Weight Training") {
                            type = .WeightTraining
                            formingObject = (object.0, type.rawValue, nil)
                            self.popupView = PopupView(frame: popupFrame, type: .IntegerInput, settings: ["prompt": "Enter the number of sets"]) //get # of sets
                        } else if (rawType == "Cardio") {
                            type = .Cardio
                            formingObject = (object.0, type.rawValue, nil)
                            self.popupView = PopupView(frame: popupFrame, type: .AorB, settings: ["prompt": "Choose a Heart Rate Source", "aButtonTitle": "Apple Watch", "bButtonTitle": "FitBit"]) //get heart rate source
                        }
                    }
                }
            } else { //(1) incoming exercise NAME
                if let typedOutput = output as? String {
                    formingObject = (typedOutput, nil, nil)
                    self.popupView = PopupView(frame: popupFrame, type: .AorB, settings: ["prompt": "Choose an exercise type", "aButtonTitle": "Weight Training", "bButtonTitle": "Cardio"])
                }
            }
        }
    }
    
    // MARK: - Data Reporting
    
    func updateDataSourceAtIndex(index: Int, withValue value: (String, String?)) { //updates dataSource w/ (name, sets); returns True (change allowed) or False (not allowed)
        print("Updating key [name] with value [\(value.0)] & sets w/ [\(value.1)] @ index \(index).")
        if let typeRaw = exercises[index]["type"] as? Int, type = ExerciseTypes(rawValue: typeRaw) {
            self.exercises[index].updateValue(value.0, forKey: "name")
            switch type {
            case .WeightTraining:
                if let setsRaw = value.1 {
                    if !(setsRaw.isEmpty) { //NOT empty
                        if let sets = Int(setsRaw) {
                            self.exercises[index].updateValue(sets, forKey: "sets")
                        }
                    } else { //empty value -> update w/ 0 value
                        self.exercises[index].updateValue(0, forKey: "sets")
                    }
                }
            case .Cardio: //no set value to update
                break
            }
        }
        if let name = exercises[index]["name"] as? String, sets = exercises[index]["sets"] as? Int {
            if !(name.isEmpty) && (sets > 0) { //BOTH values are set
                configureCompletionIndicator(true)
                return
            }
        }
        configureCompletionIndicator(false) //NOT complete -> false
    }
    
    override var configurationReportObject: AnyObject? { //checks the currently highlighted button & reports TRUE for 'yes', FALSE for 'no'
        //*REPORT TYPE: [[String: AnyObject]]*
        return exercises
    }
    
}

class ExerciseTableViewCell: UITableViewCell, UITextFieldDelegate { //cell to display Exercise
    
    var fireCounter: Int = 0 //blocks dataSource firing > 1x
    var linkedCell: ExM_WorkoutConfigurationCell?
    var dataSource: [String: AnyObject]? { //contains cell settings
        didSet {
            if let source = dataSource, count = source["count"] as? Int, name = source["name"] as? String, typeRaw = source["type"] as? Int, type = ExerciseTypes(rawValue: typeRaw) {
                countLabel.text = "\(count)."
                nameTextField.text = name
                switch type {
                case .WeightTraining:
                    exerciseTypeLabel.text = "[W]"
                case .Cardio:
                    exerciseTypeLabel.text = "[C]"
                }
                if let sets = source["sets"] as? Int { //check for # of sets
                    settingsTextField.text = "\(sets)"
                    settingsLabel.text = "Sets"
                } else {
                    settingsTextField.text = nil
                    settingsLabel.text = nil
                }
                setNeedsLayout() //update visuals
            }
        }
    }
    
    let countLabel = UILabel(frame: CGRectZero)
    let nameTextField = UITextField(frame: CGRectZero)
    let exerciseTypeLabel = UILabel(frame: CGRectZero)
    let settingsTextField = UITextField(frame: CGRectZero)
    let settingsLabel = UILabel(frame: CGRectZero)
    
    // MARK - Initializers
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.addSubview(countLabel)
        self.addSubview(nameTextField)
        self.addSubview(exerciseTypeLabel)
        self.addSubview(settingsTextField)
        self.addSubview(settingsLabel)
        
        countLabel.textAlignment = .Center
        nameTextField.delegate = self
        nameTextField.textColor = UIColor.redColor()
        nameTextField.borderStyle = .RoundedRect
        
        settingsTextField.delegate = self
        settingsTextField.keyboardType = .NumberPad
        settingsTextField.textAlignment = .Center
        settingsTextField.borderStyle = .RoundedRect
        settingsTextField.textColor = UIColor.redColor()
        settingsLabel.textAlignment = .Center
        
        exerciseTypeLabel.font = UIFont.boldSystemFontOfSize(15)
        exerciseTypeLabel.textColor = UIColor.blueColor()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Visual Layout
    
    override func setNeedsLayout() {
        super.setNeedsLayout()
        var showSettings: Bool = false
        if (settingsTextField.text != "") {
            showSettings = true
        }
        //Arrange labels in order - count - name - type - settingsTF(?) - settingsLbl(?):
        let horizontalSpacer: CGFloat = 3
        let countLblWidth: CGFloat = 20
        let typeLblWidth: CGFloat = 27
        let settingsTFWidth: CGFloat = 30
        let remainder = self.frame.width - countLblWidth - typeLblWidth - settingsTFWidth - horizontalSpacer * 4
        exerciseTypeLabel.frame = CGRectMake(horizontalSpacer, 0, typeLblWidth, self.frame.height)
        countLabel.frame = CGRectMake((exerciseTypeLabel.frame.maxX + horizontalSpacer), 0, countLblWidth, self.frame.height)
        if (showSettings) { //show settings lbl & TF
            nameTextField.frame = CGRectMake((countLabel.frame.maxX + horizontalSpacer), 0, (remainder * 0.65), self.frame.height)
            settingsTextField.frame = CGRectMake((nameTextField.frame.maxX + horizontalSpacer), 0, settingsTFWidth, self.frame.height)
            settingsLabel.frame = CGRectMake(settingsTextField.frame.maxX, 0, (self.frame.width - settingsTextField.frame.maxX), self.frame.height)
        } else { //hide settings lbl & TF
            nameTextField.frame = CGRectMake((countLabel.frame.maxX + horizontalSpacer), 0, (remainder + horizontalSpacer + settingsTFWidth), self.frame.height) //nameTF takes up 100% of remaining width
            settingsTextField.frame = CGRectZero
            settingsLabel.frame = CGRectZero
        }
    }
    
    // MARK: - Text Field
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        if let name = nameTextField.text {
            var returnTuple: (String, String?) = (name, settingsTextField.text) //name, sets
            if let text = textField.text, source = dataSource, count = source["count"] as? Int {
                let finalText = (text as NSString).stringByReplacingCharactersInRange(range, withString: string).stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                if (textField == nameTextField) { //update 'name'
                    returnTuple.0 = finalText
                    self.linkedCell?.updateDataSourceAtIndex((count - 1), withValue: returnTuple)
                } else if (textField == settingsTextField) { //update 'sets'
                    returnTuple.1 = finalText
                    self.linkedCell?.updateDataSourceAtIndex((count - 1), withValue: returnTuple)
                }
            }
        }
        return true
    }
    
}