//  DictionaryKeys.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 3/28/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// List of dictionary key aliases (so as to standardize the keys & prevent errors).

import Foundation

// MARK: - User Defaults Keys

let IS_LOGGED_IN_KEY = "is_logged_in_key"
let USERNAME_KEY = "username_key"
let EMAIL_KEY = "email_key"
let SHOW_ATTACH_DESCRIPTION = "show_attach_description_key"

// MARK: - Custom NSNotification IDs

let BMN_Notification_CompletionIndicatorDidChange = "BMNCompletionIndicatorDidChange"
let BMN_Notification_DataEntryButtonClick = "BMNDataEntryButtonClick"
let BMN_CellIndexKey = "cell_index_key" //**rename, CellWithGradient notification userInfo key

// MARK: - LEVELS Framework General Keys

let BMN_LEVELS_MainLabelKey = "LEVELS_main_label_key" //txt for cell's main label
let BMN_LEVELS_CellIsOptionalKey = "LEVELS_is_cell_optional_key" //TRUE => cell is optional
let BMN_LEVELS_HideRightViewKey = "LEVELS_hide_right_view_key" //TRUE => hide R side view
let BMN_LEVELS_CompletionIndicatorStatusKey = "LEVELS_completion_indicator_status_key" //key used in the notification that reports whether the cell is complete or incomplete
let BMN_LEVELS_TabLevelKey = "LEVELS_tab_level_key" //indicates the tab hierarchy of the cell

// MARK: - ConfigurationOptions Data Source Keys //*

let BMN_Configuration_CompletionIndicatorStatusKey = "configuration_completion_indicator_status_key" //key used in the notification that reports whether a current cell is complete or incomplete***
let BMN_Configuration_CellIsOptionalKey = "configuration_is_cell_optional_key" //key indicating whether the cell is optional or required***
let BMN_Configuration_InstructionsLabelKey = "configuration_instructions_key" //***
let BMN_Configuration_DefaultNumberKey = "configuration_default_number_key" //key for a default number to assign to a SimpleNumberConfigurationCell
let BMN_Configuration_CellDescriptorKey = "configuration_cell_descriptor_key" //key for the cell's descriptor (the dictionary key used to identify each unique cell for configuration reporting)

// MARK: - [MODULE] General Configuration Keys

let BMN_ViewForSectionKey = "view_for_section_key"
let BMN_RowsForSectionKey = "rows_for_section_key"
let BMN_AlertMessageKey = "alert_message_key"
let BMN_BehaviorsKey = "behaviors_key"
let BMN_ComputationsKey = "computations_key"

// MARK: - [MODULE] Core Data Keys

let BMN_ModuleTitleKey = "module_title_key" //key to obtain var's Module type
let BMN_VariableTypeKey = "variable_type_key" //key to obtain var's behavior/computation

// MARK: - [CustomModule (CM)] Keys, Config Cell IDs, Behavior/Computation Enum IDs (KEY = dictionary key)

let BMN_CustomModule_OptionsKey = "CM_options_key"
let BMN_CustomModule_CustomOptionsPromptKey = "CM_custom_options_prompt_key"
let BMN_CustomModule_CustomOptionsMultipleSelectionAllowedKey = "CM_custom_options_multiple_selection_allowed_key"
let BMN_CustomModule_RangeScaleMinimumKey = "CM_range_scale_min_key"
let BMN_CustomModule_RangeScaleMaximumKey = "CM_range_scale_max_key"
let BMN_CustomModule_RangeScaleIncrementKey = "CM_range_scale_increment_key"

let BMN_CustomModule_CustomOptions_PromptID = "CM_custom_options_prompt_id" //identifier: CustomModule > CustomOptions [behavior] > 'prompt' configuration cell
let BMN_CustomModule_CustomOptions_OptionsID = "CM_custom_options_options_id" //identifier: CustomModule > CustomOptions [behavior] > 'options' array
let BMN_CustomModule_CustomOptions_MultipleSelectionAllowedID = "CM_custom_options_multiple_selection_allowed_id" //identifier: Custom Module > CustomOptions [behavior] > 'multiple selection allowed' configuration cell
let BMN_CustomModule_RangeScale_MinimumID = "CM_range_scale_min_id" //identifier: CustomModule > RangeScale [behavior] > 'minimum value' configuration cell
let BMN_CustomModule_RangeScale_MaximumID = "CM_range_scale_max_id" //identifier: CustomModule > RangeScale [behavior] > 'maximum value' configuration cell
let BMN_CustomModule_RangeScale_IncrementID = "CM_range_scale_increment_id" //identifier: CustomModule > RangeScale [behavior] > 'increment value' configuration cell

// MARK: - Data Entry (DE) TV Cell Keys

let BMN_DataEntry_CustomWithOptions_NumberOfOptionsKey = "DE_custom_w/_options_number_of_options_key"