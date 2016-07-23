//  CellWithGradientFill.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 4/4/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Custom TV cells for ActiveProjectsVC - cells contain some custom abilities such as a button on the R for navigation & a horizontal gradient fill to indicate % completion for active projects.

import UIKit

class CellWithGradientFill: UITableViewCell {
    
    let backgroundImageView = UIImageView(frame: CGRectZero) //draw gradient fill into here
    var percentComplete: Double? //% completion of project, obtained from dataSource
    let reportDataButton = UIButton(frame: CGRectZero) //tapping this button segues -> DataEntryVC
    let buttonWidth: CGFloat = 40 //height & width of button
    let rightOffset: CGFloat = 0 //horizontal distance between button & end of view
    var cellIndex: Int? //cell's indexPath.row value (for notification)
    var dataSource: Project? { //cell's dataSource is the associated Project object
        didSet {
            accessDataSource()
            setNeedsLayout()
        }
    }
    
    // MARK: - Initializers
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(backgroundImageView)
        contentView.addSubview(reportDataButton) //add btn directly to contentView for touch to register!
//        contentView.sendSubviewToBack(backgroundImageView) //move behind the default txtLabel
        
        //Configure reportDataBtn:
        reportDataButton.backgroundColor = UIColor.blueColor()
        reportDataButton.setTitleColor(UIColor.redColor(), forState: UIControlState.Normal)
        reportDataButton.setTitle(">", forState: UIControlState.Normal)
        reportDataButton.addTarget(self, action: #selector(self.reportDataButtonClick(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        
        //Gesture recognizer:**
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(self.cellDidDetectSwipe(_:)))
        swipe.direction = .Left
        self.addGestureRecognizer(swipe)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func accessDataSource() {
        if let project = dataSource { //access Project name & cell color?
            self.percentComplete = project.getPercentageCompleted()
        }
    }
    
    // MARK: - Visual Layout
    
    override func setNeedsLayout() {
        //(1) Configure backgroundImageView:
        backgroundImageView.frame = CGRectMake(0, 0, self.frame.width, self.frame.height)
        
        //(2) Configure the 'reportData' button:
        reportDataButton.frame = CGRectMake((self.frame.width - buttonWidth), 0, buttonWidth, self.frame.height)
        
        //(3) Based on the % completion, fill the background an equivalent amount:
    }
    
    // MARK: - Button Actions
    
    @IBAction func reportDataButtonClick(sender: UIButton) { //send notification -> VC w/ sender's index
        if let source = dataSource { //check if project is still active before sending notification!
            source.checkProjectCompletionStatus() //check status
            if (source.isActive) { //project is still active
                if let index = cellIndex {
                    let notification = NSNotification(name: BMN_Notification_DataEntryButtonClick, object: nil, userInfo: [BMN_CellWithGradient_CellIndexKey: index])
                    NSNotificationCenter.defaultCenter().postNotification(notification)
                }
            } else { //user clicked on expired project
                print("Project is inactive! Moving to archive...")
                let notification = NSNotification(name: BMN_Notification_DataEntryButtonClick, object: nil, userInfo: [BMN_CellWithGradient_CellIndexKey: BMN_CellWithGradientFill_ErrorObject]) //send invalid index #
                NSNotificationCenter.defaultCenter().postNotification(notification)
            }
        }
    }
    
    // MARK: - Gesture Recognizers
    
    func cellDidDetectSwipe(gesture: UIGestureRecognizer) {
        if let index = cellIndex {
            let notification = NSNotification(name: BMN_Notification_EditExistingProject, object: nil, userInfo: [BMN_CellWithGradient_CellIndexKey: index])
            NSNotificationCenter.defaultCenter().postNotification(notification)
        }
    }
    
}