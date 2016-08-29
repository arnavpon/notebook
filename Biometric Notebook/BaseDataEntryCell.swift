//  BaseDataEntryCell.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 4/1/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Base data entry TV cell design upon which all custom data reporting cells are built. Custom cells define IN ENTIRETY how TV cells will be laid out for the purpose of reporting data.

import UIKit

class BaseDataEntryCell: LevelsFrameworkCell { //data source for DataEntry cells is the Module property
    
    override class var numberOfLevels: Int { //default # of levels is 2 for DataEntry cells
        return 2
    }
    
    var cellIndex: Int? //indicates indexPath.row for cell in TV (used for cellHeight notification)
    
    // MARK: - Initializers
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Data Reporting
    
    func updateModuleReportObject() { //updates the Module dataSource's report object
        if let mod = module {
            mod.mainDataObject = nil
        }
    }
    
}