//  BaseConfigurationCell.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 3/28/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Superclass for all custom configuration cell types.

import UIKit

class BaseConfigurationCell: LevelsFrameworkCell {
    
    override class var numberOfLevels: Int { //default # of levels is 2 for Configuration cells
        return 2
    }
    
    var cellDescriptor: String = "" //dictionary key used to indicate UNIQUE ID of each cell
    var flagged: Bool = false { //if flagged, indicates that there is an error w/ the cell (change visual)
        didSet {
            configureFlagForCell()
        }
    }
    
    // MARK - Initializers
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Visual Layout
    
    internal override func accessDataSource() {
        super.accessDataSource()
        if let source = dataSource, descriptor = source[BMN_Configuration_CellDescriptorKey] as? String {
            self.cellDescriptor = descriptor //set cell descriptor
        } else {
            print("[Config Cell - accessDataSource] ERROR - cell has NO descriptor!")
        }
    }
    
    // MARK: - Dynamic Visual Configuration
    
    internal override func configureCompletionIndicator(complete: Bool) {
        super.configureCompletionIndicator(complete)
        self.flagged = false //remove flag any time a change in completion status occurs
    }
    
    private func configureFlagForCell() { //adds or removes the visual flag from the cell
        if (self.flagged) { //highlights the incorrect cells in red
            configureCompletionIndicator(false) //*first, set completion indicator -> false!
            insetBackgroundView.backgroundColor = UIColor(red: 255/255, green: 0, blue: 0, alpha: 0.3)
        } else { //restore visual -> unflagged state
            insetBackgroundView.backgroundColor = insetBackgroundColor //reset background -> default
        }
    }
    
    // MARK: - Data Reporting
    
    internal var configurationReportObject: AnyObject? { //object to report -> VC, override in subclass
        return nil
    }
    
    override func reportData() { //send notification w/ data against cellDescriptor
        if let reportObject = configurationReportObject {
            let notification = NSNotification(name: BMN_Notification_CellDidReportData, object: nil, userInfo: [cellDescriptor: reportObject])
            NSNotificationCenter.defaultCenter().postNotification(notification)
        }
    }

}
