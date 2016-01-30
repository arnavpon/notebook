//  ProjectVariablesDescriptionViewController.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/30/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Provides the user with a description of what is going on in the 'Project Variables' VC. If user selects the 'don't show again' option, their choice will be stored in the user defaults & it will be skipped.

import UIKit

class ProjectVariablesDescriptionViewController: UIViewController {

    @IBOutlet weak var checkbox: CheckBox!
    
    var projectTitle: String?
    var projectQuestion: String?
    var projectEndpoint: Endpoint?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - Button Actions
    
    @IBAction func checkboxClick(sender: AnyObject) {
        performSegueWithIdentifier("showVariables", sender: nil)
        
        //Set defaults so user won't see description screen again:
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.setBool(true, forKey: "SHOW_VARS_DESCRIPTION") //set -> false to block VC
    }
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "showVariables") { //pass along project settings
            let destination = segue.destinationViewController as! ProjectVariablesViewController
            destination.projectTitle = self.projectTitle
            destination.projectQuestion = self.projectQuestion
            destination.projectEndpoint = self.projectEndpoint
        }
    }

}
