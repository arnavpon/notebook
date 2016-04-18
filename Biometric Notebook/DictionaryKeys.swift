//  DictionaryKeys.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 3/28/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// List of dictionary key aliases (so as to standardize the keys & prevent errors).

import UIKit

// MARK: - User Defaults Keys

let IS_LOGGED_IN_KEY = "is_logged_in_key"
let USERNAME_KEY = "username_key"
let EMAIL_KEY = "email_key"
let SHOW_ATTACH_DESCRIPTION = "show_attach_description_key"

// MARK: - Custom NSNotification IDs

let BMN_Notification_CompletionIndicatorDidChange = "BMN_CompletionIndicatorDidChange"
let BMN_Notification_CellDidReportData = "BMN_CellDidReportData"

//CellWithPlusButton Notifications:
let BMN_Notification_RevealHiddenArea = "BMN_RevealHiddenArea"

//CustomSlider Notifications:
let BMN_Notification_SliderSelectedNodeHasChanged = "BMN_SliderSelectedNodeHasChanged"
let BMN_Notification_SliderCrownValueWasSet = "BMN_SliderCrownValueWasSet"
let BMN_Notification_SliderControlIsMoving = "BMN_SliderControlIsMoving"
let BMN_Notification_ProjectTypeDidChange = "BMN_ProjectTypeDidChange"

//CustomOptionsConfigCell Notifications:
let BMN_Notification_AddOptionButtonWasClicked = "BMN_AddOptionButtonWasClicked"
let BMN_CustomOptionsConfigCell_NumberOfLevelsKey = "BMN_CustomOptionsConfigCell_number_of_levels_key"

//SelectFromOptionsConfigCell Notifications:
let BMN_Notification_AdjustHeightForSelectFromOptionsCell = "BMN_AdjustHeightForSelectFromOptionsCell"
let BMN_SelectFromOptionsConfigCell_NumberOfLevelsKey = "BMN_SelectFromOptionsConfigCell_number_of_levels_key"

//ComputationsCell Notifications:
let BMN_Notification_AdjustHeightForComputationCell = "BMN_AdjustHeightForComputationCell"
let BMN_BaseComputationConfigCell_NumberOfLevelsKey = "BMN_BaseComputationConfigCell_number_of_levels_key"

//CellWithGradientFill Notifications:
let BMN_Notification_DataEntryButtonClick = "BMN_DataEntryButtonClick"
let BMN_CellWithGradientFill_ErrorObject = -1 //indicates an error to VC through notification

//CustomModule DataEntryCells Notifications:
let BMN_Notification_RangeScaleValueDidChange = "BMN_RangeScaleValueDidChange"
let BMN_CustomWithRangeScaleCell_RangeScaleValueKey = "CustomWithRangeScaleCell_range_scale_value_key"

// MARK: - LEVELS Framework General Keys

let BMN_DefaultBottomSpacer: CGFloat = 3 //adds height to cells so there is space from bottom

let BMN_LEVELS_MainLabelKey = "LEVELS_main_label_key" //txt for cell's main label
let BMN_LEVELS_RevealLeftButtonKey = "LEVELS_reveal_left_button_key" //button on R of mainLabel
let BMN_LEVELS_RevealRightButtonKey = "LEVELS_reveal_right_button_key" //button on L of mainLabel
let BMN_LEVELS_CellIsOptionalKey = "LEVELS_is_cell_optional_key" //TRUE => cell is optional
let BMN_LEVELS_HideRightViewKey = "LEVELS_hide_right_view_key" //TRUE => hide R side view
let BMN_LEVELS_CompletionIndicatorStatusKey = "LEVELS_completion_indicator_status_key" //key used in the notification that reports whether the cell is complete or incomplete
let BMN_LEVELS_TabLevelKey = "LEVELS_tab_level_key" //indicates the tab hierarchy of the cell

// MARK: - CellWithGradient Keys

let BMN_CellWithGradient_CellIndexKey = "CellWithGradient_cell_index_key" //notification userInfo key

// MARK: - CellWithPlusButton Keys

let BMN_PlusBtnCell_NumberOfHiddenLevelsKey = "PlusBtn_number_of_hidden_levels_key" //notification userInfo key - indicates to VC the # of levels to reveal when btn is pressed

// MARK: - CellWithCustomSlider Keys

let BMN_CellWithCustomSlider_CrownValueKey = "CellWithCustomSlider_entered_value_key" //notification key
let BMN_CellWithCustomSlider_IsSliderMovingKey = "CellWithCustomSlider_is_slider_moving_key" //notif key
let BMN_CellWithCustomSlider_EndpointIsUndefinedKey = "CellWithCustomSlider_endpoint_is_undefined_key"
let BMN_CellWithCustomSlider_ProjectIsCCTypeKey = "CellWithCustomSlider_project_is_cc_type_key" //notif

// MARK: - ConfigurationOptions Data Source Keys

let BMN_Configuration_CellDescriptorKey = "configuration_cell_descriptor_key" //key for the cell's descriptor (the dictionary key used to identify each unique cell for configuration reporting)
let BMN_Configuration_DefaultNumberKey = "configuration_default_number_key" //key for a default number to assign to a SimpleNumberConfigurationCell
let BMN_Configuration_AllowedVariableTypesForComputationKey = "configuration_allowed_variable_types_for_computation_key" //key for BaseComputationConfigCell

// MARK: - [MODULE] General Configuration Keys

