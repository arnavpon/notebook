//  SelectFromOptionsConfigurationCell.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 4/18/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Custom configuration cell that allows the user to pick 1 or more options from a list provided by the data source. This includes a Boolean configuration.

import UIKit

class SelectFromOptionsConfigurationCell: BaseConfigurationCell { //add new class -> enum!
    
    override class var numberOfLevels: Int { //default # of levels is 1
        return 1 //for each available option in dataSource, add 1 level (unless cell is Bool type)
    }
    
    private var isCellBoolean: Bool = false //indicator if cell is Boolean type
    private var multipleSelectionEnabled: Bool = false //indicator from dataSource object
    private var fireCounter: Int = 0 //prevents btns from being generated more than 1x
    private var options: [String] = [] { //available options for selection
        didSet {
            configureSelectionButtons() //creates btns for options (fire BEFORE updating layout!)
            setNeedsLayout() //update visuals for cell
            if (isCellBoolean) && (options.count == 2) { //BINARY cell type
                let notification = NSNotification(name: BMN_Notification_AdjustHeightForSelectFromOptionsCell, object: nil, userInfo: [BMN_SelectFromOptionsConfigCell_NumberOfLevelsKey: 2]) //height = 2 lvls
                NSNotificationCenter.defaultCenter().postNotification(notification)
            } else { //DEFAULT cell type
                let notification = NSNotification(name: BMN_Notification_AdjustHeightForSelectFromOptionsCell, object: nil, userInfo: [BMN_SelectFromOptionsConfigCell_NumberOfLevelsKey: (options.count + 1)]) //tell VC to add 1 lvl for each option + 1 (for top level)
                NSNotificationCenter.defaultCenter().postNotification(notification)
            }
        }
    }
    private var optionButtons: [UIButton] = [] //buttons for available options
    private var selectedOptions: [String] = [] { //reportObject for cell (ARRAY instead of string b/c some cells allow selection of multiple options)
        didSet { //adjust completion status
            if !(selectedOptions.isEmpty) { //options have been selected, set cell -> COMPLETE
                configureCompletionIndicator(true)
            } else { //array is empty (NO options selected), set cell -> INCOMPLETE
                configureCompletionIndicator(false)
            }
        }
    }
    private let defaultBackgroundColor = UIColor(red: 248/255, green: 1, blue: 235/255, alpha: 1)
    
    // MARK: - Initializers
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func accessDataSource() {
        super.accessDataSource()
        
        if let source = self.dataSource, availableOptions = source[BMN_SelectFromOptions_OptionsKey] as? [String] { //obtain the options (REQUIRED for cell)
            if let cellIsBool = source[BMN_SelectFromOptions_IsBooleanKey] as? Bool { //check for Bool BEFORE setting options & generating btns!
                self.isCellBoolean = cellIsBool
            }
            self.options = availableOptions //setting opts generates optionBtns!
            if let multipleSelection = source[BMN_SelectFromOptions_MultipleSelectionEnabledKey] as? Bool { //check if multiple selection is allowed
                self.multipleSelectionEnabled = multipleSelection
            }
            if let defaultOptions = source[BMN_SelectFromOptions_DefaultOptionsKey] as? [String] { //check if cell has defined defaults & set them -> report object
                self.selectedOptions = defaultOptions //set defaults
                for option in selectedOptions { //update visuals for defaults
                    if let index = self.options.indexOf(option) { //get index (equivalent to btn tag)
                        self.optionButtons[index].selected = true //set btn -> selected
                    }
                }
                updateButtonVisualsForSelection() //set visuals
            }
        }
    }
    
    // MARK: - Visual Layout
    
    override func setNeedsLayout() {
        super.setNeedsLayout()
        
        //The buttons are only added 1x, so we don't have to worry about duplication:
        if (isCellBoolean) { //BINARY cell layout, configure btns side by side around center of view
            optionButtons[0].frame = getViewFrameForLevel(viewLevel: (2, HorizontalLevels.LeftThirdLevel, nil))
            optionButtons[1].frame = getViewFrameForLevel(viewLevel: (2, HorizontalLevels.RightThirdLevel, nil))
        } else { //DEFAULT layout
            var counter = 2 //start @ 2 b/c 1st level is already occupied
            for button in optionButtons {
                button.frame = getViewFrameForLevel(viewLevel: (counter, HorizontalLevels.FullLevel, nil)) //each btn takes up 1 full lvl
                counter += 1
            }
        }
    }
    
    private func configureSelectionButtons() { //configures btns for available options, CALL ONLY ONCE!
        if (fireCounter == 0) { //make sure fx hasn't fired yet
            var tagCounter = 0 //sets tag for btn (matches INDEX in 'options' & 'optionBtns' dataSource!)
            for option in options {
                let defaultFont = UIFont.systemFontOfSize(18)
                let boldFont = UIFont.boldSystemFontOfSize(18)
                let defaultAttributes = [NSFontAttributeName: defaultFont, NSForegroundColorAttributeName: UIColor.darkGrayColor()] //attributes for .Normal cell
                let selectedAttributes = [NSFontAttributeName: boldFont, NSForegroundColorAttributeName: UIColor.blackColor()] //attributes for .Selected cell
                
                let optionBtn = UIButton()
                optionBtn.tag = tagCounter //set tag (i.e. INDEX in array)
                let defaultString = NSAttributedString(string: option, attributes: defaultAttributes)
                let selectedString = NSAttributedString(string: option, attributes: selectedAttributes)
                optionBtn.setAttributedTitle(defaultString, forState: .Normal)
                optionBtn.setAttributedTitle(selectedString, forState: .Selected)
                optionBtn.layer.borderColor = UIColor.blackColor().CGColor
                optionBtn.layer.borderWidth = 0.5
                
                //Depending on cellType (binary vs. custom), some visuals are different:
                if (isCellBoolean) { //BINARY cell
                    if (option.lowercaseString == "yes") { //'YES' cell is GREEN
                        optionBtn.backgroundColor = UIColor.greenColor()
                    } else if (option.lowercaseString == "no") { //'NO' cell is RED
                        optionBtn.backgroundColor = UIColor.redColor()
                    }
                    optionBtn.layer.cornerRadius = 5
                } else {
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
            } else { //btn was already selected, so item was alrdy removed (when array was cleared^)
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
        updateButtonVisualsForSelection() //update visuals for selection/deselection @ the END
    }
    
    private func updateButtonVisualsForSelection() { //adjust btn visuals on selection
        if (isCellBoolean) { //BINARY behavior
            var deselectedCount = 0 //count # of deselected btns
            for button in optionButtons {
                if (button.selected) { //selected btn
                    button.alpha = 1
                } else { //deselected btn
                    deselectedCount += 1 //add 1 to counter
                    button.alpha = 0.3
                }
            }
            if (deselectedCount == 2) { //if both buttons are deselected, restore alpha for both
                optionButtons[0].alpha = 1
                optionButtons[1].alpha = 1
            }
        } else { //default behavior
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
    
    override var configurationReportObject: AnyObject? { //checks the currently highlighted button & reports TRUE for 'yes', FALSE for 'no'
        //*REPORT TYPE: [String]*
        return selectedOptions
    }

}