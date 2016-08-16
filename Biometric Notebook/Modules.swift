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
    case RecipeModule = "Recipe"
}

enum ModuleVariableStates { //represents the state of the variable object
    case VariableConfiguration //variable that was constructed during SET-UP for configuration
    case DataReporting //variable that was reconstructed from CORE DATA for data reporting
    case Ghost //variable that is constructed as a GHOST
}

enum ConfigurationTypes: String { //indicates whether variable is IV/OM (for DynamicConfig framework)
    case Input = "Input" //default type?
    case OutcomeMeasure = "Outcome"
    case ActionQualifier = "Qualifier"
}

enum ModuleVariableReportTypes: Int {
    case Default = 0 //default is var whose value is entered by user
    case AutoCapture = 1 //var that is automatically captured using API
    case Computation = 2 //var that is computed from other variables
    case TimeDifference = 3 //var that measures time difference between points in measurement cycle
}