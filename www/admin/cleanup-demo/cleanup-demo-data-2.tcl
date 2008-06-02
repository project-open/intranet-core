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

ns_write "
<font color=red><p>
This script does not cleanup demo users.<br>
After running this script, please go to Admin -&gt; Delete Demodata -&gt;
Delete Demo Users to delete selected users.
</font>
"

ns_write "<ul>\n"

# ---------------------------------------------------------------
# Delete all data
# ---------------------------------------------------------------

ns_write "<li>Cleanup existing security tokens.\n"
ns_write "A new set of tokens will be generated with the next server restart\n"
db_dml delete_sec_tokens "delete from secret_tokens"
db_string reset_token_seq "SELECT pg_catalog.setval('t_sec_security_token_id_seq', 1, true)"


ns_write "<li>Cleanup bulletin board email alersts\n"
if {[db_table_exists bboard_email_alerts]} {
    db_dml delete_user_bboard_email_alerts "delete from bboard_email_alerts"
    db_dml delete_user_bboard_thread_email_alerts "delete from bboard_thread_email_alerts"
    db_dml delete_user_bboard_unified "delete from bboard_unified"
}
    
ns_write "<li>Cleanup classified adss\n"
if {[db_table_exists classified_auction_bids]} {
    db_dml delete_user_classified_auction_bids "delete from classified_auction_bids"
    db_dml delete_user_classified_ads "delete from classified_ads"
    db_dml delete_user_classified_email_alerts "delete from classified_email_alerts"
    db_dml delete_user_neighbor_to_neighbor_comments "delete from general_comments"
    db_dml delete_user_neighbor_to_neighbor "delete from neighbor_to_neighbor"
}

ns_write "<li>Cleanup user calendars\n"
if {[db_table_exists calendar]} {
    db_dml delete_user_calendar "delete from calendar"
}

ns_write "<li>Cleanup entrants_table_name\n"
if {[db_table_exists entrants_table_name]} {
    set all_contest_entrants_tables [db_list unused "select entrants_table_name from contest_domains"]
    foreach entrants_table $all_contest_entrants_tables {
	db_dml delete_user_contest_entries "delete from $entrants_table"
    }
}

ns_write "<li>Cleanup spam history\n"
ns_log Notice "users/nuke2: spam_history"
if {[db_table_exists spam_history]} {
    db_dml delete_user_spam_history_sent "update spam_history set last_user_id_sent = NULL"
    db_dml delete_user_spam_history "delete from spam_history"
}

ns_write "<li>Cleanup calendar items\n"
ns_write "<ul>\n"

if {[db_table_exists calendars]} {

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
    foreach oid $cal_objects {
	ns_write ".\n"
	catch { db_dml del_cal_o "delete from acs_objects where object_id = :oid" } err_msg
    }
}
ns_write "</ul>\n"

ns_write "<li>Cleanup calendar_categories\n"
if {[db_table_exists calendar_categories]} {
    db_dml delete_user_calendar_categories "delete from calendar_categories"
}

ns_write "<li>Cleanup sessions\n"
if {[db_table_exists sec_sessions]} {
#    db_dml delete_user_sec_sessions "delete from sec_sessions"
#    db_dml delete_user_sec_login_tokens "delete from sec_login_tokens"
}

ns_write "<li>Cleanup general comments\n"
if {[db_table_exists general_comments]} {
    db_dml delete_user_general_comments "delete from general_comments"
    db_dml delete_user_comments "delete from comments"
}

ns_write "<li>Cleanup links\n"
if {[db_table_exists links]} {
    db_dml delete_user_links "delete from links"
}

ns_write "<li>Cleanup chat_msgs\n"
if {[db_table_exists chat_msgs]} {
    db_dml delete_user_chat_msgs "delete from chat_msgs"
}

ns_write "<li>Cleanup query_strings\n"
if {[db_table_exists query_strings]} {
    db_dml delete_user_query_strings "delete from query_strings"
}

ns_write "<li>Cleanup user_curriculum_map\n"
if {[db_table_exists user_curriculum_map]} {
    db_dml delete_user_user_curriculum_map "delete from user_curriculum_map"
}

ns_write "<li>Cleanup user_content_map\n"
if {[db_table_exists user_content_map]} {
    db_dml delete_user_user_content_map "delete from user_content_map"
}

ns_write "<li>Cleanup user_group_map\n"
if {[db_table_exists user_group_map]} {
    db_dml delete_user_user_group_map "delete from user_group_map"
}

ns_write "<li>Cleanup users_interests\n"
if {[db_table_exists users_interests]} {
    db_dml delete_user_users_interests "delete from users_interests"
}

ns_write "<li>Cleanup users_charges\n"
if {[db_table_exists users_charges]} {
    db_dml delete_user_users_charges "delete from users_charges"
}

ns_write "<li>Cleanup users_demographics\n"
if {[db_table_exists users_demographics]} {
    db_dml set_referred_null_user_users_demographics "update users_demographics set referred_by = null"
    db_dml delete_user_users_demographics "delete from users_demographics"
}

#ns_write "<li>Cleanup users_preferences\n"
#if {[db_table_exists users_preferences]} {
#    db_dml delete_user_users_preferences "delete from users_preferences"
#}
#
#ns_write "<li>Cleanup users_contact\n"
#if {[db_table_exists users_contact]} {
#    db_dml delete_user_users_contact "delete from users_contact"
#}

