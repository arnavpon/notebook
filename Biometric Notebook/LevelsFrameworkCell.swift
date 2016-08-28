//  LevelsFrameworkCell.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 4/4/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Base framework that dictates layout for (almost) all of BMN's custom TV cells.

import UIKit

class LevelsFrameworkCell: UITableViewCell {
    
    class var numberOfLevels: Int { return 1 } //total height of cell = (numLevels * 40) + separatorHeight
    static let levelHeight: CGFloat = 40 //height of each level is constant (linked to 'heightForRow()' method in VC TV delegate)
    
    //(REQUIRED) Default Views:
    internal let indentationView = UIView(frame: CGRectZero) //view that indents cell to the right
    internal let insetBackgroundView = UIView(frame: CGRectZero) //background for LEVELS cell
    private let separatorView = UIView(frame: CGRectZero) //adds space between cells
    private let mainLabel = UILabel(frame: CGRectZero) //cell's main label (on Level 1), enable customization of font size/color
    
    //(OPTIONAL) Default Views:
    private var hideRightSideView: Bool = false //indicates if R view should be hidden (default FALSE)
    private var rightSideView = UIImageView(frame: CGRectZero) //holds completion indicator
    private var completionIndicator = UIImageView(frame: CGRectZero) //default => INCOMPLETE
    private let completeImage = UIImage(named: "check") //control img from here!
    private let incompleteImage = UIImage(named: "x_mark") //control img from here!
    internal var firstLevelLeftButton: UIButton? { //btn is ALWAYS 35x35 if visible
        didSet { //layout views accordingly
            setNeedsLayout() //need this b/c btn is only revealed through dataSource, AFTER init
        }
    }
    internal var firstLevelRightButton: UIButton? { //btn is ALWAYS 35x35 if visible
        didSet { //layout views accordingly
            setNeedsLayout() //need this b/c btn is only revealed through dataSource, AFTER init
        }
    }
    
    //ADJUSTABLE Properties:
    internal var isOptional: Bool = false { //checks if entry of data -> cell is optional
        didSet { //if cell is set -> optional, send a SINGLE notification (status is ALWAYS complete)
            if (self.isOptional) { //set image -> nil & send LONE completion notification to VC
                print("OPTIONAL config cell - sending lone completion notification...")
                self.completionIndicator.image = nil //set default -> empty img, not 'X'
                let notification = NSNotification(name: BMN_Notification_CompletionIndicatorDidChange, object: nil, userInfo: [BMN_LEVELS_CompletionIndicatorStatusKey: true])
                NSNotificationCenter.defaultCenter().postNotification(notification) //send notification -> VC that the completion status is COMPLETE for this cell
            }
        }
    }
    internal var indentationViewBackgroundColor: UIColor = UIColor.whiteColor() { //DEFAULT background color, DO NOT CHANGE property in subclasses (references default so that state can be RESTORED)!
        didSet {
            indentationView.backgroundColor = indentationViewBackgroundColor //adjust color for view
        }
    }
    internal var insetBackgroundColor: UIColor = UIColor.whiteColor() { //DEFAULT background color, DO NOT CHANGE property in subclasses (provides reference to default so that state can be RESTORED)!
        didSet {
            insetBackgroundView.backgroundColor = insetBackgroundColor //adjust color for view
        }
    }
    internal var separatorBackgroundColor: UIColor = UIColor.blackColor() { //default separator color
        didSet {
            separatorView.backgroundColor = separatorBackgroundColor //adjust color for view
        }
    }
    internal var separatorHeight: CGFloat = 2 //amount of space between cells
    internal var tabLevel: Int = 0 //indicates what drop-down level the cell is (0 = NO tab)
    internal var mainLabelFont: UIFont? { //custom font for mainLabel
        didSet {
            mainLabel.font = mainLabelFont //adjust font
        }
    }
    internal var mainLabelTextColor: UIColor? { //custom txtColor for mainLabel
        didSet {
            mainLabel.textColor = mainLabelTextColor //adjust color
        }
    }
    
