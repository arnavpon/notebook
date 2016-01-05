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
    
    var endpointPickerFirstComponentArray: [String] = ["Continuous", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10"]
    var endpointPickerSecondComponentArray: [String] = ["Day(s)", "Week(s)", "Month(s)", "Year(s)"]
    var actionPickerRowArray: [String] = ["Eat", "Sleep", "Exercise"]
    
    var selectedAction: String?
    var projectHasName: Bool = false //checks if a name has been entered
    var projectHasQuestion: Bool = false //checks if a question has been entered
    var actionPickerSelection: String?
    var endpointPickerSelection: (String?, String?)
    
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
        
        actionPickerSelection = actionPickerRowArray.first
        endpointPickerSelection = (endpointPickerFirstComponentArray.first, endpointPickerSecondComponentArray.first)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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

    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        //save current selection
        if (pickerView == actionPicker) {
            actionPickerSelection = actionPickerRowArray[row]
            print("Current Action: \(actionPickerSelection!)")
        } else {
            if (component == 0) {
                endpointPickerSelection.0 = endpointPickerFirstComponentArray[row]
            } else {
                endpointPickerSelection.1 = endpointPickerSecondComponentArray[row]
            }
            print("Current Endpoint: \(endpointPickerSelection.0!) \(endpointPickerSelection.1!))")
        }
    }
    
    // MARK: - Text View
    
    func textViewDidChange(textView: UITextView) {
        if (textView == projectNameTextView) {
            if (textView.text != "") {
                projectHasName = true
            } else {
                projectHasName = false
            }
        } else if (textView == projectQuestionTextView) {
            if (textView.text != "") {
                projectHasQuestion = true
            } else {
                projectHasQuestion = false
            }
        }
        if (projectHasQuestion) && (projectHasName) {
            saveButton.enabled = true
        } else {
            saveButton.enabled = false
        }
    }
    
    // MARK: - Button Actions
    
    @IBAction func saveButtonClick(sender: AnyObject) {
        //Transition -> VariableVC & save project configuration:
        selectedAction = actionPickerSelection
        performSegueWithIdentifier("showVariables", sender: nil)
    }
    
    @IBAction func cancelButtonClick(sender: AnyObject) {
        //Return to home screen:
    }

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "showVariables") {
            let destination = segue.destinationViewController as! ProjectVariablesTableViewController
            destination.action = self.selectedAction
        }
    }

}
