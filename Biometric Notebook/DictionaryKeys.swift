//  DictionaryKeys.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 3/28/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// List of dictionary key aliases (so as to standardize the keys & prevent errors).

import UIKit

// MARK: - User Defaults Keys

let IP_VALUE = "ip_value" //**temporary

let IS_LOGGED_IN_KEY = "UserDefaults_is_logged_in_key"
let EMAIL_KEY = "UserDefaults_email_key"
let EDITED_PROJECTS_KEY = "UserDefaults_edited_projects_key" //keeps track of recently edited projects
let SHOW_VARIABLE_SETUP_TUTORIAL = "UserDefaults_show_variable_setup_tutorial"
let SHOW_ATTACH_DESCRIPTION = "UserDefaults_show_attach_description_key"

let INPUTS_TIME_STAMP = "UserDefaults_input_variables_time_stamp_key" //for DataEntryVC & AvgOverAction**use actionTimeStamp to get rid of this & get time period for action

// MARK: - [COMPUTATIONS] IDs
let BMN_ComputationFramework_BM_BMI_HeightID = "CF_BM_BMI_height_id"
let BMN_ComputationFramework_BM_BMI_WeightID = "CF_BM_BMI_weight_id"

let BMN_Notification_ComputationFramework_DidCreateGhostVariable = "BMN_CF_DidCreateGhostVariable"
let BMN_ComputationFramework_ComputationNameKey = "BMN_CF_computation_name_key"
let BMN_ComputationFramework_GhostNameKey = "BMN_CF_ghost_name_key"
let BMN_ComputationFramework_GhostConfigDictKey = "BMN_CF_ghost_config_dict_key"

// MARK: - [GENERAL] NSNotification IDs

let BMN_Notification_CompletionIndicatorDidChange = "BMN_CompletionIndicatorDidChange"
let BMN_Notification_CellDidReportData = "BMN_CellDidReportData"
let BMN_Notification_AutoCapVarCompletionStatusDidChange = "BMN_AutoCapVarCompletionStatusDidChange"

let BMN_Notification_AdjustHeightForConfigCell = "BMN_AdjustHeightForConfigCell" //config cell height
let BMN_AdjustHeightForConfigCell_UniqueIDKey = "BMN_AdjustHeightForConfigCell_unique_id_key"
let BMN_AdjustHeightForConfigCell_NumberOfLevelsKey = "BMN_AdjustHeightForConfigCell_number_of_levels_key"
let BMN_Notification_DataEntry_GroupSelection_OptionWasSelected = "BMN_DE_GroupSelection_OptionWasSelected"

let BMN_Notification_MeasurementTimeline_VariableWasSelected = "BMN_MT_VariableWasSelected"
let BMN_Notification_MeasurementTimeline_TimeDifferenceButtonWasClicked = "BMN_MT_TDButtonWasClicked"
let BMN_Notification_MeasurementTimeline_ShouldDeleteTimeDifferenceVariable = "BMN_MT_ShouldDeleteTDVar"
let BMN_MeasurementTimeline_TDButtonStateKey = "MT_time_difference_button_state_key"
let BMN_MeasurementTimeline_VariableForSelectionKey = "MT_variable_for_selection_key"
let BMN_MeasurementTimeline_LocationInCycleKey = "MT_location_in_cycle_key"

let BMN_Notification_DataReportingErrorProtocol_ServiceDidReportError = "BMN_DataReportingErrorProtocol_ServiceDidReportError"
let BMN_DataReportingErrorProtocol_ServiceTypeKey = "BMN_DataReportingErrorProtocol_service_type_key"

let BMN_Notification_DatabaseConnection_DataTransmissionStatusDidChange = "BMN_DBConnection_DataTransmissionStatusDidChange"
let BMN_DatabaseConnection_TransmissionStatusKey = "BMN_DBConnection_transmission_status_key"

let BMN_Notification_CoreLocationManager_LocationDidChange = "BMN_CL_location_did_change"
let BMN_CoreLocationManager_LatitudeKey = "BMN_CL_location_latitude_key" //key for notification dict
let BMN_CoreLocationManager_LongitudeKey = "BMN_CL_location_longitude_key" //key for notification dict

//CellWithPlusButton Notifications:
let BMN_Notification_RevealHiddenArea = "BMN_RevealHiddenArea"