    //CONSTANT Properties:
    private let leftPadding: CGFloat = 10 //spacing from L boundary of the TV cell
    private let rightSideViewWidth: CGFloat = 50 //width of R side view is constant
    private let completionIndicatorSize = CGSize(width: 35, height: 35)
    private let mainLabelHeight: CGFloat = 35
    private let leftButtonWidth: CGFloat = 20 //button is square so width == height
    private let rightButtonWidth: CGFloat = 30 //button is square so width == height
    private let buttonSpacer: CGFloat = 5 //horizontal space between mainLabel & button
    
    //DATA SOURCE - (1) Configuration cell dataSource is the 'dataSource' property. (2) DataEntry cell dataSource is the 'module' property.
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
    weak var module: Module? { //for DataEntry cells, all data to be displayed will be determined through the module property; for subclasses of BaseDataEntryCell, 'module' is a specific Module subclass
        didSet {
            if (fireCounter == 0) { //make sure this is only running ONCE
                accessModuleProperties() //layout cell according to module type/properties
                setNeedsLayout() //keep OUTSIDE of the accessModule function!
            }
        }
    }
    var currentlyReportingLocation: Int? //set by DEVC - used for DE cell mainLabel
    
    // MARK: - Initializers
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.clipsToBounds = true //makes sure subviews outside bounds are NOT visible
        
        contentView.backgroundColor = UIColor.clearColor() 
        contentView.addSubview(insetBackgroundView)
        contentView.addSubview(separatorView)
        contentView.addSubview(indentationView)
        indentationView.backgroundColor = indentationViewBackgroundColor //default = white
        
        //Add ALL other views -> insetBackgroundView:
        insetBackgroundView.addSubview(mainLabel)
        completionIndicator.image = incompleteImage //set default to incomplete
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
    
    internal func accessDataSource() { //configures non-DataEntry cell's visuals
        //@ most basic level, gets mainLbl txt & checks if cell is optional:
        if let source = dataSource {
            self.mainLabel.text = source[BMN_LEVELS_MainLabelKey] as? String
            if let optional = source[BMN_LEVELS_CellIsOptionalKey] as? Bool { //check if cell is optional (if NO value exists, cell is REQUIRED)
                self.isOptional = optional
            }
            if let hideRightView = source[BMN_LEVELS_HideRightViewKey] as? Bool { //check if R side view should be hidden (default is VISIBLE)
                hideRightSideView = hideRightView
            }
            if let tab = source[BMN_LEVELS_TabLevelKey] as? Int { //check if cell is tabbed
                tabLevel = tab
            }
        }
    }
    
    internal func accessModuleProperties() { //configures DataEntry cell's visuals
        if let mod = module, selection = mod.selectedFunctionality { //update mainLabel
            if let location = currentlyReportingLocation {
                let sortedArray = mod.reportLocations.sort() //sort array in ascending order
                if let index = sortedArray.indexOf(location) { //get position in array of location
                    let count = mod.reportLocations.count
                    if let alternativeTitle = mod.cellPrompt { //check for alternative title (a prompt)
                        mainLabel.text = "<Report #\(index + 1)/\(count)> [\(mod.variableName)] \(alternativeTitle)"
                    } else { //NO prompt - set mainLabel to indicate var's name & location in cycle
                        mainLabel.text = "<Report #\(index + 1)/\(count)> \(mod.variableName) "
                    }
                    return //terminate function to avoid default option
                }
            }
            mainLabel.text = "\(mod.variableName): \(selection)" //default title if all else fails
        }
    }
    
    // MARK: - STATIC Visual Layout
    
    override func prepareForReuse() { //???
        super.prepareForReuse()
    }
    
