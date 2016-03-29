//  BaseConfigurationCell.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 3/28/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Superclass for all custom configuration cell types.

import UIKit

class BaseConfigurationCell: UITableViewCell {
    
    var instructions = "" //text instructions to user
    let completionIndicator = UIImageView(image: UIImage(named: "check"))
    
    var dataSource: Dictionary<String, AnyObject>? { //contains configuration info
        didSet {
            if let source = dataSource, let text = source[BMNDefaultNumberKey] as? String {
                    self.instructions = text //set instructions
            }
        }
    }
    
    // MARK - Initializers
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
