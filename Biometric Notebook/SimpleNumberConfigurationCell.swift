//  SimpleNumberConfigurationCell.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 3/29/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Prompts the user to enter an integer value into a text field. 

import UIKit

class SimpleNumberConfigurationCell: BaseConfigurationCell {
    
    let textEntryField = UITextField(frame: CGRectZero) //make textField type safe (only allow Int)
    
    // MARK: - Initializers
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        if let dict = self.dataSource, let defaultValue = dict[BMNDefaultNumberKey] as? Int { //check for default & set it -> textField's value
            
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}