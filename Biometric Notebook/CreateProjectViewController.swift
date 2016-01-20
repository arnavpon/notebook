//  CreateProjectViewController.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/3/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Use this page to name the project, define the question to be answered, and add a time-frame (endpoint) for the project. Can use a picker for the endpoint selection & the action selection. Keep it all on a scroll view. 

import UIKit

class CreateProjectViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate, UITextViewDelegate {
    
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var projectNameTextView: UITextView!
    @IBOutlet weak var projectQuestionTextView: UITextView!
    @IBOutlet weak var endpointPicker: UIPickerView!
    @IBOutlet weak var actionPicker: UIPickerView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var nameInstructionLabel: UILabel!
    @IBOutlet weak var actionInstructionLabel: UILabel!
    @IBOutlet weak var endpointInstructionLabel: UILabel!
    @IBOutlet weak var questionInstructionLabel: UILabel!
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var endpointPickerFirstComponentArray: [String] = ["Continuous", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10"]
    var endpointPickerSecondComponentArray: [String] = ["-----", "Day(s)", "Week(s)", "Month(s)", "Year(s)"] //make sure this array matches the 'rawValue' strings in the 'Endpoint' enum!
    var actionPickerRowArray: [String] = ["Eat", "Sleep", "Exercise"] //make sure these values match the 'rawValue' strings in the picker enum!
    var actionPickerSelection: String?
    var endpointPickerSelection: (String?, String?)
    
    var projectTitle: String? //set value to indicate that a name has been entered
    var projectQuestion: String? //set value to indicate that a question has been entered
    var selectedAction: Action? //captures 'action' before segue
    var selectedEndpoint: Endpoint? //captures 'endpoint' before segue
    
    // MARK: - View Configuration
    
    override func viewWillAppear(animated: Bool) {
        nameInstructionLabel.adjustsFontSizeToFitWidth = true
        actionInstructionLabel.adjustsFontSizeToFitWidth = true
        endpointInstructionLabel.adjustsFontSizeToFitWidth = true
        questionInstructionLabel.adjustsFontSizeToFitWidth = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        actionPicker.dataSource = self
        actionPicker.delegate = self
        endpointPicker.dataSource = self
        endpointPicker.delegate = self
        projectNameTextView.delegate = self
        projectQuestionTextView.delegate = self
        
        //Initialize the actionPicker & endpointPicker selections w/ the first item in the array:
        actionPickerSelection = actionPickerRowArray.first
        endpointPickerSelection = (endpointPickerFirstComponentArray.first, endpointPickerSecondComponentArray.first)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Picker View
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        if (pickerView == actionPicker) {
            return 1
        } else {
            return 2
        }
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if (pickerView == actionPicker) {
            return actionPickerRowArray.count
        } else {
            if (component == 0) {
                return endpointPickerFirstComponentArray.count
            } else {
                return endpointPickerSecondComponentArray.count
            }
        }
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if (pickerView == actionPicker) {
            return actionPickerRowArray[row]
        } else {
            if (component == 0) {
                return endpointPickerFirstComponentArray[row]
            } else {
                return endpointPickerSecondComponentArray[row]
            }
        }
    }

    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) { //save current selection
        if (pickerView == actionPicker) {
            actionPickerSelection = actionPickerRowArray[row]
            print("Current Action: \(actionPickerSelection!)")
        } else if (pickerView == endpointPicker) {
            if (component == 0) {
                endpointPickerSelection.0 = endpointPickerFirstComponentArray[row]
            } else {
                endpointPickerSelection.1 = endpointPickerSecondComponentArray[row]
            }
            print("Current Endpoint: \(endpointPickerSelection.0!) \(endpointPickerSelection.1!))")
        }
    }
    
    // MARK: - Text View
    
    func textViewDidChange(textView: UITextView) { //enable 'save' button when name & question are entered
        if (textView == projectNameTextView) {
            if (textView.text != "") {
                projectTitle = textView.text.capitalizedString
            } else {
                projectTitle = nil
            }
        } else if (textView == projectQuestionTextView) {
            if (textView.text != "") {
                projectQuestion = textView.text
            } else {
                projectQuestion = nil
            }
        }
        if (projectQuestion != nil) && (projectTitle != nil) {
            saveButton.enabled = true
        } else {
            saveButton.enabled = false
        }
    }
    
    // MARK: - Button Actions
    
    @IBAction func saveButtonClick(sender: AnyObject) {
        //Transition -> VariableVC & save project configuration:
        let numericalValue = endpointPickerSelection.0!
        let unit = endpointPickerSelection.1!
        if (numericalValue != "Continuous") && (unit == "-----") { //block transition if '----' is selected w/ a numerical value
            print("Error. Please select an appropriate unit for the numerical value")
        } else {
            selectedAction = Action(action: actionPickerSelection!) //initializes the enum object w/ the string in the picker
            selectedEndpoint = Endpoint(firstPickerSelection: endpointPickerSelection.0!, secondPickerSelection: endpointPickerSelection.1!)
            performSegueWithIdentifier("showVariables", sender: nil)
        }
    }
    
    @IBAction func cancelButtonClick(sender: AnyObject) { //return to home screen
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateInitialViewController()!
        presentViewController(controller, animated: true, completion: nil)
    }

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        //Pass the title, question, action & endpoint through -> the remaining flows so that the complete project can be set up in the 'Summary' section:
        if (segue.identifier == "showVariables") {
            let destination = segue.destinationViewController as! ProjectVariablesTableViewController
            destination.projectTitle = self.projectTitle
            destination.projectQuestion = self.projectQuestion
            destination.projectAction = self.selectedAction
            destination.projectEndpoint = self.selectedEndpoint
        }
    }

}