let BMN_ViewForSectionKey = "view_for_section_key"
let BMN_RowsForSectionKey = "rows_for_section_key"
let BMN_AlertMessageKey = "alert_message_key"
let BMN_BehaviorsKey = "behaviors_key"
let BMN_ComputationsKey = "computations_key"

// MARK: - [GENERAL] CustomConfigurationCell Keys

let BMN_SelectFromOptions_OptionsKey = "SelectFromOptions_options_key"
let BMN_SelectFromOptions_MultipleSelectionEnabledKey = "SelectFromOptions_multiple_selection_enabled_key"
let BMN_SelectFromOptions_DefaultOptionsKey = "SelectFromOptions_default_options_key"
let BMN_SelectFromOptions_IsBooleanKey = "SelectFromOptions_is_boolean_key"

// MARK: - [MODULE] Configuration Blockers (indicate to Module subclasses that specific behaviors/computations should not be displayed in AttachModuleVC for selection)

let BMN_Blocker_CustomModule_Computation_TimeDifference = "BL_CM_computation_time_difference"

// MARK: - [MODULE] Core Data Keys

let BMN_ModuleTitleKey = "module_title_key" //key to obtain var's Module type
let BMN_VariableIsOutcomeMeasureKey = "variable_is_outcome_measure_key" //indicator if var is an OM
let BMN_VariableIsAutomaticallyCapturedKey = "variable_is_automatically_captured_key" //manual vs. auto
let BMN_VariableTypeKey = "variable_type_key" //key to obtain var's behavior/computation

// MARK: - [MODULE] Data Entry Keys

let BMN_CurrentlyReportingGroupKey = "currently_reporting_group_key" //stores groupID in tempStorageObj
let BMN_Module_MainTimeStampKey = "module_main_time_stamp_key" //main (outer) key in DB object
let BMN_Module_InputsTimeStampKey = "module_inputs_time_stamp_key" //time stamp for input vars (inner key)
let BMN_Module_OutputsTimeStampKey = "module_outputs_time_stamp_key" //time stamp for outcomes (inner key)
let BMN_Module_ReportedDataKey = "module_main_data_key" //main data (differs depending on behavior/comp)

let BMN_CustomModule_TimeDifferenceKey = "CM_time_difference_key" //key containing TD var's name
let BMN_ProjectContainsTimeDifferenceKey = "project_contains_time_difference_key" //indicator

// MARK: - CreateProjectVC Cell IDs

let BMN_ProjectTitleID = "project_title_id"
let BMN_ProjectQuestionID = "project_question_id"
let BMN_ProjectTypeID = "project_type_id"
let BMN_ProjectHypothesisID = "project_hypothesis_id"
let BMN_ProjectEndpointID = "project_endpoint_id"

// MARK: - SetupVariablesVC > "Input Variable" Dict Keys

let BMN_InputOutput_InputVariablesKey = "InputOutput_input_variables_key"
let BMN_ControlComparison_ControlKey = "ControlComparison_control_key"
let BMN_ControlComparison_ComparisonKey = "ControlComparison_comparison_key"

// MARK: - CustomModule [CM] *(KEY = dictionary key, used for storing/unpacking config options from CoreData; ID = unique identifier, used to identify information coming from a ConfigCell)*

//[Configuration KEYS]:
let BMN_CustomModule_OptionsKey = "CM_options_key"
let BMN_CustomModule_CustomOptionsPromptKey = "CM_custom_options_prompt_key"
let BMN_CustomModule_CustomOptionsMultipleSelectionAllowedKey = "CM_custom_options_multiple_selection_allowed_key"
let BMN_CustomModule_RangeScaleMinimumKey = "CM_range_scale_min_key"
let BMN_CustomModule_RangeScaleMaximumKey = "CM_range_scale_max_key"
let BMN_CustomModule_RangeScaleIncrementKey = "CM_range_scale_increment_key"
let BMN_CustomModule_CounterUniqueIDKey = "CM_counter_unique_id_key"
let BMN_CustomModule_IsTimeDifferenceKey = "CM_is_time_difference_key"

//[Configuration IDs]:
let BMN_CustomModule_CustomOptions_PromptID = "CM_custom_options_prompt_id" //identifier: CustomModule > CustomOptions [behavior] > 'prompt' configuration cell
let BMN_CustomModule_CustomOptions_OptionsID = "CM_custom_options_options_id" //identifier: CustomModule > CustomOptions [behavior] > 'options' array
let BMN_CustomModule_CustomOptions_MultipleSelectionAllowedID = "CM_custom_options_multiple_selection_allowed_id" //identifier: Custom Module > CustomOptions [behavior] > 'multiple selection allowed' configuration cell
let BMN_CustomModule_RangeScale_MinimumID = "CM_range_scale_min_id" //identifier: CustomModule > RangeScale [behavior] > 'minimum value' configuration cell
let BMN_CustomModule_RangeScale_MaximumID = "CM_range_scale_max_id" //identifier: CustomModule > RangeScale [behavior] > 'maximum value' configuration cell
let BMN_CustomModule_RangeScale_IncrementID = "CM_range_scale_increment_id" //identifier: CustomModule > RangeScale [behavior] > 'increment value' configuration cell

//DataEntry Keys:
let BMN_DataEntry_CustomWithOptions_NumberOfOptionsKey = "DE_custom_w/_options_number_of_options_key"

// MARK: - EnvironmentModule [EM]

//Configuration (CoreData) Keys:
let BMN_EnvironmentModule_Weather_SelectedOptionsKey = "EM_weather_selected_options_key"

//Configuration IDs:
let BMN_EnvironmentModule_Weather_OptionsID = "EM_weather_options_id"