//  ProjectSummaryViewController.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/3/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Provide summary of project setup before finalizing creation, showing each item & the project's object corresponding to that item. Allow user to edit as needed.

import UIKit

class ProjectSummaryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var summaryTableView: UITableView!
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    var projectTitle: String? //title (obtained from ProjectVariablesVC)
    var projectQuestion: String? //question for investigation (obtained from ProjectVariablesVC)
    var projectAction: Action? //action (obtained from ProjectVariablesVC)
    var projectEndpoint: Endpoint? //endpoint (obtained from ProjectVariablesVC)
    var beforeActionVariables: [Module]? //obtained from ProjectVariablesVC
    var afterActionVariables: [Module]? //obtained from ProjectVariablesVC
    
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
        return 6
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Project Title"
        case 1:
            return "Research Question"
        case 2:
            return "Endpoint"
        case 3:
            return "Input Variables"
        case 4:
            return "Action"
        case 5:
            return "Outcome Variables"
        default:
            return "Error! Switch Case Default"
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return 1
        case 2:
            return 1
        case 3:
            return (beforeActionVariables?.count)!
        case 4:
            return 1
        case 5:
            return (afterActionVariables?.count)!
        default:
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("summary_cell")!
        switch indexPath.section {
        case 0:
            cell.textLabel?.text = projectTitle
        case 1:
            cell.textLabel?.text = projectQuestion
        case 2: //project's endpoint
            cell.textLabel?.text = "Project ends \(projectEndpoint!.endpointInDays) days from now"
        case 3: //beforeActionVars
            cell.textLabel?.text = beforeActionVariables![indexPath.row].variableName
        case 4: //project action
            cell.textLabel?.text = projectAction?.action.rawValue
        case 5: //afterActionVars
            cell.textLabel?.text = afterActionVariables![indexPath.row].variableName
        default:
            cell.textLabel?.text = ""
        }
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //Allow user to go to correct location to edit.
    }
    
    // MARK: - Button Actions
    
    @IBAction func doneButtonClick(sender: AnyObject) {
        //Add before & after variable arrays to the current object & then save it -> persistent store before returning to homescreen:
        let beforeActionVariablesDict = createDictionaryForCoreData(beforeActionVariables!)
        let afterActionVariablesDict = createDictionaryForCoreData(afterActionVariables!)
        let context = appDelegate.managedObjectContext
        let _ = Project(title: projectTitle!, question: projectQuestion!, endPoint: projectEndpoint?.endpointInDays, action: (projectAction?.action.rawValue)!, beforeVariables: beforeActionVariablesDict, afterVariables: afterActionVariablesDict, insertIntoManagedObjectContext: context)
        do {
            try context.save()
            print("Context saved")
        } catch let error as NSError {
            print("Error saving context: \(error)")
        }
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateInitialViewController()!
        presentViewController(controller, animated: true, completion: nil)
    }
    
    func createDictionaryForCoreData(variableArray: [Module]) -> Dictionary<String, [String: AnyObject]> {
        //Construct the master dictionary for CoreData given a variableArray (array containing user-created variables):
        var dictionary = Dictionary<String, [String: AnyObject]>()
        for variable in variableArray { //construct dict
            switch variable { //check which module was attached
            case is CustomModule:
                let variableWithType = variable as! CustomModule
                dictionary[variable.variableName] = variableWithType.createDictionaryForCoreDataStore()
            case is TemperatureHumidityModule:
                let variableWithType = variable as! TemperatureHumidityModule
                dictionary[variable.variableName] = variableWithType.createDictionaryForCoreDataStore()
            case is WeatherModule:
                let variableWithType = variable as! WeatherModule
                dictionary[variable.variableName] = variableWithType.createDictionaryForCoreDataStore()
            case is ExerciseModule:
                let variableWithType = variable as! ExerciseModule
                dictionary[variable.variableName] = variableWithType.createDictionaryForCoreDataStore()
            case is FoodIntakeModule:
                let variableWithType = variable as! FoodIntakeModule
                dictionary[variable.variableName] = variableWithType.createDictionaryForCoreDataStore()
            default:
                print("Error - default triggered in beforeAction switch")
            }
        }
        return dictionary
    }
    
    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    
    }

}