    override func setNeedsLayout() {
        super.setNeedsLayout()
        
        //(1) Layout backgroundView & separatorView:
        let tabOffset = CGFloat(tabLevel) * 15 //adds a tab to the cell
        indentationView.frame = CGRectMake(0, 0, tabOffset, frame.height) //indents cell by tabOffset
        insetBackgroundView.frame = CGRectMake(tabOffset, 0, (frame.width - tabOffset), (frame.height - separatorHeight)) //offset by tabLevel
        separatorView.frame = CGRectMake(tabOffset, (frame.height - separatorHeight), (frame.width - tabOffset), separatorHeight) //offset by tabLevel
        
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
        
        //(3) Layout mainLabel & firstLevel buttons (either 1 or both can be present in a cell):
        let lvlHeight = LevelsFrameworkCell.levelHeight
        var leftButtonOffset: CGFloat = 0 //offset IFF leftButton exists
        var rightButtonOffset: CGFloat = 0 //offset IFF rightButton exists
        if let leftButton = firstLevelLeftButton {
            leftButton.frame = CGRectMake(leftPadding, (lvlHeight - leftButtonWidth)/2, leftButtonWidth, leftButtonWidth)
            leftButtonOffset = leftButtonWidth + buttonSpacer //does NOT account for labelPadding!
        }
        if let rightButton = firstLevelRightButton {
            rightButton.frame = CGRectMake((frame.width - rightOffset - leftPadding - rightButtonWidth), (lvlHeight - rightButtonWidth)/2, rightButtonWidth, rightButtonWidth)
            rightButtonOffset = rightButtonWidth + buttonSpacer //does NOT account for labelPadding!
        }
        let labelWidth = insetBackgroundView.frame.width - rightOffset - leftPadding * 2 - leftButtonOffset - rightButtonOffset
        mainLabel.frame = CGRectMake((leftPadding + leftButtonOffset), (lvlHeight - mainLabelHeight)/2, labelWidth, mainLabelHeight)
    }
    
    internal func getViewFrameForLevel(viewLevel level: (Int, HorizontalLevels, Int?)) -> CGRect { //input tuple: (StartLevel, HorizontalLevel, NumberOfLevels)
        //Automatically generates a view's frame based on the input size & its vertical/horizontal lvls; views are automatically aligned w/ the mainLabel's leading & trailing edges:
        let verticalOffset: CGFloat = 2.5 //offset for the top & bottom padding
        let horizontalSpacer: CGFloat = 2.5 //space between view & edge of its horizontal level frame (so 2 side-by-side views will never touch directly)
        
        //(1) Assign default height, width, & origin:
        var height: CGFloat = LevelsFrameworkCell.levelHeight - 2 * verticalOffset //height is always the same UNLESS view is defined as taking up MULTIPLE levels
        if let numberOfLevels = level.2 { //explicitly defined # of levels
            height = CGFloat(numberOfLevels) * 40 - 2 * verticalOffset
        }
        var leftButtonOffset: CGFloat = 0 //set IFF leftButton exists
        if let _ = firstLevelLeftButton {
            leftButtonOffset = leftButtonWidth + buttonSpacer
        }
        var baseWidth: CGFloat = insetBackgroundView.frame.width
        if !(hideRightSideView) { //R side view is NOT hidden, apply offset to base width
            baseWidth = insetBackgroundView.frame.width - rightSideViewWidth - leftButtonOffset
        }
        var width: CGFloat = baseWidth - 2 * leftPadding //default width is for view taking up FULL level
        var originX = leftPadding + leftButtonOffset //default X origin
        let originY = CGFloat(level.0 - 1) * 40 + verticalOffset //starting Y is based ONLY on vert level
        
        //(2) Overwrite defaults as needed:
        switch (level.1) { //check the assigned HORIZONTAL level
        case .FullLevel: break //all defaults apply
        case .LeftTwoThirdsLevel:
            width = baseWidth * 2/3 - leftPadding - horizontalSpacer
        case .RightTwoThirdsLevel:
            width = baseWidth * 2/3 - leftPadding - horizontalSpacer
            originX = baseWidth/3 + horizontalSpacer + leftButtonOffset
        case .LeftHalfLevel:
            width = baseWidth/2 - leftPadding - horizontalSpacer
        case .RightHalfLevel:
            width = baseWidth/2 - leftPadding - horizontalSpacer
            originX = baseWidth/2 + horizontalSpacer + leftButtonOffset
        case .LeftThirdLevel:
            width = baseWidth/3 - leftPadding - horizontalSpacer
        case .MidThirdLevel:
            width = baseWidth/3 - 2 * horizontalSpacer
            originX = baseWidth/3 + horizontalSpacer + leftButtonOffset
        case .RightThirdLevel:
            width = baseWidth/3 - leftPadding - horizontalSpacer
            originX = baseWidth * 2/3 + horizontalSpacer + leftButtonOffset
        case .LeftSevenEighthsLevel:
            width = baseWidth * 7/8 - leftPadding - horizontalSpacer
        case .RightOneEighthLevel:
            width = baseWidth/8 - leftPadding - horizontalSpacer
            originX = baseWidth * 7/8 + horizontalSpacer + leftButtonOffset
        }
        return CGRectMake(originX, originY, width, height)
    }
    
