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
    var dataObject: SleepDataObject?
    var currentOptionsScreen: Int = 0 //0 = first screen, 1 = 2nd screen (for after-waking flow)
    var arrayOfCellsForSection: [Int: NSIndexPath] = Dictionary<Int, NSIndexPath>() //dictionary containing the indexPath of the HIGHLIGHTED cell within a given section
    
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
    var mentalState: String? //store user response
    var wakeReason: String? //store user response
    
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
        let section = indexPath.section
        arrayOfCellsForSection[section] = indexPath //stores currently selected cell -> array
        let count: Int //counts # of entries that SHOULD be in the arrayOfCells object
        var compare: Int = 0 //comparison variable, checks if all necessary data has been entered
        if (currentFlow == 0) { //pre-sleep flow
            count = beforeSleepSectionTitles.count
            undoButton.enabled = true
            for i in 0...(count - 1) {
                if let _ = arrayOfCellsForSection[i] {
                    compare += 1
                }
            }
            if (compare == count) { //enable after 1 option in each section is selected
                saveButton.enabled = true
            }
        } else if (currentFlow == 1) { //after-waking flow
            if (currentOptionsScreen == 0) { //first screen
                count = afterWakingSectionTitles1.count
                undoButton.enabled = true
                for i in 0...(count - 1) {
                    if let _ = arrayOfCellsForSection[i] { //check if both options are selected
                        compare += 1
                    }
                }
                if (compare == count) { //transition -> screen 2 if checkpoint is passed
                    for (entry, index) in arrayOfCellsForSection { //capture user selections
                        let value = (tableView.cellForRowAtIndexPath(index)?.textLabel?.text)!
                        switch entry {
                        case 0:
                            mentalState = value
                        case 1:
                            wakeReason = value
                        default:
                            print("Default Case")
                        }
                        arrayOfCellsForSection[entry] = nil //clear selections dictionary
                    }
                    currentOptionsScreen = 1
                    tableView.reloadData() //transition -> screen 2
                }
            } else { //second screen
                count = afterWakingSectionTitles2.count
                for i in 0...(count - 1) {
                    if let _ = arrayOfCellsForSection[i] {
                        compare += 1
                    }
                    if (compare == count) {
                        saveButton.enabled = true
                    }
                }
            }
        }
        print("Currently selected rows: ")
        for item in arrayOfCellsForSection {
            print("Section \(item.0): Highlighted Cell @ Row - \(item.1.row)")
        }
    }
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        let section = indexPath.section
        arrayOfCellsForSection[section] = nil //clear array value for that section on deselection
        if (currentFlow == 0) { //pre-sleep flow
            saveButton.enabled = false
            if (arrayOfCellsForSection.count == 0) { //check if 0 options are selected
                undoButton.enabled = false
            }
        } else if (currentFlow == 1) { //after-waking flow
            if (currentOptionsScreen == 0) { //first screen
                if (arrayOfCellsForSection.count == 0) { //check if 0 options are selected
                    undoButton.enabled = false
                }
            } else { //second screen
                saveButton.enabled = false
            }
        }
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
        if (currentFlow == 0) { //pre-sleep flow
            var meditation: String = ""
            var bathroom: String = ""
            for (entry, index) in arrayOfCellsForSection {
                let value = (sleepDataTableView.cellForRowAtIndexPath(index)?.textLabel?.text)!
                switch entry {
                case 0:
                    meditation = value
                case 1:
                    bathroom = value
                default:
                    print("default")
                }
                arrayOfCellsForSection[entry] = nil
            }
            dataObject?.recordBeforeSleepUserResponses(meditation, bathroom: bathroom)
            print("Thanks! Sweet Dreams!")
        } else { //after-waking flow
            var temperature: String = ""
            var weather: String = ""
            var shadesDown: String = ""
            for (entry, index) in arrayOfCellsForSection {
                let value = (sleepDataTableView.cellForRowAtIndexPath(index)?.textLabel?.text)!
                switch entry {
                case 0:
                    temperature = value
                case 1:
                    weather = value
                case 2:
                    shadesDown = value
                default:
                    print("default")
                }
                arrayOfCellsForSection[entry] = nil
            }
            dataObject?.recordAfterWakingUserResponses(mentalState!, wakeReason: wakeReason!, temperature: temperature, weather: weather, shadesDown: shadesDown)
            print("Thanks! Go out & win the day!")
        }
        dataObject?.getJSONDictionaryWithSleepDate()
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
    
    @IBAction func undoButtonClick(sender: AnyObject) { //clears all selections & returns to initial TV
        if (currentFlow == 0) { //pre-sleep flow
            for (entry, indexPath) in arrayOfCellsForSection { //deselect all current selections
                sleepDataTableView.cellForRowAtIndexPath(indexPath)?.selected = false
                arrayOfCellsForSection[entry] = nil
            }
        } else { //after-waking flow
            if (currentOptionsScreen == 0) { //first screen
                for (entry, indexPath) in arrayOfCellsForSection { //deselect all current selections
                    sleepDataTableView.cellForRowAtIndexPath(indexPath)?.selected = false
                    arrayOfCellsForSection[entry] = nil
                }
            } else { //second screen; return -> first screen, clear selections
                currentOptionsScreen = 0
                for (entry, _) in arrayOfCellsForSection { //clear selection dict
                    arrayOfCellsForSection[entry] = nil
                }
                sleepDataTableView.reloadData()
            }
        }
        undoButton.enabled = false
        saveButton.enabled = false
    }
    
}
