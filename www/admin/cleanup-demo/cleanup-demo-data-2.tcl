# /packages/intranet-core/www/admin/cleanup-demo/ cleanup-demo-data-2.tcl
#
# Copyright (C) 2003 - 2006 ]project-open[
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

ad_page_contract {
    Delete all demo data in the system in order to prepare
    for production rollout

    @author frank.bergmann@project-open.com
} {
    { select_category_type "All" }
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_need_to_be_a_syst]">
    return
}

set page_title "Cleanup Demo Data"
set context_bar [im_context_bar $page_title]

set bgcolor(0) " class=rowodd"
set bgcolor(1) " class=roweven"

set default_user [db_string defuser "select min(person_id) from persons where person_id > 0"]

# ---------------------------------------------------------------
# Render page header
# ---------------------------------------------------------------

set content_type "text/html"
set http_encoding "utf-8"
append content_type "; charset=$http_encoding"
set all_the_headers "HTTP/1.0 200 OK
MIME-Version: 1.0
Content-Type: $content_type\r\n"
util_WriteWithExtraOutputHeaders $all_the_headers
ns_startcontent -type $content_type


ns_write [im_header]
ns_write [im_navbar]
ns_write "<h1>$page_title</h1>\n"

# ---------------------------------------------------------------
# No cleanup of users
# ---------------------------------------------------------------

set ttt {
ns_write "
<font color=red>
<ul>
<li>This script does not cleanup demo users.<br>
    After running this script, please go to Admin -&gt; Delete Demodata -&gt;
    Delete Demo Users to delete selected users.
<li>Due to the structure of the data model there may be cases where you<br>
    have to run this script twice in order to cleanup all data in the system.<br>
    This behaviour is due to the strong referential integrity constraints<br>
    in the system, together with 'triggers'.
</ul>
</font>
"
}


ns_write "<ul>\n"

# ---------------------------------------------------------------
# Delete all data
# ---------------------------------------------------------------

ns_write "<li>Cleanup existing security tokens.\n"
ns_write "A new set of tokens will be generated with the next server restart\n"
db_dml delete_sec_tokens "delete from secret_tokens"
db_string reset_token_seq "SELECT pg_catalog.setval('t_sec_security_token_id_seq', 1, true)"

ns_write "<li>Cleanup multi-value attributes.\n"
db_dml delete_im_dynfield_attr_multi_value "delete from im_dynfield_attr_multi_value"

ns_write "<li>Cleanup bulletin board email alersts\n"
if {[im_table_exists bboard_email_alerts]} {
    db_dml delete_user_bboard_email_alerts "delete from bboard_email_alerts"
    db_dml delete_user_bboard_thread_email_alerts "delete from bboard_thread_email_alerts"
    db_dml delete_user_bboard_unified "delete from bboard_unified"
}
    
ns_write "<li>Cleanup classified ads\n"
if {[im_table_exists classified_auction_bids]} {
    db_dml delete_user_classified_auction_bids "delete from classified_auction_bids"
    db_dml delete_user_classified_ads "delete from classified_ads"
    db_dml delete_user_classified_email_alerts "delete from classified_email_alerts"
    db_dml delete_user_neighbor_to_neighbor_comments "delete from general_comments"
    db_dml delete_user_neighbor_to_neighbor "delete from neighbor_to_neighbor"
}

ns_write "<li>Cleanup user calendars\n"
if {[im_table_exists calendar]} {
    db_dml delete_user_calendar "delete from calendar"
}

ns_write "<li>Cleanup entrants_table_name\n"
ns_log Notice "users/nuke2: entrants_table_name"
if {[im_table_exists entrants_table_name]} {
    set all_contest_entrants_tables [db_list unused "select entrants_table_name from contest_domains"]
    foreach entrants_table $all_contest_entrants_tables {
	db_dml delete_user_contest_entries "delete from $entrants_table"
    }
}

ns_write "<li>Cleanup spam history\n"
if {[im_table_exists spam_history]} {
    db_dml delete_user_spam_history_sent "update spam_history set last_user_id_sent = NULL"
    db_dml delete_user_spam_history "delete from spam_history"
}

ns_write "<li>Cleanup calendar items\n"
ns_write "<ul>\n"

