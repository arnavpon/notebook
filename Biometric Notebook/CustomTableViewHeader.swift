//  CustomTableViewHeader.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/4/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Custom header for the tableView.

import UIKit

class CustomTableViewHeader: UIView {
    
    private var label: LabelWithPadding?
    
    var labelInsets: UIEdgeInsets {
        get {
            return UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20) //give user ability to modify insets
        } set {
            configureLabel() //*
        }
    }
    
    let text: String
    
    init(frame: CGRect, text: String) {
        self.text = text
        super.init(frame: frame)
        configureLabel()
    }
    
    override func setNeedsDisplay() { //call whenever frame changes to redraw label
        configureLabel()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureLabel() { //label occupies the entire view (but is padded)
        label = LabelWithPadding(frame: frame, inset: labelInsets)
        label!.numberOfLines = 2
        label!.backgroundColor = UIColor.redColor()
        label!.text = text
        self.addSubview(label!)
    }

}

class LabelWithPadding: UILabel { //label w/ padded text
    
    let paddingInset: UIEdgeInsets //how much padding you want
    
    init(frame: CGRect, inset: UIEdgeInsets) {
        self.paddingInset = inset
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.paddingInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10) //default
        super.init(coder: aDecoder)
    }
    
    override func drawTextInRect(rect: CGRect) {
        let rectangle = UIEdgeInsetsInsetRect(rect, self.paddingInset) //adjusts existing rect w/ insets
        super.drawTextInRect(rectangle)
    }
}
