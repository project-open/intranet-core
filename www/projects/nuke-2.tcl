# /packages/intranet-core/www/projects/nuke-2.tcl
#
# Copyright (C) 1998-2004 various parties
# The code is based on ArsDigita ACS 3.4
#
# This program is free software. You can redistribute it
# and/or modify it under the terms of the GNU General
# Public License as published by the Free Software Foundation;
# either version 2 of the License, or (at your option)
# any later version. This program is distributed in the
# hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.

ad_page_contract {
    Remove a user from the system completely

    @author frank.bergmann@project-open.com
} {
    project_id:integer,notnull
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
im_project_permissions $current_user_id $project_id view read write admin

if {!$admin} {
    ad_return_complaint "You need to have administration rights for this project."
    return
}


# ---------------------------------------------------------------
# Delete
# ---------------------------------------------------------------

# if this fails, it will probably be because the installation has 
# added tables that reference the users table

set user_id "project_id"

with_transaction {
    
    # Permissions
    ns_log Notice "projects/nuke-2: acs_permissions"
    db_dml perms "delete from acs_permissions where object_id = :project_id"

    # Deleting cost entries in acs_objects that are "dangeling", i.e. that don't have an
    # entry in im_costs. These might have been created during manual deletion of objects
    # Very dirty...
    ns_log Notice "projects/nuke-2: dangeling_costs"
    db_dml dangeling_costs "delete from acs_objects where object_type = 'im_cost' and object_id not in (select cost_id from im_costs)"


    # Costs
    set cost_infos [db_list_of_lists costs "select cost_id, object_type from im_costs, acs_objects where cost_id = object_id and project_id = :project_id"]
    foreach cost_info $cost_infos {
	set cost_id [lindex $cost_info 0]
	set object_type [lindex $cost_info 1]
	ns_log Notice "projects/nuke-2: deleting cost: ${object_type}__delete($cost_id)"
	im_exec_dml del_cost "${object_type}__delete($cost_id)"
    }


    # Forum
    ns_log Notice "projects/nuke-2: im_forum_topic_user_map"
    db_dml forum "
	delete from im_forum_topic_user_map 
	where topic_id in (
		select topic_id 
		from im_forum_topics 
		where object_id = :project_id
	)"
    ns_log Notice "projects/nuke-2: im_forum_topics"
    db_dml forum "delete from im_forum_topics where object_id = :project_id"


    # Timesheet
    ns_log Notice "projects/nuke-2: im_hours"
    db_dml timesheet "delete from im_hours where project_id = :project_id"


    # Translation Quality
    ns_log Notice "projects/nuke-2: im_trans_quality_entries"
    if {[db_table_exists im_trans_quality_reports]} {
	db_dml trans_quality "delete from im_trans_quality_entries where report_id in (
	    select report_id from im_trans_quality_reports where task_id in (select task_id from im_trans_tasks where project_id = :project_id)
        )"
	ns_log Notice "projects/nuke-2: im_trans_quality_reports"
	db_dml trans_quality "delete from im_trans_quality_reports where task_id in (select task_id from im_trans_tasks where project_id = :project_id)";
    }

    # Translation
    ns_log Notice "projects/nuke-2: im_task_actions"
    db_dml task_actions "
	delete from im_task_actions 
	where task_id in (
		select task_id 
		from im_trans_tasks
		where project_id = :project_id
	)"
    ns_log Notice "projects/nuke-2: im_trans_tasks"
    db_dml trans_tasks "delete from im_trans_tasks where project_id = :project_id"

    db_dml project_target_languages "delete from im_target_languages where project_id = :project_id"

    # Filestorage
    ns_log Notice "projects/nuke-2: im_fs_folder_status"
    db_dml filestorage "delete from im_fs_folder_status where folder_id in (select folder_id from im_fs_folders where object_id = :project_id)"
    ns_log Notice "projects/nuke-2: im_fs_folders"
    db_dml filestorage "delete from im_fs_folders where object_id = :project_id"


    ns_log Notice "projects/nuke-2: rels"
    set rels [db_list rels "select rel_id from acs_rels where object_id_one = :project_id or object_id_two = :project_id"]
    foreach rel_id $rels {
	db_dml del_rels "delete from group_element_index where rel_id = :rel_id"
	db_dml del_rels "delete from im_biz_object_members where rel_id = :rel_id"
	db_dml del_rels "delete from membership_rels where rel_id = :rel_id"
	db_dml del_rels "delete from acs_rels where rel_id = :rel_id"
	db_dml del_rels "delete from acs_objects where object_id = :rel_id"
    }

    ns_log Notice "projects/nuke-2: party_approved_member_map"
    db_dml party_approved_member_map "delete from party_approved_member_map where party_id = :project_id"
    db_dml party_approved_member_map "delete from party_approved_member_map where member_id = :project_id"


    ns_log Notice "users/nuke2: Main tables"

    db_dml parent_projects "update im_projects set parent_id = null where parent_id = :project_id"
    db_dml delete_projects "delete from im_projects where project_id = :project_id"

} {
    
    set detailed_explanation ""

    if {[ regexp {integrity constraint \([^.]+\.([^)]+)\)} $errmsg match constraint_name]} {
	
	set sql "select table_name from user_constraints 
	where constraint_name=:constraint_name"

	db_foreach user_constraints_by_name $sql {
	    set detailed_explanation "<p>
	    [_ intranet-core.lt_It_seems_the_table_we]"
	}
    }

    ad_return_error "[_ intranet-core.Failed_to_nuke]" "[_ intranet-core.lt_The_nuking_of_user_us]

$detailed_explanation

<p>

[_ intranet-core.lt_For_good_measure_here]

<blockquote>
<pre>
$errmsg
</pre>
</blockquote>"
    return
}

set return_to_admin_link "<a href=\"/intranet/projects/\">[_ intranet-core.lt_return_to_user_admini]</a>" 

set page_content "[ad_admin_header "[_ intranet-core.Done]"]

<h2>[_ intranet-core.Done]</h2>

<hr>

[_ intranet-core.lt_Weve_nuked_user_user_]

[ad_admin_footer]
"


doc_return  200 text/html $page_content
