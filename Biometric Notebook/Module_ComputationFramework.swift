//  Module_ComputationFramework.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 5/26/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// The Project class defers the logic for handling of computations to this class.

//If user wants to grab BMI directly from HK, option should exist (third cell). This cell overrides the others.**

import Foundation

class Module_ComputationFramework {
    
    init() {}
    
    // MARK: - Computation Logic
    
    func setReportObjectForComputations(computations: [Module], inputsReportData: Dictionary<String, [String: AnyObject]>) { //called by Project object, sets reportObject for provided computations
        for computation in computations { //end result is setting the mainDataObj for the computation!
            if let module = Modules(rawValue: computation.moduleTitle), type = computation.selectedFunctionality {
                let processedInputs = processRawInputsForComputation(computation, module: module, functionality: type, rawInputs: inputsReportData)
                let computedValue = applyComputationRuleForVariable(module, functionality: type, processedInputs: processedInputs)
                computation.mainDataObject =  computedValue
            }
        }
    }
    
    private func processRawInputsForComputation(computation: Module, module: Modules, functionality: String, rawInputs: [String: [String: AnyObject]]) -> [String: AnyObject] { //takes in rawInputs & passes out processedInputs dict mapping each input's ID (e.g. [BMN_Height_ID]) -> reportedData
        var processedInputs = Dictionary<String, AnyObject>()
        switch module {
        case .BiometricModule:
            if let type = BiometricModuleVariableTypes(rawValue: functionality) {
                switch type {
                case .Computation_BMI:
                    if let heightName = computation.computationInputs[BMN_ComputationFramework_BM_BMI_HeightID], heightDict = rawInputs[heightName], heightValue = heightDict[BMN_Module_ReportedDataKey], weightName = computation.computationInputs[BMN_ComputationFramework_BM_BMI_WeightID], weightDict = rawInputs[weightName], weightValue = weightDict[BMN_Module_ReportedDataKey] {
                        processedInputs[BMN_ComputationFramework_BM_BMI_HeightID] = heightValue
                        processedInputs[BMN_ComputationFramework_BM_BMI_WeightID] = weightValue
                    }
                default:
                    break
                }
            }
        default:
            break
        }
        return processedInputs
    }
    
    private func applyComputationRuleForVariable(module: Modules, functionality: String, processedInputs: [String: AnyObject]) -> AnyObject? { //processedInputs = dict of format [INPUT_ID: VALUE]
        switch module {
        case .BiometricModule:
            if let type = BiometricModuleVariableTypes(rawValue: functionality) {
                switch type {
                case .Computation_BMI:
                    if let height = processedInputs[BMN_ComputationFramework_BM_BMI_HeightID] as? Double, weight = processedInputs[BMN_ComputationFramework_BM_BMI_WeightID] as? Double {
                        //Compute BMI from last height & weight - convert the weight (in pounds) & the height (in inches) -> proper units before using! How do we make this safe so that we always know what units are being given to us from HK?
                        let weightInKG = weight / 2.2
                        let heightInMeters = (height * 2.54)/100
                        if (heightInMeters != 0) { //default
                            return weightInKG / (heightInMeters * heightInMeters)
                        } else { //height = 0 - prevent infinite value
                            return -1 //error value
                        }
                    }
                default:
                    print("[ComputationFramework - applyComputationRule - BMI] Error - switch default!")
                }
            }
        default:
            print("[ComputationFramework - applyComputationRule] Error - default in switch!")
        }
        return nil
    }
    
}