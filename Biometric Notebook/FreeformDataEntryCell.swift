//  FreeformDataEntryCell.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 4/26/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// GENERAL DataEntry Cell > contains textLabel that allows freeform data entry (e.g. weight & height). Cell can be further configured to set a default value, type protections for entries, character limits, textField size, etc. Cell is extensible enough that it can, if so configured, have > 1 text field with a label indicating each value in the text field.

import UIKit

enum ProtectedFreeformTypes: String { //list of protected freeform types - used as a type check for data entered into the textField
    case Int = "BMN_ProtectedFreeformType_Int"
    case Decimal = "BMN_ProtectedFreeformType_Decimal"
    case Timing = "BMN_ProtectedFreeformType_Timing"
}

class FreeformDataEntryCell: BaseDataEntryCell, UITextFieldDelegate { //add new class -> enum!
    
    override class var numberOfLevels: Int {
        return 2 //# of levels is dynamically calculated by enum (every 2 views adds 1 level)
    }
    
    private var fireCounter = 0 //ensures 'createFreeformViews' fires only once
    private var freeformViewsConfigObject: [(String?, ProtectedFreeformTypes?, String?, Int?, (Double?, Double?)?, String?)]? { //'freeformView' = TF + lbl contained w/in a view; this tuple specifies all config for the view - indicates the # of TFs (via the array's count) + (1) label for each TF; (2) type of data in TF? (if nil, default is String); (3) defaultValue?; (4) characterLimit?; (5) (if text is numerical value) an upper/lower bound in format (Int?, Int?)?; (6) textField placeholder?
        didSet { //make sure this fires only once!
            if (fireCounter == 0) {
                fireCounter += 1 //block further firing
                createFreeformViews()
                setNeedsLayout()
            }
        }
    }
    private var freeformViews: [(UIView, UITextField, UILabel)] = []
    private var reportBlocker: Bool = false //blocks update of moduleReportObject
    private var moduleReportObject: [String] = [] { //array reported to module
        didSet { //adjust completion status & update module report object
            if !(reportBlocker) { //check for block (set when initial values are added to array)
                updateModuleReportObject()
                adjustCompletionStatusForCell()
            } else {
                reportBlocker = false //clear blocker
            }
        }
    }
    private var labelBeforeField: Bool = true //if TRUE, labels come before TF; if FALSE, they come after
    
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
                
                if let lblText = item.0 { //set lbl's text (if nil, lbl is set -> no frame)
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
                    moduleReportObject.append(defaultText) //set default value to report object
                } else { //no default, initialize reportObject w/ empty item @ this TF's index
                    reportBlocker = true //block firing of moduleReportObject update
                    moduleReportObject.append("") //initialize w/ empty value
                    if let placeholder = item.5 { //check for placeholder if there is NO default
                        textField.placeholder = placeholder
                    }
                }
                if let textType = item.1 { //check for type (to set keyboard for numerical vals)
                    switch textType {
                    case .Int, .Timing:
                        textField.keyboardType = .NumberPad
                    case .Decimal:
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
    
    private func adjustCompletionStatusForCell() { //sets completionIndicator accordingly
        var counter = 0
        for textValue in moduleReportObject {
            let trimmedValue = textValue.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            if (trimmedValue == "") { //if the textValue is empty, cell is INCOMPLETE
                configureCompletionIndicator(false)
                return //terminate function
            }
            counter += 1
        }
        configureCompletionIndicator(true) //passed checks, cell is COMPLETE
    }
    
    // MARK: - Text Field
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        let fieldTag = textField.tag
        if let configObject = self.freeformViewsConfigObject {
            if let type = configObject[fieldTag].1 { //check for any type protections
                switch type {
                case .Int: //block entry of non-numerical text
                    if (string.characters.count > 0) { //make sure data is being ENTERED (not removed)
                        guard let _ = Int(string) else { //make sure input is an Int
                            return false
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
                case .Timing:
                    break //no checks @ this point
                }
            }
            
            if let text = textField.text { //configure completion indicator & report object
                let trimmedText = text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                let trimmedString = string.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                let completeString = (trimmedText as NSString).stringByReplacingCharactersInRange(range, withString: trimmedString)
                
                //Safety checks - make sure entry does not exceed lower/upper bound or charLimit:
                let count = trimmedText.characters.count + trimmedString.characters.count - range.length
                if let limit = configObject[fieldTag].3 { //character limit is set
                    if (count > limit) { //EXCEEDS LIMIT
                        return false //do NOT change the report object, & leave completionIndicator in its current state
                    }
                }
                if let valueBounds = configObject[fieldTag].4, stringAsDouble = Double(completeString) { //bounds exist & string was able to be cast -> Double (for Int & Double types)
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
                let final = modifyReportObjectForTextField(fieldTag, newText: completeString) //IFF cell passes all checks, update reportObj
                textField.text = final //update TF manually
            }
        }
        return false //textField is updated manually
    }
    
    func modifyReportObjectForTextField(fieldTag: Int, newText: String) -> String {
        var tempString = newText //modifiable text
        if let config = freeformViewsConfigObject, type = config[fieldTag].1 { //check for 'Timing' type
            let chars = tempString.characters.count
            if (type == ProtectedFreeformTypes.Timing) {
                //Convert entered text into a string of numbers (remove ':' & '.'), then iterate through the numerical string & apply formatting:
                let noColons: NSString = (newText as NSString).stringByReplacingOccurrencesOfString(":", withString: "")
                let pureNumbers: NSString = noColons.stringByReplacingOccurrencesOfString(".", withString: "")
                var formattedString = "" //combined string
                var location = 0 //substring start location
                while location < pureNumbers.length { //loop til 1 - length to avoid range error
                    if (location == 2) || (location == 4) { //prepend colon
                        formattedString.appendContentsOf(":")
                    } else if (location == 6) { //prepend decimal
                        formattedString.appendContentsOf(".")
                    }
                    let substring = pureNumbers.substringWithRange(NSRange.init(location: location, length: 1)) //obtain next digit in line...
                    formattedString.appendContentsOf(substring) //add it to growing formatted string
                    location += 1
                }
                    
                if (chars >= 8) { //ONLY report -> Module if HH, MM, & SS have been reported
                    moduleReportObject[fieldTag] = formattedString //update report object
                } else { //set cell -> INCOMPLETE
                    configureCompletionIndicator(false)
                }
                tempString = formattedString //update fx return object
            } else { //NON-timing objects, return the input string unmodified
                moduleReportObject[fieldTag] = tempString //update report object
            }
        }
        return tempString
    }
    
    // MARK: - Data Reporting
    
    override func updateModuleReportObject() { //updates the Module dataSource's report object
        if let mod = self.module {
            if let convertedValue = mod.performConversionOnUserEnteredData(moduleReportObject) {
                mod.mainDataObject = convertedValue //update w/ converted value
            } else { //no conversion necessary
                mod.mainDataObject = moduleReportObject //update w/ textField values
            }
        }
    }
    
}