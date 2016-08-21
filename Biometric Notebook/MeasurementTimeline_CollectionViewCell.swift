//  MeasurementTimeline_CollectionViewCell.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 8/15/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

import UIKit

enum MeasurementTimeline_CardTypes {
    case Default //default card type for location in cycle
    case Action //card for project's action if it does not occupy a space in the timeline
    case TimeDifference //card containing all TD vars (@ end of timeline)
}

enum MeasurementTimeline_VariableTypes { //varTypes are used for visuals & controlling interaction
    case InputVariable
    case OutcomeMeasure
    case ActionQualifier
    case TimeDifference
    case GhostVariable
}

struct MeasurementTimelineVariable { //shell for variables found in a collection view cell
    
    let name: String //unique ID for var
    let variableType: MeasurementTimeline_VariableTypes //type => visual display format
    
    init(name: String, type: MeasurementTimeline_VariableTypes) {
        self.name = name
        self.variableType = type
    }
    
}

class MeasurementTimeline_CollectionViewCell: UICollectionViewCell, UITableViewDataSource, UITableViewDelegate { //card holding information for each location in the measurement cycle
    
    @IBOutlet weak var topLabel: UILabel! //label for cell type
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var timeDifferenceButton: UIButton!
    @IBOutlet weak var variablesTableView: UITableView!
    
    var dataSource: (MeasurementTimeline_CardTypes, Int?, [MeasurementTimelineVariable])? { //cell source
        didSet {
            self.updateVisualsForDataSource() //update card visuals after setting source
        }
    }
    var variablesForLocation: [MeasurementTimelineVariable] = [] { //indicates vars for location in cycle
        didSet {
            dispatch_async(dispatch_get_main_queue()) {
                self.variablesTableView.reloadData() //update UI
            }
        }
    }
    var cardType: MeasurementTimeline_CardTypes = .Default { //type for card
        didSet {
            self.setVisualFormattingForCardType() //adjust visuals
        }
    }
    var cellIndex: Int? //index # of cell in collectionView (used in notif when TV cell is clicked)
    var locationInCycle: Int? { //location of items on card in measurement cycle
        didSet {
            if let location = self.locationInCycle { //locationInCycle EXISTS - set label
                self.locationLabel.text = "\(location)"
                self.locationLabel.hidden = false //reveal locationLbl
                self.timeDifferenceButton.hidden = false //reveal TD btn ONLY if card has location!
            } else { //NO location - hide label & TD btn
                self.locationLabel.hidden = true //hide locationLbl
                self.timeDifferenceButton.hidden = true //NO TD btn for card w/o a location!
            }
        }
    }
    var projectAction: String? //indicates Action type for display in Action card
    
    var timeDifferenceButtonDefaultTextColor = UIColor.whiteColor()
    var timeDifferenceButtonSelectedTextColor = UIColor.greenColor()
    var timeDifferenceButtonDefaultBackgroundColor = UIColor(red: 190/255, green: 190/255, blue: 190/255, alpha: 1)
    var timeDifferenceButtonSelectedBackgroundColor = UIColor.blackColor()
    
    // MARK: - Initializers
    
    override func awakeFromNib() { //customize views after awakening
        super.awakeFromNib()
        
        //Configure tableView:
        variablesTableView.backgroundColor = UIColor.clearColor() //set background -> see-through
        variablesTableView.dataSource = self
        variablesTableView.delegate = self
        variablesTableView.registerClass(MeasurementTimeline_TableViewCell.self, forCellReuseIdentifier: NSStringFromClass(MeasurementTimeline_TableViewCell)) //register cell type
        
        //Customize self.view (add border):
        self.layer.borderColor = UIColor.whiteColor().CGColor
        self.layer.borderWidth = 1
        self.topLabel.textColor = UIColor.whiteColor() //default txtColor = white
        
        //Customize location label (add rounded border):
        locationLabel.layer.borderWidth = 2
        locationLabel.layer.borderColor = UIColor.blackColor().CGColor
        locationLabel.layer.cornerRadius = 3
        locationLabel.backgroundColor = UIColor.darkGrayColor()
        locationLabel.textColor = UIColor.redColor()
        
        //Customize TD button (make it circular):
        timeDifferenceButton.backgroundColor = timeDifferenceButtonDefaultBackgroundColor
        timeDifferenceButton.setTitleColor(timeDifferenceButtonDefaultTextColor, forState: .Normal)
        timeDifferenceButton.layer.cornerRadius = 17 //round the button
    }
    
