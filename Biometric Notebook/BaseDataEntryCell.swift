//  BaseDataEntryCell.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 4/1/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Base data entry TV cell design upon which all custom data reporting cells are built. Custom cells define IN ENTIRETY how TV cells will be laid out for the purpose of reporting data.

import UIKit

class BaseDataEntryCell: UITableViewCell {
    
    weak var module: Module? { //all data to be displayed will be determined through the module property! For subviews of the base cell, the module property will be more specific module types!
        didSet {
            accessModuleProperties() //layout cell according to module type/properties
            setNeedsLayout() //keep OUTSIDE of the accessModule function!
        }
    }
    let titleLabel = UILabel(frame: CGRectZero)
    let insetBackground = UIView(frame: CGRectZero)
    
    //MARK: - Initializer
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        //Each TV cell has a 'backgroundView' & a 'contentView'. The backgroundView is nil in Plain Style tableViews, but not nil in grouped TVs (as ours is).
        backgroundColor = UIColor.clearColor() //background is BEHIND contentView (completely obscured)
        insetBackground.backgroundColor = UIColor.whiteColor() //create custom background so we can separate cells slightly
        titleLabel.textAlignment = .Left
        
        contentView.addSubview(insetBackground)
        contentView.addSubview(titleLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    internal func accessModuleProperties() { //use Module type/selection to format cell's visuals
        if let mod = module, selection = mod.selectedFunctionality { //update cell labels accordingly
            titleLabel.text = "\(mod.variableName): \(selection)"
        }
    }
    
    // MARK: - Visual Layout
    
    override func prepareForReuse() {
        print("[BaseTVCell] Preparing for reuse.")
        super.prepareForReuse() //do we have to reset anything on prepareForReuse?
    }
    
    override func layoutSubviews() {
        print("[BaseCell] Laying out subviews...")
        super.layoutSubviews()
        let leftPadding = CGFloat(10)
        let separatorHeight = CGFloat(5) //distance between cells
        insetBackground.frame = CGRect(x: 0, y: 0, width: frame.width, height: (frame.height - separatorHeight))
        titleLabel.frame = CGRect(x: leftPadding, y: 5, width: (frame.width - leftPadding), height: 35)
    }
    
}