//  CustomSliderBackgroundView.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/29/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Background view w/ indefinite & finite length labels & background colors for endpointView

import UIKit

class CustomSliderBackgroundView: UIView {

    let leftView = UIView()
    let leftLabel = UILabel() //fix label to top middle
    let rightView = UIView()
    let rightLabel = UILabel() //fix label to top middle
    
    var customSlider: CustomSlider?
    var offsetLength: CGFloat? //distance from slider to left side of view
    var leftLabelHeight: CGFloat {
        return 50
    }
    private var leftViewWidth: CGFloat {
        if let slider = customSlider {
            let numberOfNodes = slider.fixedSelectionPointNumbers.count
            let width = slider.bounds.width
            print(slider.bounds.width)
            let distance = width / CGFloat(numberOfNodes - 1)
            return distance
        }
        return 20
    }
    
    override var frame: CGRect {
        didSet {
            self.hidden = false
            updateFrames()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.hidden = true //hide to start (so that we can get full screen size before rendering)
        self.backgroundColor = UIColor.clearColor()
        
        //Left Subview:
        self.addSubview(leftView)
        self.sendSubviewToBack(leftView)
        leftView.addSubview(leftLabel)
        leftView.backgroundColor = UIColor(red: 216/255, green: 139/255, blue: 154/255, alpha: 1)
        leftLabel.text = "Continuous Project"
        leftLabel.numberOfLines = 2
        leftLabel.lineBreakMode = .ByWordWrapping
        leftLabel.textAlignment = .Center
        leftLabel.font = UIFont.systemFontOfSize(12, weight: 0.1)
        
        //Right Subview:
        self.addSubview(rightView)
        self.sendSubviewToBack(rightView)
        rightView.addSubview(rightLabel)
        rightView.backgroundColor = UIColor(red: 216/255, green: 86/255, blue: 95/255, alpha: 1)
        rightLabel.text = "Fixed Length Project"
        rightLabel.textAlignment = .Center
        rightLabel.font = UIFont.systemFontOfSize(13, weight: 0.1)
        
        updateFrames()
    }
    
    func updateFrames() {
        if let offset = offsetLength {
            //Left Subview:
            leftView.frame = CGRect(x: 0, y: 0, width: (leftViewWidth + offset), height: frame.height)
            let leftLabelSize = CGSize(width: (leftViewWidth + offset), height: leftLabelHeight)
            let leftLabelCenter = CGPoint(x: (leftViewWidth + offset)/2, y: leftLabelSize.height/2)
            leftLabel.frame = createRectAroundCenter(leftLabelCenter, size: leftLabelSize)
            
            //Right Subview:
            rightView.frame = CGRect(x: (leftView.frame.origin.x + leftView.frame.width), y: 0, width: (frame.width - leftView.frame.width), height: frame.height)
            let rightLabelSize = CGSize(width: rightView.frame.width * 0.8, height: 25)
            let rightLabelCenter = CGPoint(x: rightView.frame.width/2, y: leftLabelSize.height/2)
            rightLabel.frame = createRectAroundCenter(rightLabelCenter, size: rightLabelSize)
        }
    }
}
