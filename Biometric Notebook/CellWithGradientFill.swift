//  CellWithGradientFill.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 4/4/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Custom TV cells for ActiveProjectsVC - cells contain some custom abilities such as a button on the R for navigation & a horizontal gradient fill to indicate % completion for active projects.

import UIKit

class CellWithGradientFill: UITableViewCell {
    
    let backgroundImageView = UIImageView(frame: CGRectZero) //draw gradient fill into here
    let reportDataButton = UIButton(frame: CGRectZero) //tapping this button segues -> DataEntryVC
    let buttonWidth: CGFloat = 40 //height & width of button
    let rightOffset: CGFloat = 10 //horizontal distance between button & end of view
    var cellIndex: Int? //cell's indexPath.row value (for notification)
    var dataSource: [String: AnyObject]? {
        didSet {
            accessDataSource()
            setNeedsLayout()
        }
    }
    
    // MARK: - Initializers
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(backgroundImageView)
        contentView.addSubview(reportDataButton) //*
//        contentView.sendSubviewToBack(backgroundImageView) //move behind the default txtLabel
//        backgroundImageView.addSubview(reportDataButton)
        
        //Configure reportDataBtn:
        reportDataButton.backgroundColor = UIColor.whiteColor()
        reportDataButton.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
        reportDataButton.setTitle(">", forState: UIControlState.Normal)
        reportDataButton.addTarget(self, action: #selector(self.reportDataButtonClick(_:)), forControlEvents: UIControlEvents.TouchUpInside)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func accessDataSource() {
        if let source = dataSource { //access Project name & cell color
            //
        }
    }
    
    // MARK: - Visual Layout
    
    override func setNeedsLayout() {
        //(1) Configure backgroundImageView:
        backgroundImageView.frame = CGRectMake(0, 0, self.frame.width, self.frame.height)
        
        //(2) Configure the 'reportData' button:
        let centerY = backgroundImageView.frame.height/2
        let originY = centerY - buttonWidth/2
        let originX = backgroundImageView.frame.width - rightOffset - buttonWidth
        reportDataButton.frame = CGRectMake(originX, originY, buttonWidth, buttonWidth)
    }
    
    // MARK: - Button Actions
    
    @IBAction func reportDataButtonClick(sender: UIButton) { //send notification -> VC w/ sender's index
        print("Button was clicked.")
        if let index = cellIndex {
            let notification = NSNotification(name: BMN_Notification_DataEntryButtonClick, object: nil, userInfo: [BMN_CellIndexKey: index])
            NSNotificationCenter.defaultCenter().postNotification(notification)
        }
    }
    
}