if {[im_table_exists calendars]} {

    ns_write "<li>Cleanup cal_party_prefs\n"
    db_dml delete_cal_party_prefs "delete from cal_party_prefs"
    ns_write "<li>Cleanup cal_items\n"
    db_dml delete_cal_items "delete from cal_items"
    ns_write "<li>Cleanup cal_item_types\n"
    db_dml delete_cal_item_types "delete from cal_item_types"
    ns_write "<li>Cleanup acs_events\n"
    db_dml delete_acs_events "delete from acs_events"
    ns_write "<li>Cleanup acs_activities\n"
    db_dml delete_acs_activities "delete from acs_activities"
    ns_write "<li>Cleanup recurrences\n"
    db_dml delete_acs_recurrences "delete from recurrences"
    ns_write "<li>Cleanup timespans\n"
    db_dml delete_timespans "delete from timespans"
    ns_write "<li>Cleanup time_intervals\n"
    db_dml delete_time_intervals "delete from time_intervals"
    ns_write "<li>Cleanup calendars\n"
    db_dml delete_calendars "delete from calendars where calendar_name <> 'Global Calendar'"

    set object_subquery "
	select object_id from acs_objects
	where object_type in ('cal_item','acs_event','acs_activity','calendars')
    "

    ns_write "<li>Cleanup calendar acs_permissions\n"
    db_dml cal_perms "delete from acs_permissions where object_id in ($object_subquery)"

    ns_write "<li>Cleanup calendar acs_objects<br>\n"
    set cal_objects [db_list costs $object_subquery]
    set cnt 0
    foreach oid $cal_objects {
 	if {0 == [expr $cnt % 37]} { ns_write ".\n" }
        catch { db_dml del_cal_o "delete from acs_objects where object_id = :oid" } err_msg
	incr cnt
    }

}
ns_write "</ul>\n"



ns_write "<li>Cleanup calendar_categories\n"
if {[im_table_exists calendar_categories]} {
    db_dml delete_user_calendar_categories "delete from calendar_categories"
    db_dml delete_cal_itmes "delete from cal_items"
}

ns_write "<li>Cleanup sessions\n"
if {[im_table_exists sec_sessions]} {
#    db_dml delete_user_sec_sessions "delete from sec_sessions"
#    db_dml delete_user_sec_login_tokens "delete from sec_login_tokens"
}

ns_write "<li>Cleanup general comments\n"
if {[im_table_exists general_comments]} {
    db_dml delete_user_general_comments "delete from general_comments"
}

ns_write "<li>Cleanup comments\n"
if {[im_table_exists comments]} {
    db_dml delete_user_comments "delete from comments"
}

ns_write "<li>Cleanup links\n"
if {[im_table_exists links]} {
    db_dml delete_user_links "delete from links"
}

ns_write "<li>Cleanup chat_msgs\n"
if {[im_table_exists chat_msgs]} {
    db_dml delete_user_chat_msgs "delete from chat_msgs"
}

ns_write "<li>Cleanup query_strings\n"
if {[im_table_exists query_strings]} {
    db_dml delete_user_query_strings "delete from query_strings"
}

ns_write "<li>Cleanup user_curriculum_map\n"
if {[im_table_exists user_curriculum_map]} {
    db_dml delete_user_user_curriculum_map "delete from user_curriculum_map"
}

ns_write "<li>Cleanup user_content_map\n"
if {[im_table_exists user_content_map]} {
    db_dml delete_user_user_content_map "delete from user_content_map"
}

ns_write "<li>Cleanup user_group_map\n"
if {[im_table_exists user_group_map]} {
    db_dml delete_user_user_group_map "delete from user_group_map"
}

ns_write "<li>Cleanup users_interests\n"
if {[im_table_exists users_interests]} {
    db_dml delete_user_users_interests "delete from users_interests"
}

ns_write "<li>Cleanup users_charges\n"
if {[im_table_exists users_charges]} {
    db_dml delete_user_users_charges "delete from users_charges"
}

ns_write "<li>Cleanup users_demographics\n"
if {[im_table_exists users_demographics]} {
    db_dml set_referred_null_user_users_demographics "update users_demographics set referred_by = null"
    db_dml delete_user_users_demographics "delete from users_demographics"
}

ns_write "<li>Cleanup users_preferences\n"
if {[im_table_exists users_preferences]} {
    db_dml delete_user_users_preferences "delete from users_preferences"
}

