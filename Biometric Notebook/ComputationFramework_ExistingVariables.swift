//  ComputationFramework_ExistingVariables.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 5/24/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Keeps track of a project's existing variables for computation configuration.

import Foundation

struct ComputationFramework_ExistingVariables {
    
    let name: String
    let variableType: String?
    let module: Modules?
    let reportType: ModuleVariableReportTypes?
    
    init(variable: Module) {
        self.name = variable.variableName
        self.variableType = variable.selectedFunctionality
        self.reportType = variable.variableReportType
        if let mod = Modules(rawValue: variable.moduleTitle) { //obtain Module type
            self.module = mod
        } else {
            self.module = nil
        }
    }
    
}