//CustomSlider Notifications:
let BMN_Notification_SliderSelectedNodeHasChanged = "BMN_SliderSelectedNodeHasChanged"
let BMN_Notification_SliderCrownValueWasSet = "BMN_SliderCrownValueWasSet"
let BMN_Notification_SliderControlIsMoving = "BMN_SliderControlIsMoving"
let BMN_Notification_ProjectTypeDidChange = "BMN_ProjectTypeDidChange"

//CellWithGradientFill Notifications:
let BMN_Notification_DataEntryButtonClick = "BMN_DataEntryButtonClick"
let BMN_Notification_EditExistingProject = "BMN_EditExistingProject" //swipe to edit existing project
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
let BMN_Configuration_ReportCountID = "configuration_report_count_id" //stores report count in CoreData

// MARK: - [MODULE] UI Setup Keys

let BMN_ViewForSectionKey = "view_for_section_key"
let BMN_RowsForSectionKey = "rows_for_section_key"
let BMN_AlertMessageKey = "alert_message_key"
let BMN_BehaviorsKey = "behaviors_key"
let BMN_ComputationsKey = "computations_key"

// MARK: - [GENERAL] CustomConfigurationCell Keys

let BMN_SimpleNumberConfigCell_DefaultKey = "SimpleNumberConfigCell_default_key" //default value
let BMN_SelectFromOptions_OptionsKey = "SelectFromOptions_options_key"
let BMN_SelectFromOptions_MultipleSelectionEnabledKey = "SelectFromOptions_multiple_selection_enabled_key"
let BMN_SelectFromOptions_DefaultOptionsKey = "SelectFromOptions_default_options_key"
let BMN_SelectFromOptions_IsBooleanKey = "SelectFromOptions_is_boolean_key"
let BMN_SelectFromDropdown_OptionsKey = "SelectFromDropdown_options_key"

// MARK: - [MODULE] Configuration Blockers (for 'Module_DynamicConfigurationFramework' class)

let BMN_DynamicConfig_InputVariablesKey = "DCF_input_variables_key"
let BMN_DynamicConfig_OutcomeMeasuresKey = "DCF_outcome_measures_key"

// MARK: - [MODULE] Core Data Keys

let BMN_ModuleTitleKey = "module_title_key" //key to obtain var's Module type
let BMN_VariableReportLocationsKey = "variable_report_positions_key" //saves report locations during cycle
let BMN_ConfigurationTypeKey = "configuration_type_key" //indicates if var is IV/OM/AQ/TD/Ghost
let BMN_VariableReportTypeKey = "variable_report_type_key" //stores var's report type (auto cap, comp)
let BMN_VariableTypeKey = "variable_type_key" //key to obtain var's behavior/computation
let BMN_DataEntry_MainLabelPromptKey = "DE_main_label_prompt_key" //alternate mainLbl title for DataEntry

// MARK: - [MODULE] Data Entry Keys

let BMN_TSO_ReportingGroupKey = "DE_reporting_group_key" //stores ID for reporting group in tempStorageObj
let BMN_TSO_DatastreamVariableLocationKey = "DE_datastream_variable_location_key"
let BMN_DBO_TimeStampKey = "DE_time_stamp_key" //key in DB object for timeStamp @ each reportLocation
let BMN_Module_AutoCapVarCompletionStatusKey = "module_auto_cap_var_completion_status_key" //notif key
let BMN_Module_ReportedDataKey = "module_main_data_key" //for var's main data (*match -> Python script*)
let BMN_Module_OptionsForListKey = "module_options_for_list_key" //*needed for Python DB creation*
let BMN_Module_OptionsForDictKey = "module_options_for_dict_key" //*needed for Python DB creation*

let BMN_DataEntry_FreeformCell_NumberOfViewsKey = "BM_DE_freeform_cell_number_of_views_key" //for height calculation

// MARK: - CreateProjectVC Cell IDs

let BMN_ProjectTitleID = "project_title_id"
let BMN_ProjectQuestionID = "project_question_id"
let BMN_ProjectTypeID = "project_type_id"
let BMN_ProjectHypothesisID = "project_hypothesis_id"
let BMN_ProjectEndpointID = "project_endpoint_id"

// MARK: - [Action] Configuration IDs & Persistence Keys

let BMN_Action_ActionLocationID = "Action_action_location_id"
let BMN_Action_ActionMeasurementRateID = "Action_action_measurement_rate_id"

