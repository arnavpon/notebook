//  Modules.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/7/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Enumeration of available types of modules.

import Foundation

enum Modules: String {
    case CustomModule = "custom"
    case WeatherModule = "weather"
    case TemperatureHumidityModule = "tempAndHumidity"
    case FoodIntakeModule = "foodIntake"
    case ExerciseModule = "exercise"
    case BiometricModule = "biometric"
}
