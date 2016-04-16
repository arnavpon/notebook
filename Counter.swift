//  Counter.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 4/13/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Counter objects - lie outside of the traditional measurement cycle flow.

import Foundation
import CoreData

class Counter: NSManagedObject {

    // MARK: - Counter Incrementing Logic
    
    func incrementCounter() { //increases counter value by 1
        let value = self.currentCount.integerValue
        self.currentCount = value + 1
        saveManagedObjectContext() //persist changes
    }
    
    func refreshCounter() { //resets counter's value to 0
        self.currentCount = 0
    }

}