ns_write "<li>Cleanup users_contact\n"
if {[im_table_exists users_contact]} {
    db_dml delete_user_users_contact "delete from users_contact"
}

ns_write "<li>Cleanup im_component_plugin_user_map\n"
if {[im_table_exists im_component_plugin_user_map]} {
    db_dml delete_im_component_plugin_user_map "delete from im_component_plugin_user_map"
}


# Content Repository etc.

ns_write "<li>Cleanup Content Repository\n"
ns_write "<ul>\n"
ns_write "<li>Cleanup acs_mail_body_headers\n"
db_dml acs_mail_body_headers "delete from acs_mail_body_headers"
ns_write "<li>Cleanup acs_mail_bodies\n"
db_dml acs_mail_bodies "delete from acs_mail_bodies"
ns_write "<li>Cleanup acs_mail_body_headers\n"
db_dml acs_mail_body_headers "delete from acs_mail_body_headers"
ns_write "<li>Cleanup acs_mail_gc_objects\n"
db_dml acs_mail_gc_objects "delete from acs_mail_gc_objects"
ns_write "<li>Cleanup acs_mail_links\n"
db_dml acs_mail_links "delete from acs_mail_links"
ns_write "<li>Cleanup acs_mail_multipart_parts\n"
db_dml acs_mail_multipart_parts "delete from acs_mail_multipart_parts"
ns_write "<li>Cleanup acs_mail_multiparts\n"
db_dml acs_mail_multiparts "delete from acs_mail_multiparts"
ns_write "<li>Cleanup acs_messages\n"
db_dml acs_messages "delete from acs_messages"
ns_write "</ul>\n"


# ToDo:
# images (leaves empty cr_items)
# cr_items (also want to delete cr_templates)
# cr_revisions
# cr_item_rels
# cr_item_publish_audit
# cr_scheduled_release_log
# lob_data
# lobs
# acs_permissions
# acs_object_context_index
# acs_objects (cleanup)
# acs_rels (cleanup)



    
# Reassign objects to a default user...
set default_user 0

# Lang_message_audit

# Deleting cost entries in acs_objects that are "dangeling", i.e. that don't have an
# entry in im_costs. These might have been created during manual deletion of objects
# Very dirty...



ns_write "<li>Cleanup im_hours\n"
db_dml timesheet "delete from im_hours"

ns_write "<li>Cleanup im_payments\n"
db_dml payments "delete from im_payments"
ns_write "<li>Cleanup im_payments_audit\n"
db_dml im_payments_audit "delete from im_payments_audit"

ns_write "<li>Cleanup dangeling_costs\n"
db_dml dangeling_costs "delete from acs_objects where object_type = 'im_cost' and object_id not in (select cost_id from im_costs)"


ns_write "<li>Cleanup im_hours - set cost_id = null\n"
db_dml timesheet_cost_refs "update im_hours set cost_id = null"


ns_write "<li>Cleanup costs<br>\n"
set cost_infos [db_list_of_lists costs "select cost_id, object_type from im_costs, acs_objects where cost_id = object_id"]
set im_invoices__invoice_id_exists_p [im_column_exists im_expenses invoice_id]
set cnt 0
foreach cost_info $cost_infos {
    set cost_id [lindex $cost_info 0]
    set object_type [lindex $cost_info 1]
    
    if {0 == [expr $cnt % 13]} { ns_write ".\n" }
    ns_log Notice "users/nuke-2: deleting cost: ${object_type}__delete($cost_id)"
    if {$im_invoices__invoice_id_exists_p} {
	db_dml del_expense_inv "update im_expenses set invoice_id = null where invoice_id = :cost_id"
    }

    db_dml del_expenses "delete from im_expenses where expense_id = :cost_id"
    im_exec_dml del_cost "${object_type}__delete($cost_id)"
    incr cnt
}

ns_write "<li>Cleanup dangeling_costs\n"
db_dml dangeling_costs "delete from acs_objects where object_type = 'im_cost' and object_id not in (select cost_id from im_costs)"



# Delete (ugly!) costs that have been deleted in im_costs
# but still exists in acs_object.
# Fix 090107 from iuri.sampaio@gmail.com: call acs_object__delete
# instead of using "delete from acs_objects".
db_list dangeling_costs "
	select	acs_object__delete(object_id)
	from	acs_objects
	where	object_type = 'im_cost' and 
		object_id not in (select cost_id from im_costs)
