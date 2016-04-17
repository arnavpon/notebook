//  CustomWithRangeScaleCell.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 4/1/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// CUSTOM MODULE > cell allowing user to report a single value between the minimum & maximum (e.g. on a scale of 1 - 10, ...)

import UIKit

class CustomWithRangeScaleCell: BaseDataEntryCell { //add new class -> enum!
    
    override class var numberOfLevels: Int { //RangeScale cell has 3 layers (topLayer + 2 for Scale)
        return 3
    }
    
    private var parameters: (Int, Int, Int)? {
        didSet {
            rangeScale.parameters = self.parameters //set parameters for scale
            setNeedsLayout() //update UI for values
            configureCompletionIndicator(true) //after 1st value has been set, view is ALWAYS complete
        }
    }
    private var selectedValue: Int? { //selected value on the scale (obtained from notification?)
        didSet {
            updateModuleReportObject() //update Module w/ new selection
        }
    }
    private let rangeScale = RangeScaleView(frame: CGRectZero)
    
    // MARK: - Initializers
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.insetBackgroundView.addSubview(rangeScale)
        
        //Add observer for changes in scale value:
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.rangeScaleValueDidChange(_:)), name: BMN_Notification_RangeScaleValueDidChange, object: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit { //unregister notificatio observer
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override internal func accessModuleProperties() { //use Module type/selection to format cell's visuals
        super.accessModuleProperties()
        if let customMod = self.module as? CustomModule, type = customMod.getTypeForVariable() { //downcast to CUSTOM module
            if (type == CustomModuleVariableTypes.Behavior_RangeScale) { //check variableType to be safe
                if let scaleParameters = customMod.rangeScaleParameters { //get parameters for scale
                    self.parameters = scaleParameters
                }
            }
        }
    }
    
    // MARK: - Visual Layout
    
    override func setNeedsLayout() {
        super.setNeedsLayout()
        
        //Layout RangeScale (occupies the full length of lvls 2 & 3):
        rangeScale.frame = getViewFrameForLevel(viewLevel: (2, HorizontalLevels.FullLevel, 2))
    }
    
    // MARK: - Data Reporting
    
    func rangeScaleValueDidChange(notification: NSNotification) {
        if let info = notification.userInfo, value = info[BMN_CustomWithRangeScaleCell_RangeScaleValueKey] as? Int { //get updated value
            self.selectedValue = value
        }
    }
    
    override func updateModuleReportObject() { //updates the Module dataSource's report object
        if let mod = module, value = selectedValue {
            mod.mainDataObject = value
        }
    }
    
}