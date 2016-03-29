//  CustomWithCounterTableViewCell.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 3/28/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// CUSTOM MODULE > cell containing a counter button (tapping the button increments the counter).

import UIKit

class CustomWithCounterTableViewCell: BaseTableViewCell {
    
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
