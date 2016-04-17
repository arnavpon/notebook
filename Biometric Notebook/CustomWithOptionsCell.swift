//  CustomWithOptionsCell.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 4/1/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// CUSTOM MODULE > cell for reporting 1 (or more) of several possible options.

import UIKit

class CustomWithOptionsCell: BaseDataEntryCell { //add new class -> enum!
    
    override class var numberOfLevels: Int { //default # of levels is 1 (the Module object will add the # of options to get the total # of levels, handled in the VC directly)
        return 1
    }
    private var multipleSelectionEnabled: Bool = false //indicator from Module object
    private var options: [String] = [] { //available options for selection
        didSet {
            configureSelectionButtons() //make sure btns are created BEFORE updating layout!
            setNeedsLayout() //update visuals for cell
        }
    }
    private var optionButtons: [UIButton] = [] //buttons for available options
    private var selectedOptions: [String] = [] { //report object for cell (array instead of string b/c some cells can have multiple options selected)
        didSet {
            if !(selectedOptions.isEmpty) { //options have been selected, set cell -> COMPLETE
                configureCompletionIndicator(true)
            } else { //array is empty (NO options selected), set cell -> INCOMPLETE
                configureCompletionIndicator(false)
            }
            updateModuleReportObject() //update Module for selection/deselection
            for opt in selectedOptions { //**
                print("[OPTION] '\(opt)'")
            }
        }
    }
    private var fireCounter: Int = 0 //prevents btns from being created more than 1x
    private let defaultBackgroundColor = UIColor(red: 248/255, green: 1, blue: 235/255, alpha: 1)
    private var cellType: CustomModuleVariableTypes?
    
    // MARK: - Initializers
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override internal func accessModuleProperties() { //use Module type/selection to format cell's visuals
        super.accessModuleProperties() //note - PROMPT is set in the LEVELS superclass automatically
        if let customMod = self.module as? CustomModule, type = customMod.getTypeForVariable() { //downcast to CUSTOM module
            if (type == CustomModuleVariableTypes.Behavior_CustomOptions) || (type == CustomModuleVariableTypes.Behavior_BinaryOptions) { //check variableType to be safe
                self.cellType = type //indicate which type of cell this is
                if let multipleSelect = customMod.multipleSelectionEnabled {
                    multipleSelectionEnabled = multipleSelect
                }
                if let availableOptions = customMod.options {
                    self.options = availableOptions
                }
            }
        }
    }
    
    // MARK: - Visual Layout
    
    override func setNeedsLayout() {
        super.setNeedsLayout()
        
        //The buttons are only added 1x, so we don't have to worry about duplication:
        if let type = cellType {
            if (type == CustomModuleVariableTypes.Behavior_BinaryOptions) { //BINARY cell layout
                optionButtons[0].frame = getViewFrameForLevel(viewLevel: (2, HorizontalLevels.LeftHalfLevel, nil))
                optionButtons[1].frame = getViewFrameForLevel(viewLevel: (2, HorizontalLevels.RightHalfLevel, nil))
            } else if (type == CustomModuleVariableTypes.Behavior_CustomOptions) { //CUSTOM OPTIONS layout
                var counter = 2 //start @ 2 b/c 1st level is already occupied
                for button in optionButtons {
                    button.frame = getViewFrameForLevel(viewLevel: (counter, HorizontalLevels.RightTwoThirdsLevel, nil)) //each btn takes up 1 lvl
                    counter += 1
                }
            }
        }
    }
    
