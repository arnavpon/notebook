//  DictionaryKeys.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 3/28/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// List of dictionary key aliases (so as to standardize the keys & prevent errors).

import Foundation

// MARK: - General Configuration Keys

let BMN_CellIsSelectableKey = "is_cell_selectable_key"
let BMN_CellIsDeletableKey = "is_cell_deletable_key"
let BMN_ViewForSectionKey = "view_for_section_key"
let BMN_RowsForSectionKey = "rows_for_section_key"
let BMN_AlertMessageKey = "alert_message_key"
let BMN_BehaviorsKey = "behaviors_key"
let BMN_ComputationsKey = "computations_key"

// MARK: - ConfigurationOptions Data Source Keys

let BMN_Configuration_CompletionIndicatorStatusKey = "configuration_completion_indicator_status_key" //key used in the notification that reports whether a current cell is complete or incomplete
let BMN_Configuration_CellIsOptionalKey = "configuration_is_cell_optional_key" //key indicating whether the cell is optional or required
let BMN_Configuration_InstructionsLabelKey = "configuration_instructions_key"
let BMN_Configuration_DefaultNumberKey = "configuration_default_number_key" //key for a default number to assign to a SimpleNumberConfigurationCell
let BMN_Configuration_CellDescriptorKey = "configuration_cell_descriptor_key" //key for the cell's descriptor (the dictionary key used to identify each unique cell for configuration reporting)

// MARK: - Module Core Data Keys

let BMN_ModuleTitleKey = "module_title_key" //key to obtain var's Module type
let BMN_VariableTypeKey = "variable_type_key" //key to obtain var's behavior/computation

// MARK: - Custom Module Keys, Config Cell IDs, Behavior/Computation Enum IDs (KEY = dictionary key)

let BMN_CustomModule_OptionsKey = "custom_module_options_key"
let BMN_CustomModule_PromptKey = "custom_module_prompt_key"
let BMN_CustomModule_RangeScaleMinimumKey = "custom_module_range_scale_min_key"
let BMN_CustomModule_RangeScaleMaximumKey = "custom_module_range_scale_max_key"
let BMN_CustomModule_RangeScaleIncrementKey = "custom_module_range_scale_increment_key"

let BMN_CustomModule_CustomOptions_PromptID = "custom_module_custom_options_prompt_id" //identifier: CustomModule > CustomOptions [behavior] > 'prompt' configuration cell
let BMN_CustomModule_CustomOptions_OptionsID = "custom_module_custom_options_options_id" //identifier: CustomModule > CustomOptions [behavior] > 'options' array
let BMN_CustomModule_RangeScale_MinimumID = "custom_module_range_scale_min_id" //identifier: CustomModule > RangeScale [behavior] > 'minimum value' configuration cell
let BMN_CustomModule_RangeScale_MaximumID = "custom_module_range_scale_max_id" //identifier: CustomModule > RangeScale [behavior] > 'maximum value' configuration cell
let BMN_CustomModule_RangeScale_IncrementID = "custom_module_range_scale_increment_id" //identifier: CustomModule > RangeScale [behavior] > 'increment value' configuration cell