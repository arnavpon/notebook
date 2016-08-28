//  GroupSelectionView_CollectionViewCell.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 8/15/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Custom cell type for DEVC group selection view's collectionView.

import UIKit

class GroupSelectionView_CollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var optionButton: UIButton!
    
    var cellIndex: Int? //cell's index # (set by collectionView delegate)
    
    // MARK: - Initializers
    
    override func awakeFromNib() {
        super.awakeFromNib()
        optionButton.titleLabel?.numberOfLines = 3
    }
    
    // MARK: - Button Actions
    
    @IBAction func optionButtonClick(sender: AnyObject) {
        if let index = cellIndex { //indicate to VC which button was selected
            print("Button @ index \(index) was pressed!")
            let notification = NSNotification(name: BMN_Notification_DataEntry_GroupSelection_OptionWasSelected, object: index)
            NSNotificationCenter.defaultCenter().postNotification(notification)
        }
    }
    
}