    private func updateVisualsForDataSource() { //when dataSource is set, adjust visuals
        if let source = dataSource {
            self.cardType = source.0 //set cardType
            if let location = source.1 { //locationInCycle EXISTS
                self.locationInCycle = location //set self indicator
            } else { //NO location
                self.locationInCycle = nil //clear self indicator
            }
            variablesForLocation = source.2 //set TV dataSource
        }
        timeDifferenceButton.backgroundColor = timeDifferenceButtonDefaultBackgroundColor //reset bckgrd
        timeDifferenceButton.setTitleColor(timeDifferenceButtonDefaultTextColor, forState: .Normal)
    }
    
    private func setVisualFormattingForCardType() {
        switch self.cardType { //adjust visuals for cardType
        case .Default:
            self.backgroundColor = UIColor(red: 1, green: 249/255, blue: 245/255, alpha: 1)
            self.topLabel.hidden = true //hide topLbl in default card
        case .Action:
            self.backgroundColor = UIColor(red: 62/255, green: 174/255, blue: 1, alpha: 1)
            if let action = projectAction {
                self.topLabel.text = action //display actionType in lbl
            } else {
                self.topLabel.text = "Action" //display generic title
            }
            self.topLabel.hidden = false //reveal topLbl
        case .TimeDifference:
            self.backgroundColor = UIColor(red: 91/255, green: 34/255, blue: 205/255, alpha: 1)
            self.topLabel.text = "Time Difference"
            self.topLabel.adjustsFontSizeToFitWidth = true
            self.topLabel.hidden = false //reveal topLbl
        }
    }
    
