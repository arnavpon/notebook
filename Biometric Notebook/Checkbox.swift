//  Checkbox.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/3/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

import UIKit

class CheckBox: UIButton {
    
    let checkedImage = UIImage(named: "checked.png")
    let uncheckedImage = UIImage(named: "unchecked.png")
    
    var isChecked: Bool = false {
        didSet {
            if (isChecked) {
                self.setImage(checkedImage, forState: .Normal)
            } else {
                self.setImage(uncheckedImage, forState: .Normal)
            }
        }
    }
    
    override func awakeFromNib() { //each time func is called, it will reset default (checked = false)
        self.addTarget(self, action: #selector(CheckBox.buttonClicked(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        self.isChecked = false
    }
    
    func buttonClicked(sender: UIButton) {
        if (isChecked) { //box is checked, set -> unchecked
            isChecked = false
        } else { //box is unchecked, set -> checked
            isChecked = true
        }
    }
}
