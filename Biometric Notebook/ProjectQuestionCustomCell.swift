//  ProjectQuestionCustomCell.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 4/5/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Custom TV cell in CreateProjectVC for setting the project's question.

import UIKit

class ProjectQuestionCustomCell: CreateProjectTableViewCell, UITextFieldDelegate {
    
    private let templateButtonIO = UIButton(frame: CGRectZero) //input/output project template
    private let templateButtonCC = UIButton(frame: CGRectZero) //control/comparison project template
    private let topTemplateLabel = UILabel(frame: CGRectZero)
    private let bottomTemplateLabel = UILabel(frame: CGRectZero)
    let topTextField = UITextField(frame: CGRectZero) //need external access to drop 1st responder
    let bottomTextField = UITextField(frame: CGRectZero) //need external access to drop 1st responder
    
    private let viewBackgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1) //*
    private let viewFont = UIFont.systemFontOfSize(14)
    
    private var topFieldComplete: Bool = false { //completion indicator
        didSet {
            setCompletionIndicatorForTextFields()
        }
    }
    private var bottomFieldComplete: Bool = false { //completion indicator
        didSet {
            setCompletionIndicatorForTextFields()
        }
    }
    var projectType: ExperimentTypes?
    
    // MARK: - Initializers
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        //Configure IO template button:
        templateButtonIO.backgroundColor = UIColor.whiteColor()
        templateButtonIO.layer.cornerRadius = 10
        templateButtonIO.setTitle("I'm studying how input factors correlate", forState: UIControlState.Normal)
        templateButtonIO.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
        templateButtonIO.addTarget(self, action: #selector(self.ioTemplateButtonClick(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        insetBackgroundView.addSubview(templateButtonIO)
        
        //Configure CC template button:
        templateButtonCC.backgroundColor = UIColor.whiteColor()
        templateButtonCC.layer.cornerRadius = 10
        templateButtonCC.setTitle("I'm comparing two or more options", forState: UIControlState.Normal)
        templateButtonCC.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
        templateButtonCC.addTarget(self, action: #selector(self.ccTemplateButtonClick(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        insetBackgroundView.addSubview(templateButtonCC)
        
        //Configure template labels/textField & hide:
        topTemplateLabel.font = viewFont
        topTemplateLabel.hidden = true
        topTemplateLabel.backgroundColor = viewBackgroundColor
        
        topTextField.font = viewFont
        topTextField.hidden = true
        topTextField.backgroundColor = viewBackgroundColor
        topTextField.delegate = self
        
        bottomTemplateLabel.font = viewFont
        bottomTemplateLabel.hidden = true
        bottomTemplateLabel.backgroundColor = viewBackgroundColor
        
        bottomTextField.font = viewFont
        bottomTextField.hidden = true
        bottomTextField.backgroundColor = viewBackgroundColor
        bottomTextField.delegate = self
        
        insetBackgroundView.addSubview(topTemplateLabel)
        insetBackgroundView.addSubview(topTextField)
        insetBackgroundView.addSubview(bottomTemplateLabel)
        insetBackgroundView.addSubview(bottomTextField)
        
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
    
    // MARK: - Visual Layout
    
    override func setNeedsLayout() {
        super.setNeedsLayout()
        
        //Layout template btns:
        templateButtonIO.frame = getViewFrameForLevel(viewLevel: (2, HorizontalLevels.FullLevel, nil))
        templateButtonCC.frame = getViewFrameForLevel(viewLevel: (3, HorizontalLevels.FullLevel, nil))
        
        //Layout lbls & txtFields:
        topTemplateLabel.frame = getViewFrameForLevel(viewLevel: (2, HorizontalLevels.LeftHalfLevel, nil))
        topTextField.frame = getViewFrameForLevel(viewLevel: (2, HorizontalLevels.RightHalfLevel, nil))
        bottomTemplateLabel.frame = getViewFrameForLevel(viewLevel: (3, HorizontalLevels.LeftHalfLevel, nil))
        bottomTextField.frame = getViewFrameForLevel(viewLevel: (3, HorizontalLevels.RightHalfLevel, nil))
    }
    
    // MARK: - Text Field
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool { //adjust completion indicator when both fields are filled
        if let text = textField.text?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) {
            if (textField == topTextField) {
                if (text.characters.count + string.characters.count - range.length) > 0 {
                    topFieldComplete = true
                } else { //INCOMPLETE field
                    topFieldComplete = false
                }
            } else if (textField == bottomTextField) {
                if (text.characters.count + string.characters.count - range.length) > 0 {
                    bottomFieldComplete = true
                } else { //INCOMPLETE field
                    bottomFieldComplete = false
                }
            }
        }
        return true
    }
    
    private func setCompletionIndicatorForTextFields() {
        if (topFieldComplete) && (bottomFieldComplete) { //COMPLETE
            configureCompletionIndicator(true)
        } else { //INCOMPLETE
            configureCompletionIndicator(false)
        }
    }
    
    // MARK: - Button Actions
    
    @IBAction func ioTemplateButtonClick(sender: UIButton) {
        topTemplateLabel.text = "IO button"
        bottomTemplateLabel.text = "IO button"
        self.projectType = ExperimentTypes.InputOutput
        revealTextEntryMode(true)
    }
    
    @IBAction func ccTemplateButtonClick(sender: UIButton) {
        topTemplateLabel.text = "CC button"
        bottomTemplateLabel.text = "CC button"
        self.projectType = ExperimentTypes.ControlComparison
        revealTextEntryMode(true)
    }
    
    @IBAction func resetButtonClick(sender: UIButton) { //resets interface (shows both template btn options again)
        topFieldComplete = false //reset
        bottomFieldComplete = false //reset
        self.projectType = nil //clear projectType
        revealTextEntryMode(false)
    }
    
    func revealTextEntryMode(reveal: Bool) { //reveal or hide btns, labels, & textFields
        templateButtonCC.hidden = reveal
        templateButtonIO.hidden = reveal
        firstLevelRightButton?.hidden = !reveal
        
        topTemplateLabel.hidden = !reveal
        topTextField.hidden = !reveal
        topTextField.text = "" //clear txt each time
        bottomTemplateLabel.hidden = !reveal
        bottomTextField.hidden = !reveal
        bottomTextField.text = "" //clear txt each time
    }
    
    // MARK: - Report Data
    
    override func reportData() -> AnyObject? {
        if let first = topTemplateLabel.text, second = topTextField.text, third = bottomTemplateLabel.text, fourth = bottomTextField.text {
            let combinedText = "\(first) \(second) \(third) \(fourth)" //get combined question
            print("[reportData] Combined Text: '\(combinedText)'.")
            return combinedText
        }
        return nil
    }
    
    func reportProjectType() -> ExperimentTypes? {
        return self.projectType
    }
    
}