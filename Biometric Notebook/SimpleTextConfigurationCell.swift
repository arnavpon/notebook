//  SimpleTextConfigurationCell.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 3/29/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Custom Config Cell - prompts the user to enter text into a txtLabel.

import UIKit

class SimpleTextConfigurationCell: BaseConfigurationCell, UITextFieldDelegate { //add new class -> enum!

    let textEntryField = UITextField(frame: CGRectZero)
    
    // MARK: - Initializers
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        textEntryField.delegate = self
        textEntryField.textAlignment = .Center
        textEntryField.borderStyle = .RoundedRect
        insetBackgroundView.addSubview(textEntryField)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Visual Layout
    
    override func setNeedsLayout() {
        super.setNeedsLayout()
        textEntryField.frame = getViewFrameForLevel(viewLevel: (2, HorizontalLevels.RightTwoThirdsLevel, nil)) //layout textField
    }
    
    // MARK: - Text Field
    
    var fullString: String? //string that is reported -> VC
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        if let text = textField.text {
            let trimmedText = text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            let trimmedString = string.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            fullString = (text as NSString).stringByReplacingCharactersInRange(range, withString: string)
            let count = trimmedText.characters.count + trimmedString.characters.count - range.length
            if (count > 0) { //set as complete if textField is not empty
                configureCompletionIndicator(true)
            } else { //set as incomplete
                configureCompletionIndicator(false)
            }
        }
        return true
    }
    
    // MARK: - Data Reporting
    
    override var configurationReportObject: AnyObject? { //reports text in textField
        //*REPORT TYPE: String*
        if let inputText = fullString {
            return inputText
        }
        return nil
    }
    
}