    // MARK: - Table View
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return variablesForLocation.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(NSStringFromClass(MeasurementTimeline_TableViewCell)) as! MeasurementTimeline_TableViewCell
        cell.separatorHeight = 6 //increase space between cells
        cell.separatorBackgroundColor = UIColor.clearColor() //space btwn cells is CLEAR
        cell.backgroundColor = UIColor.clearColor() //*background must also be clear*
        let variable = variablesForLocation[indexPath.row]
        switch variable.variableType { //adjust visuals depending on variableType
        case .InputVariable: //pale RED
            cell.insetBackgroundColor = UIColor(red: 255/255, green: 216/255, blue: 227/255, alpha: 1)
            cell.textLabel?.textColor = UIColor.blackColor()
        case .OutcomeMeasure: //pale GREEN
            cell.insetBackgroundColor = UIColor(red: 219/255, green: 255/255, blue: 232/255, alpha: 1)
            cell.textLabel?.textColor = UIColor.blackColor()
        case .ActionQualifier: //pale BLUE
            cell.insetBackgroundColor = UIColor(red: 214/255, green: 238/255, blue: 255/255, alpha: 1)
            cell.textLabel?.textColor = UIColor.blackColor()
        case .TimeDifference: //pale PURPLE
            cell.insetBackgroundColor = UIColor(red: 232/255, green: 229/255, blue: 255/255, alpha: 1)
            cell.textLabel?.textColor = UIColor.blackColor()
        case .GhostVariable: //pale GRAY
            cell.insetBackgroundColor = UIColor(red: 211/255, green: 211/255, blue: 211/255, alpha: 0.5)
            cell.textLabel?.textColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5) //fade txt
        }
        cell.textLabel?.text = variable.name
        return cell
    }
    
    func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if let cell = tableView.cellForRowAtIndexPath(indexPath) as? MeasurementTimeline_TableViewCell, index = self.cellIndex { //allow user to swap locations w/ notifications
            let selection = variablesForLocation[indexPath.row]
            switch selection.variableType {
            case .ActionQualifier, .GhostVariable:
                return false //prevent selection of these types
            case .TimeDifference: //give user option to delete var
                cell.insetBackgroundColor = UIColor.lightGrayColor() //set highlight color
                let notification = NSNotification(name: BMN_Notification_MeasurementTimeline_ShouldDeleteTimeDifferenceVariable, object: indexPath.row) //send row # of TD var to be deleted in notification
                NSNotificationCenter.defaultCenter().postNotification(notification)
                return false
            default: //allow selection of remaining types
                if let location = self.locationInCycle {
                    cell.insetBackgroundColor = UIColor.lightGrayColor() //set highlight color
                    let notification = NSNotification(name: BMN_Notification_MeasurementTimeline_VariableWasSelected, object: index, userInfo: [BMN_MeasurementTimeline_VariableForSelectionKey: selection.name, BMN_MeasurementTimeline_LocationInCycleKey: location]) //pass var/index/location
                    NSNotificationCenter.defaultCenter().postNotification(notification)
                }
            }
        }
        return false
    }
    
    // MARK: - Button Actions
    
    @IBAction func timeDifferenceButtonClick(sender: AnyObject) {
        if let location = locationInCycle {
            var selected: Bool = false //indicator (TRUE => btn was selected)
            if (timeDifferenceButton.backgroundColor != timeDifferenceButtonDefaultBackgroundColor) { //cell is ALREADY highlighted - restore DEFAULT visuals
                timeDifferenceButton.backgroundColor = timeDifferenceButtonDefaultBackgroundColor
                timeDifferenceButton.setTitleColor(timeDifferenceButtonDefaultTextColor, forState: .Normal)
            } else { //cell is NOT already highlighted - set SELECTED visuals
                timeDifferenceButton.backgroundColor = timeDifferenceButtonSelectedBackgroundColor
                timeDifferenceButton.setTitleColor(timeDifferenceButtonSelectedTextColor, forState: .Normal)
                selected = true //set indicator
            }
            let notification = NSNotification(name: BMN_Notification_MeasurementTimeline_TimeDifferenceButtonWasClicked, object: location, userInfo: [BMN_MeasurementTimeline_TDButtonStateKey: selected]) //send notification indicating location in cycle of btn & whether it was selected or deselected
            NSNotificationCenter.defaultCenter().postNotification(notification)
        }
    }
    
}

class MeasurementTimeline_TableViewCell: UITableViewCell { //custom cell in MT cell's TV
    
    internal let insetBackgroundView = UIView(frame: CGRectZero) //background for cell
    private let separatorView = UIView(frame: CGRectZero) //adds space btwn cells in TV
    
    //ADJUSTABLE Properties:
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
    
    // MARK: - Initializers
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.clipsToBounds = true //makes sure subviews outside bounds are NOT visible
        
        contentView.backgroundColor = UIColor.clearColor()
        contentView.addSubview(insetBackgroundView)
        contentView.sendSubviewToBack(insetBackgroundView)
        contentView.addSubview(separatorView)
        contentView.sendSubviewToBack(separatorView)
        insetBackgroundView.backgroundColor = insetBackgroundColor //cell background color
        insetBackgroundView.layer.borderColor = UIColor.blackColor().CGColor //set black border
        insetBackgroundView.layer.borderWidth = 1.0
        separatorView.backgroundColor = separatorBackgroundColor //color between cells
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Visual Layout
    
    override func setNeedsLayout() { //layout backgroundView & separatorView
        super.setNeedsLayout()
        insetBackgroundView.frame = CGRectMake(0, 0, frame.width, (frame.height - separatorHeight))
        separatorView.frame = CGRectMake(0, (frame.height - separatorHeight), frame.width, separatorHeight)
    }

}