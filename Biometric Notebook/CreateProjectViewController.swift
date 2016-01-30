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
    @IBOutlet weak var endpointView: CustomSliderBackgroundView! //smaller view
    @IBOutlet weak var endpointViewNumberImage: UIImageView! //(3) image
    @IBOutlet weak var thirdSuccessIndicator: UIImageView!
    
    var projectTitle: String? //set value to indicate that a name has been entered
    var projectQuestion: String? //set value to indicate that a question has been entered
    var selectedEndpoint: Endpoint = Endpoint(endpoint: Endpoints.Continuous, number: nil) //captures endpoint for segue
    let endpoints = [Endpoints.Continuous.rawValue, Endpoints.Day.rawValue, Endpoints.Week.rawValue, Endpoints.Month.rawValue, Endpoints.Year.rawValue] //endpoints for slider
    
    var firstSuccessIndicatorIsSet: Bool = false { //handles display of 1st checkmark
        didSet {
            if (firstSuccessIndicatorIsSet) {
                firstSuccessIndicator.hidden = false
                if (firstSuccessIndicatorIsSet) && (secondSuccessIndicatorIsSet) { //if all 3 checkmarks are set, enable 'Done' button (3rd success is always on unless user is interating w/ the slider)
                    createProjectButton.enabled = true
                }
            } else {
                firstSuccessIndicator.hidden = true
                createProjectButton.enabled = false
            }
        }
    }
    var secondSuccessIndicatorIsSet: Bool = false { //handles display of 2nd checkmark
        didSet {
            if (secondSuccessIndicatorIsSet) {
                secondSuccessIndicator.hidden = false
                if (firstSuccessIndicatorIsSet) && (secondSuccessIndicatorIsSet) {
                    createProjectButton.enabled = true
                }
            } else {
                secondSuccessIndicator.hidden = true
                createProjectButton.enabled = false
            }
        }
    }
    
    // MARK: - View Configuration
    
    override func viewDidLoad() {
        super.viewDidLoad()
        firstSuccessIndicator.hidden = true
        secondSuccessIndicator.hidden = true
        thirdSuccessIndicator.hidden = true //normally on, except when slider is moving
        projectTitleTextView.delegate = self
        projectQuestionTextView.delegate = self
        
        let widthPercentage: CGFloat = 0.8 //% of remaining view that slider width takes
        let viewWidth: CGFloat = (view.frame.width - endpointViewNumberImage.frame.width - thirdSuccessIndicator.frame.width - 16) //endpointView width is total width - width of #3 label - 16 (fixed offset) - width of 3rdsuccessindicator.
        let heightPercentage: CGFloat = 0.65 //% of remaining view that slider height takes
        
        let leftViewHeight = CGFloat(80) //*for 5S
        let viewHeight: CGFloat = (view.frame.height - 36 - projectTitleView.frame.height - projectQuestionView.frame.height - endpointInstructionLabel.frame.height - endpointViewNumberImage.frame.height - leftViewHeight - 10) //remainder of view after subtracting view heights, navBar height (36), label height & offset of 10 (from bottom); still not the proper height b/c Lviewheight is not set til viewDidAppear
        let sliderWidth = widthPercentage * viewWidth
        let sliderHeight = heightPercentage * viewHeight
        let centerX: CGFloat = sliderWidth/2 + (1 - widthPercentage)/2 * viewWidth
        
        let leftLabelHeight = endpointView.leftLabelHeight
        let centerY: CGFloat = leftLabelHeight + sliderHeight/2 + 10 //offset by 10 from bottom of lbl
        let center = CGPoint(x: centerX, y: centerY)
        let size = CGSize(width: sliderWidth, height: sliderHeight)
        let frame = createRectAroundCenter(center, size: size)
        let color2 = UIColor(red: 50/255, green: 163/255, blue: 216/255, alpha: 1)
        let colorScheme = (UIColor.whiteColor(), color2)
        let customSlider = CustomSlider(frame: frame, selectionPoints: endpoints, scheme: colorScheme)
        customSlider.backgroundColor = UIColor.clearColor()
        customSlider.thirdSuccessIndicator = self.thirdSuccessIndicator
        endpointView.addSubview(customSlider)
        endpointView.bringSubviewToFront(customSlider)
        customSlider.addTarget(self, action: "customSliderValueHasChanged:", forControlEvents: .ValueChanged)
        
        endpointView.customSlider = customSlider
        endpointView.offsetLength = (1 - widthPercentage)/2 * viewWidth
    }
    
    override func viewDidAppear(animated: Bool) { //add placeholders (view is properly set @ this time)
        thirdSuccessIndicator.hidden = false //normally on, except when slider is moving
        projectTitleTextView.placeholder = "Enter a title for your new project"
        projectQuestionTextView.placeholder = "What is the question that your project is trying to answer?"
        
        //Reset frame for endpointView after view frames have been set:
        let frame = endpointView.frame
        endpointView.frame = frame
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
                    //configure TF so that numbers so up on keyboard
                    textField.keyboardType = UIKeyboardType.NumberPad
                })
                presentViewController(alert, animated: true, completion: nil)
            } else { //user selected 'None' -> continuous endpoint
                selectedEndpoint = Endpoint(endpoint: Endpoints.Continuous, number: nil)
            }
        }
    }

    // MARK: - TextView Behavior
    
    func textViewDidChange(textView: UITextView) { //enable 'Create' button when name & question are entered & an endpoint is selected
        if (textView == projectTitleTextView) {
            if (textView.text != "") {
                projectTitle = textView.text.capitalizedString
                firstSuccessIndicatorIsSet = true
            } else {
                projectTitle = nil
                firstSuccessIndicatorIsSet = false
            }
        } else if (textView == projectQuestionTextView) {
            if (textView.text != "") {
                projectQuestion = textView.text
                secondSuccessIndicatorIsSet = true
            } else {
                projectQuestion = nil
                 secondSuccessIndicatorIsSet = false
            }
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
        //Check user defaults for preferences:
        let userDefaults = NSUserDefaults.standardUserDefaults()
        if let showDescription = userDefaults.valueForKey("SHOW_VARS_DESCRIPTION") as? Bool {
            if (showDescription) { //navigate -> descriptions pg.
                performSegueWithIdentifier("showVariablesDescription", sender: nil)
            } else { //go directly -> projectsVC page
                performSegueWithIdentifier("showVariables", sender: nil)
            }
        } else { //could not cast (means the value has not been set in defaults yet), -> descriptions page
            performSegueWithIdentifier("showVariablesDescription", sender: nil)
        }
    }
    
    @IBAction func cancelButtonClick(sender: AnyObject) { //return to home screen
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateInitialViewController()!
        presentViewController(controller, animated: true, completion: nil)
    }

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        //Pass the title, question, & endpoint through -> the remaining flows so that the complete project can be set up in the 'Summary' section:
        if (segue.identifier == "showVariablesDescription") { //description screen
            let nextVC = segue.destinationViewController as! ProjectVariablesDescriptionViewController
            nextVC.projectTitle = self.projectTitle
            nextVC.projectQuestion = self.projectQuestion
            nextVC.projectEndpoint = self.selectedEndpoint
        } else if (segue.identifier == "showVariables") {
            let destination = segue.destinationViewController as! ProjectVariablesViewController
            destination.projectTitle = self.projectTitle
            destination.projectQuestion = self.projectQuestion
            destination.projectEndpoint = self.selectedEndpoint
        }
    }

}
