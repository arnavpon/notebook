//  CustomWithCounterCell.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 4/1/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// CUSTOM MODULE > cell containing a counter button (tapping the button increments the counter).

import UIKit

class CustomWithCounterCell: BaseDataEntryCell { //add new class -> enum!
    
    private let incrementButton = UIButton(frame: CGRectZero)
    private let currentCountLabel = UILabel(frame: CGRectZero)
    private var currentCount: Int = 0 {
        didSet {
            currentCountLabel.text = "Count: \(currentCount)"
        }
    }
    
    // MARK: - Initializers
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        incrementButton.addTarget(self, action: #selector(self.incrementButtonClick(_:)), forControlEvents: .TouchUpInside)
        incrementButton.setTitle("Plus 1", forState: UIControlState.Normal)
        incrementButton.backgroundColor = UIColor.redColor()
        insetBackgroundView.addSubview(incrementButton)
        
        currentCountLabel.textAlignment = .Center
        currentCountLabel.layer.borderWidth = 1
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
                
            }
        }
    }
    
    // MARK: - Visual Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        incrementButton.frame = getViewFrameForLevel(viewLevel: (2, HorizontalLevels.LeftThirdLevel, nil))
        currentCountLabel.frame = getViewFrameForLevel(viewLevel: (2, HorizontalLevels.RightThirdLevel, nil))
    }
    
    // MARK: - Button Actions
    
    @IBAction func incrementButtonClick(sender: UIButton) {
        currentCount += 1
    }
    
    // MARK: - Data Reporting
    
    override func reportData() {
        //*REPORT TYPE: Int*
        let count = currentCount
    }
    
}