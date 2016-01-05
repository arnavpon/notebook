//  ProjectSummaryViewController.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/3/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Provide summary of project setup before finalizing creation. Allow user to edit as needed. 

import UIKit

class ProjectSummaryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var summaryTableView: UITableView!
    
    // MARK: - View Configuration
    
    override func viewDidLoad() {
        super.viewDidLoad()
        summaryTableView.dataSource = self
        summaryTableView.delegate = self
        summaryTableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "summary_cell")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table View
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 5
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("summary_cell")!
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //Allow user to go to correct location to edit.
    }
    
    // MARK: - Button Actions
    
    @IBAction func doneButtonClick(sender: AnyObject) {
        //return to homescreen
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
