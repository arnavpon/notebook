//  Modules.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/7/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

import Foundation

enum Modules: String { //available Module types
    case CustomModule = "Custom"
    case EnvironmentModule = "Environment"
    case FoodIntakeModule = "Food Intake"
    case ExerciseModule = "Exercise"
    case BiometricModule = "Biometric"
    case CarbonEmissionsModule = "Carbon Emissions"
    case RecipeModule = "Recipe"
}

enum ModuleVariableStates { //represents the state of the variable object during configuration
    case VariableConfiguration //variable that was constructed during SET-UP for configuration
    case DataReporting //variable that was reconstructed from CORE DATA for data reporting
    case Ghost //variable that was constructed as a GHOST
}

enum ModuleConfigurationTypes: Int { //used by DynamicConfig framework & MeasurementTimeline view
    case InputVariable = 0 //defaultType - all vars are IV unless otherwise specified
    case OutcomeMeasure = 1
    case ActionQualifier = 2
    case TimeDifference = 3
    case GhostVariable = 4
}

enum ModuleVariableReportTypes: Int { //indicates how a variable reports its data
    case Default = 0 //default is var whose value is entered by user
    case AutoCapture = 1 //var that is automatically captured using API
    case Computation = 2 //var that is computed from other variables
    case TimeDifference = 3 //var that measures time difference between points in measurement cycle
}