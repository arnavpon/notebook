//  FreeformDataEntryCell.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 4/26/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// GENERAL DataEntry Cell > contains textLabel that allows freeform data entry (e.g. weight & height). Cell can be further configured to set a default value, type protections for entries, character limits, textField size, etc. Cell is extensible enough that it can, if so configured, have > 1 text field with a label indicating each value in the text field.

import UIKit

enum ProtectedFreeformTypes: String { //list of protected freeform types - used as a type check for data entered into the textField
    
    case Int = "BMN_ProtectedFreeformType_Int"
    case Decimal = "BMN_ProtectedFreeformType_Decimal"
    
}

class FreeformDataEntryCell: BaseDataEntryCell, UITextFieldDelegate { //add new class -> enum!
    
    override class var numberOfLevels: Int {
        return 2 //# of levels is dynamically calculated by enum (every 2 views adds 1 level)
    }
    
    private var fireCounter = 0 //ensures 'createFreeformViews' fires only once
    private var freeformViewsConfigObject: [(String?, ProtectedFreeformTypes?, String?, Int?, (Double?, Double?)?)]? { //'freeformView' = TF + lbl contained w/in a view; this tuple specifies all config for the view - indicates the # of TFs (via the array's count) + (1) label for each TF; (2) type of data in TF? (if nil, default is String); (3) defaultValue?; (4) characterLimit?; (5) (if text is numerical value) an upper/lower bound in format (Int?, Int?)?.
        didSet { //make sure this fires only once!
            if (fireCounter == 0) {
                fireCounter += 1 //block further firing
                createFreeformViews()
                setNeedsLayout()
            }
        }
    }
    private var freeformViews: [(UIView, UITextField, UILabel)] = []
    private var labelBeforeField: Bool = true //if TRUE, labels come before TF; if FALSE, they come after
    private var numberOfCompletedFields: Int = 0 {
        didSet { //adjust completion status accordingly
            adjustCompletionStatusForCell()
        }
    }
    
    // MARK: - Initializers
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override internal func accessModuleProperties() { //use Module type/selection to format cell's visuals
        super.accessModuleProperties()
        if let mod = self.module { //GENERAL cell (no specific module type)
            //Access configuration parameters in Module superclass:
            if let boolValue = mod.FreeformCell_labelBeforeField { //check for lbl position
                self.labelBeforeField = boolValue
            }
            if let configObject = mod.FreeformCell_configurationObject { //master config object
                self.freeformViewsConfigObject = configObject
            }
        }
    }
    
    private func createFreeformViews() { //create freeformViews as specified in configObj
        if let configObject = freeformViewsConfigObject {
            var counter = 0 //used to assign TF tags
            for item in configObject {
                let freeformView = UIView(frame: CGRectZero) //container view
                let textField = UITextField()
                let label = UILabel()
                freeformView.addSubview(textField)
                freeformView.addSubview(label)
                
                if let lblText = item.0 { //set lbl's text (if nil, lbl will have no frame)
                    label.text = lblText
                }
                label.adjustsFontSizeToFitWidth = true
                label.textAlignment = .Center
                
                textField.delegate = self
                textField.tag = counter //tag matches INDEX in array
                textField.textAlignment = .Center
                textField.borderStyle = .RoundedRect
                if let defaultText = item.2 { //check for textField default
                    textField.text = defaultText
                    numberOfCompletedFields += 1 //add 1 completed field for each default
                }
                if let textType = item.1 { //check for type (to set keyboard for numerical vals)
                    if (textType == ProtectedFreeformTypes.Int) { //numerical pad
                        textField.keyboardType = .NumberPad
                    } else if (textType == ProtectedFreeformTypes.Decimal) { //decimal pad
                        textField.keyboardType = .DecimalPad
                    }
                }
                
                freeformViews.append((freeformView, textField, label))
                self.insetBackgroundView.addSubview(freeformView)
                counter += 1
            }
        }
    }
    
    // MARK: - Visual Layout
    
