//  Modules.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/7/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Enumeration of available types of modules.

import Foundation

enum Modules: String {
    case CustomModule = "Custom"
    case EnvironmentModule = "Environment"
    case FoodIntakeModule = "Food Intake"
    case ExerciseModule = "Exercise"
    case BiometricModule = "Biometric"
    case CarbonEmissionsModule = "Carbon Emissions"
}

enum ModuleVariableStates { //represents the state of the variable object
    case VariableConfiguration //variable that was constructed during SET-UP for configuration
    case DataReporting //variable that was reconstructed from CORE DATA for data reporting
}

enum VariableLocations { //indicates the location of the variable in DataEntry flow
    case BeforeAction //beforeAction var
    case AfterAction //afterAction var
}