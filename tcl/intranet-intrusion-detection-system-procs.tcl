# /packages/intranet-core/tcl/intranet-ids-procs.tcl
#
# Copyright (C) 2018 ]project-open[
# The code is based on work from ArsDigita ACS 3.4 and OpenACS 5.0
#
# This program is free software. You can redistribute it
# and/or modify it under the terms of the GNU General
# Public License as published by the Free Software Foundation;
# either version 2 of the License, or (at your option)
# any later version. This program is distributed in the
# hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.

ad_library {
    Intrusion Detection System Implementation
    @author frank.bergmann@project-open.com
}


# -----------------------------------------------------------
# 
# -----------------------------------------------------------

ad_proc -public im_ids_sql_to_tables { sql } {
    Extracts the referenced tables of a SQL statement.
    It just loops through all fragment and checks if the
    fragment is a known table...
} {
    ns_log Notice "im_ids_sql_to_tables: sql=$sql"

    # Disabled: Recursive call will create infinite loop
#    set all_tables [util_memoize [db_list tables "SELECT table_name FROM information_schema.tables where table_schema = 'public'"]]
    set all_tables {acs_activities acs_activity_object_map acs_attribute_descriptions acs_attributes acs_attribute_values acs_data_links acs_datatypes acs_enum_values acs_event_party_map acs_events acs_events_activities acs_events_dates acs_func_defs acs_func_headers acs_function_args acs_logs acs_magic_objects acs_mail_bodies acs_mail_body_headers acs_mail_gc_objects acs_mail_links acs_mail_lite_bounce acs_mail_lite_bounce_notif acs_mail_lite_mail_log acs_mail_lite_queue acs_mail_multipart_parts acs_mail_multiparts acs_mail_queue_incoming acs_mail_queue_messages acs_mail_queue_outgoing acs_messages acs_messages_all acs_messages_latest acs_messages_outgoing acs_named_objects acs_object_contexts acs_object_grantee_priv_map acs_object_party_privilege_map acs_object_paths acs_objects acs_object_type_attributes acs_object_types acs_object_type_supertype_map acs_object_type_tables acs_permissions acs_permissions_all acs_permissions_lock acs_privilege_descendant_map acs_privilege_descendant_map_view acs_privilege_hierarchy acs_privileges acs_reference_repositories acs_rel_roles acs_rels acs_rel_types acs_sc_bindings acs_sc_contracts acs_sc_impl_aliases acs_sc_impls acs_sc_msg_type_elements acs_sc_msg_types acs_sc_operations acs_static_attr_values acs_users_all ad_locales ad_locale_user_prefs admin_rels ad_template_sample_users ad_template_sample_users_sequence all_object_party_privilege_map apm_applications apm_enabled_package_versions apm_package_callbacks apm_package_db_types apm_package_dependencies apm_package_downloads apm_package_owners apm_packages apm_package_types apm_package_version_attr apm_package_version_info apm_package_versions apm_parameters apm_parameter_values apm_services app_group_distinct_element_map app_group_distinct_rel_map application_group_element_map application_groups application_group_segments attachments attachments_fs_root_folder_map auth_authorities auth_batch_job_entries auth_batch_jobs auth_driver_params calendars cal_items cal_item_types cal_party_prefs categories category_links category_object_map category_object_map_tree category_search category_search_index category_search_results category_synonym_index category_synonyms category_temp category_translations category_tree_map category_trees category_tree_translations cc_users comp_or_member_rel_types composition_rels constrained_rels1 constrained_rels2 content_item_globals content_template_globals countries country_codes country_names cr_child_rels cr_content_mime_type_map cr_content_text cr_doc_filter cr_dummy cr_extension_mime_type_map cr_extlinks cr_files_to_delete cr_folders cr_folder_type_map cr_item_keyword_map cr_item_publish_audit cr_item_rels cr_items cr_item_template_map cr_keywords cr_locales cr_mime_types cr_release_periods cr_resolved_items cr_revision_attributes cr_revisions cr_scheduled_release_job cr_scheduled_release_log cr_symlinks cr_templates cr_template_use_contexts cr_text cr_type_children cr_type_relations cr_type_template_map cr_xml_docs currencies currency_codes currency_country_map currency_names dav_site_node_folder_map dual dynamic_group_type_ext email_images enabled_locales etp_page_revisions fs_files fs_folders fs_objects fs_root_folders fs_rss_subscrs fs_urls_full general_comments general_objects group_approved_member_map group_component_index group_component_map group_distinct_member_map group_element_index group_element_map group_member_index group_member_map group_rels group_rel_type_combos groups group_type_rels group_types guard_list host_node_map images im_agile_kanban_status im_agile_scrum_status im_agile_task_rels im_annual_revenue im_audits im_baselines im_baseline_states im_baseline_types im_biz_object_groups im_biz_object_members im_biz_object_role im_biz_object_role_map im_biz_objects im_biz_object_tree_status im_biz_object_urls im_capacity_planning im_categories im_category_hierarchy im_companies im_company_employee_rels im_company_status im_company_types im_component_plugins im_component_plugin_user_map im_component_plugin_user_map_all im_conf_item_project_rels im_conf_items im_conf_item_status im_conf_item_type im_cost_centers im_costs im_cost_status im_cost_type im_cost_types im_departments im_dynfield_attributes im_dynfield_attr_multi_value im_dynfield_cat_multi_value im_dynfield_layout im_dynfield_layout_pages im_dynfield_type_attribute_map im_dynfield_widgets im_emp_checkpoint_checkoffs im_employee_checkpoints im_employee_pipeline_states im_employees im_employees_active im_estimate_to_completes im_exchange_rates im_expense_bundles im_expense_payment_type im_expenses im_expense_type im_forum_files im_forum_folders im_forum_topics im_forum_topics_sample im_forum_topic_status im_forum_topic_status_active im_forum_topic_types im_forum_topic_user_map im_fs_actions im_fs_files im_fs_file_status im_fs_file_status_active im_fs_folder_perms im_fs_folders im_fs_folder_status im_gantt_assignments im_gantt_assignment_timephases im_gantt_ms_project_warning im_gantt_persons im_gantt_projects im_hiring_sources im_hours im_hours_sample_contents im_idea_user_map im_indicator_results im_indicators im_indicator_sections im_investments im_invoice_canned_notes im_invoice_items im_invoice_payment_method im_invoices im_invoices_active im_job_titles im_key_account_rels im_materials im_material_status im_material_status_active im_material_types im_menus im_notes im_note_status im_note_types im_offices im_office_status im_office_types im_partner_status im_partner_types im_payments im_payments_audit im_payment_type im_planning_items im_planning_item_status im_planning_item_types im_prices im_prior_experiences im_profiles im_projects im_projects_audit im_project_status im_project_types im_project_url_map im_qualification_processes im_release_items im_release_status im_repeating_costs im_reporting_cubes im_reporting_cube_values im_reports im_report_status im_report_types im_rest_object_types im_rest_object_type_status im_rest_object_type_types im_risks im_risk_status im_risk_types im_rule_invocation_types im_rule_logs im_rules im_rule_status im_rule_types im_search_objects im_search_object_types im_sencha_column_configs im_sencha_preferences im_sql_selector_conditions im_sql_selectors im_sql_selectors_active im_sql_selector_status im_sql_selector_type im_start_months im_start_weeks im_survsimp_object_map im_ticket_queue_ext im_tickets im_ticket_status im_ticket_ticket_rels im_ticket_types im_timesheet_conf_objects im_timesheet_conf_object_status im_timesheet_conf_object_types im_timesheet_invoices im_timesheet_prices im_timesheet_task_dependencies im_timesheet_tasks im_timesheet_task_status im_timesheet_task_status_active im_timesheet_tasks_view im_timesheet_task_types im_url_types im_user_absences im_user_absence_status im_user_absence_types im_user_status im_user_type im_vat_types im_view_columns im_views invalid_uninstalled_bindings journal_entries lang_message_keys lang_messages lang_messages_audit lang_translate_columns lang_translation_registry language_639_2_codes language_codes lang_user_timezone lob_data lobs membership_rels notification_delivery_methods notification_email_hold notification_intervals notification_replies notification_requests notifications notification_types notification_types_del_methods notification_types_intervals notification_user_map orphan_implementations partially_populated_event_ids partially_populated_events parties parties_in_required_segs party_approved_member_map party_names persons pg_ts_dict pg_ts_parser postal_addresses postal_types previous_place_list rc_all_constraints rc_all_constraints_view rc_all_distinct_constraints rc_parties_in_required_segs rc_required_rel_segments rc_segment_dependency_levels rc_segment_required_seg_map rc_valid_rel_types rc_violations_by_removing_rel recurrence_interval_types recurrences registered_users rel_constraints rel_constraints_violated_one rel_constraints_violated_two rel_seg_approved_member_map rel_seg_distinct_member_map rel_segment_distinct_party_map rel_segment_group_rel_type_map rel_segment_member_map rel_segment_party_map rel_segments rel_types_valid_obj_one_types rel_types_valid_obj_two_types rss_gen_subscrs search_observer_queue secret_tokens sec_session_properties side_one_constraints site_node_object_mappings site_nodes site_nodes_selection subsite_callbacks subsite_themes survsimp_choice_id_sequence survsimp_choice_scores survsimp_logic survsimp_logic_id_sequence survsimp_logic_surveys_map survsimp_question_choices survsimp_question_responses survsimp_question_responses_un survsimp_questions survsimp_responses survsimp_responses_unique survsimp_surveys survsimp_variable_id_sequence survsimp_variables survsimp_variables_surveys_map syndication target_place_list time_intervals timespans timezone_rules timezones user_col_comments user_portraits user_preferences users users_active users_contact users_email_image user_tab_columns user_tab_comments valid_uninstalled_bindings wf_attribute_value_audit wf_case_assigned_party_actions wf_case_assigned_user_actions wf_case_assignments wf_context_assignments wf_context_role_info wf_contexts wf_context_task_panels wf_context_transition_info wf_context_workflow_info wf_enabled_transitions wf_places wf_role_info wf_roles wf_task_assignments wf_tasks wf_tokens wf_transition_attribute_map wf_transition_contexts wf_transition_info wf_transition_places wf_transition_role_assign_map wf_transitions wf_user_tasks wf_workflows workflow_action_allowed_roles workflow_action_callbacks workflow_action_privileges workflow_actions workflow_callbacks workflow_case_action_assignees workflow_case_assigned_actions workflow_case_enabled_actions workflow_case_fsm workflow_case_log workflow_case_log_data workflow_case_log_rev workflow_case_role_party_map workflow_case_role_user_map workflow_cases workflow_deputies workflow_fsm_action_en_in_st workflow_fsm_actions workflow_fsm_states workflow_role_allowed_parties workflow_role_callbacks workflow_role_default_parties workflow_roles workflows workflow_user_deputy_map xowiki_autonames xowiki_file xowiki_form xowiki_form_instance_attributes xowiki_form_instance_children xowiki_form_instance_item_view xowiki_form_page xowiki_last_visited xowiki_object xowiki_package xowiki_page xowiki_page_instance xowiki_page_live_revision xowiki_page_template xowiki_plain_page xowiki_podcast_item xowiki_references xowiki_tags}

    regsub -all {\W+} $sql " " sql1; 	# Remove leading white spaces

    array set table_hash {}
    foreach table [split $sql1 " "] {
	if {"" eq $table} { continue }
	if {$table in $all_tables} { 
	    set table_hash($table) 1
	}
    }

    return [array names table_hash]
}


ad_proc -public im_ids_collect_db_call { user_id db command statement_name sql } {
    Receives events from the DB interface
} {
    ns_log Notice "im_ids_collect_db_call: uid=$user_id, db=$db, cmd=$command, name=$statement_name, sql=$sql"

    switch $command {

	select {
	    # set tables [util_memoize [list im_ids_sql_to_tables $sql]]
	    set tables [im_ids_sql_to_tables $sql]
	    ns_log Notice "im_ids_collect_db_call: tables=$tables"
	    nsv_set ids_user_last_tables $user_id $tables
	}

	getrow {
	    if {![nsv_exists ids_user_last_tables $user_id]} { return }
	    set tables [nsv_get ids_user_last_tables $user_id]
	    foreach table $tables {
		set count 0
		set key "$user_id-$table"
		if {[nsv_exists ids_user_table_count $key]} { set count [nsv_get ids_user_table_count $key]}
		incr count
		nsv_set ids_user_table_count $key $count
	    }
	}
    }    

}


