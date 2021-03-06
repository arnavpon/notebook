//  DataEntryCellTypes.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 3/29/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Enum containing all possible data reporting cell types.

import Foundation
import UIKit

enum DataEntryCellTypes: String { //REGISTER each new enum type w/ TV in DataEntryVC & add class to cellForRowAtIndexPath()!
    
    case Freeform //General cell for freeform entry (contains textField)
    case Picker //General cell for value selection (contains PickerView)
    case CustomWithCounter //Custom Module cell w/ counter
    case CustomWithOptions //Custom Module cell w/ options
    case CustomWithRangeScale //Custom Module cell w/ range scale
    case FIM_FoodIntake //FoodIntake Module cell for inputting meal data
    case ExM_Workout //Exercise Module cell for inputting workout data
    
    func getHeightForDataEntryCell(userInfo: [String: AnyObject]) -> CGFloat { //calculates the height for a DataEntry cell given the input parameters (stored against function-specific keys)
        let levelHeight: CGFloat = LevelsFrameworkCell.levelHeight
        var numberOfLevels: Int //default # of lvls
        switch self {
        case .Freeform:
            numberOfLevels = FreeformDataEntryCell.numberOfLevels
            if let numberOfOptions = userInfo[BMN_DataEntry_FreeformCell_NumberOfViewsKey] as? Double { //every 2 views (past the original 2) increases # of levels by 1
                if (numberOfOptions > 2) {
                    numberOfLevels = FreeformDataEntryCell.numberOfLevels + Int(floor(numberOfOptions/2))
                } else { //less than 2 options (return only base # of levels)
                    numberOfLevels = FreeformDataEntryCell.numberOfLevels
                }
                print("Options = \(numberOfOptions). Number of levels = \(numberOfLevels).")
            }
        case .Picker:
            numberOfLevels = DataEntryCellWithPicker.numberOfLevels
        case .CustomWithOptions: //access key indicating # of custom options to calculate height
            numberOfLevels = CustomWithOptionsCell.numberOfLevels
            if let numberOfOptions = userInfo[BMN_DataEntry_CustomWithOptions_NumberOfOptionsKey] as? Int {
                numberOfLevels = CustomWithOptionsCell.numberOfLevels + numberOfOptions
            }
        case .CustomWithCounter:
            numberOfLevels = CustomWithCounterCell.numberOfLevels
        case .CustomWithRangeScale:
            numberOfLevels = CustomWithRangeScaleCell.numberOfLevels
            print("CWRS option LEVELS = \(numberOfLevels).")
        case .FIM_FoodIntake:
            numberOfLevels = FIM_FoodIntakeDataEntryCell.numberOfLevels
        case .ExM_Workout: //height is defined via notification
            numberOfLevels = ExM_WorkoutDataEntryCell.numberOfLevels
        }
        return levelHeight * CGFloat(numberOfLevels) + BMN_DefaultBottomSpacer //default height
    }
    
}