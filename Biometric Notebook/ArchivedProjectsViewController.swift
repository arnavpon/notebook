//  ArchivedProjectsViewController.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 4/4/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Displays a tableView listing all of the archived (completed) projects. The user can select these projects to view statistics & other data.

import UIKit

class ArchivedProjectsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var archivedProjectsTV: UITableView!
    
    // MARK: - View Configuration
    
    override func viewDidLoad() {
        super.viewDidLoad()
        archivedProjectsTV.dataSource = self
        archivedProjectsTV.delegate = self
        archivedProjectsTV.registerClass(CellWithGradientFill.self, forCellReuseIdentifier: NSStringFromClass(CellWithGradientFill))
        archivedProjectsTV.registerClass(UITableViewCell.self, forCellReuseIdentifier: NSStringFromClass(UITableViewCell))
    }
    
    // MARK: - Table View
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(NSStringFromClass(CellWithGradientFill))!
        return cell
    }

    // MARK: - Navigation
    
    @IBAction func unwindToArchivedProjectsVC(sender: UIStoryboardSegue) { //unwind segue
        //returns from ProjectOverviewVC
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "showProjectOverview") {
            //pass data -> VC for visualization of project stats
        }
    }

}
