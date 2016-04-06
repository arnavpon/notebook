//  CustomSliderBackgroundView.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/29/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Background view w/ indefinite & finite length labels & background colors for endpointView

import UIKit

class CustomSliderBackgroundView: UIView {

    private let leftView = UIView()
    private let leftLabel = UILabel() //fix label to top middle
    private let rightView = UIView()
    private let rightLabel = UILabel() //fix label to top middle
    
    weak var customSlider: CustomSlider?
    private var leftLabelHeight: CGFloat {
        return 50
    }
    private var leftViewWidth: CGFloat {
        if let slider = customSlider {
            let numberOfNodes = slider.fixedSelectionPointNumbers.count
            let width = slider.bounds.width
            let distance = width / CGFloat(numberOfNodes - 1) + 0.1 * self.frame.width //need to add (1 - % of view that slider is taking up) * width!
            return distance
        }
        return 20
    }
    internal var labelBottomY: CGFloat { //reports bottom Y of lbl for slider positioning
        return leftLabelHeight
    }
    
    override var frame: CGRect {
        didSet { //any time frame changes, update visuals
            updateFrames()
        }
    }
    
    // MARK: - Initializers
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureBackgroundView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureBackgroundView()
    }
    
    private func configureBackgroundView() {
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
    
    private func updateFrames() {
        //Left Subview:
        leftView.frame = CGRect(x: 0, y: 0, width: leftViewWidth, height: frame.height)
        leftLabel.frame = CGRectMake(0, 0, leftViewWidth, leftLabelHeight)
            
        //Right Subview:
        rightView.frame = CGRect(x: leftViewWidth, y: 0, width: (frame.width - leftViewWidth), height: frame.height)
        let rightLabelSize = CGSize(width: rightView.frame.width * 0.8, height: 25)
        let rightLabelCenter = CGPoint(x: rightView.frame.width/2, y: leftLabelHeight/2)
        rightLabel.frame = createRectAroundCenter(rightLabelCenter, size: rightLabelSize)
    }
}
