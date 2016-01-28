//  CreateProjectViewController.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/3/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Use this page to name the project, define the question to be answered, and add a time-frame (endpoint) for the project.

import UIKit

class CreateProjectViewController: UIViewController, UITextViewDelegate {
    
    
    @IBOutlet weak var createProjectButton: UIBarButtonItem!
    @IBOutlet weak var projectTitleView: UIView!
    @IBOutlet weak var titleInstructionLabel: UILabel!
    @IBOutlet weak var projectTitleTextView: CustomTextView!
    @IBOutlet weak var firstSuccessIndicator: UIImageView!
    
    @IBOutlet weak var projectQuestionView: UIView!
    @IBOutlet weak var questionInstructionLabel: UILabel!
    @IBOutlet weak var projectQuestionTextView: CustomTextView!
    @IBOutlet weak var secondSuccessIndicator: UIImageView!
    
    @IBOutlet weak var projectEndpointView: UIView! //larger view
    @IBOutlet weak var endpointInstructionLabel: UILabel! //main lbl
    @IBOutlet weak var endpointView: UIView! //smaller view
    @IBOutlet weak var endpointViewLeftLabel: UILabel! //'indefinite length' label
    @IBOutlet weak var endpointViewNumberImage: UIImageView! //(3) image
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
        
        let widthPercentage: CGFloat = 0.87 //% of remaining view that slider width takes
        let viewWidth: CGFloat = (view.frame.width - endpointViewNumberImage.frame.width - thirdSuccessIndicator.frame.width - 16) //endpointView width is total width - width of #3 label - 16 (fixed offset) - width of 3rdsuccessindicator.
        let heightPercentage: CGFloat = 0.60 //% of remaining view that slider height takes
        let viewHeight: CGFloat = (view.frame.height - 36 - projectTitleView.frame.height - projectQuestionView.frame.height - endpointInstructionLabel.frame.height - endpointViewNumberImage.frame.height - endpointViewLeftLabel.frame.height - 10) //remainder of view after subtracting view heights, navBar height (36), label height & offset of 10 (from bottom); still not the proper height!
        print("view height: \(viewHeight)")
        let sliderWidth = widthPercentage * viewWidth
        let sliderHeight = heightPercentage * viewHeight
        let centerX: CGFloat = sliderWidth/2 + (1 - widthPercentage)/2 * viewWidth
        let centerY: CGFloat = endpointViewLeftLabel.frame.height + sliderHeight/2 + 10
        let center = CGPoint(x: centerX, y: centerY)
        let size = CGSize(width: sliderWidth, height: sliderHeight)
        let frame = createRectAroundCenter(center, size: size)
        let endpoints = ["NONE", "DAY", "WEEK", "MONTH", "YEAR"]
        let colorScheme = (UIColor.whiteColor(), UIColor.greenColor(), 1)
        let customSlider = CustomSlider(frame: frame, selectionPoints: endpoints, scheme: colorScheme)
        endpointView.addSubview(customSlider)
        endpointView.bringSubviewToFront(customSlider)
        customSlider.addTarget(self, action: "customSliderValueHasChanged:", forControlEvents: .ValueChanged)
        
        //test ui changes:
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(NSEC_PER_SEC))
        dispatch_after(time, dispatch_get_main_queue()) { () -> Void in
            customSlider.controlTintColor = UIColor.purpleColor()
        }
    }
    
    override func viewDidAppear(animated: Bool) { //add placeholders (view is properly set @ this time)
        projectTitleTextView.placeholder = "Enter a title for your new project"
        projectQuestionTextView.placeholder = "What is the question that your project is trying to answer?"
    }
    
    func customSliderValueHasChanged(customSlider: CustomSlider) {
        print("New Slider Value: \(customSlider.currentValue)")
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
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) { //if touch is outside textView, resign 1st responder; doesn't drop 1stR when I touch slider for some reason
        let touch = touches.first
        if let location = touch?.locationInView(self.view) {
            if !(projectQuestionTextView.frame.contains(location)) {
                projectQuestionTextView.resignFirstResponder()
            }
            if !(projectTitleTextView.frame.contains(location)) {
                projectTitleTextView.resignFirstResponder()
            }
        }
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
