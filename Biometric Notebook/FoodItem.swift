//  FoodItem.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 12/28/15.
//  Copyright © 2015 Confluent Ideals. All rights reserved.

// Data object for storing information about individual food items - the name of the food & the nutrition content.

import Foundation

enum Food { //enumerates the different possible kinds of food, would be better to use a centralized API or database containing food calorie & nutrition counts.
    case Almond
    case Peanut
    case CashewNut
    case Banana
    case Yogurt
    case Milk
}

class FoodItem {
    let name: String
    
    init(food: Food) { //initialize w/ enum case
        switch food {
        case .Almond:
            self.name = "almond"
        case .Peanut:
            self.name = "peanut"
        case .CashewNut:
            self.name = "cashew"
        case .Banana:
            self.name = "banana"
        case .Yogurt:
            self.name = "yogurt"
        case .Milk:
            self.name = "milk"
        }
    }
}
