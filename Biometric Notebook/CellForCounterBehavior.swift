//  CellForCounterBehavior.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 4/15/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// HomeScreen TV cell for active counters.

import UIKit

class CellForCounterBehavior: LevelsFrameworkCell {
    
    private let incrementButton = UIButton(frame: CGRectZero)
    private let currentCountLabel = UILabel(frame: CGRectZero)
    private var currentCount: Int { //pull currentCount value from Counter dataSource
        if let counter = counterDataSource {
            return (counter.currentCount as Int)
        }
        return 0
    }
    var counterDataSource: Counter? { //set externally by VC
        didSet {
            updateTextLabelWithCount() //update cell visuals when set
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
        currentCountLabel.adjustsFontSizeToFitWidth = true
        currentCountLabel.layer.borderWidth = 0.5
        currentCountLabel.layer.borderColor = UIColor.blackColor().CGColor
        currentCountLabel.text = "Count: \(currentCount)"
        insetBackgroundView.addSubview(currentCountLabel)
        
        insetBackgroundColor = UIColor(red: 255/255, green: 243/255, blue: 167/255, alpha: 1)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func updateTextLabelWithCount() { //updates txtLabel whenever counter value changes
        currentCountLabel.text = "Count: \(currentCount)"
    }
    
    // MARK: - Visual Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        incrementButton.frame = getViewFrameForLevel(viewLevel: (2, HorizontalLevels.LeftThirdLevel, nil))
        currentCountLabel.frame = getViewFrameForLevel(viewLevel: (2, HorizontalLevels.RightThirdLevel, nil))
    }
    
    // MARK: - Button Actions
    
    @IBAction func incrementButtonClick(sender: UIButton) {
        if let counter = counterDataSource { //increment the persistent counter value
            counter.incrementCounter()
            updateTextLabelWithCount()
        }
    }
    
}