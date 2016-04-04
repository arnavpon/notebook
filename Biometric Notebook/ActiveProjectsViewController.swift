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
    
    let context = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    var projects: [Project] = [] //list of project objects, TV dataSource
    let cellColors: [UIColor] = [UIColor.blueColor(), UIColor.greenColor(), UIColor.redColor(), UIColor.blackColor()] //adjust the colors so that they have some meaning
    var selectedProject: Project? //object to pass on segue
    
    // MARK: - View Configuration
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //        clearCoreDataStoreForEntity(entity: "Project") //*
        if (userDefaults.boolForKey(IS_LOGGED_IN_KEY) == true) { //user is logged in
            loggedIn = true //tell system that user is logged in
            self.projects = fetchAllProjectsFromStore() //obtain list of all projects from data store
            if (self.projects.isEmpty) { //empty state, handle appropriately
                
            } else {
                
            }
            activeProjectsTableView.dataSource = self
            activeProjectsTableView.delegate = self
            activeProjectsTableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "project_cell")
        } else {
            loggedIn = false //transition -> LoginVC
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        if (userJustLoggedIn) { //check if user just logged in & set the projects accordingly
            self.projects = fetchAllProjectsFromStore() //**obtain projects SPECIFIC to new user?!? - we will need to store local projects against username for this to work; better to pull all projects from the cloud & store to the device (overwriting existing entity) rather than creating a store for each user
            if (self.projects.isEmpty) { //empty state, handle appropriately
                
            } else {
                
            }
            activeProjectsTableView.reloadData() //reload UI w/ new project list
            userJustLoggedIn = false //reset the variable
        }
    }
    
    // MARK: - TV Data Source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
        //eventually, we will want to organize projects using the same framework as for IA
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return projects.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("project_cell", forIndexPath: indexPath)
        cell.textLabel?.text = projects[indexPath.row].title
        cell.textLabel?.textAlignment = .Center
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
        } else if (segue.identifier == "showLogin") { //set delegate for LoginVC
            let destination = segue.destinationViewController as! LoginViewController
            destination.delegate = self
        }
    }
    
}