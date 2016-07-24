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
    case RecipeModule = "RecipeModule"
}

enum ModuleVariableStates { //represents the state of the variable object
    case VariableConfiguration //variable that was constructed during SET-UP for configuration
    case DataReporting //variable that was reconstructed from CORE DATA for data reporting
    case Ghost //variable that is constructed as a GHOST
}

enum VariableLocations: Int { //indicates the location of the variable in DataEntry flow
    case BeforeAction = 0 //beforeAction var
    case AfterAction = 1 //afterAction var
}

enum ModuleVariableReportTypes: Int {
    case Default = 0 //default is var whose value is entered by user
    case AutoCapture = 1 //var that is automatically captured using API
    case Computation = 2 //var that is computed from other variables
}