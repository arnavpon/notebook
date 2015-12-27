//  HomeScreenTableViewController.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 12/25/15.
//  Copyright © 2015 Confluent Ideals. All rights reserved.

// Displays selection options for data entry. Swiping right opens up the visual display VC.

import UIKit

class HomeScreenTableViewController: UITableViewController {
    
    @IBOutlet var categoriesTableView: UITableView!
    
    let categories = ["Sleep", "Exercise", "Breathing", "Nutrition", "Upper Airway"]
    let cellColors: [UIColor] = [UIColor.blueColor(), UIColor.greenColor(), UIColor.yellowColor(), UIColor.brownColor(), UIColor.blackColor()]
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - TV Data Source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("category", forIndexPath: indexPath)
        cell.textLabel?.text = categories[indexPath.row]
        cell.textLabel?.textAlignment = .Center
        cell.textLabel?.textColor = UIColor.whiteColor()
        cell.backgroundColor = cellColors[indexPath.row]
        return cell
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        //Split TV height evenly among the possible categories:
        let height = tableView.frame.height/CGFloat(categories.count)
        return height
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //Select the appropriate storyboard to navigate to:
        var storyboard: UIStoryboard
        var controller: UIViewController
        switch indexPath.row {
        case 0:
            storyboard = UIStoryboard(name: "SleepFlow", bundle: nil)
            controller = storyboard.instantiateInitialViewController()!
            print("Case 1 selected")
        default:
            storyboard = UIStoryboard()
            controller = UIViewController()
        }
        presentViewController(controller, animated: true, completion: nil)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
