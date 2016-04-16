//  ProjectOverviewViewController.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/3/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Pulled up on clicking cell w/ a current project. Used to display summary of data that has been obtained/visualize data. 

import UIKit

class ProjectOverviewViewController: UIViewController {
    
    var selectedProject: Project?
    var sender: UIViewController? //stores ID of sender for unwind segue
    
    // MARK: - View Configuration
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - Button Actions
    
    @IBAction func backButtonClick(sender: AnyObject) { //unwind to sender VC
        if (self.sender is ActiveProjectsViewController) {
            performSegueWithIdentifier("unwindToActiveProjects", sender: nil)
        } else if (self.sender is ArchivedProjectsViewController) {
            performSegueWithIdentifier("unwindToArchivedProjects", sender: nil)
        }
    }
    
}
