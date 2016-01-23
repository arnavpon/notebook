//  CreateProjectViewController.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/3/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Use this page to name the project, define the question to be answered, and add a time-frame (endpoint) for the project.

import UIKit

class CreateProjectViewController: UIViewController, UITextViewDelegate {
    
    @IBOutlet weak var createProjectButton: UIBarButtonItem!
    @IBOutlet weak var titleInstructionLabel: UILabel!
    @IBOutlet weak var questionInstructionLabel: UILabel!
    @IBOutlet weak var endpointInstructionLabel: UILabel!
    @IBOutlet weak var projectTitleView: UIView!
    @IBOutlet weak var projectTitleTextView: CustomTextView!
    @IBOutlet weak var projectQuestionView: UIView!
    @IBOutlet weak var projectQuestionTextView: CustomTextView!
    @IBOutlet weak var projectEndpointView: UIView!
    @IBOutlet weak var firstSuccessIndicator: UIImageView!
    @IBOutlet weak var secondSuccessIndicator: UIImageView!
    @IBOutlet weak var thirdSuccessIndicator: UIImageView!
    
    var projectTitle: String? //set value to indicate that a name has been entered
    var projectQuestion: String? //set value to indicate that a question has been entered
    var selectedEndpoint: Endpoint? //captures endpoint for segue
    
    // MARK: - View Configuration
    
    override func viewDidLoad() {
        super.viewDidLoad()
        firstSuccessIndicator.hidden = true
        secondSuccessIndicator.hidden = true
        thirdSuccessIndicator.hidden = true
        projectTitleTextView.delegate = self
        projectQuestionTextView.delegate = self
    }
    
    override func viewDidAppear(animated: Bool) { //add placeholders (view is properly set @ this time)
        projectTitleTextView.placeholder = "Enter a title for your new project"
        projectQuestionTextView.placeholder = "What is the question that your project is trying to answer?"
    }

    // MARK: - TextView Behavior
    
    func textViewDidChange(textView: UITextView) { //enable 'Create' button when name & question are entered & an endpoint is selected
        if (textView == projectTitleTextView) {
            if (textView.text != "") {
                projectTitle = textView.text.capitalizedString
                firstSuccessIndicator.hidden = false
            } else {
                projectTitle = nil
                firstSuccessIndicator.hidden = true
            }
        } else if (textView == projectQuestionTextView) {
            if (textView.text != "") {
                projectQuestion = textView.text
                secondSuccessIndicator.hidden = false
            } else {
                projectQuestion = nil
                 secondSuccessIndicator.hidden = true
            }
        }
        if (projectQuestion != nil) && (projectTitle != nil) {
            createProjectButton.enabled = true
        } else {
            createProjectButton.enabled = false
        }
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if (textView == projectTitleTextView) { //cap the project title @ 40 characters
            if ((textView.text.characters.count + text.characters.count - range.length) > 25) {
                print("String too long")
                return false
            }
        } else if (textView == projectQuestionTextView) { //cap question length @ 100 characters
            if ((textView.text.characters.count + text.characters.count - range.length) > 100) {
                print("String too long")
                return false
            }
        }
        return true
    }
    
    // MARK: - Button Actions
    
    @IBAction func createProjectButtonClick(sender: AnyObject) { //transition -> VariablesVC
        performSegueWithIdentifier("showVariables", sender: nil)
    }
    
    @IBAction func cancelButtonClick(sender: AnyObject) { //return to home screen
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateInitialViewController()!
        presentViewController(controller, animated: true, completion: nil)
    }

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        //Pass the title, question, & endpoint through -> the remaining flows so that the complete project can be set up in the 'Summary' section:
        if (segue.identifier == "showVariables") {
            let destination = segue.destinationViewController as! ProjectVariablesViewController
            destination.projectTitle = self.projectTitle
            destination.projectQuestion = self.projectQuestion
            destination.projectEndpoint = self.selectedEndpoint
        }
    }

}
