//  FreeformDataEntryCell.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 4/26/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// GENERAL DataEntry Cell > contains textLabel that allows freeform data entry (e.g. weight & height). Cell can be further configured to set a default value, type protections for entries, character limits, textField size, etc.

import UIKit

enum ProtectedFreeformTypes: String { //list of protected freeform types - used as a type check for data entered into the textField
    
    case Int = "BMN_ProtectedFreeformType_Int"
    
}

class FreeformDataEntryCell: BaseDataEntryCell, UITextFieldDelegate { //add new class -> enum!
    
    override class var numberOfLevels: Int { //cell has 2 layers (topLayer + 1 for textLabel)
        return 2
    }
    
    private var enteredValue: String? { //value entered into textField
        didSet {
            updateModuleReportObject() //update Module w/ new selection
        }
    }
    private let mainTextField = UITextField(frame: CGRectZero)
    
    //Custom configuration items (set by module class):
    private var allowedType: ProtectedFreeformTypes? //type check for the data entered into the TF
    private var characterLimit: Int? //limit # of characters
    
    // MARK: - Initializers
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        //Configure textField:
        insetBackgroundView.addSubview(mainTextField) //add -> background view
        mainTextField.delegate = self
        mainTextField.borderStyle = .RoundedRect
        mainTextField.textAlignment = .Center
        mainTextField.font = UIFont.systemFontOfSize(15) //**
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override internal func accessModuleProperties() { //use Module type/selection to format cell's visuals
        super.accessModuleProperties()
        if let mod = self.module { //GENERAL cell (no specific module type)
            //Access configuration parameters in Module superclass:
            if let defaultVal = mod.FreeformCell_defaultValue {
                mainTextField.text = defaultVal
            }
            if let type = mod.FreeformCell_dataType { //limits type of data entered in cell
                self.allowedType = type
                if (type == ProtectedFreeformTypes.Int) { //change textField keyboard type to numerical
                    mainTextField.keyboardType = .NumberPad
                }
            }
            if let limit = mod.FreeformCell_characterLimit { //character limit for entered data
                self.characterLimit = limit
            }
        }
    }
    
    // MARK: - Visual Layout
    
    override func setNeedsLayout() {
        super.setNeedsLayout()
        
        //Layout textField (by default, occupies 2/3s of the length of lvl 2):
        mainTextField.frame = getViewFrameForLevel(viewLevel: (2, HorizontalLevels.RightTwoThirdsLevel, nil))
    }
    
    // MARK: - Text Field
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        if let type = allowedType { //check for any type protections
            switch type {
            case .Int: //block entry of non-numerical text
                if (string.characters.count > 0) { //make sure data is being ENTERED (not removed)
                    guard let _ = Int(string) else { //make sure input is an Int
                        return false
                    }
                    if (string == "0") && (textField.text?.characters.count == 0) { //block LEADING 0s
                        return false
                    }
                }
            }
        }
        
        if let text = textField.text { //configure completion indicator & report object
            let trimmedText = text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            let trimmedString = string.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            let count = trimmedText.characters.count + trimmedString.characters.count - range.length
            if (count > 0) { //set as complete if textField is not empty
                if let limit = characterLimit { //character limit is set
                    if (count > limit) { //EXCEEDS LIMIT
                        return false //do NOT change the report object, & leave completionIndicator in its current state
                    }
                }
                enteredValue = (text as NSString).stringByReplacingCharactersInRange(range, withString: string) //update report object
                configureCompletionIndicator(true)
            } else { //set as incomplete
                enteredValue = (text as NSString).stringByReplacingCharactersInRange(range, withString: string) //update report object
                configureCompletionIndicator(false)
            }
        }
        return true
    }
    
    // MARK: - Data Reporting
    
    override func updateModuleReportObject() { //updates the Module dataSource's report object
        if let mod = self.module, value = enteredValue {
            if let type = allowedType { //pre-defined type is set, cast value -> that type
                switch type {
                case .Int:
                    mod.mainDataObject = Int(value)
                }
            } else { //default behavior (no type is set) - leave value as String
                mod.mainDataObject = value //update w/ current value in textField
            }
        }
    }
    
}