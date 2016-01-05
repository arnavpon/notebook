//  CustomTableViewHeader.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/4/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Custom header for the tableView.

import UIKit

class CustomTableViewHeader: UIView {
    
    let label: UILabel
    let text: String
    
    init(frame: CGRect, text: String) {
        label = UILabel(frame: frame)
        self.text = text
        super.init(frame: frame)
        configureLabel()
        self.addSubview(label)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureLabel() { //label occupies the entire view
        label.numberOfLines = 2
        label.backgroundColor = UIColor.redColor()
        label.text = text
    }

}
