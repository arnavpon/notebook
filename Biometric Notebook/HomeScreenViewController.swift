//  HomeScreenViewController.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 12/26/15.
//  Copyright © 2015 Confluent Ideals. All rights reserved.

// Displays selection options for data entry. Swiping right opens up the visual display VC.

import UIKit
import HealthKit

class HomeScreenViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var categoriesTableView: UITableView!
    
    let categories = ["Sleep", "Exercise", "Dummy Project 1"]
    let cellColors: [UIColor] = [UIColor.blueColor(), UIColor.greenColor(), UIColor.redColor(), UIColor.brownColor(), UIColor.blackColor()]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        categoriesTableView.dataSource = self
        categoriesTableView.delegate = self
        categoriesTableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "project_cell")
        
        let height = HealthKitConnection().getHeightFromHKStore()
        print("Height: \(height)")
        
        //        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        //        let context = appDelegate.managedObjectContext
    }
    
    // MARK: - TV Data Source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("project_cell", forIndexPath: indexPath)
        cell.textLabel?.text = categories[indexPath.row]
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
        //Tapping a cell brings up the data visualization flow for that project. 
        var storyboard: UIStoryboard
        var controller: UIViewController
        switch indexPath.row {
        case 0:
            storyboard = UIStoryboard(name: "SleepFlow", bundle: nil)
            controller = storyboard.instantiateInitialViewController()!
            presentViewController(controller, animated: true, completion: nil) //does not count as segue
        case 1:
            storyboard = UIStoryboard(name: "ExerciseFlow", bundle: nil)
            controller = storyboard.instantiateInitialViewController()!
            presentViewController(controller, animated: true, completion: nil) //does not count as segue
        default:
            performSegueWithIdentifier("showDataVisuals", sender: nil) //transition to ProjectOverviewVC
        }
    }
    
    // MARK: - Button Actions
    
    @IBAction func addProjectButtonClick(sender: AnyObject) { //navigate to CreateProject flow
        let storyboard = UIStoryboard(name: "CreateProjectFlow", bundle: nil)
        let controller = storyboard.instantiateInitialViewController()!
        presentViewController(controller, animated: true, completion: nil)
    }
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    }
}
