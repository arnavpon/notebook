//  HelperFunctions.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/22/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

import Foundation
import UIKit
import CoreData

// MARK: - Core Data

func clearCoreDataStoreForEntity(entity entity: String) {
    print("Clearing data store...")
    let context = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    let request = NSFetchRequest(entityName: entity)
    do {
        let results = try context.executeFetchRequest(request)
        for result in results {
            context.deleteObject(result as! NSManagedObject)
            print("Deleted object.")
            do {
                print("Context saved!")
                try context.save()
            } catch let error as NSError {
                print("Error saving store: \(error)")
            }
        }
        print("Deleted \(results.count) object(s)\n")
    } catch let error as NSError {
        print("Error fetching stored projects: \(error)")
    }
}

//Code for two interdependent checkboxes (when one is clicked, the other is unclicked):
//@IBAction func inputVariableCheckboxClicked(sender: AnyObject) {
//    if !(inputVariableCheckbox.isChecked) { //box is NOT currently checked
//        beforeOrAfterAction = false //set value for variable
//    } else { //box is currently checked & is being unchecked (so NO boxes will be selected)
//        beforeOrAfterAction = nil
//    }
//    if (outcomeVariableCheckbox.isChecked) { //uncheck other box if checked
//        outcomeVariableCheckbox.isChecked = false
//    }
//}
//
//@IBAction func outcomeVariableCheckboxClicked(sender: AnyObject) {
//    if !(outcomeVariableCheckbox.isChecked) { //box is NOT currently checked
//        beforeOrAfterAction = true //set value for variable
//    } else { //box is currently checked & is being unchecked (so NO boxes will be selected)
//        beforeOrAfterAction = nil
//    }
//    if (inputVariableCheckbox.isChecked) { //uncheck other box if checked
//        inputVariableCheckbox.isChecked = false
//    }
//}

