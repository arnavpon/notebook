//  ExerciseFlowFirstViewController.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 12/28/15.
//  Copyright © 2015 Confluent Ideals. All rights reserved.

import UIKit

class ExerciseFlowFirstViewController: UIViewController {

    @IBOutlet weak var exerciseStartOrFinishButton: UIButton!
    
    var currentFlow: Int = 0 //0 = pre-workout flow, 1 = after-workout flow
    var dataObject: ExerciseDataObject? //contains user-reported info
    
    override func viewWillAppear(animated: Bool) {
        //Call up start or finish assets based on currentFlow:
        if (true) { //for pre-workout, use <> assets
            currentFlow = 0
            view.backgroundColor = UIColor.blueColor()
            exerciseStartOrFinishButton.setTitle("Starting the workout now!", forState: .Normal)
            exerciseStartOrFinishButton.backgroundColor = UIColor.yellowColor()
            exerciseStartOrFinishButton.setTitleColor(UIColor.blueColor(), forState: .Normal)
        }
//        else { //otherwise, use post-workout assets
//            currentFlow = 1
//            view.backgroundColor = UIColor.orangeColor()
//            exerciseStartOrFinishButton.setTitle("Finished the workout!", forState: .Normal)
//            exerciseStartOrFinishButton.backgroundColor = UIColor.yellowColor()
//            exerciseStartOrFinishButton.setTitleColor(UIColor.redColor(), forState: .Normal)
//        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func exerciseStartOrFinishButtonClick(sender: AnyObject) {
        //Capture current time, create dictionary w/ this start time, & navigate to the TV for data entry.
        let currentTime = DateTime() //capture time as of button click
        let date = currentTime.getCurrentDateString()
        let time = currentTime.getCurrentTimeString()
        if (currentFlow == 0) { //pre-workout flow
            print("Start Time: \(time)")
            print("Today's Date: \(date)")
            dataObject = ExerciseDataObject(flow: currentFlow, date: date, time: time)
        } else if (currentFlow == 1) { //after-workout flow
            print("End Time: \(time)")
            dataObject = ExerciseDataObject(flow: currentFlow, date: date, time: time)
        }
        performSegueWithIdentifier("showExerciseTV", sender: nil)
    }
    
    @IBAction func cancelButtonClick(sender: AnyObject) { //return to app home screen:
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateInitialViewController()!
        presentViewController(controller, animated: true, completion: nil)
    }
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (true) { //pre-workout if there is no existing dataObject
            (segue.destinationViewController as! ExerciseFlowSecondViewController).currentFlow = 0
        }
//        else { //post-workout if dataObject exists
//            (segue.destinationViewController as! ExerciseFlowSecondViewController).currentFlow = 1
//        }
        (segue.destinationViewController as! ExerciseFlowSecondViewController).dataObject = self.dataObject
    }
    
}