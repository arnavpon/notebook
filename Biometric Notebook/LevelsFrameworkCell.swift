//  LevelsFrameworkCell.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 4/4/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Base framework that dictates layout for all of BMN's custom TV cells.

import UIKit

class LevelsFrameworkCell: UITableViewCell {
    
    // MARK: - Initializers
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Visual Layout
    
    override func prepareForReuse() {
        //
    }
    
    override func setNeedsLayout() {
        //
    }

}
