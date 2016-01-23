//  HomeScreenViewController.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 12/26/15.
//  Copyright © 2015 Confluent Ideals. All rights reserved.

// Displays a list of all open projects & indicates their remaining duration. 

import UIKit
import HealthKit
import CoreData

class HomeScreenViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, LoginViewControllerDelegate {
    
    @IBOutlet weak var categoriesTableView: UITableView!
    
    let context = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    var projects: [Project] = [] //list of project objects
    let cellColors: [UIColor] = [UIColor.blueColor(), UIColor.greenColor(), UIColor.redColor(), UIColor.blackColor()]
    var selectedProject: Project? //object to pass on segue
    
    // MARK: - View Configuration
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (userDefaults.valueForKey("ISLOGGEDIN") as? Bool == true) { //user is logged in
            loggedIn = true //tell system that user is logged in
            obtainDataFromStore("Project")
            
            //clearCoreDataStoreForEntity(entity: "PROJECT")
            categoriesTableView.dataSource = self
            categoriesTableView.delegate = self
            categoriesTableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "project_cell")
        } else {
            loggedIn = false //transition -> LoginVC
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        if (userJustLoggedIn) { //check if user just logged in & set the projects accordingly
            obtainDataFromStore("Project")
            categoriesTableView.dataSource = self
            categoriesTableView.delegate = self
            categoriesTableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "project_cell")
            userJustLoggedIn = false //reset the variable
        }
    }
    
    func obtainDataFromStore(entity: String) {
        let request = NSFetchRequest(entityName: entity)
        do { //obtain user's projects from data store
            let results = try context.executeFetchRequest(request)
            for result in results {
                let project = result as! Project
                projects.append(project)
                let count = project.beforeActionVars.count + project.afterActionVars.count
                print("[\(project.title)] Number of variables: \(count)")
                for (variable, dict) in project.beforeActionVars {
                    let options = dict["options"] as? [String] //not all vars have 'options'
                    let prompt = dict["prompt"] as? String
                    print("Before Action Variable Name: \(variable)")
                    print("Options: \(options)")
                    print("Prompt: \(prompt)")
                }
                for (variable, dict) in project.afterActionVars {
                    let options = dict["options"] as? [String]
                    print("After Action Variable Name: \(variable)")
                    print("Options: \(options)")
                }
                print("\n")
            }
        } catch let error as NSError {
            print("Error fetching stored projects: \(error)")
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
//        let height = tableView.frame.height/CGFloat(categories.count) //split TV height evenly
//        return height
        return 50
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //Tapping a cell brings up the data visualization flow for that project:
        selectedProject = projects[indexPath.row]
        performSegueWithIdentifier("showDataVisuals", sender: nil) //transition to ProjectOverviewVC
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
            if !(loggedIn) { //not logged in
                performSegueWithIdentifier("showLogin", sender: nil)
            }
        }
    }
    
    func didLoginSuccessfully(username: String, email: String?) { //store username & pwd & dismiss LoginVC
        userDefaults.setObject(username, forKey: "USERNAME") //save username -> preferences
        if (email != nil) { //consider creating an email formatting class!
            userDefaults.setObject(email!, forKey: "EMAIL") //save email -> preferences
        }
        userDefaults.setBool(true, forKey: "ISLOGGEDIN")
        let success = userDefaults.synchronize() //update the store
        print("Sync successful?: \(success)")
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func logout() {
        userDefaults.setBool(false, forKey: "ISLOGGEDIN")
        loggedIn = false
    }
    
    // MARK: - Navigation
    
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
