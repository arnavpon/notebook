//  SleepFlowSecondViewController.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 12/27/15.
//  Copyright © 2015 Confluent Ideals. All rights reserved.

// We will start w/ a single table VC & try to reuse it to display different aspects of the data by reloading data during the transitions.

import UIKit

class SleepFlowSecondViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var sleepDataTableView: UITableView!
    @IBOutlet weak var undoButton: UIBarButtonItem! //disable until items have been selected
    @IBOutlet weak var saveButton: UIBarButtonItem! //disable until all information is entered
    
    var currentFlow: Int = 0 //0 = pre-sleep flow, 1 = after-waking flow
    var currentOptionsScreen: Int = 0 //0 = first screen, 1 = 2nd screen (for after-waking flow)
    let beforeSleepSectionTitles = ["Did you meditate?", "Did you use the bathroom?"]
    let meditationOptions = ["Yes", "No"]
    let bathroomOptions = ["Yes", "No"]
    
    let afterWakingSectionTitles1 = ["How are you feeling?", "What woke you up?"]
    let afterWakingSectionTitles2 = ["How was the temperature in bed?", "What's the weather like?", "Are the shades up or down?"]
    let mentalStateOptions = ["Lucid", "Neutral", "Groggy"]
    let wakeReasonOptions = ["The Alarm", "Nothing. I woke up naturally!", "There's too much noise", "It's too bright"]
    let temperatureOptions = ["Pleasant", "Warm", "Chilly"]
    let weatherOptions = ["Sunny", "Partly Sunny", "Cloudy", "Dark"]
    let shadesOptions = ["Shades Up", "Shades Down"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sleepDataTableView.dataSource = self
        sleepDataTableView.delegate = self
        saveButton.enabled = false
        undoButton.enabled = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - TV Data Source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if (currentFlow == 0) { //before-sleep flow
            return beforeSleepSectionTitles.count
        } else { //after-waking flow
            if (currentOptionsScreen == 0) { //options screen #1
                return afterWakingSectionTitles1.count
            } else { //options screen #2
                return afterWakingSectionTitles2.count
            }
        }
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if (currentFlow == 0) { //before-sleep flow
            return beforeSleepSectionTitles[section]
        } else { //after-waking flow
            if (currentOptionsScreen == 0) { //options screen #1
                return afterWakingSectionTitles1[section]
            } else { //options screen #2
                return afterWakingSectionTitles2[section]
            }
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (currentFlow == 0) { //before-sleep flow
            if (section == 0) {
                return meditationOptions.count
            } else {
                return bathroomOptions.count
            }
        } else { //after-waking flow
            if (currentOptionsScreen == 0) { //options screen #1
                if (section == 0) {
                    return mentalStateOptions.count
                } else {
                    return wakeReasonOptions.count
                }
            } else { //options screen #2
                if (section == 0) {
                    return temperatureOptions.count
                } else if (section == 1) {
                    return weatherOptions.count
                } else {
                    return shadesOptions.count
                }
            }
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("sleep_cell", forIndexPath: indexPath)
        if (currentFlow == 0) { //before-sleep flow
            if (indexPath.section == 0) {
                cell.textLabel?.text = meditationOptions[indexPath.row]
            } else if (indexPath.section == 1) {
                cell.textLabel?.text = bathroomOptions[indexPath.row]
            }
        } else { //after-waking flow
            if (currentOptionsScreen == 0) { //options screen #1
                if (indexPath.section == 0) {
                    cell.textLabel?.text = mentalStateOptions[indexPath.row]
                } else if (indexPath.section == 1) {
                    cell.textLabel?.text = wakeReasonOptions[indexPath.row]
                }
            } else { //options screen #2
                if (indexPath.section == 0) {
                    cell.textLabel?.text = temperatureOptions[indexPath.row]
                } else if (indexPath.section == 1) {
                    cell.textLabel?.text = weatherOptions[indexPath.row]
                } else {
                    cell.textLabel?.text = shadesOptions[indexPath.row]
                }
            }
        }
        cell.textLabel?.textColor = UIColor.blueColor()
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //Highlight selected row. If another row in the same section is selected, clear it.
        if (currentFlow == 0) { //pre-sleep flow
            saveButton.enabled = true
            undoButton.enabled = true
        } else if (currentFlow == 1) { //after-waking flow
            if (currentOptionsScreen == 0) {
                undoButton.enabled = true
                currentOptionsScreen = 1
                tableView.reloadData()
            } else {
                saveButton.enabled = true
            }
        }
    }
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        if (currentFlow == 0) { //pre-sleep flow
            undoButton.enabled = false
            saveButton.enabled = false
        } else if (currentFlow == 1) { //after-waking flow
            if (currentOptionsScreen == 0) {
                currentOptionsScreen = 1
                tableView.reloadData()
            } else {
                saveButton.enabled = true
            }
        }
    }
    
    func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    // MARK: - Button Actions
    
    @IBAction func saveButtonClick(sender: AnyObject) {
        //Captures all entered information in a SleepDataObject dictionary & sends it to the database:
        
        //Send notification of successful data capture:
        print("Data sent!")
        
        //Return to home page:
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateInitialViewController()!
        presentViewController(controller, animated: true, completion: nil)
    }
    
    @IBAction func cancelButtonClick(sender: AnyObject) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateInitialViewController()!
        presentViewController(controller, animated: true, completion: nil)
    }
    
    @IBAction func undoButtonClick(sender: AnyObject) {
        //Clears all selections & returns to the first TV.
    }
    
}