    internal func setMainLabelTitle(title: String) { //allows external title control
        self.mainLabel.text = title //update title
    }
    
    // MARK: - DYNAMIC Visual Layout
    
    internal func configureCompletionIndicator(complete: Bool) { //adjusts visuals on completionIndicator
        if (isOptional) { //if cell is OPTIONAL, modify functionality - (1) When config is incomplete, the completionView shows NOTHING instead of an 'X'; (2) NO notifications are posted.
            if (complete) { //config COMPLETE
                completionIndicator.image = completeImage
                reportData() //fire the reportData() fx to update the external (VC) report object
            } else { //config INCOMPLETE
                completionIndicator.image = nil //clear image, but don't show the X mark
            }
        } else { //REQUIRED configuration cell
            reportData() //fire reportData() to update the external (VC) report object
            if (complete) { //config COMPLETE
                if (completionIndicator.image != completeImage) { //ONLY switch images & fire notification if the current image is NOT alrdy set -> 'check'
                    completionIndicator.image = completeImage
                    let notification = NSNotification(name: BMN_Notification_CompletionIndicatorDidChange, object: nil, userInfo: [BMN_LEVELS_CompletionIndicatorStatusKey: true])
                    NSNotificationCenter.defaultCenter().postNotification(notification) //send notification -> VC that the completion status has changed to COMPLETE
                }
            } else { //config INCOMPLETE
                if (completionIndicator.image != incompleteImage) { //ONLY switch images & fire notification if the current image is NOT alrdy set -> 'x_mark'
                    completionIndicator.image = incompleteImage
                    let notification = NSNotification(name: BMN_Notification_CompletionIndicatorDidChange, object: nil, userInfo: [BMN_LEVELS_CompletionIndicatorStatusKey: false])
                    NSNotificationCenter.defaultCenter().postNotification(notification) //send notification -> VC that the completion status has changed to INCOMPLETE
                }
            }
        }
    }
    
    // MARK: - Data Reporting
    
    internal func reportData() { //reports all pertinent data entered by user, override ONLY in BASE ConfigurationCells & CreateProject cells
        //when called, send a notification -> VC w/ the data to update the report object whenever the cell is marked as complete
    }

}

enum HorizontalLevels { //horizontal level options
    case FullLevel
    case LeftTwoThirdsLevel
    case RightTwoThirdsLevel
    case LeftHalfLevel
    case RightHalfLevel
    case LeftThirdLevel
    case MidThirdLevel
    case RightThirdLevel
    
    case LeftSevenEighthsLevel //part of a level pair (view + small button on its right)
    case RightOneEighthLevel //part of a level pair (view + small button on its right)
}