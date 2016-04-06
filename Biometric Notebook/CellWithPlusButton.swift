//  CellWithPlusButton.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 4/5/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Custom TV cell that contains a + button on the right of the mainLabel that can be used to reveal a previously hidden area of the cell - this might be achieved by sending a notification -> VC that will increase the cell height in the TV, thereby revealing the hidden view. So initially, when the VC queries for the TV height, it returns a height w/ the smaller # of levels. 

import UIKit

class CellWithPlusButton: LevelsFrameworkCell {
    
    internal var isLowerLevelHidden: Bool = true //default is HIDDEN
    internal var numberOfHiddenLevels: Int = 0 //set manually in subclass initializers!
    
    // MARK: - Initializers
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func accessDataSource() {
        super.accessDataSource()
        if let source = self.dataSource {
            if let revealRightBtn = source[BMN_LEVELS_RevealRightButtonKey] as? Bool {
                if (revealRightBtn) { //configure R button
                    firstLevelRightButton = UIButton() //initialize R button
                    firstLevelRightButton?.setImage(UIImage(named: "plus_square"), forState: UIControlState.Normal) //need to be able to adjust color of img
                    firstLevelRightButton?.addTarget(self, action: #selector(self.plusButtonClick(_:)), forControlEvents: UIControlEvents.TouchUpInside)
                    self.insetBackgroundView.addSubview(firstLevelRightButton!) //add -> bckgrdView
                }
            }
        }
    }
    
    // MARK: - Button Actions
    
    @IBAction func plusButtonClick(sender: UIButton) {
        print("Plus button was clicked. Sending notification...")
        if (isLowerLevelHidden) { //reveal hidden levels**
            isLowerLevelHidden = false //set indicator
            let notification = NSNotification(name: BMN_Notification_RevealHiddenArea, object: nil, userInfo: [BMN_PlusBtnCell_NumberOfHiddenLevelsKey: numberOfHiddenLevels])
            NSNotificationCenter.defaultCenter().postNotification(notification)
        } else { //re-hide hidden levels
            isLowerLevelHidden = true //reset indicator
            let notification = NSNotification(name: BMN_Notification_RevealHiddenArea, object: nil, userInfo: [BMN_PlusBtnCell_NumberOfHiddenLevelsKey: 0]) //tell VC to re-hide lvls
            NSNotificationCenter.defaultCenter().postNotification(notification)
        }
    }
    
}