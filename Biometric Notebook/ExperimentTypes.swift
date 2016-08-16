//  ExperimentTypes.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 4/4/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Lists all supported study designs.

import Foundation

enum ExperimentTypes: String { //string rawValues are required for notification to work!
    
    case InputOutput = "InputOutput"
    case ControlComparison = "ControlComparison"
    
    func getTypeNameForDisplay() -> String { //gives display-friendly title for TV cell
        switch self {
        case .InputOutput:
            return "Correlations"
        case .ControlComparison:
            return "CC Project"
        }
    }
    
}

enum GroupTypes: String { //string rawVals are needed to create unique ID for groups in a project!
    case LoneGroup = "LONE_GROUP" //for projects w/ single groups
    case Control = "CONTROL"
    case Comparison = "COMPARISON"
}