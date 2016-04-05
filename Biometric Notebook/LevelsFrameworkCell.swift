//  LevelsFrameworkCell.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 4/4/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Base framework that dictates layout for (almost) all of BMN's custom TV cells.

import UIKit

class LevelsFrameworkCell: UITableViewCell {
    
    //(REQUIRED) Default Views:
    internal let insetBackgroundView = UIView(frame: CGRectZero) //background for LEVELS cell
    private let separatorView = UIView(frame: CGRectZero) //adds space between cells
    private let mainLabel = UILabel(frame: CGRectZero) //cell's main label (on Level 1), enable customization of font size/color
    
    //(OPTIONAL) Default Views:
    private var hideRightSideView: Bool = false //indicates if R view should be hidden (default FALSE)
    private var rightSideView = UIImageView(frame: CGRectZero) //holds completion indicator
    private var completionIndicator = UIImageView(image: UIImage(named: "x_mark")) //default => INCOMPLETE
    internal var firstLevelLeftButton: UIButton? { //btn is ALWAYS 35x35 if visible
        didSet { //layout views accordingly
            setNeedsLayout()
        }
    }
    internal var firstLevelRightButton: UIButton? { //btn is ALWAYS 35x35 if visible
        didSet { //layout views accordingly
            setNeedsLayout()
        }
    }
    
    //ADJUSTABLE Properties:
    internal var isOptional: Bool = false //checks if entry of data -> cell is optional (default = FALSE)
    internal var insetBackgroundColor: UIColor = UIColor.whiteColor() //default cell background color
    internal var separatorBackgroundColor: UIColor = UIColor.blackColor() //default separator color
    internal var separatorHeight: CGFloat = 2 //amount of space between cells
    internal var tabLevel: Int = 0 //indicates what drop-down level the cell is (0 = NO tab)
    internal var mainLabelFont: UIFont? //custom font for mainLabel
    internal var mainLabelTextColor: UIColor? //custom txtColor for mainLabel
    
    internal var numberOfLevels: Int = 1 //**indicates total height of cell (ht = # of levels * 40 + separatorHeight)
    
    //CONSTANT Properties:
    private let leftPadding: CGFloat = 10 //spacing from L boundary of the TV cell
    private let rightSideViewWidth: CGFloat = 50 //width of R side view is constant
    private let completionIndicatorSize = CGSize(width: 35, height: 35)
    private let levelHeight: CGFloat = 40 //height of each level is constant
    
    private var fireCounter: Int = 0 //ensures that 'accessDataSource' runs only 1x
    var dataSource: Dictionary<String, AnyObject>? { //contains all necessary configuration info
        didSet {
            if (fireCounter == 0) { //make sure this is only running ONCE
                accessDataSource() //obtain basic setup data from dataSource
                setNeedsLayout() //redraw the cell (must go OUTSIDE 'accessDataSource()'!)
                fireCounter = 1 //block further firing for this cell (cell can't change after 1st setup)
            }
        }
    }
    
    // MARK: - Initializers
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.backgroundColor = UIColor.clearColor() //*
        contentView.addSubview(insetBackgroundView)
        contentView.addSubview(separatorView)
        
        //Add ALL other views -> insetBackgroundView:
        insetBackgroundView.addSubview(mainLabel)
        rightSideView.addSubview(completionIndicator) //add completionIndicator -> R side view
        insetBackgroundView.addSubview(rightSideView)
        insetBackgroundView.backgroundColor = insetBackgroundColor
        separatorView.backgroundColor = separatorBackgroundColor //color between cells
        
