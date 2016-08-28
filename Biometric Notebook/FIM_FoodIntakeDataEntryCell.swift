//  FIM_FoodIntakeDataEntryCell.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 6/2/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// FOOD INTAKE MODULE > cell for reporting nutritional intake for a single complete meal.

import UIKit

class FIM_FoodIntakeDataEntryCell: BaseDataEntryCell, UITextFieldDelegate, DataEntry_PopupConfigurationViewProtocol { //add new class -> enum!
    
    override class var numberOfLevels: Int {
        return 2 //# of levels is dynamically calculated by enum (& depending on current view mode)
    }
    
    var cellType: DataEntryCellTypes = DataEntryCellTypes.FIM_FoodIntake //protocol property
    
    // MARK: - Initializers
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override internal func accessModuleProperties() { //use Module type/selection to format cell's visuals
        super.accessModuleProperties()
        if let mod = self.module as? FoodIntakeModule { //FOOD INTAKE cell
            //Access configuration parameters in Module superclass:
            if let boolValue = mod.FreeformCell_labelBeforeField { //check for lbl position
                //
            }
            if let configObject = mod.FreeformCell_configurationObject { //master config object
                //
            }
        }
    }
    
    // MARK: - Visual Layout
    
    override func setNeedsLayout() {
        super.setNeedsLayout()
    }
    
    private func getLevelAndRemainderForCount(count: Int) -> (Int, Int) { //returns (level, remainder) based on the count
        let remainder = count % 2
        let level = Int(floor(Double(count/2))) + 2 //add 2 to arrive @ proper level
        return (level, remainder)
    }
    
    // MARK: - Text Field
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        return false
    }
    
    // MARK: - Protocol Logic
    
    func backButtonWasClicked() {
        //handle reverse navigation...
    }
    
    func valueWasReturnedByUser(value: AnyObject) {
        //takes input value & does something...
    }
    
    // MARK: - Data Reporting
    
    override func updateModuleReportObject() { //updates the Module dataSource's report object
        if let mod = self.module { //format the return object
            mod.mainDataObject = nil //** update w/ textField values
        }
    }
    
}