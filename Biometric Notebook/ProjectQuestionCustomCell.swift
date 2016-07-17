//  ProjectQuestionCustomCell.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 4/5/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Custom TV cell in CreateProjectVC for setting the project's question.

import UIKit

class ProjectQuestionCustomCell: BaseCreateProjectCell, UITextFieldDelegate {
    
    private let templateButtonIO = UIButton(frame: CGRectZero) //input/output project template
    private let templateButtonCC = UIButton(frame: CGRectZero) //control/comparison project template
    
    //IO view & subviews:
    private let ioView = UIImageView(frame: CGRectZero) //use img view so we can draw lines
    private let ioFirstLabel = UILabel(frame: CGRectZero) //'what is the impact of'
    private let ioVariablesTextField = UITextField(frame: CGRectZero)
    private let ioSecondLabel = UILabel(frame: CGRectZero) //'on'
    private let ioOutcomeTextField = UITextField(frame: CGRectZero)
    private let ioQuestionMark = UILabel(frame: CGRectZero) //'?' @ end
    
    //CC view & subviews:
    private let ccView = UIImageView(frame: CGRectZero) //use img view so we can draw lines
    private let ccFirstLabel = UILabel(frame: CGRectZero) //'Is'
    private let ccComparisonGroupsTextField = UITextField(frame: CGRectZero)
    private let ccSecondLabel = UILabel(frame: CGRectZero) //'or'
    private let ccControlGroupTextField = UITextField(frame: CGRectZero)
    private let ccThirdLabel = UILabel(frame: CGRectZero) //'better for'
    private let ccOutcomeTextField = UITextField(frame: CGRectZero)
    private let ccQuestionMark = UILabel(frame: CGRectZero) //'?' @ end
    
