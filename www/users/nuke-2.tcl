# /packages/intranet-core/www/users/nuke-2.tcl
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

    @author various@arsdigita.com
    @author frank.bergmann@project-open.com
} {
    user_id:integer,notnull
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
im_user_permissions $current_user_id $user_id view read write admin

if {!$admin} {
    ad_return_complaint "You need to have administration rights for this user."
    return
}


# ---------------------------------------------------------------
# Delete
# ---------------------------------------------------------------

# if this fails, it will probably be because the installation has 
# added tables that reference the users table


with_transaction {
    # education module
    # TO DO: IF YOU UNCOMMENT THESE, MAKE USER_ID A BIND VARIABLE
    # This is assumes that all info added by a user is no longer wanted
    #db_dml unused "delete from edu_department_info where last_modifiying_user = :user_id"
    #db_dml unused "delete from edu_subjects where last_modifiying_user = :user_id"
    #db_dml unused "delete from edu_class_info where last_modifiying_user = :user_id"
    #db_dml unused "delete from edu_grades where last_modifiying_user = :user_id"
    #db_dml unused "delete from edu_student_tasks where assigned_by = $user_id"
    #db_dml unused "delete from edu_student_answers where student_id = $user_id"
    #db_dml unused "delete from edu_student_answers where student_id = $user_id"
    #db_dml unused "delete from edu_student_evaluations where student_id = $user_id"
    #db_dml unused "delete from edu_student_evaluations where grader_id = $user_id"
    #db_dml unused "delete from edu_student_evaluations where last_modifying_user = $user_id"
    #db_dml unused "delete from edu_task_instances where approving_user = $user_id"
    #db_dml unused "delete from edu_task_user_map where student_id = $user_id"
    #db_dml unused "delete from edu_appointments where user_id = $user_id"
    #db_dml unused "delete from edu_appointments_scheduled where user_id = $user_id"
    #db_dml unused "delete from portal_weather where user_id = $user_id"
    #db_dml unused "delete from portal_stocks where user_id = $user_id"
    #db_dml unused "delete from edu_calendar where owner = $user_id"
    #db_dml unused "delete from edu_calendar where creation_user = $user_id"
    

    # bboard system
    ns_log Notice "users/nuke2: bboard_email_alerts"
    if {[db_table_exists bboard_email_alerts]} {
	db_dml delete_user_bboard_email_alerts "delete from bboard_email_alerts where user_id = :user_id"
	db_dml delete_user_bboard_thread_email_alerts "delete from bboard_thread_email_alerts where user_id = :user_id"
	db_dml delete_user_bboard_unified "delete from bboard_unified where user_id = :user_id"
    
	# deleting from bboard is hard because we have to delete not only a user's
	# messages but also subtrees that refer to them
	bboard_delete_messages_and_subtrees_where  -bind [list user_id $user_id] "user_id = :user_id"
    }
    
    # let's do the classifieds now
    ns_log Notice "users/nuke2: classified_auction_bids"
    if {[db_table_exists classified_auction_bids]} {
	db_dml delete_user_classified_auction_bids "delete from classified_auction_bids where user_id = :user_id"
	db_dml delete_user_classified_ads "delete from classified_ads where user_id = :user_id"
	db_dml delete_user_classified_email_alerts "delete from classified_email_alerts where user_id = :user_id"
	db_dml delete_user_neighbor_to_neighbor_comments "
	delete from general_comments 
	where
		on_which_table = 'neighbor_to_neighbor'
		and on_what_id in (select neighbor_to_neighbor_id 
	from neighbor_to_neighbor 
	where poster_user_id = :user_id)"
	db_dml delete_user_neighbor_to_neighbor "delete from neighbor_to_neighbor where poster_user_id = :user_id"
    }

    # now the calendar
    ns_log Notice "users/nuke2: calendar"
    if {[db_table_exists calendar]} {
	db_dml delete_user_calendar "delete from calendar where creation_user = :user_id"
    }

    # contest tables are going to be tough
    ns_log Notice "users/nuke2: entrants_table_name"
    if {[db_table_exists entrants_table_name]} {
	set all_contest_entrants_tables [db_list unused "select entrants_table_name from contest_domains"]
	foreach entrants_table $all_contest_entrants_tables {
	    db_dml delete_user_contest_entries "delete from $entrants_table where user_id = :user_id"
	}
    }

    # spam history
    ns_log Notice "users/nuke2: spam_history"
    if {[db_table_exists spam_history]} {
	db_dml delete_user_spam_history "delete from spam_history where creation_user = :user_id"
	db_dml delete_user_spam_history_sent "update spam_history set last_user_id_sent = NULL
                    where last_user_id_sent = :user_id"
    }

    # calendar
    ns_log Notice "users/nuke2: calendar_categories"
    if {[db_table_exists calendar_categories]} {
	db_dml delete_user_calendar_categories "delete from calendar_categories where user_id = :user_id"
    }

    # sessions
    ns_log Notice "users/nuke2: sec_sessions"
    if {[db_table_exists sec_sessions]} {
	db_dml delete_user_sec_sessions "delete from sec_sessions where user_id = :user_id"
	db_dml delete_user_sec_login_tokens "delete from sec_login_tokens where user_id = :user_id"
    }
    
    # general stuff
    ns_log Notice "users/nuke2: general_comments"
    if {[db_table_exists general_comments]} {
	db_dml delete_user_general_comments "delete from general_comments where user_id = :user_id"
	db_dml delete_user_comments "delete from comments where user_id = :user_id"
    }
    ns_log Notice "users/nuke2: links"
    if {[db_table_exists links]} {
	db_dml delete_user_links "delete from links where user_id = :user_id"
    }
    ns_log Notice "users/nuke2: chat_msgs"
    if {[db_table_exists chat_msgs]} {
	db_dml delete_user_chat_msgs "delete from chat_msgs where creation_user = :user_id"
    }
    ns_log Notice "users/nuke2: query_strings"
    if {[db_table_exists query_strings]} {
	db_dml delete_user_query_strings "delete from query_strings where user_id = :user_id"
    }
    ns_log Notice "users/nuke2: user_curriculum_map"
    if {[db_table_exists user_curriculum_map]} {
	db_dml delete_user_user_curriculum_map "delete from user_curriculum_map where user_id = :user_id"
    }
    ns_log Notice "users/nuke2: user_content_map"
    if {[db_table_exists user_content_map]} {
	db_dml delete_user_user_content_map "delete from user_content_map where user_id = :user_id"
    }
    ns_log Notice "users/nuke2: user_group_map"
    if {[db_table_exists user_group_map]} {
	db_dml delete_user_user_group_map "delete from user_group_map where user_id = :user_id"
    }

    ns_log Notice "users/nuke2: users_interests"
    if {[db_table_exists users_interests]} {
	db_dml delete_user_users_interests "delete from users_interests where user_id = :user_id"
    }

    ns_log Notice "users/nuke2: users_charges"
    if {[db_table_exists users_charges]} {
	db_dml delete_user_users_charges "delete from users_charges where user_id = :user_id"
    }

    ns_log Notice "users/nuke2: users_demographics"
    if {[db_table_exists users_demographics]} {
	db_dml set_referred_null_user_users_demographics "update users_demographics set referred_by = null where referred_by = :user_id"
	db_dml delete_user_users_demographics "delete from users_demographics where user_id = :user_id"
    }

    ns_log Notice "users/nuke2: users_preferences"
    if {[db_table_exists users_preferences]} {
	db_dml delete_user_users_preferences "delete from users_preferences where user_id = :user_id"
    }

    if {[db_table_exists user_preferences]} {
	db_dml delete_user_user_preferences "delete from user_preferences where user_id = :user_id"
    }

    if {[db_table_exists users_contact]} {
	db_dml delete_user_users_contact "delete from users_contact where user_id = :user_id"
    }

    # Permissions
    db_dml perms "delete from acs_permissions where grantee_id = :user_id"
    db_dml perms "delete from acs_permissions where object_id = :user_id"


    # Reassign objects to a default user...
    set default_user 0
    db_dml reassign_objects "update acs_objects set modifying_user = :default_user where modifying_user = :user_id"
    db_dml reassign_projects "update acs_objects set creation_user = :default_user where object_type = 'im_project' and creation_user = :user_id"
    db_dml reassign_cr_revisions "update acs_objects set creation_user = :default_user where object_type = 'content_revision' and creation_user = :user_id"


    # Lang_message_audit
    db_dml lang_message_audit "update lang_messages_audit set overwrite_user = null where overwrite_user = :user_id"
    db_dml lang_message "update lang_messages set creation_user = null where creation_user = :user_id"

    # Deleting cost entries in acs_objects that are "dangeling", i.e. that don't have an
    # entry in im_costs. These might have been created during manual deletion of objects
    # Very dirty...
    db_dml dangeling_costs "delete from acs_objects where object_type = 'im_cost' and object_id not in (select cost_id from im_costs)"

    # Costs
    set cost_infos [db_list_of_lists costs "select cost_id, object_type from im_costs, acs_objects where cost_id = object_id and (creation_user = :user_id or cause_object_id = :user_id)"]
    foreach cost_info $cost_infos {
	set cost_id [lindex $cost_info 0]
	set object_type [lindex $cost_info 1]

	ns_log Notice "users/nuke-2: deleting cost: ${object_type}__delete($cost_id)"
	im_exec_dml del_cost "${object_type}__delete($cost_id)"
    }


    # Forum
    db_dml forum "delete from im_forum_topic_user_map where user_id = :user_id"
    db_dml forum "update im_forum_topics set owner_id = :default_user where owner_id = :user_id"
    db_dml forum "update im_forum_topics set asignee_id = null where asignee_id = :user_id"
    db_dml forum "update im_forum_topics set object_id = :default_user where object_id = :user_id"


    # Timesheet
    db_dml timesheet "delete from im_hours where user_id = :user_id"
    db_dml timesheet "delete from im_user_absences where owner_id = :user_id"


    # Remove user from business objects that we don't want to delete...
    db_dml remove_from_companies "update im_companies set manager_id = null where manager_id = :user_id"
    db_dml remove_from_projects "update im_projects set supervisor_id = null where supervisor_id = :user_id"
    db_dml remove_from_projects "update im_projects set project_lead_id = null where project_lead_id = :user_id"


    db_dml reassign_projects "update acs_objects set creation_user = :default_user where object_type = 'im_office' and creation_user = :user_id"
    db_dml reassign_projects "update acs_objects set creation_user = :default_user where object_type = 'im_company' and creation_user = :user_id"
    db_dml remove_from_companies "update im_offices set contact_person_id = null where contact_person_id = :user_id"



    # Translation
    if {[db_table_exists im_trans_tasks]} {
	db_dml trans_tasks "update im_trans_tasks set trans_id = null where trans_id = :user_id"
	db_dml trans_tasks "update im_trans_tasks set edit_id = null where edit_id = :user_id"
	db_dml trans_tasks "update im_trans_tasks set proof_id = null where proof_id = :user_id"
	db_dml trans_tasks "update im_trans_tasks set other_id = null where other_id = :user_id"
	db_dml task_actions "delete from im_task_actions where user_id = :user_id"
    }

    if {[db_table_exists im_trans_quality_reports]} {
	db_dml trans_quality "delete from im_trans_quality_entries where report_id in (
	    select report_id from im_trans_quality_reports where reviewer_id = :user_id
        )"
	db_dml trans_quality "delete from im_trans_quality_reports where reviewer_id = :user_id";
    }


    # Filestorage
    db_dml forum "delete from im_fs_folder_status where user_id = :user_id"
    db_dml filestorage "delete from im_fs_actions where user_id = :user_id"

    set rels [db_list rels "select rel_id from acs_rels where object_id_one = :user_id or object_id_two = :user_id"]
    foreach rel_id $rels {
	db_dml del_rels "delete from group_element_index where rel_id = :rel_id"
	db_dml del_rels "delete from im_biz_object_members where rel_id = :rel_id"
	db_dml del_rels "delete from membership_rels where rel_id = :rel_id"
	db_dml del_rels "delete from acs_rels where rel_id = :rel_id"
	db_dml del_rels "delete from acs_objects where object_id = :rel_id"
    }

    db_dml party_approved_member_map "delete from party_approved_member_map where party_id = :user_id"
    db_dml party_approved_member_map "delete from party_approved_member_map where member_id = :user_id"

    if {[db_table_exists im_employees]} {
	db_dml delete_employees "delete from im_employees where employee_id = :user_id"
    }

    ns_log Notice "users/nuke2: Main user tables"
    db_dml delete_user "delete from users where user_id = :user_id"
    db_dml delete_user "delete from persons where person_id = :user_id"
    db_dml delete_user "delete from parties where party_id = :user_id"
    db_dml delete_user "delete from acs_objects where object_id = :user_id"

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

set return_to_admin_link "<a href=\"/intranet/users/\">[_ intranet-core.lt_return_to_user_admini]</a>" 

set page_content "[ad_admin_header "[_ intranet-core.Done]"]

<h2>[_ intranet-core.Done]</h2>

<hr>

[_ intranet-core.lt_Weve_nuked_user_user_]

[ad_admin_footer]
"


doc_return  200 text/html $page_content
