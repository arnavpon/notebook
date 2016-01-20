//  HomeScreenViewController.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 12/26/15.
//  Copyright © 2015 Confluent Ideals. All rights reserved.

// Displays a list of all open projects & indicates their remaining duration. 

import UIKit
import HealthKit
import CoreData

class HomeScreenViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var categoriesTableView: UITableView!
    
    var projects: [Project] = [] //list of project objects
    let cellColors: [UIColor] = [UIColor.blueColor(), UIColor.greenColor(), UIColor.redColor(), UIColor.blackColor()]
    var selectedProject: Project? //object to pass on segue
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //clearDataStore("Project")
        categoriesTableView.dataSource = self
        categoriesTableView.delegate = self
        categoriesTableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "project_cell")
        
        let height = HealthKitConnection().getHeightFromHKStore()
        print("Height: \(height)")
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let context = appDelegate.managedObjectContext
        let request = NSFetchRequest(entityName: "Project")
        do {
            let results = try context.executeFetchRequest(request)
            for result in results {
                let project = result as! Project
                projects.append(project)
                let count = project.beforeActionVars.count + project.afterActionVars.count
                print("[\(project.title)] Number of variables: \(count)")
                for (variable, dict) in project.beforeActionVars {
                    let options = dict["options"] as! [String]
                    print("Before Action Variable Name: \(variable)")
                    print("Options: \(options)")
                }
                for (variable, dict) in project.afterActionVars {
                    let options = dict["options"] as! [String]
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
        //eventually, we will want to organize projects based on some criteria
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
    
    // MARK: - Helper Functions
    
    func clearDataStore(entity: String) {
        print("Clearing data store...")
        let context = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
        let request = NSFetchRequest(entityName: entity)
        do {
            let results = try context.executeFetchRequest(request)
            for result in results {
                context.deleteObject(result as! NSManagedObject)
                print("Deleted object.")
                do {
                    print("Context saved!")
                    try context.save()
                } catch let error as NSError {
                    print("Error saving store: \(error)")
                }
            }
            print("Deleted \(results.count) object(s)\n")
        } catch let error as NSError {
            print("Error fetching stored projects: \(error)")
        }
    }
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "showDataVisuals") { //pass the selected project
            let destination = segue.destinationViewController as! ProjectOverviewViewController
            destination.selectedProject = self.selectedProject
        }
    }
}
