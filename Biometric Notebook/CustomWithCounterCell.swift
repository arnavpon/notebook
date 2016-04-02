//  CustomWithCounterCell.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 4/1/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// CUSTOM MODULE > cell containing a counter button (tapping the button increments the counter).

import UIKit

class CustomWithCounterCell: BaseDataEntryCell {
    
    let incrementButton = UIButton(frame: CGRectZero)
    let currentCountLabel = UILabel(frame: CGRectZero)
    var currentCount: Int = 0 {
        didSet {
            currentCountLabel.text = "\(currentCount)"
        }
    }
    
    // MARK: - Initializers
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        incrementButton.addTarget(self, action: #selector(self.incrementButtonClick(_:)), forControlEvents: .TouchUpInside)
        incrementButton.setTitle("Plus 1", forState: UIControlState.Normal)
        incrementButton.backgroundColor = UIColor.redColor()
        contentView.addSubview(incrementButton)
        
        currentCountLabel.textAlignment = .Center
        currentCountLabel.layer.borderWidth = 1
        currentCountLabel.layer.borderColor = UIColor.blackColor().CGColor
        currentCountLabel.text = "\(currentCount)"
        contentView.addSubview(currentCountLabel)
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
        
        incrementButton.frame = CGRectMake(10, 36, 80, 30)
        currentCountLabel.frame = CGRectMake(100, 36, 40, 30)
    }
    
    // MARK: - Button Actions
    
    @IBAction func incrementButtonClick(sender: UIButton) {
        currentCount += 1
    }
    
}