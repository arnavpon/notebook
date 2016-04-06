//  CellWithTextView.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 4/5/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Custom TV cell for CreateProjectVC that contains a textView for entering a project title.

import UIKit

class CellWithTextView: CreateProjectTableViewCell, UITextViewDelegate {
    
    let customTextView = CustomTextView(frame: CGRectZero, textContainer: nil) //txtView w/ placeholder
    
    // MARK: - Initializers
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.numberOfHiddenLevels = 3 //# of hidden levels to reveal if + button is clicked
        self.insetBackgroundView.addSubview(customTextView)
        customTextView.delegate = self
        customTextView.font = UIFont.systemFontOfSize(18)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Visual Layout
    
    override func setNeedsLayout() { //textView goes on level 2+
        super.setNeedsLayout()
        customTextView.frame = self.getViewFrameForLevel(viewLevel: (2, HorizontalLevels.FullLevel, 3))
    }
    
    // MARK: - Text View
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool { //control completionIndicator based on text in view
        let input = textView.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        let count = input.characters.count + text.characters.count - range.length
        if (count > 0) { //set as complete if textField is not empty
            configureCompletionIndicator(true)
        } else { //set as incomplete
            configureCompletionIndicator(false)
        }
        return true
    }
    
    // MARK: - Button Actions
    
    override func plusButtonClick(sender: UIButton) {
        super.plusButtonClick(sender)
        if !(self.isLowerLevelHidden) { //if the textView is hidden again, clear the text!
            customTextView.text = ""
            configureCompletionIndicator(false)
        }
    }
    
    // MARK: - Data Reporting
    
    override func reportData() -> AnyObject? {
        return customTextView.text
    }
    
}