"



ns_write "<li>Cleanup Forum\n"
db_dml im_forum_topic_user_map "delete from im_forum_topic_user_map"
db_dml im_forum_topic_user_map "delete from im_forum_topic_user_map"
db_dml forum "delete from im_forum_topics"

# Never Ever!
# The folders are part of the base configuration that is required
# db_dml im_forum_folders "delete from im_forum_folders"


if {[im_table_exists im_notes]} {
    ns_write "<li>Cleanup Notes\n"
    db_dml im_notes "delete from im_notes"
    db_dml forum "delete from acs_objects where object_type = 'im_notes'"
}


ns_write "<li>Cleanup im_hours\n"
db_dml timesheet "delete from im_hours"
ns_write "<li>Cleanup im_user_absences\n"
db_dml timesheet "delete from im_user_absences"

ns_write "<li>Cleanup im_timesheet_prices\n"
if {[im_table_exists im_timesheet_prices]} {
    db_dml im_timsheet_prices "delete from im_timesheet_prices"
}


if {[im_table_exists im_trans_quality_reports]} {
    ns_write "<li>Cleanup im_trans_quality_reports\n"
    db_dml im_trans_quality_entries "delete from im_trans_quality_entries"
    db_dml im_trans_quality_reports "delete from im_trans_quality_reports"
}

if {[im_table_exists im_trans_tasks]} {
    ns_write "<li>Cleanup Translation\n"
    db_dml im_target_languages "delete from im_target_languages"
    db_dml im_task_actions "delete from im_task_actions"
    db_dml im_trans_tasks "delete from im_trans_tasks"
    db_dml im_trans_prices "delete from im_trans_prices"
    db_dml trados_matrix "delete from im_trans_trados_matrix"
}


ns_write "<li>Cleanup Filestorage\n"
ns_write "<ul>\n"
ns_write "<li>Cleanup im_fs_files\n"
db_dml files "delete from im_fs_files"
ns_write "<li>Cleanup im_fs_folder_status\n"
db_dml forum "delete from im_fs_folder_status"
ns_write "<li>Cleanup im_fs_actions\n"
db_dml filestorage "delete from im_fs_actions"
ns_write "<li>Cleanup im_fs_folder_perms\n"
db_dml im_fs_folder_perms "delete from im_fs_folder_perms"
ns_write "<li>Cleanup im_fs_folders\n"
db_dml forum "delete from im_fs_folders"
ns_write "</ul>\n"


ns_write "<li>Cleanup Bug Tracker\n"
if {[im_table_exists bt_bugs]} {

    # Delete the application tables
    db_dml bt_del "delete from bt_bugs"
    db_dml bt_del "delete from bt_bug_revisions"
    db_dml bt_del "delete from bt_patch_actions"

    # Go for context index
    db_dml bt_del "delete from acs_object_context_index where ancestor_id in (
		select object_id from acs_objects where object_type = 'bt_bug'
    )"
    db_dml bt_del "delete from acs_object_context_index where ancestor_id in (
		select object_id from acs_objects where object_type = 'bt_bug_revision'
    )"

    # Keyword Map
    db_dml bt_del "delete from cr_item_keyword_map where item_id in (
	select item_id from cr_items where live_revision in (
		select object_id from acs_objects where object_type = 'bt_bug_revision'	
	)
    )"

    # Permissions
    db_dml bt_del "delete from acs_permissions where object_id in (
	select object_id from acs_objects where object_type = 'bt_bug'
    )"
    
    # Delete the Content Repository Items
    db_dml bt_del "update cr_items set live_revision = null where live_revision in (
	select object_id from acs_objects where object_type = 'bt_bug_revision'
    )"
    db_dml bt_del "update cr_items set latest_revision = null where latest_revision in (
	select object_id from acs_objects where object_type = 'bt_bug_revision'
    )"
    db_dml bt_del "delete from cr_items where content_type = 'bt_bug_revision'"

    db_dml bt_del "delete from cr_child_rels where rel_id in (
	select object_id from acs_objects where context_id in (select object_id from acs_objects where object_type = 'bt_bug')
    )"


    # Delete other objects depending on bugs.
    db_dml bt_del "update acs_objects set context_id = null
    where context_id in (
	select object_id from acs_objects where object_type = 'bt_bug'
    )"

    db_dml bt_del "delete from workflow_case_log where entry_id in (
	select item_id from cr_items where parent_id in (select object_id from acs_objects where object_type = 'bt_bug')
    )"
    db_dml bt_del "update cr_items set live_revision = null, latest_revision = null 
    where parent_id in (select object_id from acs_objects where object_type = 'bt_bug')"
    db_dml bt_del "delete from cr_items where parent_id in (select object_id from acs_objects where object_type = 'bt_bug')"
    db_dml bt_del "delete from acs_objects where object_type = 'bt_bug'"

    # Delete acs_objects
    db_dml bt_del "delete from acs_objects where object_type = 'bt_bug_revision'"

}


