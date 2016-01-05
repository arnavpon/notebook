//  ExerciseVisualizationViewController.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 12/28/15.
//  Copyright © 2015 Confluent Ideals. All rights reserved.

// This VC is responsible for presenting a summary of the workout upon completion for visualization; it should display information such as duration, calories burned?, etc.

import UIKit

class ExerciseVisualizationViewController: UIViewController {
    
    @IBOutlet weak var exerciseDurationLabel: UILabel!
    
    var workoutStartTime: NSDate?
    var workoutEndTime: NSDate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