    private func configureSelectionButtons() { //configures btns for available options, CALL ONLY ONCE!
        if (fireCounter == 0) { //make sure fx hasn't fired yet
            var tagCounter = 0 //sets tag for btn (matches INDEX in 'options' & 'optionBtns' dataSource!)
            for option in options {
                let optionBtn = UIButton()
                optionBtn.tag = tagCounter //set tag (i.e. INDEX in array)
                let boldAttribute = [NSFontAttributeName: UIFont.boldSystemFontOfSize(16)]
                let attributedString = NSAttributedString(string: option, attributes: boldAttribute)
                optionBtn.setAttributedTitle(attributedString, forState: .Normal)
                optionBtn.layer.borderColor = UIColor.blackColor().CGColor
                optionBtn.layer.borderWidth = 0.5
                
                //Depending on cellType (binary vs. custom), background colors are different:
                if (cellType == CustomModuleVariableTypes.Behavior_BinaryOptions) { //BINARY cell
                    if (tagCounter == 0) { //'YES' cell
                        optionBtn.backgroundColor = UIColor.greenColor()
                    } else if (tagCounter == 1) { //'NO' cell
                        optionBtn.backgroundColor = UIColor.redColor()
                    }
                } else if (cellType == CustomModuleVariableTypes.Behavior_CustomOptions) {
                    optionBtn.backgroundColor = defaultBackgroundColor
                }
                
                optionBtn.addTarget(self, action: #selector(self.buttonWasClicked(_:)), forControlEvents: .TouchUpInside)
                optionButtons.append(optionBtn)
                insetBackgroundView.addSubview(optionBtn)
                    
                tagCounter += 1 //increment tag
            }
        }
        fireCounter = 1 //block future firing of this fx
    }
    
    // MARK: - Button Actions
    
    @IBAction func buttonWasClicked(sender: UIButton) { //adjusts the selectedOptions array on btn click
        let index = sender.tag //tag matches index in 'optionsButtons' & 'options' arrays
        if !(self.multipleSelectionEnabled) { //DEFAULT is SINGLE SELECTION
            selectedOptions = [] //clear array so there can be @ most 1 item selected
            if !(sender.selected) { //'selected' is FALSE, btn is not yet selected (add -> array)
                selectedOptions.append(options[index]) //add selected option
                for button in optionButtons { //deselect all cells first (only 1 can be selected @ a time)
                    button.selected = false
                }
                sender.selected = true //set btn -> SELECTED
            } else { //btn was already selected, so item was removed (when we cleared the array)
                sender.selected = false //deselect btn
            }
        } else { //MULTIPLE SELECTION is allowed
            if !(sender.selected) { //'selected' is FALSE, btn is not yet selected (add -> array)
                selectedOptions.append(options[index])
                sender.selected = true //set btn -> SELECTED
            } else { //'selected' is TRUE, btn was already selected (remove from array)
                if let indexToRemove = selectedOptions.indexOf(options[index]) { //get the index of the selectedOption for removal (match -> btn title -> option name)
                    selectedOptions.removeAtIndex(indexToRemove)
                    sender.selected = false //deselect btn
                } else { //critical error
                    print("ERROR - btn is ALREADY selected, but matching option is NOT in array!!!")
                }
            }
        }
        updateButtonVisualsForSelection() //update visuals for selection/deselection
    }
    
    private func updateButtonVisualsForSelection() { //adjust btn background color on selection
        if (cellType == CustomModuleVariableTypes.Behavior_BinaryOptions) { //BINARY behavior
            var deselectedCount = 0 //count # of deselected btns
            for button in optionButtons {
                if (button.selected) { //selected btn
                    button.alpha = 1
                } else { //deselected btn
                    deselectedCount += 1 //add 1 to counter
                    button.alpha = 0.3
                }
            }
            if (deselectedCount == 2) { //if both buttons are deselected, restore full color bckgrd
                optionButtons[0].alpha = 1
                optionButtons[1].alpha = 1
            }
        } else if (cellType == CustomModuleVariableTypes.Behavior_CustomOptions) { //default behavior
            for button in optionButtons {
                if (button.selected) { //btn is SELECTED, set background -> highlighted color
                    button.backgroundColor = UIColor.greenColor()
                } else { //NOT selected, set background back -> default
                    button.backgroundColor = defaultBackgroundColor
                }
            }
        }
    }
    
    // MARK: - Data Reporting
    
    override func updateModuleReportObject() { //updates the Module dataSource's report object
        if let mod = module {
            mod.mainDataObject = self.selectedOptions
        }
    }
    
}