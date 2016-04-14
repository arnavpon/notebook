//  ActiveProjectsViewController.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 4/4/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Displays a TV listing all of the active Counters (if any) & Projects (i.e. those projects for which data is still actively being reported). The user can navigate to the DataEntryVC or the ProjectOverviewVC from here. 

import UIKit
import HealthKit
import CoreData

class ActiveProjectsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, LoginViewControllerDelegate {

    @IBOutlet weak var activeProjectsTableView: UITableView!
    
    var projects: [Project] = [] //list of project objects (TV dataSource)
    let cellColors: [UIColor] = [UIColor.blueColor(), UIColor.greenColor(), UIColor.redColor(), UIColor.blackColor()] //adjust the colors so that they have some meaning
    var selectedProject: Project? //object to pass on segue
    
    // MARK: - View Configuration
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //        clearCoreDataStoreForEntity(entity: "Project") //*
        
        if (userDefaults.boolForKey(IS_LOGGED_IN_KEY) == true) { //user is logged in
            if let activeProjects = fetchAllObjectsFromStore("Project") as? [Project] { //obtain list of all projects from data store
                self.projects = activeProjects
                for project in projects {
                    let date = DateTime(date: project.startDate)
                    print("Project Title: '\(project.title)'. Start Date: [\(date.getFullTimeStamp())]. # of groups: \(project.groups.count).")
                    for item in project.groups {
                        if let group = item as? Group {
                            print("[Group] Action: \(group.action). # of Inputs: \(group.beforeActionVariables.count). # of Outputs: \(group.afterActionVariables.count).")
                        }
                    }
                }
                if (self.projects.isEmpty) { //empty state, handle appropriately
                    
                } else {
                    
                }
            }
        }
        
        //Register TV dataSource & delegate:
        activeProjectsTableView.dataSource = self
        activeProjectsTableView.delegate = self
        activeProjectsTableView.registerClass(CellWithGradientFill.self, forCellReuseIdentifier: NSStringFromClass(CellWithGradientFill))
    }
    
    override func viewWillAppear(animated: Bool) {
        activeProjectsTableView.reloadData() //clears visuals on selected TV cell
        
        if (userJustLoggedIn) { //check if user just logged in & set the projects accordingly
            if let activeProjects = fetchAllObjectsFromStore("Project") as? [Project] {
                self.projects = activeProjects //**obtain projects SPECIFIC to new user?!? - we will need to store local projects against username for this to work; better to pull all projects from the cloud & store to the device (overwriting existing entity) rather than creating a store for each user
                    print("User was logged out & has now logged in.")
                if (self.projects.isEmpty) { //empty state, handle appropriately
                    
                } else {
                    
                }
                activeProjectsTableView.reloadData() //reload UI w/ new project list
                userJustLoggedIn = false //reset the variable
            }
        }
        NSNotificationCenter.defaultCenter().removeObserver(self) //clear old indicators to be safe
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.dataEntryButtonWasClicked(_:)), name: BMN_Notification_DataEntryButtonClick, object: nil)
    }
    
    override func viewDidAppear(animated: Bool) { //if user is not logged in, transitions -> loginVC
        if (userDefaults.boolForKey(IS_LOGGED_IN_KEY) == true) { //check if user is logged in
            loggedIn = true //tell system that user is logged in
        } else {
            loggedIn = false //transition -> LoginVC
        }
    }
    
    override func viewWillDisappear(animated: Bool) { //clear notification observer
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func dataEntryButtonWasClicked(notification: NSNotification) {
        if let dict = notification.userInfo, index = dict[BMN_CellWithGradient_CellIndexKey] as? Int {
            print("Data entry button clicked by cell #\(index).")
            selectedProject = projects[index] //set selectedProject before segue
            performSegueWithIdentifier("showDataEntry", sender: nil)
        }
    }
    
    // MARK: - TV Data Source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
        //eventually, we will want to organize projects using the same framework as for IA???
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return projects.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(NSStringFromClass(CellWithGradientFill)) as! CellWithGradientFill
        cell.highlighted = false //clears highlighting on view reload
        cell.selected = false //clears highlighting on view reload
        cell.cellIndex = indexPath.row
        let project = projects[indexPath.row]
        let title = project.title
        if let projectType = project.getProjectTypeForDisplay() {
            cell.textLabel?.text = "\(title.uppercaseString): \(projectType)"
        } else {
            cell.textLabel?.text = title
        }
        cell.textLabel?.textColor = UIColor.whiteColor()
        cell.backgroundColor = cellColors[indexPath.row]
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 75
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //Tapping a cell brings up the data visualization flow for that project?:
        selectedProject = projects[indexPath.row]
        performSegueWithIdentifier("showDataVisuals", sender: nil) //segue -> ProjectOverviewVC
    }
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle { //allow deletion of projects from here
        return UITableViewCellEditingStyle.None
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.Delete) { //*
            //Project must be removed from TV dataSource, core data, DB must be removed from web, etc.!
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
        }
    }
    
    // MARK: - Button Actions
    
    @IBAction func addProjectButtonClick(sender: AnyObject) { //navigate to CreateProject flow
        let storyboard = UIStoryboard(name: "CreateProjectFlow", bundle: nil)
        let controller = storyboard.instantiateInitialViewController()!
        presentViewController(controller, animated: true, completion: nil)
    }
    
    @IBAction func menuButtonClick(sender: AnyObject) {
        logout()
    }
    
    // MARK: - Login Logic
    
    let userDefaults = NSUserDefaults.standardUserDefaults()
    var userJustLoggedIn: Bool = false
    var loggedIn: Bool = false {
        didSet {
            if !(loggedIn) { //user logged out
                userDefaults.setBool(false, forKey: IS_LOGGED_IN_KEY) //adjust defaults
                performSegueWithIdentifier("showLogin", sender: nil)
            }
        }
    }
    
    func didLoginSuccessfully(username: String, email: String?) { //store username/email & dismiss LoginVC
        userDefaults.setObject(username, forKey: USERNAME_KEY) //save username -> preferences
        if (email != nil) { //**consider creating an email regex formatting class!
            userDefaults.setObject(email!, forKey: EMAIL_KEY) //save email -> preferences
        }
        userDefaults.setBool(true, forKey: IS_LOGGED_IN_KEY)
        let success = userDefaults.synchronize() //update the store
        print("Sync successful?: \(success)")
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func logout() {
        loggedIn = false
    }
    
    // MARK: - Navigation
    
    @IBAction func unwindToActiveProjectsVC(sender: UIStoryboardSegue) { //unwind segue
        //
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "showDataVisuals") { //pass the selected project
            let destination = segue.destinationViewController as! ProjectOverviewViewController
            destination.selectedProject = self.selectedProject
        } else if (segue.identifier == "showDataEntry") { //pass the selected project
            let destination = segue.destinationViewController as! DataEntryViewController
            destination.selectedProject = self.selectedProject
        } else if (segue.identifier == "showLogin") { //set delegate for LoginVC
            let destination = segue.destinationViewController as! LoginViewController
            destination.delegate = self
        }
    }
    
}
