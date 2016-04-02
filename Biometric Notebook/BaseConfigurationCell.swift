//  BaseConfigurationCell.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 3/28/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Superclass for all custom configuration cell types.

import UIKit

class BaseConfigurationCell: UITableViewCell {
    
    //Cell-Specific Variables:
    var cellDescriptor: String = "" //dictionary key used to indicate UNIQUE ID of each cell
    var flagged: Bool = false { //if flagged, indicates that there is an error w/ the cell (change visual)
        didSet {
            configureFlagForCell()
        }
    }
    internal var isOptional: Bool = false //checks if cell is optional; default is FALSE (i.e. required)
    
    //Base Views:
    internal let insetBackground = UIView(frame: CGRectZero) //background for custom cell
    private let separatorView = UIView(frame: CGRectZero) //creates space between cells
    private let instructionsLabel = UILabel(frame: CGRectZero) //label w/ instructions for user
    private let completionSideView = UIImageView(frame: CGRectZero) //holds completion indicator
    private let completionIndicator = UIImageView(image: UIImage(named: "x_mark")) //default => incomplete
    
    //Layout Coordinates:
    private let insetBackgroundColor: UIColor = UIColor.whiteColor() //cell background color
    internal let completionViewWidth: CGFloat = 50
    internal let instructionsLabelHeight: CGFloat = 30
    internal let instructionsLabelTopPadding: CGFloat = 5
    internal let instructionsLabelLeftPadding: CGFloat = 10
    internal var instructionsLabelCenterX: CGFloat { //get centerX in LABEL's coordinate system
        return instructionsLabel.frame.width/2
    }
    internal var startingY: CGFloat {
        return instructionsLabelHeight + instructionsLabelTopPadding + 1
    }//**the superclass' layoutSubviews should provide helpful indicators to all subclasses about where to layout their special views (in relation to the superclass' label & completionIndicator views). These indicators indicate the start x & y values for any & all subviews. All subclasses should override & redescribe the starting point so that any subclasses of their own will start @ a different location!
    
    private var fireCounter: Int = 0 //ensures that 'accessDataSource' runs only 1x
    var dataSource: Dictionary<String, AnyObject>? { //contains all necessary configuration info
        didSet {
            if (fireCounter == 0) { //make sure this is only running ONCE
                accessDataSource() //obtain basic setup data from dataSource
                setNeedsLayout() //redraw the cell (must go OUTSIDE 'accessDataSource()'!)
                fireCounter = 1 //block further firing for this cell
            }
        }
    }
    
    // MARK - Initializers
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        insetBackground.backgroundColor = insetBackgroundColor
        separatorView.backgroundColor = UIColor.blackColor() //adds some space between cells
        contentView.addSubview(insetBackground)
        contentView.addSubview(separatorView)
        insetBackground.addSubview(instructionsLabel)
        insetBackground.addSubview(completionSideView)
        completionSideView.addSubview(completionIndicator)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Visual Layout
    
    override func prepareForReuse() { //do we have to reset anything on prepareForReuse?
        super.prepareForReuse()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let separatorHeight = CGFloat(2) //distance between cells
        insetBackground.frame = CGRect(x: 0, y: 0, width: frame.width, height: (frame.height - separatorHeight))
        separatorView.frame = CGRect(x: 0, y: (frame.height - separatorHeight), width: frame.width, height: separatorHeight)
        
        //(2) Configure the instructionsLabel:
        let labelWidth = frame.width - completionViewWidth - 2 * instructionsLabelLeftPadding
        let labelFrame = CGRectMake(instructionsLabelLeftPadding, instructionsLabelTopPadding, labelWidth, instructionsLabelHeight)
        instructionsLabel.frame = labelFrame
        
        //(3) Configure the completionIndicator & its parent view:
        let rightViewX = insetBackground.frame.width - completionViewWidth
        completionSideView.frame = CGRect(x: rightViewX, y: 0, width: completionViewWidth, height: insetBackground.frame.height)
        let center: CGPoint = CGPoint(x: completionSideView.frame.width/2, y: completionSideView.frame.height/2)
        let width = CGFloat(40)
        let indicatorFrame = CGRectMake((center.x - width/2), (center.y - width/2), width, width)
        completionIndicator.frame = indicatorFrame
        let startPoint = CGPoint(x: 1, y: 0)
        let endPoint = CGPoint(x: 1, y: insetBackground.frame.height)
        drawLine(completionSideView, fromPoint: [startPoint], toPoint: [endPoint])
    }
    
    internal func accessDataSource() {
        if let source = dataSource, descriptor = source[BMN_Configuration_CellDescriptorKey] as? String {
            self.instructionsLabel.text = source[BMN_Configuration_InstructionsLabelKey] as? String
            self.cellDescriptor = descriptor //set cell descriptor
            if let optional = source[BMN_Configuration_CellIsOptionalKey] as? Bool { //check if cell is optional (if no value exists, cell is REQUIRED)
                self.isOptional = optional
                    
                if (self.isOptional) { //set image -> nil & send lone completion notification to VC
                    print("OPTIONAL config cell - sending single completion notification...")
                    self.completionIndicator.image = nil //set default -> empty img, not 'X'
                    let notification = NSNotification(name: "BMNCompletionIndicatorDidChange", object: nil, userInfo: [BMN_Configuration_CompletionIndicatorStatusKey: true])
                    NSNotificationCenter.defaultCenter().postNotification(notification) //send notification -> VC that the completion status is COMPLETE
                }
            }
        } else {
            print("[Config Cell - accessDataSource] ERROR - cell has NO descriptor!")
        }
    }
    
    // MARK: - Dynamic Visual Configuration
    
    internal func configureCompletionIndicator(complete: Bool) { //adjusts visuals on completionIndicator
        self.flagged = false
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
                    let notification = NSNotification(name: BMN_Notification_CompletionIndicatorDidChange, object: nil, userInfo: [BMN_Configuration_CompletionIndicatorStatusKey: true])
                    NSNotificationCenter.defaultCenter().postNotification(notification) //send notification -> VC that the completion status has changed to COMPLETE
                }
            } else { //config INCOMPLETE
                if (completionIndicator.image != UIImage(named: "x_mark")) { //ONLY switch images if the current image is NOT alrdy set -> 'x_mark'
                    completionIndicator.image = UIImage(named: "x_mark")
                    let notification = NSNotification(name: BMN_Notification_CompletionIndicatorDidChange, object: nil, userInfo: [BMN_Configuration_CompletionIndicatorStatusKey: false])
                    NSNotificationCenter.defaultCenter().postNotification(notification) //send notification -> VC that the completion status has changed to INCOMPLETE
                }
            }
        }
    }
    
    private func configureFlagForCell() { //adds or removes the visual flag from the cell
        if (self.flagged) { //highlights the incorrect cells in red
            configureCompletionIndicator(false) //*first, set completion indicator -> false!
            insetBackground.backgroundColor = UIColor(red: 255/255, green: 0, blue: 0, alpha: 0.3)
        } else { //restore visual -> unflagged state
            insetBackground.backgroundColor = insetBackgroundColor //reset background -> default
        }
    }
    
    // MARK: - Data Reporting
    
    internal func reportData() -> AnyObject? { //reports all pertinent data entered by the user
        print("[BaseConfigCell > reportData()] Being called from super class...(make sure there is an EXAMPLE cell in the setup, or else this is an error)!")
        return nil
    }

}
