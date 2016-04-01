//  SimpleNumberConfigurationCell.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 3/29/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Prompts the user to enter an integer value into a text field. 

import UIKit

class SimpleNumberConfigurationCell: BaseConfigurationCell, UITextFieldDelegate {
    
    let textEntryField = UITextField(frame: CGRectZero) //make textField type safe (only allow Int)
    
    // MARK: - Initializers
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        textEntryField.borderStyle = .RoundedRect
        textEntryField.delegate = self
        textEntryField.textAlignment = .Center
        insetBackground.addSubview(textEntryField)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Visual Layout
    
    internal override func accessDataSource() { //obtain SUBCLASS-SPECIFIC info from data source
        super.accessDataSource()
        if let source = dataSource {
            if let defaultValue = source[BMN_Configuration_DefaultNumberKey] as? Int { //check for default
                textEntryField.text = "\(defaultValue)"
                self.configurationIsComplete = true //set as complete if default exists
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        //Configure textField (centered beneath the instructionsLabel):
        let width = CGFloat(80)
        let originX = instructionsLabelCenterX - width/2
        let textFieldFrame = CGRectMake(originX, (instructionsLabelTopPadding + instructionsLabelHeight + 1), width, 30)
        textEntryField.frame = textFieldFrame
    }
    
    // MARK: - Text Field
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        if (string.characters.count > 0) { //block entry of non-numerical text
            guard let _ = Int(string) else { //make sure input is an Int
                return false
            }
        }
        if let input = textField.text?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) {
            let count = input.characters.count + string.characters.count - range.length
            if (count > 0) { //set as complete
                self.configurationIsComplete = true //set as complete if textField is not empty
            } else { //set as incomplete
                self.configurationIsComplete = false
            }
        }
        return true
    }
    
    // MARK: - Data Reporting
    
    internal override func reportData() -> AnyObject? {
        //*REPORT TYPE: Int*
        if let inputText = textEntryField.text, let inputAsInt = Int(inputText) {
            return inputAsInt
        }
        return nil
    }
    
}