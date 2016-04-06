//  ProjectQuestionCustomCell.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 4/5/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Custom TV cell in CreateProjectVC for setting the project's question.

import UIKit

class ProjectQuestionCustomCell: CreateProjectTableViewCell {
    
    let templateButtonIO = UIButton(frame: CGRectZero) //input/output project template
    let templateButtonCC = UIButton(frame: CGRectZero) //control/comparison project template
    //add textView of some sort w/ template fillers
    
    // MARK: - Initializers
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        //Configure IO template button:
        templateButtonIO.backgroundColor = UIColor.blueColor()
        templateButtonIO.setTitle("IO template name", forState: UIControlState.Normal)
        templateButtonIO.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
        templateButtonIO.addTarget(self, action: #selector(self.ioTemplateButtonClick(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        insetBackgroundView.addSubview(templateButtonIO)
        
        //Configure CC template button:
        templateButtonCC.backgroundColor = UIColor.redColor()
        templateButtonCC.setTitle("CC template name", forState: UIControlState.Normal)
        templateButtonCC.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
        templateButtonCC.addTarget(self, action: #selector(self.ccTemplateButtonClick(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        insetBackgroundView.addSubview(templateButtonCC)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Visual Layout
    
    override func setNeedsLayout() {
        super.setNeedsLayout()
        templateButtonIO.frame = getViewFrameForLevel(viewLevel: (2, HorizontalLevels.FullLevel, nil))
        templateButtonCC.frame = getViewFrameForLevel(viewLevel: (3, HorizontalLevels.FullLevel, nil))
    }
    
    // MARK: - Button Actions
    
    @IBAction func ioTemplateButtonClick(sender: UIButton) {
        print("IO button click")
        renderTemplate(sender)
    }
    
    @IBAction func ccTemplateButtonClick(sender: UIButton) {
        print("CC button click")
        renderTemplate(sender)
    }
    
    func renderTemplate(sender: UIButton) {
        templateButtonCC.hidden = true
        templateButtonIO.hidden = true
        if (sender == templateButtonIO) {
            //
        } else if (sender == templateButtonCC) {
            //
        }
//        setNeedsLayout() //redraw after adjustment
    }
    
    // MARK: - Report Data
    
    override func reportData() -> AnyObject? {
        return nil
    }
    
}