ns_write "<li>Cleanup im_search_objects\n"
if {[im_table_exists im_search_objects]} {
    db_dml im_search_objects "delete from im_search_objects"
}


ns_write "<li>Cleanup search_observer_queue\n"
if {[im_table_exists search_observer_queue]} {
    db_dml search_observer_queue "delete from search_observer_queue"
}


ns_write "<li>Cleanup Workflow\n"
ns_write "<ul>\n"
ns_write "<li>Cleanup wf_case_assignments\n"
db_dml wf_case_assignments "delete from wf_case_assignments"
ns_write "<li>Cleanup wf_task_assignments\n"
db_dml wf_task_assignments "delete from wf_task_assignments"
ns_write "<li>Cleanup wf_tokens\n"
db_dml wf_tokens "delete from wf_tokens"
ns_write "<li>Cleanup wf_tasks\n"
db_dml wf_tasks "delete from wf_tasks"
ns_write "<li>Cleanup wf_cases\n"
db_dml wf_cases "delete from wf_cases"
ns_write "<li>Cleanup wf_attribute_value_audit\n"
db_dml wf_attribute_value_audits "delete from wf_attribute_value_audit"
ns_write "<li>Cleanup wf_case_deadlines\n"
db_dml wf_case_deadlines "delete from wf_case_deadlines"
ns_write "</ul>\n"



# Remove user from business objects that we don't want to delete...
ns_write "<li>Cleanup im_biz_object_members\n"
db_dml im_biz_object_members "delete from im_biz_object_members"

ns_write "<li>Cleanup im_projects\n"
db_dml remove_from_projects "update im_projects set parent_id = null"

ns_write "<li>Cleanup im_timesheet_tasks\n"
db_dml remove_from_projects "delete from im_timesheet_tasks"

ns_write "<li>Cleanup im_timesheet_task_dependencies\n"
db_dml remove_from_projects "delete from im_timesheet_task_dependencies"

