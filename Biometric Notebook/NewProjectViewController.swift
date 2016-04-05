//  NewProjectViewController.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 4/4/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Use this page to name the project, define the question to be answered and (optionally) a hypothesis, & add a time-frame (endpoint) for the project.

import UIKit

class NewProjectViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var setupButton: UIBarButtonItem!
    @IBOutlet weak var newProjectTV: UITableView!
    
    var projectTitle: String? //set value to indicate that a name has been entered
    var projectQuestion: String? //set value to indicate that a question has been entered
    var projectHypothesis: String? //optional configuration item
    var selectedEndpoint: Endpoint = Endpoint(endpoint: Endpoints.Continuous, number: nil) //captures endpoint for segue
    let endpoints = [Endpoints.Continuous.rawValue, Endpoints.Day.rawValue, Endpoints.Week.rawValue, Endpoints.Month.rawValue, Endpoints.Year.rawValue] //endpoints for slider
    
    // MARK: - View Configuration
    
    override func viewDidLoad() {
        super.viewDidLoad()
        newProjectTV.dataSource = self
        newProjectTV.delegate = self
        //register custom TV cell
        newProjectTV.registerClass(LevelsFrameworkCell.self, forCellReuseIdentifier: NSStringFromClass(LevelsFrameworkCell)) //**
    }
    
    func customSliderValueHasChanged(customSlider: CustomSlider) { //if slider lands on a fixedPoint that is NOT 'none', create an alert for adding the amount
        if (customSlider.suppressAlert) { //check if alert should be allowed to appear
            customSlider.suppressAlert = false //reset suppression alert
            return //break function early
        }
        
        let selectedValue = customSlider.currentValue
        //Match the selected value -> a node:
        if let index = customSlider.fixedSelectionPointNumbers.indexOf(selectedValue) {
            let selection = endpoints[index]
            if (selection != endpoints.first) { //make sure the 1st item wasn't selected
                let alert = UIAlertController(title: "Add a Value", message: "Enter a number to complete your endpoint setup.", preferredStyle: UIAlertControllerStyle.Alert)
                let cancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: { (let cancel) -> Void in
                    customSlider.currentValue = 0.0 //set slider back -> 'None'
                    customSlider.setNodeAsSelected() //change highlighting to reflect currentNode
                    self.selectedEndpoint = Endpoint(endpoint: Endpoints.Continuous, number: nil)
                })
                let ok = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (let ok) -> Void in
                    //add typed value -> crown for the slider; type check to make sure it is an int:
                    if let input = Int((alert.textFields?.first?.text)!) {
                        customSlider.crownLayerValue = input
                        
                        //Set the selectedEndpoint:
                        var counter = 0
                        var selection: String = ""
                        for selectionPoint in customSlider.fixedSelectionPointNumbers {
                            if (customSlider.currentValue == selectionPoint) { //get node #
                                selection = self.endpoints[counter] //get node name
                                break
                            }
                            counter += 1
                        }
                        if let select: Endpoints = Endpoints(rawValue: selection) { //match -> endpoint
                            self.selectedEndpoint = Endpoint(endpoint: select, number: input)
                        } else {
                            print("Error: selectedEndpoint does not match known endpoint!")
                        }
                    } else { //if input is not an integer value
                        customSlider.currentValue = 0.0
                        customSlider.setNodeAsSelected() //change highlighting to reflect currentNode
                        self.selectedEndpoint = Endpoint(endpoint: Endpoints.Continuous, number: nil)
                    }
                })
                alert.addAction(cancel)
                alert.addAction(ok)
                alert.addTextFieldWithConfigurationHandler({ (let textField) -> Void in
                    //configure TF so that numbers show up on keyboard
                    textField.keyboardType = UIKeyboardType.NumberPad
                })
                presentViewController(alert, animated: true, completion: nil)
            } else { //user selected 'None' -> continuous endpoint
                selectedEndpoint = Endpoint(endpoint: Endpoints.Continuous, number: nil)
            }
        }
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) { //if touch is outside textView, resign 1st responder; doesn't drop 1stR when I touch slider for some reason
        let touch = touches.first
        if let location = touch?.locationInView(self.view) {
//            if !(projectQuestionTextView.frame.contains(location)) {
//                projectQuestionTextView.resignFirstResponder()
//            }
//            if !(projectTitleTextView.frame.contains(location)) {
//                projectTitleTextView.resignFirstResponder()
//            }
        }
    }

    // MARK: - Table View
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4 //Project Title, Project Question, Project Hypothesis, Project Endpoint
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 80 //customize
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(NSStringFromClass(LevelsFrameworkCell)) as! LevelsFrameworkCell
        if (indexPath.row == 0) {
            cell.dataSource = [BMN_LEVELS_MainLabelKey: "TEST LABEL\nsecond line", BMN_LEVELS_HideRightViewKey: true]
        } else if (indexPath.row == 1) {
            cell.dataSource = [BMN_LEVELS_MainLabelKey: "TEST LABEL\nsecond line", BMN_LEVELS_HideRightViewKey: true, BMN_LEVELS_TabLevelKey: 1]
        } else {
            cell.dataSource = [BMN_LEVELS_MainLabelKey: "TEST LABEL\nsecond line", BMN_LEVELS_HideRightViewKey: true, BMN_LEVELS_TabLevelKey: 2]
        }
        return cell
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
        //Pass the title, question, hypothesis, & endpoint through -> the remaining flows:
        if (segue.identifier == "showVariables") {
            let destination = segue.destinationViewController as! ProjectVariablesViewController
            destination.tutorialDescriptionViewMode = false //**enable/disable tutorial
            //destination.tutorialDescriptionViewMode = self.showTutorial //true => show tutorial
            destination.projectTitle = self.projectTitle
            destination.projectQuestion = self.projectQuestion
            destination.projectEndpoint = self.selectedEndpoint
            destination.projectHypothesis = self.projectHypothesis
        }
    }

}
