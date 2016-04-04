//  CellWithGradientFill.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 4/4/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Custom TV cells for ActiveProjectsVC - cells contain some custom abilities such as a button on the R for navigation & a horizontal gradient fill to indicate % completion for active projects.

import UIKit

class CellWithGradientFill: UITableViewCell {
    
    // MARK: - Initializers
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
