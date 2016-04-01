//  SimpleTextConfigurationCell.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 3/29/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Prompts the user to enter text into a txtLabel.

import UIKit

class SimpleTextConfigurationCell: BaseConfigurationCell, UITextFieldDelegate {

    let textEntryField = UITextField(frame: CGRectZero)
    
    // MARK: - Initializers
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        textEntryField.delegate = self
        textEntryField.textAlignment = .Center
        textEntryField.borderStyle = .RoundedRect
        insetBackground.addSubview(textEntryField)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Visual Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        //Configure textField:
        let textFieldPadding = instructionsLabelLeftPadding + 2 //inset slightly from instructionLabel
        let textFieldWidth = frame.width - completionViewWidth - 2 * textFieldPadding
        let textFieldFrame = CGRectMake(textFieldPadding, (instructionsLabelTopPadding + instructionsLabelHeight + 1), textFieldWidth, 30)
        textEntryField.frame = textFieldFrame
    }
    
    // MARK: - Text Field
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        if let input = textField.text?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) {
            let count = input.characters.count + string.characters.count - range.length
            if (count > 0) { //set as complete if textField is not empty
                self.configurationIsComplete = true
            } else { //set as incomplete
                self.configurationIsComplete = false
            }
        }
        return true
    }
    
    // MARK: - Data Reporting
    
    internal override func reportData() -> AnyObject? {
        //*REPORT TYPE: String*
        if let inputText = textEntryField.text {
            return inputText
        }
        return nil
    }
    
}
