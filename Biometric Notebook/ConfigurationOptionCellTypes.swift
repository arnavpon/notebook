//  ConfigurationOptionCellTypes.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 3/29/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Enumeration containing all possible Config Cell types.

import Foundation
import UIKit

enum ConfigurationOptionCellTypes { //REGISTER each new cell class w/ TV in ConfigurationOptionsVC & add class to cellForRowAtIndexPath()!
    
    case SimpleText //corresponds -> SimpleTextConfigurationCell type
    case SimpleNumber //corresponds -> SimpleNumberConfigurationCell type
    case SelectFromOptions //corresponds -> SelectFromOptionsConfigurationCell type
    case SelectFromDropdown //corresponds -> SelectFromDropdownConfigurationCell type
    case CustomOptions //corresponds -> CustomOptionsConfigurationCell type
    case TimeDifference //corresponds -> TimeDifferenceConfigurationCell type
    
    case Example //corresponds -> ExampleConfigurationCell type**
    
    func getHeightForConfigurationCellType() -> CGFloat { //called by VC to set cell height
        let levelHeight: CGFloat = LevelsFrameworkCell.levelHeight
        var numberOfLevels: Int
        switch self {
        case .SimpleText:
            numberOfLevels = SimpleTextConfigurationCell.numberOfLevels
        case .SimpleNumber:
            numberOfLevels = SimpleNumberConfigurationCell.numberOfLevels
        case .SelectFromOptions:
            numberOfLevels = SelectFromOptionsConfigurationCell.numberOfLevels
        case .SelectFromDropdown:
            numberOfLevels = SelectFromDropdownConfigurationCell.numberOfLevels
        case .CustomOptions:
            numberOfLevels = CustomOptionsConfigurationCell.numberOfLevels
        case .TimeDifference:
            numberOfLevels = TimeDifferenceConfigurationCell.numberOfLevels
        case .Example:
            numberOfLevels = ExampleConfigurationCell.numberOfLevels
        }
        return levelHeight * CGFloat(numberOfLevels) + BMN_DefaultBottomSpacer 
    }
    
}