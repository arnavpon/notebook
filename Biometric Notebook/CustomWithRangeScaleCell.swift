//  CustomWithRangeScaleCell.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 4/1/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// CUSTOM MODULE > cell allowing user to report a single value between the minimum & maximum (e.g. on a scale of 1 - 10, ...)

import UIKit

class CustomWithRangeScaleCell: BaseDataEntryCell { //add new class -> enum!
    
    // MARK: - Initializers
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override internal func accessModuleProperties() { //use Module type/selection to format cell's visuals
        super.accessModuleProperties()
        if let customMod = self.module as? CustomModule, type = customMod.getTypeForVariable() { //downcast to CUSTOM module
            if (type == CustomModuleVariableTypes.Behavior_RangeScale) { //check variableType to be safe
                
            }
        }
    }
    
    // MARK: - Visual Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
}