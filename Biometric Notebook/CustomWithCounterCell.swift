//  CustomWithCounterCell.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 4/1/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// CUSTOM MODULE > cell containing a counter button (tapping the button increments the counter).

import UIKit

class CustomWithCounterCell: BaseDataEntryCell { //add new class -> enum!
    
    private let incrementButton = UIButton(frame: CGRectZero)
    private let currentCountLabel = UILabel(frame: CGRectZero)
    private var currentCount: Int { //pull current value from linked Counter object
        if let counter = counterDataSource {
            return (counter.currentCount as Int)
        }
        return 0
    }
    private var counterDataSource: Counter? { //persistent source holding currentCount
        didSet {
            updateTextLabelWithCount()
            updateModuleReportObject() //send preliminary persistent count -> Module object
        }
    }
    
    // MARK: - Initializers
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.configureCompletionIndicator(true) //cell is ALWAYS complete
        
        incrementButton.addTarget(self, action: #selector(self.incrementButtonClick(_:)), forControlEvents: .TouchUpInside)
        incrementButton.setTitle("Plus 1", forState: UIControlState.Normal)
        incrementButton.backgroundColor = UIColor.redColor()
        insetBackgroundView.addSubview(incrementButton)
        
        currentCountLabel.textAlignment = .Center
        currentCountLabel.adjustsFontSizeToFitWidth = true
        currentCountLabel.layer.borderWidth = 0.5
        currentCountLabel.layer.borderColor = UIColor.blackColor().CGColor
        currentCountLabel.text = "Count: \(currentCount)"
        insetBackgroundView.addSubview(currentCountLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override internal func accessModuleProperties() { //use Module type/selection to format cell's visuals
        super.accessModuleProperties()
        if let customMod = self.module as? CustomModule, type = customMod.getTypeForVariable() { //downcast to CUSTOM module
            if (type == CustomModuleVariableTypes.Behavior_Counter) { //check variableType to be safe
                if let uniqueID = customMod.counterUniqueID, counter = fetchObjectsFromCoreDataStore("Counter", filterProperty: "id", filterValue: [uniqueID as NSNumber]) as? [Counter] { //obtain linked counter
                    if (counter.isEmpty) { //no counter found for that ID
                        print("[accessModuleProperties] ERROR - no counter was found for that ID #!")
                    } else if (counter.count == 1) { //1 counter found
                        self.counterDataSource = counter.first
                    } else { //error
                        print("[accessModuleProperties] ERROR - > 1 counter was found for that ID #!")
                    }
                }
            }
        }
    }
    
    private func updateTextLabelWithCount() { //adjust txtLbl w/ updated count
        self.currentCountLabel.text = "Count: \(currentCount)"
    }
    
    // MARK: - Visual Layout
    
    override func setNeedsLayout() {
        super.setNeedsLayout()
        
        incrementButton.frame = getViewFrameForLevel(viewLevel: (2, HorizontalLevels.LeftThirdLevel, nil))
        currentCountLabel.frame = getViewFrameForLevel(viewLevel: (2, HorizontalLevels.RightThirdLevel, nil))
    }
    
    // MARK: - Button Actions
    
    @IBAction func incrementButtonClick(sender: UIButton) { //update persistent Counter's count value
        if let counter = counterDataSource {
            counter.incrementCounter()
            updateTextLabelWithCount() //show updated count in lbl
            updateModuleReportObject() //update Module object w/ the incremented count
        }
    }
    
    // MARK: - Data Reporting
    
    override func updateModuleReportObject() { //updates the Module dataSource's report object
        if let mod = module {
            mod.mainDataObject = currentCount
        }
    }
    
}