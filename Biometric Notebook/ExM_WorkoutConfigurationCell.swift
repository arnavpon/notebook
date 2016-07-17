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
        exercisesTableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
//        exercisesTableView.registerClass(ExerciseTableViewCell.self, forCellReuseIdentifier: NSStringFromClass(ExerciseTableViewCell))
        
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
//        let cell = tableView.dequeueReusableCellWithIdentifier(NSStringFromClass(ExerciseTableViewCell)) as! ExerciseTableViewCell
        let cell = tableView.dequeueReusableCellWithIdentifier("cell")!
        let count = indexPath.row + 1
        let exerciseSettings = exercises[indexPath.row]
        if let name = exerciseSettings["name"] as? String, typeRaw = exerciseSettings["type"] as? Int, type = ExerciseTypes(rawValue: typeRaw) {
            let length = name.characters.count
            var truncatedName = name
            if (length > 15) {
                truncatedName = (name as NSString).substringToIndex(15) + "..." //shorten name to fit
            }
            var typeIndicator: String
            switch type {
            case .WeightTraining:
                typeIndicator = "[Weight]"
                if let sets = exerciseSettings["sets"] as? Int {
                    typeIndicator += " <\(sets) Sets>"
                }
            case .Cardio:
                typeIndicator = "[Cardio]"
            }
            cell.textLabel?.text = "\(count).  \(truncatedName)  \(typeIndicator)"
        }
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
    
    override var configurationReportObject: AnyObject? { //checks the currently highlighted button & reports TRUE for 'yes', FALSE for 'no'
        //*REPORT TYPE: [[String: AnyObject]]*
        return exercises
    }
    
}

class ExerciseTableViewCell: UITableViewCell { //cell to display Exercise
    
    var dataSource: [String: AnyObject]? { //contains cell settings
        didSet {
            if let source = dataSource {
                setNeedsLayout()
            }
        }
    }
    var name: String?
    var type: ExerciseTypes?
    
    let nameLabel = UILabel(frame: CGRectZero)
    let exerciseTypeLabel = UILabel(frame: CGRectZero)
    
    // MARK - Initializers
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Visual Layout
    
    override func setNeedsLayout() {
        //
    }
    
}

enum PopupTypes {
    case AorB //select from 2 options
    case StringInput //textField w/ String input
    case IntegerInput //textField w/ Int input
}

class PopupView: UIView, UITextFieldDelegate {
    
    let type: PopupTypes
    let topLabel = UILabel(frame: CGRectZero)
    let mainView = UIView(frame: CGRectZero)
    
    //AorB Views:
    var aButton: UIButton?
    var bButton: UIButton?
    var centerLabel: UILabel?
    var selectedButton: String? //indicates selection
    
    //Integer/String Input Views:
    var inputTextField: UITextField?
    var okButton: UIButton?
    
    // MARK: - Initializers
    