ns_write "<li>Cleanup acs_mail_lite_log"
if {[im_table_exists acs_mail_lite_mail_log"]} {
    db_dml acs_mail_lite_log "delete from acs_mail_lite_mail_log"
}
ns_write "<li>Cleanup Relationships (except for membership, composition & user_portrait)\n"
set rels [db_list cr "
	select rel_id from 
	acs_rels
	where rel_type not in ('user_portrait_rel', 'membership_rel', 'composition_rel')
"]
set cnt 0
foreach rel_id $rels {
    if {0 == [expr $cnt % 37]} { ns_write ".\n" }
    db_string del_rel "select acs_rel__delete(:rel_id)"
    incr cnt
}


ns_write "<li>Cleanup Indicator Results\n"
if {[im_table_exists im_indicator_results]} {
    db_dml indicator_results "delete from im_indicator_results"
}



ns_write "<li>Cleanup Conf Objects\n"
if {[im_table_exists im_timesheet_conf_objects]} {
    db_dml expense_invoices "delete from im_timesheet_conf_objects"
}

ns_write "<li>Cleanup Freelance RFQs\n"
if {[im_table_exists im_freelance_rfqs]} {
    db_dml expense_invoices "delete from im_object_freelance_skill_map"
    db_dml expense_invoices "delete from im_freelance_rfq_answers"
    db_dml expense_invoices "delete from im_freelance_rfqs"
}


ns_write "<li>Cleanup Simple Surveys\n"
if {[im_table_exists survsimp_responses]} {

    db_dml expense_invoices "
	delete from 
	survsimp_responses 
	where related_object_id in (
		select	object_id
		from	acs_objects
		where	object_type in ('im_project', 'im_company')
	)
    "

    db_dml expense_invoices "
	delete from 
	survsimp_responses 
	where related_context_id in (
		select	object_id
		from	acs_objects
		where	object_type in ('im_project', 'im_company')
	)
    "
}



ns_write "<li>Cleanup Conf Items\n"
if {[im_table_exists im_conf_items]} {
    db_dml remove_helpdesk_conf_item_dependency "update im_tickets set ticket_conf_item_id = null"
    db_dml remove_from_conf_items "delete from im_conf_items"

    set rels [db_list cr "
	select rel_id from 
	acs_rels, acs_objects 
	where object_id_two = object_id and object_type = 'im_conf_item'
    UNION
	select rel_id from 
	acs_rels, acs_objects 
	where object_id_one = object_id and object_type = 'im_conf_item'
    "]
    foreach rel_id $rels {
	db_string del_rel "select acs_rel__delete(:rel_id)"
    }
    db_dml remove_conf_item_objects "delete from acs_objects where object_type = 'im_conf_item'"
}


ns_write "<li>Cleanup Helpdesk\n"
if {[im_table_exists im_tickets]} {
    db_dml remove_from_tickets "delete from im_tickets"
}

ns_write "<li>Cleanup Release Items\n"
if {[im_table_exists im_release_items]} {
    db_dml remove_release_items "delete from im_release_items"
}

ns_write "<li>Cleanup SLA Parameters\n"
if {[im_table_exists im_sla_parameters]} {
    db_dml remove_release_items "delete from im_sla_parameters"
}

ns_write "<li>Cleanup SLA Service Hours\n"
if {[im_table_exists im_sla_service_hours]} {
    db_dml remove_release_items "delete from im_sla_service_hours"
}

ns_write "<li>Cleanup Gantt Projects\n"
if {[im_table_exists im_gantt_projects]} {
    db_dml remove_gantt_projects "delete from im_gantt_projects"
}
if {[im_table_exists im_gantt_persons]} {
    db_dml remove_gantt_persons "delete from im_gantt_persons"
}

ns_write "<li>Cleanup im_projects\n"
db_dml remove_from_biz_objects "delete from im_biz_objects where object_id in (select project_id from im_projects)"
db_dml remove_from_projects "delete from im_projects"

ns_write "<li>Cleanup im_companies\n"
db_dml remove_from_companies "delete from im_companies where company_path != 'internal'"

ns_write "<li>Cleanup im_offices\n"
db_dml remove_from_companies "delete from im_offices where office_id not in (select main_office_id from im_companies)"



ns_write "<li>Cleanup Projects & subclasses\n"
db_dml im_biz_object_members "delete from im_biz_object_members"
db_dml remove_from_projects "update im_projects set parent_id = null"
db_dml remove_from_projects "delete from im_timesheet_tasks"
db_dml remove_from_projects "delete from im_projects"
db_dml remove_from_companies "delete from im_companies where company_path != 'internal'"
db_dml remove_from_companies "delete from im_offices where office_id not in (select main_office_id from im_companies)"

if {[im_table_exists im_timesheet_task_dependencies]} {
    db_dml del_deps "delete from im_timesheet_task_dependencies"
}


ns_write "<li>Cleanup Translation\n"
if {[im_table_exists im_trans_tasks]} {
    db_dml trans_tasks "delete from im_trans_tasks"
    db_dml task_actions "delete from im_task_actions"
}

ns_write "<li>Cleanup Translation Quality\n"
if {[im_table_exists im_trans_quality_reports]} {
    db_dml trans_quality "delete from im_trans_quality_entries"
    db_dml trans_quality "delete from im_trans_quality_reports"
}

ns_write "<li>Cleanup Filestorage\n"
db_dml files "delete from im_fs_files"
db_dml forum "delete from im_fs_folder_status"
db_dml filestorage "delete from im_fs_actions"
db_dml im_fs_folder_perms "delete from im_fs_folder_perms"
db_dml forum "delete from im_fs_folders"


ns_write "<li>Cleanup TSearch2 Search Engine\n"
if {[im_table_exists im_search_objects]} {
    db_dml im_search_objects "delete from im_search_objects"
}

ns_write "<li>Cleanup Workflow\n"
db_dml wf_case_assignments "delete from wf_case_assignments"
db_dml wf_task_assignments "delete from wf_task_assignments"
db_dml wf_tokens "delete from wf_tokens"
db_dml wf_tasks "delete from wf_tasks"
db_dml wf_cases "delete from wf_cases"
db_dml wf_attribute_value_audits "delete from wf_attribute_value_audit"
db_dml wf_case_deadlines "delete from wf_case_deadlines"
db_dml wf_journal_entries "delete from journal_entries"


ns_write "<li>Cleanup Offices\n"
db_dml office_context "
	delete from acs_object_context_index where ancestor_id in (
		select object_id from acs_objects where object_type = 'im_office'
		and object_id not in (select office_id from im_offices)
	)
"
db_dml office_context "
	delete from acs_rels where object_id_one in (
		select object_id from acs_objects where object_type = 'im_office'
		and object_id not in (select office_id from im_offices)
	)
"
db_dml office_context "
	update acs_objects set context_id = null where context_id in (
		select object_id from acs_objects where object_type = 'im_office'
		and object_id not in (select office_id from im_offices)
	)
"
db_dml office_biz_objects "
	delete from im_biz_objects where object_id in (select object_id from acs_objects where object_type = 'im_office')
"
db_dml office_biz_objects "
	delete from parties where party_id in (select object_id from acs_objects where object_type = 'im_office')
"
db_dml rfq_objects "
	delete from acs_objects where object_type = 'im_office' 
	and object_id not in (select office_id from im_offices)
"



ns_write "<li>Cleanup Projects\n"
ns_write "<ul>\n"
ns_write "<li>Cleanup acs_object_context_index\n"
db_dml project_context "
	delete from acs_object_context_index where ancestor_id in (
		select object_id from acs_objects where object_type in (
 			'im_project', 'im_timesheet_task', 'im_ticket', 'im_company'
		)
	)
"
ns_write "<li>Cleanup acs_rels\n"
db_dml project_acs_rels "
	delete from acs_rels where object_id_one in (
		select object_id from acs_objects where object_type in (
			'im_project', 'im_timesheet_task', 'im_ticket', 'im_company'
		)
	)
"
ns_write "<li>Cleanup acs_objects.context_id\n"
db_dml project_context_null "
	update acs_objects set context_id = null where context_id in (
		select object_id from acs_objects where object_type in (
			'im_project', 'im_timesheet_task', 'im_ticket', 'im_company'
		)
	)
"
ns_write "<li>Cleanup acs_objects\n"
db_dml project_objects "delete from acs_objects where object_type = 'im_project'"
db_list ts_objects "select acs_object__delete(object_id) from acs_objects where object_type = 'im_timesheet_task'"
ns_write "</ul>\n"


ns_write "<li>Cleanup Companies\n"
ns_write "<ul>\n"
ns_write "<li>Cleanup acs_object_context_index\n"
db_dml remove_from_acs_object_context_index "
    delete from acs_object_context_index
    where object_id in (select object_id from acs_objects where object_type = 'im_company')
    or ancestor_id in (select object_id from acs_objects where object_type = 'im_company')
"
ns_write "<li>Cleanup parties\n"
db_dml company_parties "
    delete from parties where party_id in (select object_id from acs_objects where object_type = 'im_company')
"
ns_write "<li>Cleanup acs_rels\n"
db_dml remove_company_rfq_objects_from_acs_rels "
    delete from acs_rels
    where object_id_one in (select object_id from acs_objects where object_type = 'im_company')
    or object_id_two in (select object_id from acs_objects where object_type = 'im_company')
"
ns_write "<li>Cleanup acs_objects\n"
db_list remove_from_acs_objects "
	select	acs_object__delete(object_id) from acs_objects
	where	context_id in (
		select	object_id 
		from	acs_objects where object_type = 'im_company' and
			object_id not in (select company_id from im_companies)
	)
"
ns_write "<li>Cleanup acs_objects(2)\n"
db_list company_acs_objects "
	select	acs_object__delete(object_id)
	from	acs_objects
	where	object_type = 'im_company' and 
		object_id not in (select company_id from im_companies)
"
ns_write "</ul>\n"




db_dml del_biz_rels "delete from im_biz_object_members"
db_dml del_biz_rel_rels "delete from acs_rels where rel_type = 'im_biz_object_member'"
db_dml del_biz_rel_os "delete from acs_objects where object_type = 'im_biz_object_member'"


db_dml rfq_objects "delete from acs_objects where object_type = 'im_trans_task'"
db_dml rfq_objects "delete from acs_objects where object_type = 'journal_entry'"
db_dml rfq_objects "delete from acs_objects where object_type = 'im_freelance_rfq'"
db_dml rfq_objects "delete from acs_objects where object_type = 'im_freelance_rfq_answer'"
# db_dml rfq_objects "delete from acs_objects where object_type = 'workflow_case_log_entry'"
db_dml rfq_objects "delete from acs_objects where object_type = 'trans_edit_proof_wf'"
# select count(*) as cnt, object_type from acs_objects group by object_type order by cnt DESC;



# ------------------------------------------------------------
# Cleanup dangling objects
# ------------------------------------------------------------

ns_write "<li>Cleanup dangling RFQ objects\n"
db_list rfq_objects "select acs_object__delete(object_id) from acs_objects where object_type = 'im_freelance_rfq'"
db_dml rfq_objects "delete from acs_objects where object_type = 'im_freelance_rfq_answer'"
db_dml rfq_objects "delete from acs_objects where object_type = 'rfq_objects'"
db_list rfq_objects "select acs_object__delete(object_id) from acs_objects where object_type = 'acs_activity'"
db_dml remove_from_cal_itemsw "delete from cal_items where on_which_calendar in (select object_id from acs_objects where object_type = 'cal_item')"
db_list rfq_objects "select acs_object__delete(object_id) from acs_objects where object_type = 'cal_item'"


db_dml rfq_objects "delete from acs_objects where object_type = 'im_freelance_rfq'"
db_dml rfq_objects "delete from acs_objects where object_type = 'im_freelance_rfq_answer'"
db_dml rfq_objects "delete from acs_objects where object_type = 'rfq_objects'"
db_dml rfq_objects "delete from acs_objects where object_type = 'acs_activity'"
db_dml rfq_objects "delete from acs_objects where object_type = 'cal_item'"

ns_write "<li>Cleanup dangling objects<br>\n"
set object_infos [db_list_of_lists objects "
        select  object_id,
                object_type
        from    acs_objects
        where   object_type in (
                        'im_project',
                        'im_timesheet_task',
                        'im_office',
                        'content_item',
                        'relationship',
                        'acs_mail_body',
                        'im_biz_object_member',
                        'user',
                        'im_company',
                        'im_trans_task',
                        'acs_mail_multipart'
                )
"]
set cnt 0
foreach object_info $object_infos {
    set object_id [lindex $object_info 0]
    set object_type [lindex $object_info 1]

    if {0 == [expr $cnt % 17]} { ns_write ".\n" }
    catch { db_dml del_object "delete from acs_objects where object_id = :object_id" }
    incr cnt
}





# ------------------------------------------------------------
# Cleanup Demo Users except for SysAdmin & Current User
# ------------------------------------------------------------

ns_write "<li>Cleanup demo users<br>\n"
ns_write "<ul>\n"
ns_write "<li><font color=red>Please note that we can't delete the current user and neither the user 'System Administrator'</font>\n"

set user_ids [db_list users "
	select	person_id
	from	persons
	where	person_id not in (
			0,
			[ad_get_user_id],
			(select min(person_id) from persons where person_id > 0)
		)
"]


foreach id $user_ids {

  ns_write "<li>Nuking user \#$id ...\n"
  set error [im_user_nuke $id]
  if {"" == $error} {
      ns_write " successful\n"
  } else {
      ns_write "<br><font color=red>$error</font>\n"
  }

}

ns_write "</ul>\n"

ns_write "<li>Please manually rename the user 'System Administrator' to your name and email.\n"
ns_write "<li>To delete the remaining adminstrators, please remove them from the profile '\]po\[ Admins' and delete them via Admin - Delete Demo Data - Delete Demo Users.\n"



# ------------------------------------------------------------
# Render Footer
# ------------------------------------------------------------

ns_write "</ul><p>Finished Successfully</p>\n"

ns_write "
</ul>
[im_footer]
"

ad_script_abort

