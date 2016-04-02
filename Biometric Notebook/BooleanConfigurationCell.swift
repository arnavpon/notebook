//  BooleanConfigurationCell.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 4/2/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Configuration cell w/ 2 buttons - YES & NO. 

import UIKit

class BooleanConfigurationCell: BaseConfigurationCell {
    
    let yesButton = UIButton(frame: CGRectZero) //YES option
    let noButton = UIButton(frame: CGRectZero) //NO option
    
    var currentSelection: Bool = false { //FALSE -> NO button, TRUE -> YES button
        didSet {
            configureVisualsForSelection()
        }
    }
    
    // MARK: - Initializers
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureVisualsForSelection() //manually fire this fx on initialization!
        
        let defaultFont = UIFont.systemFontOfSize(18)
        let boldFont = UIFont.boldSystemFontOfSize(18)
        let fontColor = UIColor.blackColor()
        let defaultAttributes = [NSFontAttributeName: defaultFont, NSForegroundColorAttributeName: fontColor]
        let boldAttributes = [NSFontAttributeName: boldFont, NSForegroundColorAttributeName: fontColor]
        
        let yesDefault = NSAttributedString(string: "YES", attributes: defaultAttributes)
        let yesHighlighted = NSAttributedString(string: "YES", attributes: boldAttributes)
        yesButton.backgroundColor = UIColor.greenColor()
        yesButton.setAttributedTitle(yesDefault, forState: UIControlState.Normal)
        yesButton.setAttributedTitle(yesHighlighted, forState: UIControlState.Highlighted)
        yesButton.addTarget(self, action: #selector(self.yesButtonClick(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        
        let noDefault = NSAttributedString(string: "NO", attributes: defaultAttributes)
        let noHighlighted = NSAttributedString(string: "NO", attributes: boldAttributes)
        noButton.backgroundColor = UIColor.redColor()
        noButton.setAttributedTitle(noDefault, forState: UIControlState.Normal)
        noButton.setAttributedTitle(noHighlighted, forState: UIControlState.Highlighted)
        noButton.addTarget(self, action: #selector(self.noButtonClick(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        
        insetBackground.addSubview(yesButton)
        insetBackground.addSubview(noButton)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Visual Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        //Configure buttons side by side, w/ some space in between:
        let buttonWidth: CGFloat = 55
        let buttonHeight: CGFloat = 30
        let viewCenter = (insetBackground.frame.width - completionViewWidth)/2
        let offSet: CGFloat = 10
        
        //Center both buttons around the middle of the frame w/ some spacing in between:
        let yesOriginX = viewCenter - offSet - buttonWidth
        yesButton.frame = CGRectMake(yesOriginX, startingY, buttonWidth, buttonHeight)
        let noOriginX = viewCenter + offSet
        noButton.frame = CGRectMake(noOriginX, startingY, buttonWidth, buttonHeight)
    }
    
    // MARK: - Button Actions
    
    @IBAction func yesButtonClick(sender: UIButton) {
        currentSelection = true
    }
    
    @IBAction func noButtonClick(sender: UIButton) {
        currentSelection = false
    }
    
    private func configureVisualsForSelection() {
        let reducedAlpha: CGFloat = 0.3
        if (currentSelection == true) { //selection is TRUE/YES
            yesButton.alpha = 1
            yesButton.highlighted = true //triggers attributedText
            noButton.alpha = reducedAlpha
            noButton.highlighted = false //remove highlight from de-selected btn
        } else { //selection is FALSE/NO
            yesButton.alpha = reducedAlpha
            yesButton.highlighted = false //remove highlight from de-selected btn
            noButton.alpha = 1
            noButton.highlighted = true //triggers attributedText
        }
        configureCompletionIndicator(true) //completion indicator is always checked
    }
    
    // MARK: - Data Reporting
    
    internal override func reportData() -> AnyObject? { //checks the currently highlighted button & reports TRUE for yes, FALSE for no
        //*REPORT TYPE: Bool*
        return currentSelection
    }
    
}