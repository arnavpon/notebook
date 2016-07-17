//  SelectFromDropdownConfigurationCell.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 7/16/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Allows selection of a single item from a list of potential items via a dropdown tableView.

import UIKit

class SelectFromDropdownConfigurationCell: BaseConfigurationCell, UITableViewDataSource, UITableViewDelegate { //add new class -> enum!
    
    override class var numberOfLevels: Int { //default # of levels is 1
        return 2 //2 levels (mainLabel + dropdownView)
    }
    
    private var options: [String] = [] { //available options for selection
        didSet {
            dropdownTableView.reloadData() //update TV visuals
            setNeedsLayout() //update visuals for cell
        }
    }
    private var selectedOption: String? { //reportObject for cell (single STRING)
        didSet { //adjust completion status
            if let _ = selectedOption { //option has been selected, set cell -> COMPLETE
                configureCompletionIndicator(true)
            } else { //configObject is empty (NO option selected), set cell -> INCOMPLETE
                configureCompletionIndicator(false)
            }
        }
    }
    private let dropdownTableView = UITableView(frame: CGRectZero) //TV displaying options
    private let dropdownView = UIView(frame: CGRectZero) //view containing btn, lbl, img
    private let selectionLabel = UILabel(frame: CGRectZero) //indicates current selection
    private let dropdownImage = UIImageView(frame: CGRectZero) //down arrow
    private let dropdownButton = UIButton(frame: CGRectZero) //btn
    private let defaultBackgroundColor = UIColor(red: 248/255, green: 1, blue: 235/255, alpha: 1)
    
    private let noneKey = "<none>" //option in TV that clears selection
    
    // MARK: - Initializers
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        //(1) Add components to dropdownView:
        self.insetBackgroundView.addSubview(dropdownView) //add to main view
        dropdownView.layer.borderColor = UIColor.blackColor().CGColor
        dropdownView.layer.borderWidth = 1
        dropdownView.layer.cornerRadius = 4
        
        dropdownView.addSubview(selectionLabel)
        selectionLabel.adjustsFontSizeToFitWidth = true
        selectionLabel.backgroundColor = defaultBackgroundColor
        selectionLabel.textAlignment = .Center
        
        dropdownView.addSubview(dropdownImage)
        dropdownImage.image = UIImage(named: "down_arrow") //dropdown img
        dropdownImage.backgroundColor = UIColor.whiteColor()
        
        dropdownView.addSubview(dropdownButton) //btn (transparent) is SUPERFICIAL to img/lbl
        dropdownButton.backgroundColor = UIColor.clearColor() //btn is TRANSPARENT
        dropdownButton.addTarget(self, action: #selector(self.dropdownButtonWasClicked(_:)), forControlEvents: .TouchUpInside)
        
        //(2) Configure TV:
        self.insetBackgroundView.addSubview(dropdownTableView) //add to main view
        dropdownTableView.delegate = self
        dropdownTableView.dataSource = self
        dropdownTableView.hidden = true //TV starts hidden
        dropdownTableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        self.clipsToBounds = false //displays TV outside of cell bounds
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func accessDataSource() {
        super.accessDataSource()
        if let source = self.dataSource, availableOptions = source[BMN_SelectFromDropdown_OptionsKey] as? [String] { //obtain the available options (REQUIRED for cell)
            self.options = availableOptions //setting opts populates TV
            self.options.insert(noneKey, atIndex: 0) //insert value @ index 0 (for clearing selection)
        }
    }
    
    // MARK: - Visual Layout
    
    override func setNeedsLayout() {
        super.setNeedsLayout()
        
        //Cell contains a drop-down menu button with a hidden tableView (that extends beyond bounds of cell) directly underneath:
        dropdownView.frame = getViewFrameForLevel(viewLevel: (2, HorizontalLevels.FullLevel, nil))
        let imageOffset: CGFloat = 3 //x & y axis offset
        let dropdownImgWidth: CGFloat = dropdownView.frame.height - 2 * imageOffset
        selectionLabel.frame = CGRectMake(0, 0, (dropdownView.frame.width - dropdownImgWidth - 2 * imageOffset), dropdownView.frame.height) //lbl takes up most of L side of view
        dropdownImage.frame = CGRectMake((selectionLabel.frame.width + imageOffset), imageOffset, dropdownImgWidth, dropdownImgWidth) //img takes up small portion of R side of view
        dropdownButton.frame = CGRectMake(0, 0, dropdownView.frame.width, dropdownView.frame.height) //btn is same size as overall view
        
        dropdownTableView.frame = getViewFrameForLevel(viewLevel: (3, HorizontalLevels.FullLevel, 3))
    }
    
    // MARK: - Button Actions
    
    @IBAction func dropdownButtonWasClicked(sender: UIButton) { //reveals/hides dropdown menu
        if (dropdownTableView.hidden) { //REVEAL TV if HIDDEN
            dropdownTableView.hidden = false
            //send notification -> VC to increase # of levels by # of levels the TV takes up
        } else { //HIDE TV if VISIBLE
            dropdownTableView.hidden = true
            //send notification -> VC to reduce # of levels back to default (2)
        }
    }
    
    // MARK: - Table View
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell")!
        cell.textLabel?.text = options[indexPath.row]
        cell.backgroundColor = UIColor(red: 240/255, green: 240/255, blue: 240/255, alpha: 1)
        return cell
    }
    
    func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        let selection = options[indexPath.row]
        if (selection != noneKey) {
            selectedOption = selection
        } else { //empty selection -> nil
            selectedOption = nil
        }
        updateLabelForSelection() //update lbl
        tableView.hidden = true //hide TV upon click
        return false //block highlight
    }
    
    private func updateLabelForSelection() {
        if (self.selectedOption != noneKey) {
            selectionLabel.text = self.selectedOption
        } else { //noneKey selection -> empty label
            selectionLabel.text = nil
        }
    }
    
    // MARK: - Data Reporting
    
    override var configurationReportObject: AnyObject? { //reports current selection
        //*REPORT TYPE: String*
        return selectedOption
    }
    
}