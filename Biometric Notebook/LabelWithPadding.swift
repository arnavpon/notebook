//  LabelWithPadding.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/31/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Label with insets to space the text away from the edges.

import UIKit

class LabelWithPadding: UILabel { //label w/ padded text
    
    var paddingInset: UIEdgeInsets { //how much padding you want
        didSet {
            drawTextInRect(self.frame) //*
        }
    }
    
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