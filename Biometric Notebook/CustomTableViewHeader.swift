//  CustomTableViewHeader.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/4/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Custom header for the tableView.

import UIKit

class CustomTableViewHeader: UIView {
    
    let label: LabelWithPadding
    let text: String
    
    init(frame: CGRect, text: String) {
        let inset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20) //alternatively we can set insets in tableVC (default insets change depending on whether there is a TV in tableVC or normal VC)
        label = LabelWithPadding(frame: frame, inset: inset)
        self.text = text
        super.init(frame: frame)
        configureLabel()
        self.addSubview(label)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureLabel() { //label occupies the entire view (but is padded)
        label.numberOfLines = 2
        label.backgroundColor = UIColor.redColor()
        label.text = text
    }

}

class LabelWithPadding: UILabel { //label w/ padded text
    
    let paddingInset: UIEdgeInsets //how much padding you want
    
    init(frame: CGRect, inset: UIEdgeInsets) {
        self.paddingInset = inset
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func drawTextInRect(rect: CGRect) {
        let rectangle = UIEdgeInsetsInsetRect(rect, self.paddingInset) //adjusts existing rect w/ insets
        super.drawTextInRect(rectangle)
    }
}
