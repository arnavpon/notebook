//  ArchivedProjectsViewController.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 4/4/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Displays a tableView listing all of the archived (completed) projects. The user can select these projects to view statistics & other data.

import UIKit

class ArchivedProjectsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var archivedProjectsTV: UITableView!
    
    var archivedProjects: [Project] = [] //TV dataSource
    var selectedProject: Project? //obj to pass on segue
    
    // MARK: - View Configuration
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.archivedProjects = getArchivedProjects() //populate data source
        archivedProjectsTV.dataSource = self
        archivedProjectsTV.delegate = self
        archivedProjectsTV.registerClass(UITableViewCell.self, forCellReuseIdentifier: NSStringFromClass(UITableViewCell))
        
        if (self.archivedProjects.isEmpty) { //no projects, HIDE TV
            archivedProjectsTV.hidden = true
        } else { //REVEAL TV
            archivedProjectsTV.hidden = false
        }
    }
    
    override func viewWillAppear(animated: Bool) { //update UI
        self.archivedProjects = getArchivedProjects() //populate data source
        if (self.archivedProjects.isEmpty) { //no projects, HIDE TV
            archivedProjectsTV.hidden = true
        } else { //REVEAL TV
            archivedProjectsTV.hidden = false
        }
        archivedProjectsTV.reloadData()
    }
    
    func getArchivedProjects() -> [Project] {
        if let projects = fetchObjectsFromCoreDataStore("Project", filterProperty: "isActive", filterValue: [false]) as? [Project] { //list of ARCHIVED projects
            return projects
        }
        return []
    }
    
    // MARK: - Table View
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return archivedProjects.count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(NSStringFromClass(UITableViewCell))!
        let projectForCell = archivedProjects[indexPath.row]
        cell.textLabel?.text = projectForCell.title
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        performSegueWithIdentifier("showProjectOverview", sender: nil)
    }
    
    // MARK: - Navigation
    
    @IBAction func unwindToArchivedProjectsVC(sender: UIStoryboardSegue) { //unwind segue
        //returns from ProjectOverviewVC
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "showProjectOverview") { //pass project -> VC for visualization of stats
            let destination = segue.destinationViewController as! ProjectOverviewViewController
            destination.selectedProject = self.selectedProject
            destination.sender = NSStringFromClass(ArchivedProjectsViewController) //pass type over
        }
    }

}