    init(frame: CGRect, type: PopupTypes, settings: [String: String]) { //init w/ objectType & settings
        self.type = type
        super.init(frame: frame)
        
        self.clipsToBounds = true
        self.backgroundColor = UIColor.whiteColor()
        self.addSubview(topLabel)
        topLabel.backgroundColor = UIColor(red: 0, green: 55/255, blue: 235/255, alpha: 1)
        topLabel.textColor = UIColor.whiteColor()
        topLabel.text = settings["prompt"]
        topLabel.textAlignment = .Center
        
        switch type { //instantiate views specific to type
        case .AorB:
            aButton = UIButton(frame: CGRectZero)
            aButton?.backgroundColor = UIColor.redColor()
            aButton?.setTitle(settings["aButtonTitle"], forState: .Normal)
            aButton?.addTarget(self, action: #selector(self.buttonAorBClick(_:)), forControlEvents: .TouchUpInside)
            
            bButton = UIButton(frame: CGRectZero)
            bButton?.backgroundColor = UIColor.greenColor()
            bButton?.setTitle(settings["bButtonTitle"], forState: .Normal)
            bButton?.addTarget(self, action: #selector(self.buttonAorBClick(_:)), forControlEvents: .TouchUpInside)
            
            centerLabel = UILabel(frame: CGRectZero)
            centerLabel?.text = "OR"
            centerLabel?.textAlignment = .Center
            centerLabel?.font = UIFont.boldSystemFontOfSize(18)
            
            self.addSubview(aButton!)
            self.addSubview(bButton!)
            self.addSubview(centerLabel!)
        case .IntegerInput, .StringInput:
            inputTextField = UITextField(frame: CGRectZero)
            inputTextField?.textAlignment = .Center
            inputTextField?.borderStyle = .RoundedRect
            inputTextField?.delegate = self
            
            okButton = UIButton(frame: CGRectZero)
            okButton?.backgroundColor = UIColor.lightGrayColor()
            okButton?.setTitle("OK", forState: .Normal)
            okButton?.addTarget(self, action: #selector(self.okButtonClick(_:)), forControlEvents: .TouchUpInside)
            
            if (type == .IntegerInput) { //set keyboard type for Int input
                inputTextField?.keyboardType = .NumberPad
            }
            self.addSubview(inputTextField!)
            self.addSubview(okButton!)
        }
        setNeedsLayout()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
//    deinit {
//        print("deinit")
//        for subview in self.subviews {
//            subview.removeFromSuperview()
//        }
//    }
    
    // MARK: - Visual Layout
    
    override func setNeedsLayout() {
        super.setNeedsLayout()
        //(1) Draw topLabel:
        let topLabelHeight: CGFloat = 25
        topLabel.frame = CGRectMake(0, 0, self.frame.width, topLabelHeight)
        
        //(2) Draw mainView:
        mainView.frame = CGRectMake(0, topLabelHeight, self.frame.width, (self.frame.height - topLabelHeight))
        switch self.type {
        case .AorB:
            configureAorBVisuals()
        case .IntegerInput, .StringInput:
            configureTextFieldInputVisuals()
        }
    }
    
    private func configureAorBVisuals() {
        let verticalSpacer: CGFloat = 12
        let horizontalSpacer: CGFloat = 10
        let labelWidth: CGFloat = 30 //constant
        let totalHeight = self.frame.height - topLabel.frame.height
        let viewHeight: CGFloat = totalHeight - 2 * verticalSpacer //dynamic
        let buttonWidth = (self.frame.width - labelWidth - 4 * horizontalSpacer)/2 //dynamic
        aButton?.frame = CGRectMake(horizontalSpacer, (topLabel.frame.height + verticalSpacer), buttonWidth, viewHeight)
        centerLabel?.frame = CGRectMake((buttonWidth + 2 * horizontalSpacer), (topLabel.frame.height + verticalSpacer), labelWidth, viewHeight)
        bButton?.frame = CGRectMake((buttonWidth + labelWidth + 3 * horizontalSpacer), (topLabel.frame.height + verticalSpacer), buttonWidth, viewHeight)
    }
    
    private func configureTextFieldInputVisuals() {
        let verticalSpacer: CGFloat = 5
        let totalWidth = topLabel.frame.width
        let widthMultiplier: CGFloat = 0.70
        let textFieldHeight: CGFloat = 35
        inputTextField?.frame = CGRectMake((totalWidth * (1 - widthMultiplier)/2), (topLabel.frame.height + verticalSpacer), totalWidth * widthMultiplier, textFieldHeight)
        okButton?.frame = CGRectMake((totalWidth * (1 - widthMultiplier/2)/2), (topLabel.frame.height + textFieldHeight + 2 * verticalSpacer), totalWidth * widthMultiplier/2, (self.frame.height - topLabel.frame.height - 3 * verticalSpacer - textFieldHeight))
        inputTextField?.becomeFirstResponder() //set to 1st-R
    }
    
    // MARK: - Text Field
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        if (self.type == .IntegerInput) {
            if let text = textField.text {
                if let number = Int((text as NSString).stringByReplacingCharactersInRange(range, withString: string)) {
                    if !(number > 0) {
                        return false
                    }
                } else {
                    return false
                }
            }
        }
        return true
    }
    
    // MARK: - Button Actions
    
    @IBAction func okButtonClick(sender: UIButton) {
        if let text = inputTextField?.text {
            let trimmedText = text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            if (trimmedText != "") {
                fireNotification() //terminate view (send notification -> parent)
            }
        }
    }
    
    @IBAction func buttonAorBClick(sender: UIButton) {
        selectedButton = sender.titleLabel?.text
        fireNotification() //terminate view (send notification)
    }
    
    private func fireNotification() {
        let notification = NSNotification(name: BMN_Notification_PopupViewActionWasTriggered, object: self) //only parent can see notification
        NSNotificationCenter.defaultCenter().postNotification(notification)
    }
    
    // MARK: - Data Reporting
    
    func getDataForPopupView() -> AnyObject? {
        switch self.type {
        case .AorB:
            return selectedButton //send back which btn was clicked
        case .IntegerInput, .StringInput:
            if let text = inputTextField?.text {
                return text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            } else {
                return nil
            }
        }
    }
    
}