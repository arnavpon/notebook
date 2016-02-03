//  AttachModuleTableViewCell.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 2/2/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

import UIKit

class AttachModuleTableViewCell: UITableViewCell {
    
    @IBOutlet weak var centeredTextLabel: UILabel!
    @IBOutlet weak var backgroundImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
