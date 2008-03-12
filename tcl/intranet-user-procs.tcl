# /packages/intranet-core/tcl/intranet-user-procs.tcl
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
# See the GNU General Public License for more details.

# @author various@arsdigita.com
# @author frank.bergmann@project-open.com




ad_proc -public im_user_permissions { current_user_id user_id view_var read_var write_var admin_var } {
    Fill the "by-reference" variables read, write and admin
    with the permissions of $current_user_id on $user_id
} {
    upvar $view_var view
    upvar $read_var read
    upvar $write_var write
    upvar $admin_var admin

    set view 0
    set read 0
    set write 0
    set admin 0

    if {"" == $user_id} { return }
    if {"" == $current_user_id} { return }

    # Admins and creators can do everything
    set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]
    set creation_user_id [util_memoize "db_string creator {select creation_user from acs_objects where object_id = $user_id}"]
    if {$user_is_admin_p || $current_user_id == $creation_user_id} {
	set view 1
	set read 1
	set write 1
	set admin 1
	return
    }

    # Get the list of profiles of user_id (the one to be managed)
    # together with the information if current_user_id can read/write
    # it.
    # m.group_id are all the groups to whom user_id belongs
    set profile_perm_sql "
select
	m.group_id,
	im_object_permission_p(m.group_id, :current_user_id, 'view') as view_p,
	im_object_permission_p(m.group_id, :current_user_id, 'read') as read_p,
	im_object_permission_p(m.group_id, :current_user_id, 'write') as write_p,
	im_object_permission_p(m.group_id, :current_user_id, 'admin') as admin_p
from
	acs_objects o,
	group_distinct_member_map m
where
	m.member_id=:user_id
     	and m.group_id = o.object_id
	and o.object_type = 'im_profile'
"
    set first_loop 1
    db_foreach profile_perm_check $profile_perm_sql {
	ns_log Notice "im_user_permissions: $group_id: view=$view_p read=$read_p write=$write_p admin=$admin_p"
	if {$first_loop} {
	    # set the variables to 1 if current_user_id is member of atleast
	    # one group. Otherwise, an unpriviliged user could read the data
	    # of another unpriv user
	    set view 1
	    set read 1
	    set write 1
	    set admin 1
	}

	if {[string equal f $view_p]} { set view 0 }
	if {[string equal f $read_p]} { set read 0 }
	if {[string equal f $write_p]} { set write 0 }
	if {[string equal f $admin_p]} { set admin 0 }
	set first_loop 0
    }

    # Myself - I can read and write its data
	    if { $user_id == $current_user_id } { 
		set read 1
		set write 1
		set admin 0
    }


    if {$admin} {
		set read 1
		set write 1
    }
    if {$read} { set view 1 }

    ns_log Notice "im_user_permissions: cur=$current_user_id, user=$user_id, view=$view, read=$read, write=$write, admin=$admin"

}


ad_proc -public user_permissions { current_user_id user_id view_var read_var write_var admin_var } {
    Helper being called when calling dynamic permissions
    for objects (im_biz_objects...).<br>
    This procedure is identical to im_user_permissions.
} {
    upvar $view_var view
    upvar $read_var read
    upvar $write_var write
    upvar $admin_var admin

    im_user_permissions $current_user_id $user_id view read write admin
}


ad_proc -public im_sysadmin_user_default { } {
    Determines the default system Administrator account
    Just takes the lowest user_id from the members of
    the Admin group...
} {

    set user_id [util_memoize "db_string default_admin \"
        select
                min(user_id) as user_id
        from
                acs_rels ar,
                membership_rels mr,
		users u
        where
                ar.rel_id = mr.rel_id
                and u.user_id = ar.object_id_two
                and ar.object_id_one = [im_admin_group_id]
                and mr.member_state = 'approved'
    \" -default 0" 60]

    return $user_id
}




