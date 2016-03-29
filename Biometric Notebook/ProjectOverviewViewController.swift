//  ProjectOverviewViewController.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/3/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Pulled up on clicking cell w/ a current project. Used to display summary of data that has been obtained/visualize data. Offers a link to the data reporting flow.

import UIKit

class ProjectOverviewViewController: UIViewController {
    
    var selectedProject: Project?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Navigation
    
    @IBAction func unwindToOverviewVC(sender: UIStoryboardSegue) { //unwind segue -> overviewVC
        if let _ = sender.sourceViewController as? DataEntryTableViewController {
            //update overview w/ new information? 
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "showDataEntry") {
            let destination = segue.destinationViewController as! DataEntryTableViewController
            destination.selectedProject = self.selectedProject
            
            //Check if IVs for the current data entry set (IV + OM) have been entered:
            if (selectedProject!.inputVariableDataHasBeenEntered) { //IVs entered - show OM reporting flow
                destination.currentSectionToDisplay = true
            } else { //IVs not entered - show IV reporting flow
                destination.currentSectionToDisplay = false
            }
        }
    }

}