ns_write "<li>Cleanup im_component_plugin_user_map\n"
if {[db_table_exists im_component_plugin_user_map]} {
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



ns_write "<li>Cleanup im_payments\n"
db_dml payments "delete from im_payments"
ns_write "<li>Cleanup im_payments_audit\n"
db_dml im_payments_audit "delete from im_payments_audit"

ns_write "<li>Cleanup dangeling_costs\n"
db_dml dangeling_costs "delete from acs_objects where object_type = 'im_cost' and object_id not in (select cost_id from im_costs)"

# Timesheet
ns_write "<li>Cleanup im_hours - set cost_id = null\n"
db_dml timesheet_cost_refs "update im_hours set cost_id = null"

# Costs
ns_write "<li>Cleanup costs<br>\n"
set cost_infos [db_list_of_lists costs "select cost_id, object_type from im_costs, acs_objects where cost_id = object_id"]
foreach cost_info $cost_infos {
    set cost_id [lindex $cost_info 0]
    set object_type [lindex $cost_info 1]
    
    ns_write ".\n"
    ns_log Notice "users/nuke-2: deleting cost: ${object_type}__delete($cost_id)"
    im_exec_dml del_cost "${object_type}__delete($cost_id)"
}

ns_write "<li>Cleanup dangeling_costs\n"
db_dml dangeling_costs "delete from acs_objects where object_type = 'im_cost' and object_id not in (select cost_id from im_costs)"


ns_write "<li>Cleanup Forum\n"
db_dml im_forum_topic_user_map "delete from im_forum_topic_user_map"
db_dml im_forum_topic_user_map "delete from im_forum_topic_user_map"
db_dml forum "delete from im_forum_topics"

# Never Ever!
# The folders are part of the base configuration that is required
# db_dml im_forum_folders "delete from im_forum_folders"


ns_write "<li>Cleanup im_hours\n"
db_dml timesheet "delete from im_hours"
ns_write "<li>Cleanup im_user_absences\n"
db_dml timesheet "delete from im_user_absences"

ns_write "<li>Cleanup im_timesheet_prices\n"
if {[db_table_exists im_timesheet_prices]} {
    db_dml im_timsheet_prices "delete from im_timesheet_prices"
}


ns_write "<li>Cleanup im_trans_quality_reports\n"
if {[db_table_exists im_trans_quality_reports]} {
    db_dml im_trans_quality_entries "delete from im_trans_quality_entries"
    db_dml im_trans_quality_reports "delete from im_trans_quality_reports"
}

ns_write "<li>Cleanup Translation\n"
if {[db_table_exists im_trans_tasks]} {
    db_dml im_target_languages "delete from im_target_languages"
    db_dml im_task_actions "delete from im_task_actions"
    db_dml im_trans_tasks "delete from im_trans_tasks"
    db_dml im_trans_prices "delete from im_trans_prices"
}

# Remove user from business objects that we don't want to delete...
ns_write "<li>Cleanup im_biz_object_members\n"
db_dml im_biz_object_members "delete from im_biz_object_members"
ns_write "<li>Cleanup im_projects\n"
db_dml remove_from_projects "update im_projects set parent_id = null"
ns_write "<li>Cleanup im_timesheet_tasks\n"
db_dml remove_from_projects "delete from im_timesheet_tasks"
ns_write "<li>Cleanup im_timesheet_task_dependencies\n"
db_dml remove_from_projects "delete from im_timesheet_task_dependencies"

ns_write "<li>Cleanup im_projects\n"
db_dml remove_from_projects "delete from im_projects"
ns_write "<li>Cleanup im_companies\n"
db_dml remove_from_companies "delete from im_companies where company_path != 'internal'"
ns_write "<li>Cleanup im_offices\n"
db_dml remove_from_companies "delete from im_offices where office_id not in (select main_office_id from im_companies)"


ns_write "<li>Cleanup im_trans_tasks\n"
if {[db_table_exists im_trans_tasks]} {
    db_dml trans_tasks "delete from im_trans_tasks"
    db_dml task_actions "delete from im_task_actions"
}

ns_write "<li>Cleanup im_trans_quality_reports\n"
if {[db_table_exists im_trans_quality_reports]} {
    db_dml trans_quality "delete from im_trans_quality_entries"
    db_dml trans_quality "delete from im_trans_quality_reports";
}

ns_write "<li>Cleanup Indicators\n"
if {[db_table_exists im_indicator_results]} {
    db_dml indicator_results "delete from im_indicator_results"
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


ns_write "<li>Cleanup im_search_objects\n"
if {[db_table_exists im_search_objects]} {
    db_dml im_search_objects "delete from im_search_objects"
}

ns_write "<li>Cleanup search_observer_queue\n"
if {[db_table_exists search_observer_queue]} {
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



# ------------------------------------------------------------
# Cleanup dangling objects 
# ------------------------------------------------------------

ns_write "<li>Cleanup dangling objects<br>\n"
set object_infos [db_list_of_lists objects "
	select	object_id,
		object_type 
	from	acs_objects
	where	object_type in (
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
foreach object_info $object_infos {
    set object_id [lindex $object_info 0]
    set object_type [lindex $object_info 1]
    
    ns_write ".\n"
    catch { db_dml del_object "delete from acs_objects where object_id = :object_id" }
}


# ------------------------------------------------------------
# Render Footer
# ------------------------------------------------------------

ns_write "
</ul>
[im_footer]
"

ad_script_abort

