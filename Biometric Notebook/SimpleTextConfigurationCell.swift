//  SimpleTextConfigurationCell.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 3/29/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Prompts the user to enter text into a txtLabel.

import UIKit

class SimpleTextConfigurationCell: BaseConfigurationCell {

    let textEntryField = UITextField(frame: CGRectZero)
    
    // MARK: - Initializers
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
