//  CreateProjectTableViewCell.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 4/5/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Base class for all CreateProjectVC tableView cells (contains visible 1st level L button).

import UIKit

class CreateProjectTableViewCell: CellWithPlusButton {
    
    // MARK: - Initializers
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        //Configure L side button:
        firstLevelLeftButton = UIButton()
        firstLevelLeftButton?.userInteractionEnabled = false //prevent btn click
        self.insetBackgroundView.addSubview(firstLevelLeftButton!)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}