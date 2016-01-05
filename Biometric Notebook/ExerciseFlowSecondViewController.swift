//  ExerciseFlowSecondViewController.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 12/28/15.
//  Copyright © 2015 Confluent Ideals. All rights reserved.

// TableView showing exercise data options.

import UIKit

class ExerciseFlowSecondViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var exerciseDataTableView: UITableView!
    @IBOutlet weak var saveButton: UIBarButtonItem! //disable until all information is entered
    
    var currentFlow: Int = 0 //0 = pre-sleep flow, 1 = after-waking flow
    var dataObject: ExerciseDataObject?
    var arrayOfCellsForSection: [Int: NSIndexPath] = Dictionary<Int, NSIndexPath>() //dictionary containing the indexPath of the HIGHLIGHTED cell within a given section
    
    let beforeWorkoutSectionTitles = ["How is your breathing?", "How does your stomach feel?", "How's your temperature?"]
    let breathingOptions = ["Clear", "Tight/Restricted"]
    let digestionOptions = ["Still digesting", "Neutral", "Empty - I'm starving"]
    let temperatureOptions = ["Hot", "Neutral", "Cold"]
    
    let afterWorkoutSectionTitles = ["How was the workout?"]
    let exerciseQualityOptions = ["High Quality", "Neutral", "Poor Quality"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        exerciseDataTableView.dataSource = self
        exerciseDataTableView.delegate = self
        saveButton.enabled = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - TV Data Source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if (currentFlow == 0) { //pre-workout flow
            return beforeWorkoutSectionTitles.count
        } else { //after-workout flow
            return afterWorkoutSectionTitles.count
        }
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if (currentFlow == 0) { //before-workout flow
            return beforeWorkoutSectionTitles[section]
        } else { //after-workout flow
            return afterWorkoutSectionTitles[section]
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (currentFlow == 0) { //before-workout flow
            if (section == 0) {
                return breathingOptions.count
            } else if (section == 1) {
                return digestionOptions.count
            } else {
                return temperatureOptions.count
            }
        } else { //after-workout flow
            return exerciseQualityOptions.count
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("sleep_cell", forIndexPath: indexPath)
        if (currentFlow == 0) { //before-sleep flow
            if (indexPath.section == 0) {
                cell.textLabel?.text = breathingOptions[indexPath.row]
            } else if (indexPath.section == 1) {
                cell.textLabel?.text = digestionOptions[indexPath.row]
            } else {
                cell.textLabel?.text = temperatureOptions[indexPath.row]
            }
        } else { //after-waking flow
            cell.textLabel?.text = exerciseQualityOptions[indexPath.row]
        }
        cell.textLabel?.textColor = UIColor.blueColor()
        cell.backgroundColor = UIColor.lightGrayColor()
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let section = indexPath.section
        arrayOfCellsForSection[section] = indexPath //stores currently selected cell -> array
        let count: Int //counts # of entries that SHOULD be in the arrayOfCells object
        var compare: Int = 0 //comparison variable, checks if all necessary data has been entered
        if (currentFlow == 0) { //pre-workout flow
            count = beforeWorkoutSectionTitles.count
            for i in 0...(count - 1) {
                if let _ = arrayOfCellsForSection[i] {
                    compare += 1
                }
            }
            if (compare == count) { //enable after 1 option in each section is selected
                saveButton.enabled = true
            }
        } else if (currentFlow == 1) { //after-workout flow
            saveButton.enabled = true
        }
        print("Currently selected rows: ")
        for item in arrayOfCellsForSection {
            print("Section \(item.0): Highlighted Cell @ Row - \(item.1.row)")
        }
    }
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        let section = indexPath.section
        arrayOfCellsForSection[section] = nil //clear array value for that section on deselection
        saveButton.enabled = false
        print("Currently selected rows: ")
        for item in arrayOfCellsForSection {
            print("Section \(item.0): Highlighted Cell @ Row - \(item.1.row)")
        }
    }
    
    func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        let selectedCellSection = indexPath.section
        let selectedCellRow = indexPath.row
        if let previouslySelectedCellIndexPath = arrayOfCellsForSection[selectedCellSection] { //check if another row in the same section has been selected previously
            if (previouslySelectedCellIndexPath.row != selectedCellRow) { //check if it is the same cell
                print("Unhighlighted cell: Section - \(previouslySelectedCellIndexPath.section), Row - \(previouslySelectedCellIndexPath.row)")
                tableView.cellForRowAtIndexPath(previouslySelectedCellIndexPath)?.selected = false
            }
        }
        return true
    }
    
    // MARK: - Button Actions
    
    @IBAction func saveButtonClick(sender: AnyObject) { //capture user entries
        if (currentFlow == 0) { //pre-workout flow
            var breathing: String = ""
            var digestion: String = ""
            var temperature: String = ""
            for (entry, index) in arrayOfCellsForSection {
                let value = (exerciseDataTableView.cellForRowAtIndexPath(index)?.textLabel?.text)!
                switch entry {
                case 0:
                    breathing = value
                case 1:
                    digestion = value
                case 2:
                    temperature = value
                default:
                    print("default")
                }
                arrayOfCellsForSection[entry] = nil
            }
            dataObject?.recordBeforeWorkoutUserResponses(breathing, digestion: digestion, temperature: temperature)
            print("Thanks! Go get 'em!")
        } else { //after-workout flow
            var exerciseQuality: String = ""
            for (entry, index) in arrayOfCellsForSection {
                let value = (exerciseDataTableView.cellForRowAtIndexPath(index)?.textLabel?.text)!
                exerciseQuality = value
                arrayOfCellsForSection[entry] = nil
            }
            dataObject?.recordAfterWorkoutUserResponses(exerciseQuality)
            print("Thanks! Don't forget to hydrate and rest!")
        }
        dataObject?.getJSONDictionaryWithExerciseDate()
        performSegueWithIdentifier("showExerciseDataVisual", sender: nil) //navigate to data visualization
        
    }
    
    @IBAction func cancelButtonClick(sender: AnyObject) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateInitialViewController()!
        presentViewController(controller, animated: true, completion: nil)
    }
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        //Pass start & finish time & any other necessary data:
        let _ = segue.destinationViewController as! ExerciseVisualizationViewController
    }
    
}