    override func setNeedsLayout() {
        super.setNeedsLayout()
        
        //Assign frames - TF takes up 2/3 of view, label 1/3 (unless there is no text):
        var viewCounter = 0
        for (view, textField, label) in freeformViews {
            let (level, remainder) = getLevelAndRemainderForCount(viewCounter)
            if (remainder == 0) { //even #
                view.frame = getViewFrameForLevel(viewLevel: (level, HorizontalLevels.LeftHalfLevel, nil))
            } else if (remainder == 1) { //odd #
                view.frame = getViewFrameForLevel(viewLevel: (level, HorizontalLevels.RightHalfLevel, nil))
            }
            if (label.text != nil) { //lbl exists
                let horizontalSpacer: CGFloat = 5 //spacer
                if (labelBeforeField) { //add label BEFORE TF
                    label.frame = CGRectMake(0, 0, view.frame.width/3, view.frame.height)
                    textField.frame = CGRectMake((horizontalSpacer + view.frame.width/3), 0, (view.frame.width * 2/3 - horizontalSpacer), view.frame.height)
                } else { //add label AFTER TF
                    textField.frame = CGRectMake(0, 0, view.frame.width * 2/3, view.frame.height)
                    label.frame = CGRectMake((horizontalSpacer + view.frame.width * 2/3), 0, (view.frame.width/3 - horizontalSpacer), view.frame.height)
                }
            } else { //NO LABEL, TF occupies whole view
                textField.frame = CGRectMake(0, 0, view.frame.width, view.frame.height)
                label.frame = CGRectZero
            }
            viewCounter += 1
        }
    }
    
    private func getLevelAndRemainderForCount(count: Int) -> (Int, Int) { //returns (level, remainder) based on the count
        let remainder = count % 2
        let level = Int(floor(Double(count/2))) + 2 //add 2 to arrive @ proper level
        return (level, remainder)
    }
    
    private func adjustCompletionStatusForCell() {
        let total = freeformViews.count
        if (numberOfCompletedFields == total) { //cell is COMPLETE
            configureCompletionIndicator(true)
        } else { //cell is INCOMPLETE
            configureCompletionIndicator(false)
            if (numberOfCompletedFields > total) { //safety
                print("[FreeformCell - adjustCompletionStatus] Error - # of completed cells > total!")
            }
        }
    }
    
    // MARK: - Text Field
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        let tag = textField.tag
        if let configObject = self.freeformViewsConfigObject {
            if let type = configObject[tag].1 { //check for any type protections
                switch type {
                case .Int: //block entry of non-numerical text
                    if (string.characters.count > 0) { //make sure data is being ENTERED (not removed)
                        guard let _ = Int(string) else { //make sure input is an Int
                            return false
                        }
                        if (string == "0") && (textField.text?.characters.count == 0) { //block LEADING 0s
                            return false //**need to use bounds purely instead of this as a block, but how do we stop leading 0s then?
                        }
                    }
                case .Decimal:
                    if (string.characters.count > 0) { //make sure data is being ENTERED
                        if let text = textField.text {
                            let fullString = (text as NSString).stringByReplacingCharactersInRange(range, withString: string)
                            guard let _ = Double(fullString) else { //make sure input is Double
                                return false
                            }
                        }
                    }
                }
            }
            
            if let text = textField.text { //configure completion indicator & report object
                let trimmedText = text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                let trimmedString = string.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                let completeString = (trimmedText as NSString).stringByReplacingCharactersInRange(range, withString: trimmedString)
                
                //(1) Safety checks - make sure entry does not exceed lower/upper bound or charLimit:
                let count = trimmedText.characters.count + trimmedString.characters.count - range.length
                if let limit = configObject[tag].3 { //character limit is set
                    if (count > limit) { //EXCEEDS LIMIT
                        return false //do NOT change the report object, & leave completionIndicator in its current state
                    }
                }
                if let valueBounds = configObject[tag].4, stringAsDouble = Double(completeString) { //bounds exist & string was able to be cast -> Double (for Int & Double types)
                    if let lowerBound = valueBounds.0 { //make sure val is >= lowerBound
                        if (stringAsDouble < lowerBound) {
                            return false
                        }
                    }
                    if let upperBound = valueBounds.1 { //make sure val is <= upperBound
                        if (stringAsDouble > upperBound) {
                            return false
                        }
                    }
                }
                
                //Adjust completion status for textField modification:
                let originalTextCount = trimmedText.characters.count
                if (originalTextCount == 0) { //originally textField was EMPTY
                    if (trimmedString.characters.count - range.length) > 0 { //adding non-whitespace txt
                        numberOfCompletedFields += 1 //increase # completed by 1
                    }
                } else { //textField originally has some entered data
                    if (originalTextCount + string.characters.count - range.length) == 0 { //cleared field
                        numberOfCompletedFields -= 1 //reduce # completed by 1
                    }
                }
                updateModuleReportObject() //adjust reportObject
            }
        }
        return true
    }
    
    // MARK: - Data Reporting
    
    override func updateModuleReportObject() { //updates the Module dataSource's report object
        if let mod = self.module {
            var reportObject: [String] = []
            for (_, field, _) in freeformViews { //construct array w/ all TF values in order
                if let text = field.text {
                    reportObject.append(text)
                } else {
                    print("[updateModuleReportObject] Error - textField text is NIL!")
                    reportObject.append("") //add empty string to counts remain accurate
                }
            }
            mod.mainDataObject = reportObject //update w/ textField values
        }
    }
    
}