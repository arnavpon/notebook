//  CreateProjectViewController.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/3/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// In this VC, users name their project, define the question to be answered, create a hypothesis (optionally), & add a time-frame (endpoint) for the project.

import UIKit

class CreateProjectViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var setupButton: UIBarButtonItem!
    @IBOutlet weak var createProjectTV: UITableView!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
        
    var projectTitle: String? //set value to indicate that a name has been entered
    var projectQuestion: String? //set value to indicate that a question has been entered
    var projectHypothesis: String? //optional configuration item
    var projectEndpoint: Endpoint = Endpoint(endpoint: Endpoints.Continuous, number: nil) //captures endpoint for segue
    var projectType: ExperimentTypes?
    var numberOfConfiguredCells: Int = 0 { //keeps track of the current # of configured cells
        didSet { //adjust 'doneButton' status appropriately
            configureDoneButton()
        }
    }
    
    // MARK: - View Configuration
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createProjectTV.dataSource = self
        createProjectTV.delegate = self
        
        //Register (4) custom TV cells:
        createProjectTV.registerClass(ProjectTitleCustomCell.self, forCellReuseIdentifier: NSStringFromClass(ProjectTitleCustomCell))
        createProjectTV.registerClass(ProjectQuestionCustomCell.self, forCellReuseIdentifier: NSStringFromClass(ProjectQuestionCustomCell))
        createProjectTV.registerClass(ProjectHypothesisCustomCell.self, forCellReuseIdentifier: NSStringFromClass(ProjectHypothesisCustomCell))
        createProjectTV.registerClass(CellWithCustomSlider.self, forCellReuseIdentifier: NSStringFromClass(CellWithCustomSlider))
    }
    
    override func viewWillAppear(animated: Bool) { //add notification observers
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.revealHiddenArea(_:)), name: BMN_Notification_RevealHiddenArea, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.cellDidReportData(_:)), name: BMN_Notification_CellDidReportData, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.cellCompletionStatusDidChange(_:)), name: BMN_Notification_CompletionIndicatorDidChange, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.customSliderSelectedNodeHasChanged(_:)), name: BMN_Notification_SliderSelectedNodeHasChanged, object: nil)
        
        //Keyboard notifications:
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.keyboardDidAppearWithFrame(_:)), name: UIKeyboardDidChangeFrameNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.keyboardDidHide(_:)), name: UIKeyboardDidHideNotification, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) { //clear notification observer
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func cellDidReportData(notification: NSNotification) { //update project config variables
        if let dict = notification.userInfo {
            if let title = dict[BMN_ProjectTitleID] as? String {
                projectTitle = title
            } else if let question = dict[BMN_ProjectQuestionID] as? String, type = dict[BMN_ProjectTypeID] as? String {
                projectQuestion = question
                projectType = ExperimentTypes(rawValue: type) //re-init w/ rawValue
            } else if let hypothesis = dict[BMN_ProjectHypothesisID] as? String {
                projectHypothesis = hypothesis
            } else if let endpoint = dict[BMN_ProjectEndpointID] as? Int { //gets # of days from cell
                if (endpoint == 0) { //continuous project
                    projectEndpoint = Endpoint(endpointInDays: nil) //use appropriate init
                } else { //definite length project
                    projectEndpoint = Endpoint(endpointInDays: endpoint)
                }
            }
        }
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
    
    func configureDoneButton() { //controls whether the 'setupButton' is enabled or not
        let total = 4 //4 total cells that need to be filled
        if (numberOfConfiguredCells != total) { //some cells haven't been configured yet
            setupButton.enabled = false
            if (numberOfConfiguredCells > total) { //error check
                print("[configureDoneButton] Error - # of configured cells exceeds total # of cells!")
            }
        } else { //all cells have been configured
            setupButton.enabled = true
        }
    }
    
    func customSliderSelectedNodeHasChanged(notification: NSNotification) { //if slider's node changes, create an alert for user to enter a crown value
        let alert = UIAlertController(title: "Add a Value", message: "Enter a number to complete your endpoint setup.", preferredStyle: UIAlertControllerStyle.Alert)
        let cancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: { (let cancel) -> Void in
            let notification = NSNotification(name: BMN_Notification_SliderCrownValueWasSet, object: nil, userInfo: [BMN_CellWithCustomSlider_CrownValueKey: -1])
            NSNotificationCenter.defaultCenter().postNotification(notification)
        })
        let ok = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (let ok) -> Void in
            //add typed value -> crown for the slider; type check to make sure it is an int:
            if let input = Int((alert.textFields?.first?.text)!) {
                if (input > 0) { //make sure value is > 0
                    let notification = NSNotification(name: BMN_Notification_SliderCrownValueWasSet, object: nil, userInfo: [BMN_CellWithCustomSlider_CrownValueKey: input])
                    NSNotificationCenter.defaultCenter().postNotification(notification)
                } else { //set slider back -> start
                    let notification = NSNotification(name: BMN_Notification_SliderCrownValueWasSet, object: nil, userInfo: [BMN_CellWithCustomSlider_CrownValueKey: -1])
                    NSNotificationCenter.defaultCenter().postNotification(notification)
                }
            } else { //if input is NOT an integer value
                let notification = NSNotification(name: BMN_Notification_SliderCrownValueWasSet, object: nil, userInfo: [BMN_CellWithCustomSlider_CrownValueKey: -1])
                NSNotificationCenter.defaultCenter().postNotification(notification)
            }
        })
        alert.addAction(cancel)
        alert.addAction(ok)
        alert.addTextFieldWithConfigurationHandler({ (let textField) -> Void in
            //configure TF so that numbers show up on keyboard
            textField.keyboardType = UIKeyboardType.NumberPad
        })
        presentViewController(alert, animated: true, completion: nil)
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
    
    // MARK: - Table View
    
    var hypothesisCellVisibleLevels: Int = 0 //default # of hidden cells is 0
    
    func revealHiddenArea(notification: NSNotification) { //reveals hidden area in TV cell when + button (on the cell) is clicked
        if let dict = notification.userInfo, levels = dict[BMN_PlusBtnCell_NumberOfHiddenLevelsKey] as? Int {
            hypothesisCellVisibleLevels = levels
            createProjectTV.reloadData() //reload TV cells to update UI
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4 //Project Title, Project Question, Project Hypothesis, Project Endpoint
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let separatorHeight: CGFloat = 2
        switch (indexPath.row) { //add 2 for separator height + default space from bottom
        case 0: //project title
            return 160 + BMN_DefaultBottomSpacer + separatorHeight
        case 1: //project question
            return 160 + BMN_DefaultBottomSpacer + separatorHeight
        case 2: //hypothesis (size is dynamic)
            return (40 + CGFloat(hypothesisCellVisibleLevels) * 40) + BMN_DefaultBottomSpacer + separatorHeight
        case 3: //project endpoint
            return 200 + BMN_DefaultBottomSpacer //NO separator for last cell
        default:
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = BaseCreateProjectCell()
        switch (indexPath.row) {
        case 0: //Title
            cell = tableView.dequeueReusableCellWithIdentifier(NSStringFromClass(ProjectTitleCustomCell)) as! ProjectTitleCustomCell
            cell.mainLabelFont = UIFont.systemFontOfSize(17, weight: 2)
            cell.mainLabelTextColor = UIColor.whiteColor()
            cell.insetBackgroundColor = UIColor(red: 82/255, green: 33/255, blue: 1, alpha: 1)
            cell.firstLevelLeftButton?.setImage(UIImage(named: "1"), forState: UIControlState.Normal)
            (cell as! ProjectTitleCustomCell).customTextView.placeholder = "Enter a title for your project"
            cell.dataSource = [BMN_LEVELS_MainLabelKey: "PROJECT TITLE"]
            
        case 1: //Question
            cell = tableView.dequeueReusableCellWithIdentifier(NSStringFromClass(ProjectQuestionCustomCell)) as! ProjectQuestionCustomCell
            cell.mainLabelFont = UIFont.systemFontOfSize(17, weight: 2)
            cell.mainLabelTextColor = UIColor.whiteColor()
            cell.insetBackgroundColor = UIColor(red: 255/255, green: 120/255, blue: 111/255, alpha: 1)
            cell.firstLevelLeftButton?.setImage(UIImage(named: "2"), forState: UIControlState.Normal)
            cell.dataSource = [BMN_LEVELS_MainLabelKey: "QUESTION TO ANSWER"]
            
        case 2: //Hypothesis
            cell = tableView.dequeueReusableCellWithIdentifier(NSStringFromClass(ProjectHypothesisCustomCell)) as! ProjectHypothesisCustomCell
            cell.mainLabelFont = UIFont.systemFontOfSize(15, weight: 2)
            cell.mainLabelTextColor = UIColor.whiteColor()
            cell.insetBackgroundColor = UIColor(red: 50/255, green: 163/255, blue: 216/255, alpha: 1)
            cell.firstLevelLeftButton?.setImage(UIImage(named: "3"), forState: UIControlState.Normal)
            (cell as! ProjectHypothesisCustomCell).customTextView.placeholder = "Enter a hypothesis (what you think the results will show in response to your question)."
            cell.dataSource = [BMN_LEVELS_MainLabelKey: "HYPOTHESIS (OPTIONAL)", BMN_LEVELS_CellIsOptionalKey: true, BMN_LEVELS_RevealRightButtonKey: true]
            
        case 3: //Endpoint
            cell = tableView.dequeueReusableCellWithIdentifier(NSStringFromClass(CellWithCustomSlider)) as! CellWithCustomSlider
            cell.mainLabelFont = UIFont.systemFontOfSize(17, weight: 2)
            cell.mainLabelTextColor = UIColor.whiteColor()
            cell.insetBackgroundColor = UIColor(red: 1, green: 109/255, blue: 21/255, alpha: 1)
            cell.firstLevelLeftButton?.setImage(UIImage(named: "4"), forState: UIControlState.Normal)
            cell.dataSource = [BMN_LEVELS_MainLabelKey: "PROJECT TIMEFRAME"]
            
        default:
            break
        }
        return cell
    }
    
    func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        self.view.endEditing(true) //force firstResponder to disappear
        return false
    }
    
    // MARK: - Button Actions
    
    var showTutorial: Bool = true //sets tutorial to ACTIVE in ProjectVarsVC
    
    @IBAction func setupButtonClick(sender: AnyObject) { //segue -> ProjectVarsVC
        let userDefaults = NSUserDefaults.standardUserDefaults()
        if let shouldShowTutorial = userDefaults.valueForKey("SHOW_VARS_TUTORIAL") as? Bool {
            showTutorial = shouldShowTutorial
        }
        performSegueWithIdentifier("showVariables", sender: nil)
    }
    
    @IBAction func cancelButtonClick(sender: AnyObject) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateInitialViewController()!
        presentViewController(controller, animated: true, completion: nil)
    }
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        //Pass the title, question, hypothesis, endpoint, & type through -> remaining flows:
        if (segue.identifier == "showVariables") {
            let destination = segue.destinationViewController as! ProjectVariablesViewController
            destination.tutorialDescriptionViewMode = false //**enable/disable tutorial
            //destination.tutorialDescriptionViewMode = self.showTutorial //true => show tutorial
            destination.projectTitle = self.projectTitle
            destination.projectQuestion = self.projectQuestion
            destination.projectHypothesis = self.projectHypothesis
            destination.projectEndpoint = self.projectEndpoint
            destination.projectType = self.projectType
        }
    }
    
}