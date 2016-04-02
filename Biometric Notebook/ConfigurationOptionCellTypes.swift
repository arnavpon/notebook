//  ConfigurationOptionCellTypes.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 3/29/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Enumeration containing all possible Config Cell types.

import Foundation
import UIKit

enum ConfigurationOptionCellTypes {
    
    case SimpleText //corresponds -> SimpleTextConfigurationCell type
    case SimpleNumber //corresponds -> SimpleNumberConfigurationCell type
    case Boolean //corresponds -> BooleanConfigurationCell type
    case Example //corresponds -> ExampleConfigurationCell type
    
    func getHeightForConfigurationCellType() -> CGFloat {
        let defaultHeight: CGFloat
        switch self {
        case .Example:
            defaultHeight = 100
        default: //default height
            defaultHeight = 70
        }
        return defaultHeight
    }
    
}
