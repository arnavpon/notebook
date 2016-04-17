//  DataEntryCellTypes.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 3/29/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Enum containing all possible data reporting cell types.

import Foundation
import UIKit

enum DataEntryCellTypes: String { //REGISTER each new enum type w/ TV in DataEntryVC & add class to cellForRowAtIndexPath()!
    
    case CustomWithCounter //Custom Module cell w/ counter
    case CustomWithOptions //Custom Module cell w/ options
    case CustomWithRangeScale //Custom Module cell w/ range scale
    
    func getHeightForDataEntryCell(userInfo: [String: AnyObject]) -> CGFloat { //calculates the height for a DataEntry cell given the input parameters (stored against function-specific keys)
        let levelHeight: CGFloat = LevelsFrameworkCell.levelHeight
        var numberOfLevels: Int //default # of lvls
        switch self {
        case .CustomWithOptions: //access key indicating # of custom options to calculate height
            numberOfLevels = CustomWithOptionsCell.numberOfLevels
            if let numberOfOptions = userInfo[BMN_DataEntry_CustomWithOptions_NumberOfOptionsKey] as? Int {
                numberOfLevels = CustomWithOptionsCell.numberOfLevels + numberOfOptions
            }
        case .CustomWithCounter:
            numberOfLevels = CustomWithCounterCell.numberOfLevels
        case .CustomWithRangeScale:
            numberOfLevels = CustomWithRangeScaleCell.numberOfLevels
        }
        return levelHeight * CGFloat(numberOfLevels) + BMN_DefaultBottomSpacer //default height
    }
    
}