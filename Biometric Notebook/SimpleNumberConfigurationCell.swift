//  SimpleNumberConfigurationCell.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 3/29/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Custom Config Cell - prompts the user to enter an integer value into a text field. 

import UIKit

class SimpleNumberConfigurationCell: BaseConfigurationCell, UITextFieldDelegate { //add new class -> enum!
    
    let textEntryField = UITextField(frame: CGRectZero) //make textField type safe (only allow Int)
    
    // MARK: - Initializers
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        textEntryField.borderStyle = .RoundedRect
        textEntryField.delegate = self
        textEntryField.textAlignment = .Center
        textEntryField.keyboardType = .NumberPad
        insetBackgroundView.addSubview(textEntryField)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    internal override func accessDataSource() { //obtain SUBCLASS-SPECIFIC info from data source
        super.accessDataSource()
        if let source = dataSource {
            if let defaultValue = source[BMN_Configuration_DefaultNumberKey] as? Int { //check for default
                textEntryField.text = "\(defaultValue)"
                fullString = "\(defaultValue)" //initialize report object
                configureCompletionIndicator(true) //set as complete if default exists
            }
        }
    }
    
    // MARK: - Visual Layout
    
    override func setNeedsLayout() {
        super.setNeedsLayout()
        
        //Layout textField (centered beneath the instructionsLabel):
        textEntryField.frame = getViewFrameForLevel(viewLevel: (2, HorizontalLevels.MidThirdLevel, nil))
    }
    
    // MARK: - Text Field
    
    var fullString: String? //string that is reported -> VC
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        if (string.characters.count > 0) { //block entry of non-numerical text
            guard let _ = Int(string) else { //make sure input is an Int
                return false
            }
        }
        if let text = textField.text {
            let trimmedText = text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            fullString = (text as NSString).stringByReplacingCharactersInRange(range, withString: string)
            let count = trimmedText.characters.count + string.characters.count - range.length
            if (count > 0) { //set as complete
                configureCompletionIndicator(true) //set as complete if textField is NOT empty
            } else { //set as incomplete
                configureCompletionIndicator(false)
            }
        }
        return true
    }
    
    // MARK: - Data Reporting
    
    override var configurationReportObject: AnyObject? { //*still reporting 1 back!
        //*REPORT TYPE: Int*
        if let inputText = fullString, let inputAsInt = Int(inputText) {
            return inputAsInt
        }
        return nil
    }
    
}