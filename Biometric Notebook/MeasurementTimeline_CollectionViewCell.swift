//  MeasurementTimeline_CollectionViewCell.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 8/15/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

import UIKit

enum MeasurementTimeline_CardTypes: Int {
    case Default = 0 //default card type for location in cycle
    case Action = 1 //card for project's action if it does not occupy a space in the timeline
    case TimeDifference = 2 //card containing all TD vars (@ end of timeline)
}

struct MeasurementTimeline_VariableShell { //shell for the collection view cell
    
    let name: String
    let variableType: String //indicate if var is an IV, OM, AQ, ghost, etc. (may need to modify VariableTypes?)
    let location: Int //measurement location
    var cardIndex: Int? //**
    
    init(name: String, type: String, location: Int) {
        self.name = name
        self.variableType = type
        self.location = location
    }
    
}

let BMN_MeasurementTimeline_LocationNumberKey = "MT_location_number_key"
let BMN_MeasurementTimeline_CellIndexKey = "MT_cell_index_key"
let BMN_MeasurementTimeline_CardTypeKey = "MT_card_type_key"

class MeasurementTimeline_CollectionViewCell: UICollectionViewCell, UITableViewDataSource, UITableViewDelegate { //card holding information for each location in the measurement cycle
    
    @IBOutlet weak var topLabel: UILabel! //label for cell type
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var timeDifferenceButton: UIButton!
    @IBOutlet weak var variablesTableView: UITableView!
    
    var dataSource: ([String: AnyObject], [Module])? { //(infoDictionary, variables)
        didSet {
            self.adjustVisualsForData() //update visuals when set
        }
    }
    private var cardType: MeasurementTimeline_CardTypes = .Default //type for card
    var cellIndex: Int? //index # of cell in collectionView
    var locationInCycle: Int? //location of item in measurement cycle
    var variables: [Module]? //tableView dataSource
    
    // MARK: - Initializers
    
    override func awakeFromNib() { //customize views after awakening
        super.awakeFromNib()
        
        variablesTableView.dataSource = self
        variablesTableView.delegate = self
        
        //Customize self.view:
        self.layer.borderColor = UIColor.blackColor().CGColor
        self.layer.borderWidth = 2
        self.layer.cornerRadius = 6.5
        
        //Customize location label:
        locationLabel.layer.borderWidth = 2
        locationLabel.layer.borderColor = UIColor.cyanColor().CGColor
        locationLabel.layer.cornerRadius = 4
        locationLabel.backgroundColor = UIColor.whiteColor()
        
        //Customize TD button:
        timeDifferenceButton.setTitleColor(UIColor.redColor(), forState: .Highlighted)
    }
    
    private func adjustVisualsForData() { //when data is set, adjust visuals
        if let (info, variables) = dataSource, index = info[BMN_MeasurementTimeline_CellIndexKey] as? Int {
            self.cellIndex = index
            self.variables = variables //set TV dataSource
            variablesTableView.reloadData() //update UI
            if let location = info[BMN_MeasurementTimeline_LocationNumberKey] as? Int {
                self.locationInCycle = location
                self.locationLabel.text = "\(location)"
                self.locationLabel.hidden = false //reveal locationLbl
            } else {
                self.locationLabel.hidden = true //hide locationLbl
            }
            if let typeRaw = info[BMN_MeasurementTimeline_CellIndexKey] as? Int, type = MeasurementTimeline_CardTypes(rawValue: typeRaw) {
                self.cardType = type
            }
        }
        switch cardType { //adjust visuals for cardType
        case .Default:
            self.backgroundColor = UIColor(red: 0, green: 0.8, blue: 0.5, alpha: 0.8) //**
            self.topLabel.hidden = true //hide topLbl in default
        case .Action:
            self.backgroundColor = UIColor(red: 0, green: 0.8, blue: 0.5, alpha: 0.8) //**
            self.topLabel.text = "Action"
            self.topLabel.textColor = UIColor(red: 0, green: 0.5, blue: 1, alpha: 1) //**
            self.topLabel.hidden = false //reveal topLbl
        case .TimeDifference:
            self.backgroundColor = UIColor(red: 0, green: 0.8, blue: 0.5, alpha: 0.8) //**
            self.topLabel.text = "T. D."
            self.topLabel.textColor = UIColor(red: 0.4, green: 0.8, blue: 0.5, alpha: 1) //**
            self.topLabel.hidden = false //reveal topLbl
        }
    }
    
    // MARK: - Table View
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let vars = variables {
            return vars.count
        }
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell")!
        return cell
    }
    
    func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        tableView.cellForRowAtIndexPath(indexPath)?.backgroundColor = UIColor.greenColor() //highlight
        let notification = NSNotification(name: BMN_Notification_MeasurementTimeline_VariableWasSelected, object: nil, userInfo: [:]) //pass which var was selected & @ what location
        NSNotificationCenter.defaultCenter().postNotification(notification)
        return false //allow user to swap locations w/ notifications
    }
    
    // MARK: - Button Actions
    
    @IBAction func timeDifferenceButtonClick(sender: AnyObject) {
        print("TD button was clicked for cell @ index \(cellIndex).")
        if (timeDifferenceButton.highlighted) { //cell is ALREADY highlighted
            timeDifferenceButton.backgroundColor = UIColor.whiteColor()
        } else { //cell is NOT already highlighted
            timeDifferenceButton.backgroundColor = UIColor.greenColor()
        }
        timeDifferenceButton.highlighted = !(timeDifferenceButton.highlighted) //swap state
        print("TD button is highlighted? \(timeDifferenceButton.highlighted)")
        let notification = NSNotification(name: BMN_Notification_MeasurementTimeline_TimeDifferenceButtonWasClicked, object: nil, userInfo: ["location": cellIndex!, "state": timeDifferenceButton.highlighted]) //send notif indicating which btn was clicked & whether it was selected or deselected
        NSNotificationCenter.defaultCenter().postNotification(notification)
        //highlight on btn click & store reference somewhere
    }
    
}