    //Constants:
    private let viewBackgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.7) //blend w/ cell color
    private let underlineWidth: CGFloat = 1
    private let underlineColor = UIColor.blackColor()
    
    var projectType: ExperimentTypes? {
        didSet {
            var ccType: Bool = false
            if (projectType == .ControlComparison) { //CC type project
                ccType = true
            }
            let notification = NSNotification(name: BMN_Notification_ProjectTypeDidChange, object: nil, userInfo: [BMN_CellWithCustomSlider_ProjectIsCCTypeKey: ccType])
            NSNotificationCenter.defaultCenter().postNotification(notification)
        }
    }
    private var ioVariablesFieldComplete: Bool = false { //completion indicator
        didSet {
            setCompletionIndicatorForTextFields()
        }
    }
    private var ioOutcomeFieldComplete: Bool = false { //completion indicator
        didSet {
            setCompletionIndicatorForTextFields()
        }
    }
    private var ccComparisonsFieldComplete: Bool = false { //completion indicator
        didSet {
            setCompletionIndicatorForTextFields()
        }
    }
    private var ccControlFieldComplete: Bool = false { //completion indicator
        didSet {
            setCompletionIndicatorForTextFields()
        }
    }
    private var ccOutcomeFieldComplete: Bool = false { //completion indicator
        didSet {
            setCompletionIndicatorForTextFields()
        }
    }
    
    // MARK: - Initializers
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        let ioAttributes: [String: AnyObject] = [NSFontAttributeName: UIFont.boldSystemFontOfSize(13), NSForegroundColorAttributeName: UIColor.darkGrayColor()]
        let ioString = NSAttributedString(string: "1) I'm looking for correlations between input & output variables", attributes: ioAttributes)
        let ccAttributes: [String: AnyObject] = [NSFontAttributeName: UIFont.boldSystemFontOfSize(13), NSForegroundColorAttributeName: UIColor.darkTextColor()]
        let ccString = NSAttributedString(string: "2) I'm comparing an experimental group to a control group", attributes: ccAttributes)
        
        //Configure IO template button:
        templateButtonIO.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.75) //lighter
        templateButtonIO.layer.cornerRadius = 5
        templateButtonIO.setAttributedTitle(ioString, forState: .Normal)
        templateButtonIO.titleLabel?.numberOfLines = 2
        templateButtonIO.addTarget(self, action: #selector(self.ioTemplateButtonClick(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        insetBackgroundView.addSubview(templateButtonIO)
        
        //Configure CC template button:
        templateButtonCC.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.50) //darker
        templateButtonCC.layer.cornerRadius = 5
        templateButtonCC.setAttributedTitle(ccString, forState: .Normal)
        templateButtonCC.titleLabel?.numberOfLines = 2
        templateButtonCC.addTarget(self, action: #selector(self.ccTemplateButtonClick(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        insetBackgroundView.addSubview(templateButtonCC)
        
        //Configure IO template labels/textFields & hide:
        ioView.userInteractionEnabled = true //need this to interact w/ TF
        ioView.backgroundColor = viewBackgroundColor
        ioView.layer.borderColor = UIColor.blackColor().CGColor
        ioView.layer.borderWidth = 1
        
        ioFirstLabel.text = "What is the impact of"
        ioView.addSubview(ioFirstLabel)
        ioVariablesTextField.placeholder = "<variable(s)>"
        ioVariablesTextField.autocapitalizationType = .None
        ioView.addSubview(ioVariablesTextField)
        ioSecondLabel.text = "on"
        ioView.addSubview(ioSecondLabel)
        ioOutcomeTextField.placeholder = "<outcome(s) of interest>"
        ioOutcomeTextField.autocapitalizationType = .None
        ioView.addSubview(ioOutcomeTextField)
        ioQuestionMark.text = "?"
        ioView.addSubview(ioQuestionMark)
        configureSubviews(ioView)
        ioView.hidden = true //hide
        insetBackgroundView.addSubview(ioView)
        
        //Configure CC template labels/textFields & hide:
        ccView.userInteractionEnabled = true //need this to interact w/ TF
        ccView.backgroundColor = viewBackgroundColor
        ccView.layer.borderColor = UIColor.blackColor().CGColor
        ccView.layer.borderWidth = 1
        
        ccFirstLabel.text = "Is"
        ccView.addSubview(ccFirstLabel)
        ccComparisonGroupsTextField.placeholder = "<comparison group>"
        ccComparisonGroupsTextField.autocapitalizationType = .None
        ccView.addSubview(ccComparisonGroupsTextField)
        ccSecondLabel.text = "or"
        ccView.addSubview(ccSecondLabel)
        ccControlGroupTextField.placeholder = "<control grp>"
        ccControlGroupTextField.autocapitalizationType = .None
        ccView.addSubview(ccControlGroupTextField)
        ccThirdLabel.text = "better for"
        ccView.addSubview(ccThirdLabel)
        ccOutcomeTextField.placeholder = "<outcome(s) of interest>"
        ccOutcomeTextField.autocapitalizationType = .None
        ccView.addSubview(ccOutcomeTextField)
        ccQuestionMark.text = "?"
        ccView.addSubview(ccQuestionMark)
        configureSubviews(ccView)
        ccView.hidden = true //hide
        insetBackgroundView.addSubview(ccView)
        
        //Configure firstLevelRightButton (reset btn) & hide:
        firstLevelRightButton = UIButton(frame: CGRectZero)
        firstLevelRightButton?.addTarget(self, action: #selector(self.resetButtonClick(_:)), forControlEvents: .TouchUpInside)
        firstLevelRightButton?.setImage(UIImage(named: "rotate"), forState: .Normal) //*get new img
        insetBackgroundView.addSubview(firstLevelRightButton!)
        firstLevelRightButton?.hidden = true //hide initially
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureSubviews(view: UIView) { //configure all subviews
        let boldFont = UIFont.boldSystemFontOfSize(15)
        let normalFont = UIFont.systemFontOfSize(15)
        for subview in view.subviews {
            if subview is UILabel {
                (subview as! UILabel).textAlignment = .Center
                (subview as! UILabel).font = boldFont
                (subview as! UILabel).backgroundColor = UIColor.clearColor() //clear bckground
            } else if subview is UITextField {
                (subview as! UITextField).delegate = self
                (subview as! UITextField).textAlignment = .Center
                (subview as! UITextField).autocapitalizationType = .None
                (subview as! UITextField).font = normalFont
                (subview as! UITextField).backgroundColor = UIColor(red: 164/255, green: 190/255, blue: 211/255, alpha: 0.65) //light blue/gray
            }
        }
    }
    
    // MARK: - Visual Layout
    
    override func setNeedsLayout() {
        super.setNeedsLayout()
        
        //Layout template btns:
        templateButtonIO.frame = getViewFrameForLevel(viewLevel: (2, HorizontalLevels.FullLevel, nil))
        templateButtonCC.frame = getViewFrameForLevel(viewLevel: (3, HorizontalLevels.FullLevel, nil))
        
        let verticalSpacer: CGFloat = 4
        let horizontalSpacer: CGFloat = 6
        
        //Layout ioView w/ subviews:
        ioView.frame = getViewFrameForLevel(viewLevel: (2, HorizontalLevels.FullLevel, 3))
        let ioThirdHeight = ioView.frame.height/3
        let ioSpacedHeight = ioThirdHeight - 2 * verticalSpacer
        let ioViewWidth = ioView.frame.width
        let ioSpacedWidth = ioViewWidth - 2 * horizontalSpacer
        
        ioFirstLabel.frame = CGRectMake(horizontalSpacer, verticalSpacer, ioSpacedWidth, ioSpacedHeight) //line 1
        
        ioVariablesTextField.frame = CGRectMake(horizontalSpacer, (ioThirdHeight + verticalSpacer), ioSpacedWidth, ioSpacedHeight) //line 2
        
        ioSecondLabel.frame = CGRectMake(horizontalSpacer, (ioThirdHeight * 2 + verticalSpacer), 20, ioSpacedHeight) //start line 3
        let questionMarkWidth: CGFloat = 18 //width of ? mark lbl
        ioOutcomeTextField.frame = CGRectMake((ioSecondLabel.frame.width + horizontalSpacer * 2), (ioThirdHeight * 2 + verticalSpacer), (ioSpacedWidth - ioSecondLabel.frame.width - questionMarkWidth - 2 * horizontalSpacer), ioSpacedHeight) //middle line 3
        ioQuestionMark.frame = CGRectMake((ioSecondLabel.frame.width + ioOutcomeTextField.frame.width + 3 * horizontalSpacer), (ioThirdHeight * 2 + verticalSpacer), questionMarkWidth, ioSpacedHeight) //end line 3
        
        
        //Draw 2 lines on ioView (1 under each textField):
        let varsTFFromPoint = CGPoint(x: ioVariablesTextField.frame.minX, y: (ioVariablesTextField.frame.maxY + verticalSpacer/2)) //bottom L corner of frame
        let varsTFToPoint = CGPoint(x: ioVariablesTextField.frame.maxX, y: (ioVariablesTextField.frame.maxY + verticalSpacer/2)) //bottom R corner of frame
        let ioOutcomeTFFromPoint = CGPoint(x: ioOutcomeTextField.frame.minX, y: (ioOutcomeTextField.frame.maxY + verticalSpacer/2)) //bottom L corner
        let ioOutcomeTFToPoint = CGPoint(x: ioOutcomeTextField.frame.maxX, y: (ioOutcomeTextField.frame.maxY + verticalSpacer/2)) //bottom R corner
        drawLine(ioView, fromPoint: [varsTFFromPoint, ioOutcomeTFFromPoint], toPoint: [varsTFToPoint, ioOutcomeTFToPoint], lineColor: underlineColor, lineWidth: underlineWidth)
        
        //Layout ccView w/ subviews:
        ccView.frame = getViewFrameForLevel(viewLevel: (2, HorizontalLevels.FullLevel, 3))
        let ccThirdHeight = ccView.frame.height/3
        let ccSpacedHeight = ccThirdHeight - 2 * verticalSpacer
        let ccWidth = ccView.frame.width
        let ccSpacedWidth = ccWidth - 2 * horizontalSpacer
        
        ccFirstLabel.frame = CGRectMake(horizontalSpacer, verticalSpacer, 20, ccSpacedHeight) //line 1
        let secondLblWidth: CGFloat = 20
        ccComparisonGroupsTextField.frame = CGRectMake((ccFirstLabel.frame.width + 2 * horizontalSpacer), verticalSpacer, (ccSpacedWidth - ccFirstLabel.frame.width - secondLblWidth - 2 * horizontalSpacer), ccSpacedHeight) //line 1 mid
        ccSecondLabel.frame = CGRectMake((ccFirstLabel.frame.width + ccComparisonGroupsTextField.frame.width + 3 * horizontalSpacer), verticalSpacer, secondLblWidth, ccSpacedHeight) //line 1 end
        
        ccControlGroupTextField.frame = CGRectMake(horizontalSpacer, (ccThirdHeight + verticalSpacer), (ccSpacedWidth/2), ccSpacedHeight) //line 2 (first half)
        ccThirdLabel.frame = CGRectMake((ccControlGroupTextField.frame.width + 2 * horizontalSpacer), (ccThirdHeight + verticalSpacer), (ccSpacedWidth/2 - horizontalSpacer), ccSpacedHeight) //line 2 (2nd half)
        
        let questionWidth: CGFloat = 20
        ccOutcomeTextField.frame = CGRectMake(horizontalSpacer, (ccThirdHeight * 2 + verticalSpacer), (ccSpacedWidth - questionWidth - horizontalSpacer), ccSpacedHeight) //line 3 start
        ccQuestionMark.frame = CGRectMake((ccOutcomeTextField.frame.width + 2 * horizontalSpacer), (ccThirdHeight * 2 + verticalSpacer), questionWidth, ccSpacedHeight) //line 3 end
        
        //Draw 3 lines on ccView (1 under each textField):
        let comparisonsTFFromPoint = CGPoint(x: ccComparisonGroupsTextField.frame.minX, y: (ccComparisonGroupsTextField.frame.maxY + verticalSpacer/2)) //bottom L corner
        let comparisonsTFToPoint = CGPoint(x: ccComparisonGroupsTextField.frame.maxX, y: (ccComparisonGroupsTextField.frame.maxY + verticalSpacer/2)) //bottom R corner
        let controlTFFromPoint = CGPoint(x: ccControlGroupTextField.frame.minX, y: (ccControlGroupTextField.frame.maxY + verticalSpacer/2)) //bottom L corner
        let controlTFToPoint = CGPoint(x: ccControlGroupTextField.frame.maxX, y: (ccControlGroupTextField.frame.maxY + verticalSpacer/2)) //bottom R corner
        let ccOutcomeTFFromPoint = CGPoint(x: ccOutcomeTextField.frame.minX, y: (ccOutcomeTextField.frame.maxY + verticalSpacer/2)) //bottom L corner
        let ccOutcomeTFToPoint = CGPoint(x: ccOutcomeTextField.frame.maxX, y: (ccOutcomeTextField.frame.maxY + verticalSpacer/2)) //bottom R corner
        drawLine(ccView, fromPoint: [comparisonsTFFromPoint, controlTFFromPoint, ccOutcomeTFFromPoint], toPoint: [comparisonsTFToPoint, controlTFToPoint, ccOutcomeTFToPoint], lineColor: underlineColor, lineWidth: underlineWidth)
    }
    
    // MARK: - Text Field
    
    var ioVariablesFullText: String? //IO string reported -> VC
    var ioOutcomeFullText: String? //IO string reported -> VC
    var ccComparisonsFullText: String? //CC string reported -> VC
    var ccControlFullText: String? //CC string reported -> VC
    var ccOutcomeFullText: String? //CC string reported -> VC
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool { //adjust completion indicator when all fields are filled
        if let text = textField.text {
            let trimmedText = text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            let trimmedString = string.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            let fullText = (text as NSString).stringByReplacingCharactersInRange(range, withString: string) //report obj contains FULL text (w/ replaced characters)
            if (textField == ioVariablesTextField) { //IO view - variables
                ioVariablesFullText = fullText
                if (trimmedText.characters.count + trimmedString.characters.count - range.length) > 0 {
                    ioVariablesFieldComplete = true
                } else { //INCOMPLETE field
                    ioVariablesFieldComplete = false
                }
            } else if (textField == ioOutcomeTextField) { //IO view - outcome of interest
                ioOutcomeFullText = fullText
                if (trimmedText.characters.count + trimmedString.characters.count - range.length) > 0 {
                    ioOutcomeFieldComplete = true
                } else { //INCOMPLETE field
                    ioOutcomeFieldComplete = false
                }
            } else if (textField == ccComparisonGroupsTextField) { //CC view - comparison groups
                ccComparisonsFullText = fullText
                if (trimmedText.characters.count + trimmedString.characters.count - range.length) > 0 {
                    ccComparisonsFieldComplete = true
                } else { //INCOMPLETE field
                    ccComparisonsFieldComplete = false
                }
            } else if (textField == ccControlGroupTextField) { //CC view - control group
                ccControlFullText = fullText
                if (trimmedText.characters.count + trimmedString.characters.count - range.length) > 0 {
                    ccControlFieldComplete = true
                } else { //INCOMPLETE field
                    ccControlFieldComplete = false
                }
            } else if (textField == ccOutcomeTextField) { //CC view - outcome of interest
                ccOutcomeFullText = fullText
                if (trimmedText.characters.count + trimmedString.characters.count - range.length) > 0 {
                    ccOutcomeFieldComplete = true
                } else { //INCOMPLETE field
                    ccOutcomeFieldComplete = false
                }
            }
        }
        return true
    }
    
    private func setCompletionIndicatorForTextFields() { //checks completion status
        if let type = projectType {
            if (type == ExperimentTypes.InputOutput) {
                if (ioVariablesFieldComplete) && (ioOutcomeFieldComplete) { //COMPLETE
                    configureCompletionIndicator(true)
                } else { //INCOMPLETE
                    configureCompletionIndicator(false)
                }
            } else if (type == ExperimentTypes.ControlComparison) {
                if (ccComparisonsFieldComplete) && (ccControlFieldComplete) && (ccOutcomeFieldComplete) {
                    configureCompletionIndicator(true)
                } else { //INCOMPLETE
                    configureCompletionIndicator(false)
                }
            }
        }
    }
    
    // MARK: - Button Actions
    
    @IBAction func ioTemplateButtonClick(sender: UIButton) {
        self.projectType = ExperimentTypes.InputOutput
        revealTextEntryMode(true, sender: sender)
    }
    
    @IBAction func ccTemplateButtonClick(sender: UIButton) {
        self.projectType = ExperimentTypes.ControlComparison
        revealTextEntryMode(true, sender: sender)
    }
    
    @IBAction func resetButtonClick(sender: UIButton) { //resets interface (shows both template btn options again)
        //Reset all completion indicators & CLEAR txt in fields:
        if let type = projectType {
            if (type == ExperimentTypes.InputOutput) {
                ioVariablesFieldComplete = false
                ioVariablesTextField.text = ""
                ioOutcomeFieldComplete = false
                ioOutcomeTextField.text = ""
            } else if (type == ExperimentTypes.ControlComparison) {
                ccComparisonsFieldComplete = false
                ccComparisonGroupsTextField.text = ""
                ccControlFieldComplete = false
                ccControlGroupTextField.text = ""
                ccOutcomeFieldComplete = false
                ccOutcomeTextField.text = ""
            }
        }
        
        self.projectType = nil //clear projectType
        revealTextEntryMode(false, sender: sender)
    }
    
    func revealTextEntryMode(reveal: Bool, sender: UIButton) { //reveal or hide btns, labels, & textFields
        templateButtonCC.hidden = reveal
        templateButtonIO.hidden = reveal
        firstLevelRightButton?.hidden = !reveal
        
        if (sender == templateButtonIO) {
            ioView.hidden = false
            ioVariablesTextField.becomeFirstResponder()
        } else if (sender == templateButtonCC) {
            ccView.hidden = false
            ccComparisonGroupsTextField.becomeFirstResponder()
        } else if (sender == firstLevelRightButton!) { //hide BOTH views on RESET click
            ioView.hidden = true
            ccView.hidden = true
            self.endEditing(true) //resign 1st responder
        }
    }
    
    // MARK: - Report Data
    
    override func reportData() { //send notification -> VC w/ question & experiment type
        var combinedText: String = ""
        if let type = projectType { //obtain combined question for appropriate view
            if (type == ExperimentTypes.InputOutput) {
                if let first = ioFirstLabel.text, second = ioVariablesFullText, third = ioSecondLabel.text, fourth = ioOutcomeFullText {
                    combinedText = "\(first) \(second) \(third) \(fourth)?"
                }
            } else if (type == ExperimentTypes.ControlComparison) {
                if let first = ccFirstLabel.text, second = ccComparisonsFullText, third = ccSecondLabel.text, fourth = ccControlFullText, fifth = ccThirdLabel.text, sixth = ccOutcomeFullText {
                    combinedText = "\(first) \(second) \(third) \(fourth) \(fifth) \(sixth)?"
                }
            }
            let notification = NSNotification(name: BMN_Notification_CellDidReportData, object: nil, userInfo: [BMN_ProjectQuestionID: combinedText, BMN_ProjectTypeID: type.rawValue]) //report ? & projectType
            NSNotificationCenter.defaultCenter().postNotification(notification)
        }
    }
    
}