        //Configure mainLabel:
        mainLabel.numberOfLines = 2 //displays on 2 lines (default is L alignment)
        if let font = mainLabelFont {
            mainLabel.font = font
        } else {
            mainLabel.font = UIFont.systemFontOfSize(14) //max fontSize that fits on 2 lines is (14)
        }
        if let txtColor = mainLabelTextColor { //default txtColor is BLACK
            mainLabel.textColor = txtColor
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    internal func accessDataSource() { //@ most basic level, gets mainLbl txt & checks if cell is optional
        if let source = dataSource {
            self.mainLabel.text = source[BMN_LEVELS_MainLabelKey] as? String
            if let optional = source[BMN_LEVELS_CellIsOptionalKey] as? Bool { //check if cell is optional (if NO value exists, cell is REQUIRED)
                self.isOptional = optional
                if (self.isOptional) { //set image -> nil & send LONE completion notification to VC
                    print("OPTIONAL config cell - sending lone completion notification...")
                    self.completionIndicator.image = nil //set default -> empty img, not 'X'
                    let notification = NSNotification(name: BMN_Notification_CompletionIndicatorDidChange, object: nil, userInfo: [BMN_LEVELS_CompletionIndicatorStatusKey: true])
                    NSNotificationCenter.defaultCenter().postNotification(notification) //send notification -> VC that the completion status is COMPLETE for this cell
                }
            }
            if let hideRightView = source[BMN_LEVELS_HideRightViewKey] as? Bool { //check if R side view should be hidden (default is VISIBLE)
                hideRightSideView = hideRightView
            }
            if let tab = source[BMN_LEVELS_TabLevelKey] as? Int { //check if cell is tabbed
                tabLevel = tab
            }
        }
    }
    
    // MARK: - STATIC Visual Layout
    
    override func prepareForReuse() { //???
        super.prepareForReuse()
    }
    
    override func setNeedsLayout() {
        super.setNeedsLayout()
        //**Cell height must be correctly set EXTERNALLY for this to work!!!
        print("[setNeedsLayout] Cell Height: \(self.frame.height).")
        
        //(1) Layout backgroundView & separatorView:
        let tabOffset = CGFloat(tabLevel) * 15 //adds a tab to the cell
        insetBackgroundView.frame = CGRectMake(tabOffset, 0, (frame.width - tabOffset), (frame.height - separatorHeight)) //offset by tabLevel
        separatorView.frame = CGRectMake(0, 0, frame.width, separatorHeight) //covers ENTIRE width!
        
        //(2) Layout rightSideView:
        var rightOffset: CGFloat = rightSideViewWidth //default offset from R (to account for sideView)
        if (hideRightSideView) { //leave frame as is (CGRectZero)
            rightOffset = 0 //remove R offset if the R side view is hidden
            completionIndicator.hidden = true //hide subview or imageView still shows!
        } else { //normal behavior, setup frame for view
            rightSideView.frame = CGRectMake((self.frame.width - rightSideViewWidth), 0, rightSideViewWidth, insetBackgroundView.frame.height)
            let completionIndicatorFrame = centerFrameInRect(completionIndicatorSize, superviewFrame: rightSideView.frame)
            completionIndicator.frame = completionIndicatorFrame
            
            //Draw a line separating R side view from views on L side:
            let lineWidth: CGFloat = 1.25
            let startPoint = CGPoint(x: lineWidth/2, y: 0) //offset by lineWidth/2 to show full line!
            let endPoint = CGPoint(x: lineWidth/2, y: insetBackgroundView.frame.height)
            drawLine(rightSideView, fromPoint: [startPoint], toPoint: [endPoint], lineColor: UIColor.blackColor(), lineWidth: lineWidth) //draw dividing line between R view & rest of view
        }
        
        //(3) Layout mainLabel & firstLevel buttons (ONLY 1 of the 2 can be present @ any time):
        let spacer: CGFloat = 5 //horizontal space between mainLabel & button
        if let leftButton = firstLevelLeftButton {
            leftButton.frame = CGRectMake(leftPadding, 2.5, 35, 35)
            let offsetX = leftButton.frame.maxX + spacer
            let labelWidth = insetBackgroundView.frame.width - rightOffset - leftPadding - offsetX
            mainLabel.frame = CGRectMake(offsetX, 2.5, labelWidth, 35)
        } else if let rightButton = firstLevelRightButton {
            rightButton.frame = CGRectMake((frame.width - rightOffset - leftPadding - 35), 2.5, 35, 35)
            let labelWidth = insetBackgroundView.frame.width - rightOffset - leftPadding * 2 - spacer - 35
            mainLabel.frame = CGRectMake(leftPadding, 2.5, labelWidth, 35)
        } else { //neither button exists, default layout
            let labelWidth = insetBackgroundView.frame.width - rightOffset - leftPadding * 2
            mainLabel.frame = CGRectMake(leftPadding, 2.5, labelWidth, 35)
        }
    }
    
    internal func getViewFrameForLevel(viewLevel level: (Int, HorizontalLevels, Int?)) -> CGRect { //input tuple: (StartLevel, HorizontalLevel, NumberOfLevels)
        //Automatically generates a view's frame based on the input size & its vertical/horizontal lvls; views are automatically aligned w/ the mainLabel's leading & trailing edges:
        let verticalOffset: CGFloat = 2.5 //offset for the top & bottom padding
        let horizontalSpacer: CGFloat = 2.5 //space between view & edge of its horizontal level frame (so 2 side-by-side views will never touch directly)
        
        //(1) Assign default height, width, & origin:
        var height: CGFloat = levelHeight - 2 * verticalOffset //height is always the same UNLESS view is defined as taking up MULTIPLE levels
        if let numberOfLevels = level.2 { //explicitly defined # of levels
            height = CGFloat(numberOfLevels) * 40 - 2 * verticalOffset
        }
        var baseWidth: CGFloat = insetBackgroundView.frame.width
        if !(hideRightSideView) { //R side view is NOT hidden, apply offset to base width
            baseWidth = insetBackgroundView.frame.width - rightSideViewWidth
        }
        var width: CGFloat = baseWidth - 2 * leftPadding //default width is for view taking up FULL level
        var originX = leftPadding //default X origin is @ leftPadding
        let originY = CGFloat(level.0 - 1) * 40 + verticalOffset //starting Y is based ONLY on vert level
        
        //(2) Overwrite defaults as needed:
        switch (level.1) { //check the assigned HORIZONTAL level
        case .FullLevel: break //all defaults apply
        case .LeftTwoThirdsLevel:
            width = baseWidth * 2/3 - leftPadding - horizontalSpacer
        case .RightTwoThirdsLevel:
            width = baseWidth * 2/3 - leftPadding - horizontalSpacer
            originX = baseWidth/3 + horizontalSpacer
        case .LeftHalfLevel:
            width = baseWidth/2 - leftPadding - horizontalSpacer
        case .RightHalfLevel:
            width = baseWidth/2 - leftPadding - horizontalSpacer
            originX = baseWidth/2 + horizontalSpacer
        case .LeftThirdLevel:
            width = baseWidth/3 - leftPadding - horizontalSpacer
        case .MidThirdLevel:
            width = baseWidth/3 - 2 * horizontalSpacer
            originX = baseWidth/3 + horizontalSpacer
        case .RightThirdLevel:
            width = baseWidth/3 - leftPadding - horizontalSpacer
            originX = baseWidth * 2/3 + horizontalSpacer
        }
        return CGRectMake(originX, originY, width, height)
    }
    
    // MARK: - DYNAMIC Visual Layout
    
    internal func configureCompletionIndicator(complete: Bool) { //adjusts visuals on completionIndicator
        if (isOptional) { //if cell is OPTIONAL, modify functionality - (1) When config is incomplete, the completionView shows NOTHING instead of an 'X'; (2) NO notifications are posted.
            if (complete) { //config COMPLETE
                completionIndicator.image = UIImage(named: "check")
            } else { //config INCOMPLETE
                completionIndicator.image = nil //clear image, but don't show the X mark
            }
        } else { //REQUIRED configuration cell
            if (complete) { //config COMPLETE
                if (completionIndicator.image != UIImage(named: "check")) { //ONLY switch images if the current image is NOT alrdy set -> 'check'
                    completionIndicator.image = UIImage(named: "check")
                    let notification = NSNotification(name: BMN_Notification_CompletionIndicatorDidChange, object: nil, userInfo: [BMN_LEVELS_CompletionIndicatorStatusKey: true])
                    NSNotificationCenter.defaultCenter().postNotification(notification) //send notification -> VC that the completion status has changed to COMPLETE
                }
            } else { //config INCOMPLETE
                if (completionIndicator.image != UIImage(named: "x_mark")) { //ONLY switch images if the current image is NOT alrdy set -> 'x_mark'
                    completionIndicator.image = UIImage(named: "x_mark")
                    let notification = NSNotification(name: BMN_Notification_CompletionIndicatorDidChange, object: nil, userInfo: [BMN_LEVELS_CompletionIndicatorStatusKey: false])
                    NSNotificationCenter.defaultCenter().postNotification(notification) //send notification -> VC that the completion status has changed to INCOMPLETE
                }
            }
        }
    }
    
    // MARK: - Data Reporting
    
    internal func reportData() -> AnyObject? { //reports all pertinent data entered by user, override
        print("[CellW/Levels > reportData()] Being called from super class...")
        return nil
    }

}

enum HorizontalLevels: Int { //horizontal level options
    case FullLevel = 0
    case LeftTwoThirdsLevel = 1
    case RightTwoThirdsLevel = 2
    case LeftHalfLevel = 3
    case RightHalfLevel = 4
    case LeftThirdLevel = 5
    case MidThirdLevel = 6
    case RightThirdLevel = 7
}