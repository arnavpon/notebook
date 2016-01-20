//  ProjectOverviewViewController.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/3/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Pulled up on clicking cell w/ a current project. Used to display summary of data that has been obtained/visualize data. May also be used to report new information.

import UIKit

class ProjectOverviewViewController: UIViewController {
    
    var selectedProject: Project?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
            destination.currentSectionToDisplay = false //set whether inputs or outcomes are reported
        }
    }

}