ad_proc -public im_employee_options { {include_empty 1} } {
    Cost provider options
} {
    set options [db_list_of_lists provider_options "
	select	im_name_from_user_id(user_id) as name, 
		user_id
        from	im_employees_active
	order by name
    "]
    if {$include_empty} { set options [linsert $options 0 { "" "" }] }
    return $options
}

ad_proc -public im_project_manager_options { 
    {-include_empty 1} 
    {-current_pm_id 0}
} {
    Cost provider options
} {
    set options [db_list_of_lists provider_options "
	select * from (
	        select	im_name_from_user_id(user_id) as name, user_id
	        from	im_employees_active
	    UNION
	        select	im_name_from_user_id(user_id) as name, user_id
	        from	users_active u,
			group_distinct_member_map gm
		where	u.user_id = gm.member_id
			and gm.group_id = [im_pm_group_id]
	    UNION
		select	im_name_from_user_id(user_id) as name, user_id
		from	users_active u
		where	u.user_id = :current_pm_id
	) t
	order by name
    "]
    if {$include_empty} { set options [linsert $options 0 { "" "" }] }
    return $options
}

ad_proc im_user_select { 
    {-include_empty_p 0}
    {-include_empty_name "All"}
    {-group_id 0 }
    select_name 
    { default "" } 
} {
    Returns an html select box named $select_name and defaulted to 
    $default with a list of all the available project_leads in 
    the system
} {
    if {0 == $group_id} { set group_id [im_employee_group_id] }

    # We need a "distinct" because there can be more than one
    # mapping between a user and a group, one for each role.
    #
    set bind_vars [ns_set create]
    ns_set put $bind_vars group_id $group_id
    set sql "
	select	u.user_id, 
		im_name_from_user_id(u.user_id) as name
	from
		users_active u,
		group_distinct_member_map m
	where
		u.user_id = m.member_id
		and m.group_id = :group_id
	order by 
		name
    "
    return [im_selection_to_select_box -translate_p 0 -include_empty_p $include_empty_p -include_empty_name $include_empty_name $bind_vars project_lead_list $sql $select_name $default]
}


ad_proc im_employee_select_multiple { select_name { defaults "" } { size "6"} {multiple ""}} {
    set bind_vars [ns_set create]
    set employee_group_id [im_employee_group_id]
    set sql "
select
	u.user_id,
	im_name_from_user_id(u.user_id) as employee_name
from
	registered_users u,
	group_distinct_member_map gm
where
	u.user_id = gm.member_id
	and gm.group_id = $employee_group_id
order by lower(im_name_from_user_id(u.user_id))
"
    return [im_selection_to_list_box -translate_p "0" $bind_vars category_select $sql $select_name $defaults $size $multiple]
}    



# ------------------------------------------------------
# User Community Component
# Show the most recent user registrations.
# This allows to detect duplicat registrations
# of users with multiple emails
# ------------------------------------------------------

ad_proc -public im_user_registration_component { current_user_id { max_rows 8} } {
    Shows the list of the last n registrations

    This allows to detect duplicat registrations
    of users with multiple emails
} {
    set date_format "YYYY-MM-DD"
    set bgcolor(0) " class=roweven"
    set bgcolor(1) " class=rowodd"
    set user_view_page "/intranet/users/view"
    set return_url [ad_conn url]?[ad_conn query]
    
    set user_id [ad_get_user_id]
    
    if {![im_permission $user_id view_user_regs]} { return "" }

    set rows_html ""
    set ctr 1
    db_foreach registered_users "" {

	regexp {(.*)\@(.*)} $email match email_name email_url
	set email_breakable "$email_name \@ $email_url"

	# Allow to approve non-approved members
	set approve_link ""
	if {"approved" != $member_state} { set approve_link "<a href=\"/acs-admin/users/member-state-change?member_state=approved&amp;[export_url_vars user_id return_url]\">[_ intranet-core.activate]</a>"
	}

	append rows_html "
<tr $bgcolor([expr $ctr % 2])>
  <td>$creation_date</td>
  <td><A href=\"$user_view_page?user_id=$user_id\">$name</A></td>
  <td><A href=\"mailto:$email\">$email_breakable</A></td>
  <td>$member_state $approve_link</td>
</tr>
"
	incr ctr
    }

    return "
<table border=0 cellspacing=1 cellpadding=1>
<tr class=rowtitle><td class=rowtitle align=center colspan=5>[_ intranet-core.Recent_Registrations]</td></tr>
<tr class=rowtitle>
  <td align=center class=rowtitle>[_ intranet-core.Date]</td>
  <td align=center class=rowtitle>[_ intranet-core.Name]</td>
  <td align=center class=rowtitle>[_ intranet-core.Email]</td>
  <td align=center class=rowtitle>[_ intranet-core.State]</td>
</tr>
$rows_html
<tr class=rowblank align=right>
  <td colspan=5>
    <a href=\"/intranet/users/index?view_name=user_community&amp;user_group_name=all&amp;order_by=Creation\">[_ intranet-core.more]</a>
  </td>
</tr>
</table>
"
}


# ------------------------------------------------------------------------
# functions for printing the org chart
# ------------------------------------------------------------------------

ad_proc im_print_employee {person rowspan} "print function for org chart" {
    set user_id [fst $person]
    set employee_name [snd $person]
    set currently_employed_p [thd $person]

# Removed job title display
#    set job_title [lindex $person 3]

    if { $currently_employed_p == "t" } {

# Removed job title display
#	if { $rowspan>=2 } {
#	    return "<a href=\"/intranet/users/view?[export_url_vars user_id]\">$employee_name</a><br><i>$job_title</i>\n"
#	} else {
	    return "<a href=\"/intranet/users/view?[export_url_vars user_id]\">$employee_name</a><br>\n"
#	}
    } else {
	return "<i>[_ intranet-core.Position_Vacant]</i>"
    }
}

ad_proc im_prune_org_chart {tree} "deletes all leaves where currently_employed_p is set to vacant position" {
    set result [list [head $tree]]
    # First, recursively process the sub-trees.
    foreach subtree [tail $tree] {
	set new_subtree [im_prune_org_chart $subtree]
	if { ![null_p $new_subtree] } {
	    lappend result $new_subtree
	}
    }
    # Now, delete vacant leaves.
    # We also delete vacant inner nodes that have only one child.
    # 1. if the tree only consists of one vacant node
    #    -> return an empty tree
    # 2. if the tree has a vacant root and only one child
    #    -> return the child 
    # 3. otherwise
    #    -> return the tree 
    if { [thd [head $result]] == "f" } {
	switch [llength $result] {
	    1       { return [list] }
	    2       { return [snd $result] }
	    default { return $result }
	}
    } else {
	return $result
    }
}



# ------------------------------------------------------------------------
# Nuke a User
# ------------------------------------------------------------------------


ad_proc -public im_user_nuke {user_id} { 
    Delete a user from the database -
    Extremely dangerous!
} {
    set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
    if {$user_is_admin_p} {
	return "User is an administrator - you can't nuke an administrator"
    }

    set result ""

    db_transaction {
	
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
    
	# general comments
	ns_log Notice "users/nuke2: general_comments"
	if {[db_table_exists general_comments]} {
	    db_dml delete_user_general_comments "delete from general_comments where object_id = :user_id"
	}

	ns_log Notice "users/nuke2: comments"
	if {[db_table_exists comments]} {
	    db_dml delete_user_comments "delete from comments where object_id = :user_id"
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
	db_dml invoice_references "update im_invoices set company_contact_id = null where company_contact_id = :user_id"

	set cost_infos [db_list_of_lists costs "select cost_id, object_type from im_costs, acs_objects where cost_id = object_id and (creation_user = :user_id or cause_object_id = :user_id)"]
	foreach cost_info $cost_infos {
	    set cost_id [lindex $cost_info 0]
	    set object_type [lindex $cost_info 1]
	    
	    ns_log Notice "users/nuke-2: deleting cost: ${object_type}__delete($cost_id)"
	    im_exec_dml del_cost "${object_type}__delete($cost_id)"
	}

	db_dml reset_cost_center_managers "update im_cost_centers set manager_id = null where manager_id = :user_id"
	
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
	db_dml remove_from_companies "update im_companies set accounting_contact_id = null where accounting_contact_id = :user_id"
	db_dml remove_from_companies "update im_companies set primary_contact_id = null where primary_contact_id = :user_id"
	db_dml remove_from_projects "update im_projects set supervisor_id = null where supervisor_id = :user_id"
	db_dml remove_from_projects "update im_projects set project_lead_id = null where project_lead_id = :user_id"
	
    	db_dml reassign_projects "update acs_objects set creation_user = :default_user where object_type = 'im_office' and creation_user = :user_id"
	db_dml reassign_projects "update acs_objects set creation_user = :default_user where object_type = 'im_company' and creation_user = :user_id"
	db_dml remove_from_companies "update im_offices set contact_person_id = null where contact_person_id = :user_id"


	# Freelance
	if {[db_table_exists im_freelance_skills]} {
	    db_dml trans_tasks "delete from im_freelance_skills where user_id = :user_id"
	    db_dml freelance "delete from im_freelancers where user_id = :user_id"
	    db_dml freelance_conf "update im_freelance_skills set confirmation_user_id = null where confirmation_user_id = :user_id"
	}

	
	# Translation
	if {[db_table_exists im_trans_tasks]} {

	    db_dml remove_from_projects "update im_projects set company_contact_id = null where company_contact_id = :user_id"

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
	    db_dml trans_quality "delete from im_trans_quality_reports where reviewer_id = :user_id"
	}
	
	# Filestorage
	db_dml filestorage "delete from im_fs_folder_status where user_id = :user_id"
	db_dml filestorage "delete from im_fs_actions where user_id = :user_id"
	db_dml filestorage "update im_fs_folders set object_id = null where object_id = :user_id"



	# Bug-Tracker
	db_dml bt_prefs "delete from bt_user_prefs where user_id = :user_id"
	db_dml bt_comps "update bt_components set maintainer = null where maintainer = :user_id"


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
	    db_dml update_dependent_employees "update im_employees set supervisor_id = null where supervisor_id = :user_id"
	    db_dml delete_employees "delete from im_employees where employee_id = :user_id"
	}
	
	ns_log Notice "users/nuke2: Main user tables"
	db_dml update_creation_users "update acs_objects set creation_user = null where creation_user = :user_id"
	db_dml delete_user "delete from users where user_id = :user_id"
	db_dml delete_user "delete from persons where person_id = :user_id"
	db_dml delete_user "delete from parties where party_id = :user_id"
	db_dml delete_user "delete from acs_objects where object_id = :user_id"

	# Returning empty string - everything went OK
	return ""	

    } on_error {
	
	set detailed_explanation ""
	if {[ regexp {integrity constraint \([^.]+\.([^)]+)\)} $errmsg match constraint_name]} {
	    set sql "
		select table_name 
		from user_constraints 
		where constraint_name=:constraint_name
	    "
	    db_foreach user_constraints_by_name $sql {
		set detailed_explanation "<p>
	    [_ intranet-core.lt_It_seems_the_table_we]"
	    }
	}

	# Return the error string - indicates that there were errors    
	set result "
	[_ intranet-core.lt_The_nuking_of_user_us]
	$detailed_explanation<p>
	[_ intranet-core.lt_For_good_measure_here]
	<blockquote><pre>\n$errmsg\n</pre></blockquote>
        "
    }

    return $result
}

