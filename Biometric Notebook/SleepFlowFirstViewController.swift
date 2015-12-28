//  SleepFlowFirstViewController.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 12/26/15.
//  Copyright © 2015 Confluent Ideals. All rights reserved.

// This VC is the first view of the sleep flow. When it reads the current time as DAY, it brings up the wake flow. If it records the current time as NIGHT, it brings up the night flow.

import UIKit

class SleepFlowFirstViewController: UIViewController {
    
    @IBOutlet weak var sleepOrWakeTimeButton: UIButton!
    
    var currentTime = DateTime() //current time upon opening the 'sleep' flow
    var currentFlow: Int = 0 //0 = pre-sleep flow, 1 = after-waking flow
    var dataObject: SleepDataObject? //contains user-reported info
    
    override func viewWillAppear(animated: Bool) {
        //Call up nighttime OR daytime assets depending on current time:
        //let hours = currentTime.hours
        //let hours = 20
        let hours = 8
        if (hours >= 19) || (hours <= 3) { //between 7 PM & 3 AM, use nighttime assets
            currentFlow = 0
            view.backgroundColor = UIColor.blueColor()
            sleepOrWakeTimeButton.setTitle("I'm going to sleep now!", forState: .Normal)
            sleepOrWakeTimeButton.backgroundColor = UIColor.yellowColor()
            sleepOrWakeTimeButton.setTitleColor(UIColor.blueColor(), forState: .Normal)
        } else { //otherwise, use daytime assets
            currentFlow = 1
            view.backgroundColor = UIColor.orangeColor()
            sleepOrWakeTimeButton.setTitle("I'm awake!", forState: .Normal)
            sleepOrWakeTimeButton.backgroundColor = UIColor.yellowColor()
            sleepOrWakeTimeButton.setTitleColor(UIColor.redColor(), forState: .Normal)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func sleepOrWakeTimeButtonClick(sender: AnyObject) {
        //Capture current time, create dictionary w/ this sleep time, & navigate to the TV for data entry.
        currentTime = DateTime() //capture time as of button click
        let date = currentTime.getCurrentDateString()
        let time = currentTime.getCurrentTimeString()
        if (currentFlow == 0) { //pre-sleep flow
            print("Sleep Time: \(time)")
            print("Today's Date: \(date)")
            dataObject = SleepDataObject(flow: currentFlow, date: date, time: time)
        } else if (currentFlow == 1) { //after-waking flow
            print("Wake Time: \(time)")
            print("Today's Date: \(date)")
            dataObject = SleepDataObject(flow: currentFlow, date: date, time: time)
        }
        performSegueWithIdentifier("showSleepTV", sender: nil)
    }
    
    @IBAction func cancelButtonClick(sender: AnyObject) {
        //Return to app home screen:
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateInitialViewController()!
        presentViewController(controller, animated: true, completion: nil)
    }
    
    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        //let hours = currentTime.hours //current time in hours
        //let hours = 20
        let hours = 8
        if (hours >= 19) || (hours <= 3) { //between 7 PM & 3 AM, call pre-sleep flow
            (segue.destinationViewController as! SleepFlowSecondViewController).currentFlow = 0
        } else { //otherwise, call the after-waking flow
            (segue.destinationViewController as! SleepFlowSecondViewController).currentFlow = 1
        }
        (segue.destinationViewController as! SleepFlowSecondViewController).dataObject = self.dataObject
    }
    
}
