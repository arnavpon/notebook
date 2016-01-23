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