let BMN_Action_QualifiersCountKey = "Action_qualifiers_count_key"
let BMN_Action_QualifiersStoredDataKey = "Action_qualifiers_stored_data_key"
let BMN_Action_ActionTypeKey = "Action_action_type_key"
let BMN_Action_CustomNameKey = "Action_custom_name_key"
let BMN_Action_EnumLocationKey = "Action_enum_location_key"
let BMN_Action_LocationInCycleKey = "Action_location_in_cycle_key"
let BMN_Action_OccursInEachCycleKey = "Action_occurs_in_each_cycle_key"
let BMN_Action_ActionTimeStampKey = "Action_action_time_stamp_key"

// MARK: - CustomModule [CM] *(KEY = dictionary key, used for storing/unpacking config options from CoreData; ID = unique identifier, used to identify information coming from specific ConfigCells)*

//[Configuration KEYS]:
let BMN_CustomModule_CustomOptions_OptionsKey = "CM_options_key" //CustomModule > CustomOptions [behavior] > 'options' array
let BMN_CustomModule_CustomOptions_MultipleSelectionAllowedKey = "CM_custom_options_multiple_selection_allowed_key" //Custom Module > CustomOptions [behavior] > 'multiple selection allowed' configuration cell
let BMN_CustomModule_RangeScaleMinimumKey = "CM_range_scale_min_key" //CustomModule > RangeScale [behavior] > 'minimum value' configuration cell
let BMN_CustomModule_RangeScaleMaximumKey = "CM_range_scale_max_key" //CustomModule > RangeScale [behavior] > 'maximum value' configuration cell
let BMN_CustomModule_RangeScaleIncrementKey = "CM_range_scale_increment_key" //CustomModule > RangeScale [behavior] > 'increment value' configuration cell
let BMN_CustomModule_CounterUniqueIDKey = "CM_counter_unique_id_key"
let BMN_CustomModule_TimeDifferenceTypeKey = "CM_time_difference_type_key" //CM > TimeDifference [computation] > 'type' config object
let BMN_CustomModule_TimeDifferenceLocation1Key = "CM_time_difference_location1_key"
let BMN_CustomModule_TimeDifferenceLocation2Key = "CM_time_difference_location2_key"

//[Configuration IDs]:
let BMN_CustomModule_CustomOptions_PromptID = "CM_custom_options_prompt_id" //identifier: CustomModule > CustomOptions [behavior] > 'prompt' configuration cell

//[DataEntry Keys]:
let BMN_DataEntry_CustomWithOptions_NumberOfOptionsKey = "DE_custom_w/_options_number_of_options_key"

// MARK: - EnvironmentModule [EnM]

//[Configuration Keys]:
let BMN_EnvironmentModule_Weather_SelectedOptionsKey = "EnM_weather_selected_options_key"

// MARK: - BiometricModule [BM]

//[Configuration KEYS]:
let BMN_BiometricModule_DataSourceOptionsKey = "BM_data_source_options_key"
let BMN_BiometricModule_HeartRateSamplingOptionKey = "BM_heart_rate_sampling_options_key"

//[Configuration IDs]:
let BMN_BiometricModule_DataSourceOptionsID = "BM_data_source_options_id"
let BMN_BiometricModule_DataSourceOptions2ID = "BM_data_source_options_2_id"

//[CoreData Keys]:
let BMN_BiometricModule_ComputationInputsKey = "BMN_BM_computation_inputs_key"

// MARK: - FoodIntakeModule [FiM]

//[Configuration KEYS]:
let BMN_FoodIntakeModule_NutritionCategoriesKey = "FiM_nutrition_categories_key"
let BMN_FoodIntakeModule_DataStreamLocationsKey = "FiM_data_stream_locations_key"

// MARK: - ExerciseModule [ExM]

//[Datastream Keys]:
let BMN_ExM_CurrentExerciseKey = "ExM_current_exercise_key"
let BMN_ExM_ReportedDataKey = "ExM_reported_data_key"

// MARK: - RecipeModule [ExM]

//[Configuration KEYS]:
let BMN_RecipeModule_RatingCategoriesKey = "ReM_rating_categories_key"

//[Configuration IDs]:
let BMN_RecipeModule_RecipeNameID = "ReM_recipe_name_id"