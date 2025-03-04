# /packages/intranet-core/tcl/intranet-permissions-procs.tcl
#
# Copyright (C) 2004 various authors
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

ad_library {
    ]project-open[specific permissions routines.
    The P/O permission model is based on the OpenACS model,
    extending it by several concepts:

    @author various@arsdigita.com
    @author frank.bergmann@project-open.com
}

ad_proc -public im_biz_object_role_full_member {} { return 1300 }
ad_proc -public im_biz_object_role_project_manager {} { return 1301 }
ad_proc -public im_biz_object_role_key_account {} { return 1302 }
ad_proc -public im_biz_object_role_office_admin {} { return 1303 }
# The final customer of a project when the invoicing customer is in the middle
ad_proc -public im_biz_object_role_final_customer {} { return 1304 }
# A generic association between business objects.
# Don't know what this might be good for in the future...
ad_proc -public im_biz_object_role_generic {} { return 1305 }
# Associated Email
ad_proc -public im_biz_object_role_email {} { return 1306 }
ad_proc -public im_biz_object_role_consultant {} { return 1307 }
ad_proc -public im_biz_object_role_trainer {} { return 1308 }
ad_proc -public im_biz_object_role_conf_item_manager {} { return 1309 }



ad_proc -public im_biz_object_url { object_id {url_type "view"} } {
    Returns a URL to a page to view a specific object_id,
    independent of the object type.
    @param object_id
    @param url_tpye is "view" or "edit", according to what you
	want to do with the object.
} {
    im_security_alert_check_alphanum -location "im_biz_object_url: url_type" -value $url_type
    set url [util_memoize [list db_string object_type_url "
    	select	url
	from	im_biz_object_urls u,
		acs_objects o
	where	o.object_id = $object_id
		and o.object_type = u.object_type
		and u.url_type = '$url_type'
    " -default ""]]
    return "$url$object_id"
}


ad_proc -public im_biz_object_member_p { user_id object_id } {
    Returns >0 if the user has some type of relationship with
    the specified object.
} {
    return [util_memoize [list im_biz_object_member_p_helper $user_id $object_id] 60]
}

ad_proc -public im_biz_object_member_p_helper { user_id object_id } {
    Returns >0 if the user has some type of relationship with
    the specified object.
} {
    set sql "
	select count(*)
	from acs_rels
	where	object_id_one = :object_id and 
		(	object_id_two = :user_id
		OR	object_id_two in (
				select	 group_id
				from	 group_distinct_member_map
				where	 member_id = :user_id
			)
		)
    "
    set result [db_string im_biz_object_member_p $sql]
    return $result
}

ad_proc -public im_biz_object_admin_p { user_id object_id } {
    Returns >0 if the user is a PM of a project or a Key
    Account of a company
    the specified object.
} {
    return [util_memoize [list im_biz_object_admin_p_helper $user_id $object_id] 60]
}

ad_proc -public im_biz_object_admin_p_helper { user_id object_id } {
    Returns >0 if the user is a PM of a project or a Key
    Account of a company
    the specified object.
} {
    set sql "
	select	count(*)
	from	acs_rels r,
		im_biz_object_members m
	where	r.object_id_one=:object_id
		and r.object_id_two=:user_id
		and r.rel_id = m.rel_id
		and m.object_role_id in (1301,1302,1303,1309)
    "
    # 1301=PM, 1302=Key Account, 1303=Office Man., 1309=Conf Item Man.

    set result [db_string im_biz_object_member_p $sql]
    return $result
}

ad_proc -public im_biz_object_admin_ids { object_id } {
    Returns the list of administrators of the specified object_id
} {
    set sql "
	select	object_id_two
	from	acs_rels r,
		im_biz_object_members m
	where	r.object_id_one=:object_id
		and r.rel_id = m.rel_id
		and m.object_role_id in (1301,1302,1303,1309) and
		r.object_id_two not in (
			-- Exclude deleted or disabled users
			select	m.member_id
			from	group_member_map m,
				membership_rels mr
			where	m.group_id = acs__magic_object_id('registered_users') and
				m.rel_id = mr.rel_id and
				m.container_id = m.group_id and
				mr.member_state != 'approved'
		)
    "

    # 1301=PM, 1302=Key Account, 1303=Office Man, 1309=Conf Item Manager

    set result [db_list im_biz_object_admin_ids $sql]
    return $result
}

ad_proc -public im_biz_object_member_ids { object_id } {
    Returns the list of members of the specified object_id
} {
    set sql "
	select	r.object_id_two
	from	acs_rels r
	where	r.object_id_one=:object_id and
		r.rel_type = 'im_biz_object_member' and
		r.object_id_two not in (
			-- Exclude deleted or disabled users
			select	m.member_id
			from	group_member_map m,
				membership_rels mr
			where	m.group_id = acs__magic_object_id('registered_users') and
				m.rel_id = mr.rel_id and
				m.container_id = m.group_id and
				mr.member_state != 'approved'
		)
    "
    set result [db_list im_biz_object_member_ids $sql]
    return $result
}

ad_proc -public im_biz_object_user_rels_ids { user_id object_id } {
    Returns the list of acs_rel_ids that the user has 
    with the specified object.
} {
    set sql "
	select rel_id
	from acs_rels
	where	object_id_one=:object_id
		and object_id_two=:user_id
"
    set result [db_list im_biz_object_member_ids $sql]
    return $result
}

ad_proc -public im_biz_object_role_ids { user_id object_id } {
    Returns the list of "biz-object"-role IDs that the user has 
    with the specified object.<br>
} {
    set sql "
	select distinct
		m.object_role_id
	from
		acs_rels r,
		im_biz_object_members m
	where
		r.object_id_one=:object_id
		and r.object_id_two=:user_id
		and r.rel_id = m.rel_id
"
    set result [db_list im_biz_object_roles $sql]
    return $result
}

ad_proc -public im_biz_object_roles { user_id object_id } {
    Returns the list of "biz-object"-roles that the user has 
    with the specified object.<br>
    For example, this procedure could return {Developer PM}
    as the roles(!) of a specific user in a project or
    {Key Account} for the roles in a company.
} {
    set sql "
	select distinct
		im_category_from_id(m.object_role_id)
	from
		acs_rels r,
		im_biz_object_members m
	where
		r.object_id_one=:object_id
		and r.object_id_two=:user_id
		and r.rel_id = m.rel_id
"
    set result [db_list im_biz_object_roles $sql]
    return $result
}




ad_proc -public im_biz_object_add_role { 
    {-debug_p 0}
    {-percentage ""}
    {-current_user_id ""}
    {-propagate_superproject_p 1}
    user_id 
    object_id 
    role_id 
} {
    Adds a user in a role to a Business Object.
    Returns the rel_id of the relationship or "" if an error occured.
    @param propagate_superproject Should we check the superprojects 
	   and add the user there as well? This is the default,
	   because otherwise members of subprojects wouldn't even
	   be able to get to their subproject.
} {
    if {$debug_p} { ns_log Notice "im_biz_object_add_role: percentage=$percentage, propagate=$propagate_superproject_p, user_id=$user_id, object_id=$object_id, role_id=$role_id" }
    if {"" eq $user_id || "" eq $object_id || 0 eq $user_id || 0 eq $object_id || ![string is integer $user_id] || ![string is integer $object_id]} {
	ns_log Error "im_biz_object_add_role: user_id=$user_id, object_id=$object_id, role_id=$role_id: invalid user_id or object_id, skipping"
	ns_log Notice "im_biz_object_add_role: Stack trace:\n[ad_print_stack_trace]"
	return "" 
    }
    
    # Deal with execution from within a "sweeper" process
    # where ns_conn returns an error
    set user_ip "0.0.0.0"
    set creation_user_id $current_user_id
    if {"" == $creation_user_id ||  0 == $creation_user_id} {
	set creation_user_id 0
	catch { 
	    set user_ip [ad_conn peeraddr] 
	    set creation_user_id [ad_conn user_id]
	}
    }
    
    # Determine the object's type
    if {![string is integer $object_id]} { im_security_alert -location "im_biz_object_add_role" -message "Found non-integer object_id" -value $object_id }
    set object_type [util_memoize [list db_string object_type "select object_type from acs_objects where object_id = $object_id" -default ""]]
    if {"" eq $object_type} {
	# The object doesn't exist. This is probably a harmless condition, so just skip.
	return
    }
    
    # Get the existing relationship
    set rel_id ""
    set org_percentage ""
    set org_role_id ""
    db_0or1row relationship_info "
	select  r.rel_id,
		bom.percentage as org_percentage,
		bom.object_role_id as org_role_id
	from    acs_rels r,
		im_biz_object_members bom
	where   r.rel_id = bom.rel_id and
		object_id_one = :object_id and
		object_id_two = :user_id
    "

    # Don't overwrite an admin role
    if {[lsearch [list [im_biz_object_role_project_manager] [im_biz_object_role_key_account] [im_biz_object_role_office_admin] [im_biz_object_role_conf_item_manager]] $org_role_id] > -1} {
	set role_id $org_role_id
    }

    # Check if the relationship already exists as
    if {[lsearch {} $org_role_id] > -1} { return $rel_id }
    
    if {![info exists rel_id] || 0 == $rel_id || "" == $rel_id} {
	ns_log Notice "im_biz_object_add_role: oid=$object_id, uid=$user_id, rid=$role_id"
	set rel_id [db_string create_rel "
		select im_biz_object_member__new (
			null,
			'im_biz_object_member',
			:object_id,
			:user_id,
			:role_id,
			:creation_user_id,
			:user_ip
		)
	"]
    }

    if {"" == $rel_id || 0 == $rel_id} { ad_return_complaint 1 "im_biz_object_add_role: rel_id=$rel_id" }

    # Update the bom's percentage and role only if necessary
    if {$org_percentage != $percentage || $org_role_id != $role_id} {
	db_dml update_perc "
		UPDATE im_biz_object_members SET
			percentage = :percentage,
			object_role_id = :role_id
		WHERE rel_id = :rel_id
	"
    }

    # Take specific action to create relationships depending on the object types
    if {$debug_p} { ns_log Notice "im_biz_object_add_role: object_type=$object_type" }
    switch $object_type {
	im_company {
	    # Differentiate between employee_rel and key_account_rel
	    set company_internal_p [db_string internal_p "select count(*) from im_companies where company_id = :object_id and company_path = 'internal'"]
	    set user_employee_p [im_user_is_employee_p $user_id]
	    
	    # User emplolyee_rel either if it's our guy and our company OR if it's another guy and an external company
	    # We can't currently deal with the case of a freelancer as a key account to a customer...
	    if {(1 == $company_internal_p && 1 == $user_employee_p) || (0 == $company_internal_p && 0 == $user_employee_p) } {
		# We are adding an employee to the internal company,
		# create an "employee_rel" relationship
		set emp_count [db_string emp_cnt "select count(*) from im_company_employee_rels where employee_rel_id = :rel_id"]
		if {0 == $emp_count} {
		    db_dml insert_employee "insert into im_company_employee_rels (employee_rel_id) values (:rel_id)"
		}
		db_dml update_employee "update acs_rels set rel_type = 'im_company_employee_rel' where rel_id = :rel_id"
	    } else {
		# We are adding a non-employee to a customer of provider company.
		set user_key_account_p [db_string key_account_p "select count(*) from im_key_account_rels where key_account_rel_id = :rel_id"]
		if {!$user_key_account_p} {
		    db_dml insert_key_account "insert into im_key_account_rels (key_account_rel_id) values (:rel_id)"
		}
		db_dml update_key_account "update acs_rels set rel_type = 'im_key_account_rel' where rel_id = :rel_id"
	    }
	}
	
	im_project - im_timesheet_task - im_ticket {
	    # Specific actions on projects, tasks and tickets

	    # Reset the time phase date for this relationship
	    im_biz_object_delete_timephased_data -rel_id $rel_id

	    if {$propagate_superproject_p} {

		# Reset the percentage to "", so that there is no percentage assignment
		# to the super-project (that would be a duplication).
		set percentage ""

		set super_project_id [db_string super_project "
			select parent_id
			from im_projects
			where project_id = :object_id
		" -default ""]

		set update_parent_p 0
		if {"" != $super_project_id} {
		    set already_assigned_p [db_string already_assigned "
				select count(*) from acs_rels where object_id_one = :super_project_id and object_id_two = :user_id
		    "]
		    if {!$already_assigned_p} { set update_parent_p 1 }
		}

		if {$update_parent_p} {
		    set super_role_id [im_biz_object_role_full_member]
		    im_biz_object_add_role -percentage $percentage $user_id $super_project_id $super_role_id
		}
	    }
	}
	
	im_conf_item {
	    # Specific actions on configuration item - propagate membersuip up the is-part-of hierarchy
	    set super_conf_item_id [db_string super_conf_item "select conf_item_parent_id from im_conf_items where conf_item_id = :object_id" -default ""]
	    if {$debug_p} { ns_log Notice "im_biz_object_add_role: conf_item: propagate up to super_conf_item_id=$super_conf_item_id" }
	    
	    set update_parent_p 0
	    if {"" != $super_conf_item_id} {
		set already_assigned_p [db_string already_assigned "
			select count(*) from acs_rels where object_id_one = :super_conf_item_id and object_id_two = :user_id
		    "]
		if {!$already_assigned_p} { set update_parent_p 1 }
	    }
	    
	    if {$update_parent_p} {
		set super_role_id [im_biz_object_role_full_member]
		im_biz_object_add_role $user_id $super_conf_item_id $super_role_id
	    }
	}
	
	default {
	    # Nothing.
	    # In the future we may want to add more specific rels here.
	}
    }

    # Remove all permission related entries in the system cache
    im_permission_flush

    return $rel_id
}


ad_proc -public im_biz_object_roles_select { select_name object_id { default "" } } {
    A common drop-down box to select the available roles for 
    users to be assigned to the object.<br>
    Returns an html select box named $select_name and defaulted to
    $default with a list of all available roles for this object.
} {
    set bind_vars [ns_set create]
    set acs_object_type [db_string acs_object_type "select object_type from acs_objects where object_id = :object_id" -default "invalid"]
    ns_set put $bind_vars acs_object_type $acs_object_type

    set sql "
	select distinct
		r.object_role_id,
		im_category_from_id(r.object_role_id)
	from
		im_biz_object_role_map r
	where
		r.acs_object_type = :acs_object_type
    "
    return [im_selection_to_select_box $bind_vars "project_member_select" $sql $select_name $default]
}




ad_proc -public im_biz_object_delete_timephased_data {
    { -rel_id "" }
    { -task_id "" }
} {
    This routine is called after any modification of assignments
    or resources to tasks.
    Timephased Data are optional structures from MS-Project with
    minute by minute assignment data. These data become invalid
    after any modification (percentage, resource) of an assignment.
} {
    if {![im_table_exists im_gantt_assignment_timephases]} { return }

    if {"" != $rel_id} {
	db_dml delete_gantt_timephased_data "
		delete from im_gantt_assignment_timephases
		where rel_id = :rel_id
	"
	db_dml delete_gantt_assignments "
		delete from im_gantt_assignments
		where rel_id = :rel_id
	"
    }

    if {"" != $task_id} {
	db_dml delete_gantt_timephased_data "
		delete from im_gantt_assignment_timephases
		where rel_id in (
			select	rel_id
			from	acs_rels
			where	object_id_one = :task_id
		)
	"
	db_dml delete_gantt_assignments "
		delete from im_gantt_assignments
		where rel_id in (
			select	rel_id
			from	acs_rels
			where	object_id_one = :task_id
		)
	"
    }

}


# --------------------------------------------------------------
# Show the members of the Admin Group of the current Business Object.
# --------------------------------------------------------------


ad_proc -public im_group_member_component { 
    {-show_percentage_p ""}
    {-debug 0}
    object_id 
    current_user_id 
    { add_admin_links 0 } 
    { return_url "" } 
    { limit_to_users_in_group_id "" } 
    { dont_allow_users_in_group_id "" } 
    { also_add_to_group_id "" } 
} {
    Returns an html formatted list of all the users in the specified
    group. 

    Required Arguments:
    -------------------
    - object_id: Group we're interested in.
    - current_user_id: The user_id of the person viewing the page that
      called this function. 

    Optional Arguments:
    -------------------
    - description: A description of the group. We use pass this to the
      spam function for UI
    - add_admin_links: Boolean. If 1, we add links to add/email
      people. Current user must be member of the specified object_id to add
      him/herself
    - return_url: Where to go after we do something like add a user
    - limit_to_users_in_group_id: Only shows users who belong to
      group_id and who are also members of the group specified in
      limit_to_users_in_group_id. For example, if object_id is an intranet
      project, and limit_to_users_group_id is the object_id of the employees
      group, we only display users who are members of both the employees and
      this project groups
    - dont_allow_users_in_group_id: Similar to
      limit_to_users_in_group_id, but says that if a user belongs to the
      object_id specified by dont_allow_users_in_group_id, then don't display
      that user.  
    - also_add_to_group_id: If we're adding users to a group, we might
      also want to add them to another group at the same time. If you set
      also _add_to_group_id to a object_id, the user will be added first to
      object_id, then to also_add_to_group_id. Note that adding the person to
      both groups is NOT atomic.

    Notes:
    -------------------
    This function has quickly become complicated. Any proposals to simplify
    are welcome...

} {
    im_security_alert_check_integer -location "im_group_member_component: object_id" -value $object_id

    # Settings ans Defaults
    set name_order [parameter::get -package_id [apm_package_id_from_key intranet-core] -parameter "NameOrder" -default 1]

    # Check if there is a percentage column from intranet-ganttproject
    set object_type [util_memoize [list db_string otype "select object_type from acs_objects where object_id=$object_id" -default ""]]
    if {"" == $show_percentage_p && ($object_type eq "im_project" || $object_type eq "im_timesheet_task")} { 
	# Do not show percentage in projects with children
	set children_count [db_string children "select count(*) from im_projects where parent_id = :object_id"]
	if {0 eq $children_count} { set show_percentage_p 1 }
    }

    if {"" == $show_percentage_p} { set show_percentage_p 0 }
    if {![im_column_exists im_biz_object_members percentage]} { set show_percentage_p 0 }

    set show_hours_p [parameter::get_from_package_key -package_key "intranet-core" -parameter "MemberPortletShowHoursP" -default "0"]
    set edit_hours_p [parameter::get_from_package_key -package_key "intranet-core" -parameter "MemberPortletEditHoursP" -default "0"]
    set show_days_p [parameter::get_from_package_key -package_key "intranet-core" -parameter "MemberPortletShowDaysInsteadOfHoursP" -default "0"]

    if {!$show_percentage_p} { set show_hours_p 0 }; # don't show hours without percentages
    if {$object_type ni {"im_project" "im_timesheet_task"}} { 
	set show_hours_p 0; # don't show hours for objects other than project or task
    } else {
	db_1row project_info "select start_date, end_date from im_projects where project_id = :object_id"
    }

#    ad_return_complaint 1 "show_percentage_p=$show_percentage_p, show_hours_p=$show_hours_p, otype=$object_type"

    set group_l10n [lang::message::lookup "" intranet-core.Group "Group"]
    
    # ------------------ limit_to_users_in_group_id ---------------------
    set limit_to_group_id_sql ""
    if {$limit_to_users_in_group_id ne ""} {
	set limit_to_group_id_sql "
	and rels.object_id_two in (
		select	gdmm.member_id
		from	group_distinct_member_map gdmm
		where	gdmm.group_id = :limit_to_users_in_group_id
	)"
    } 

    # ------------------ dont_allow_users_in_group_id ---------------------
    set dont_allow_sql ""
    if {$dont_allow_users_in_group_id ne ""} {
	set dont_allow_sql "
	and rels.object_id_two not in (
		select	gdmm.member_id
		from	group_distinct_member_map gdmm
		where	gdmm.group_id = :dont_allow_users_in_group_id
	)"
    } 

    set bo_rels_percentage_sql ""
    if {$show_percentage_p} {
	set bo_rels_percentage_sql ",bo_rels.percentage as percentage"
    }

    set bo_rels_hours_sql ""
    if {$show_hours_p} {
	set bo_rels_hours_sql ", im_resource_mgmt_work_days (rels.object_id_two, :start_date, :end_date) as work_days"
    }

    # ------------------ Main SQL ----------------------------------------
    set sql_query "
	select
		rels.object_id_two as user_id, 
		rels.object_id_two as party_id, 
		im_email_from_user_id(rels.object_id_two) as email,
		coalesce(
			im_name_from_user_id(rels.object_id_two, $name_order), 
			:group_l10n || ': ' || acs_object__name(rels.object_id_two)
		) as name,
		im_category_from_id(c.category_id) as member_role,
		c.category_gif as role_gif,
		c.category_description as role_description
		$bo_rels_percentage_sql
		$bo_rels_hours_sql
	from
		acs_rels rels
		LEFT OUTER JOIN im_biz_object_members bo_rels ON (rels.rel_id = bo_rels.rel_id)
		LEFT OUTER JOIN im_categories c ON (c.category_id = bo_rels.object_role_id)
	where
		rels.object_id_one = :object_id and
		rels.object_id_two in (select party_id from parties)
		$limit_to_group_id_sql 
		$dont_allow_sql
	order by 
		name	
    "

    # ------------------ Format the table header ------------------------
    set colspan 1
    set header_html "
      <tr> 
	<td class=rowtitle align=middle>[_ intranet-core.Name]</td>
    "
    if {$show_percentage_p} {
	incr colspan
	append header_html "<td class=rowtitle align=middle>[_ intranet-core.Perc]</td>"
    }
    if {$show_hours_p} {
	incr colspan
	if {$show_days_p} {
	    append header_html "<td class=rowtitle align=middle>[lang::message::lookup "" intranet-core.Days Days]</td>"
	} else {
            set hours_help [lang::message::lookup "" intranet-core.Members_Portlet_Hours_help "Working days between start- and end-date, multiplied with the assigned resource percentage."]
	    append header_html "<td class=rowtitle align=middle>[_ intranet-core.Hours] [im_gif help $hours_help]</td>"
	}
    }
    if {$add_admin_links} {
	incr colspan
	append header_html "<td class=rowtitle align=middle><input id=list_check_all type='checkbox' name='_dummy'></td>"
    }
    append header_html "
      </tr>"

    # ------------------ Format the table body ----------------
    set td_class(0) "class=roweven"
    set td_class(1) "class=rowodd"
    set found 0
    set count 0
    set body_html ""
    set output_hidden_vars ""
    db_foreach users_in_group $sql_query {

	# Make up a GIF with ALT text to explain the role (Member, Key 
	# Account, ...
	set descr $role_description
	if {"" == $descr} { set descr $member_role }

	# Allow for object type specific localization of GIF and comment
	set member_role_key [lang::util::suggest_key $member_role]
	set descr_otype_key "intranet-core.Role_${object_type}_$member_role_key"
	set descr [lang::message::lookup "" $descr_otype_key $descr]
# fraber 170810: Stupid! Why localize the GIF??
#	set role_gif_key "intranet-core.Role_GIF_[lang::util::suggest_key $role_gif]"
#	set role_gif [lang::message::lookup "" $role_gif_key $role_gif]
	set profile_gif [im_gif -translate_p 0 $role_gif $descr]
	if {[im_user_deleted_p $user_id]} { set color "red" } else { set color "black" }

	incr count
	if { $current_user_id == $user_id } { set found 1 }

	# determine how to show the user: 
	# -1: Show name only, 0: don't show, 1:Show link
	set show_user [im_show_user_style $user_id $current_user_id $object_id]
	if {$debug} { ns_log Notice "im_group_member_component: user_id=$user_id, show_user=$show_user" }

	if {$show_user == 0} { continue }

	append output_hidden_vars "<input type=hidden name=member_id value=$user_id>"
	append body_html "
		<tr $td_class([expr {$count % 2}])>
			<td>
	"
	set name_html $name
	if {[im_user_deleted_p $user_id]} { set name_html "<font color=red>$name</font>" }
	if {$show_user > 0} {
		append body_html "<A HREF=/intranet/users/view?user_id=$user_id>$name_html</A>"
	} else {
		append body_html $name_html
	}

	append body_html "$profile_gif</td>"
	if {$show_percentage_p} {
	    set  html "<td align=middle><input type=input size=4 maxlength=4 name=\"percentage.$user_id\" value=\"$percentage\"></td>"
	    if {$edit_hours_p} {
		set html "<td align=right>$percentage%</td>"
		if {"" eq $percentage || "0" eq $percentage} { set html "<td>&nbsp;</td>" }
	    }
	    append body_html $html
	}

	if {$show_hours_p} {
	    set work_days_array [lindex [split $work_days "="] 1]
	    regsub -all {,} $work_days_array " " work_days_array
	    set work_days_array [string range $work_days_array 1 end-1]

	    if {"" eq $percentage} { set percentage 0 }
	    set days 0
	    foreach d $work_days_array { set days [expr $days + $d] }
	    set hours [expr round($percentage * $days * 8.0 / 1000.0) / 10.0]
	    if {0 == $hours} { set hours "" }
	    set html "<td align=middle>$hours</td>"
	    if {$edit_hours_p} {

		if {$show_days_p} {
		    set days [expr round($percentage * $days / 1000.0) / 10.0]
		    set html "<td><input type=input size=4 maxlength=4 name=\"days.$user_id\" value=\"$days\"></td>"
		} else {
		    set html "<td><input type=input size=4 maxlength=4 name=\"hours.$user_id\" value=\"$hours\"></td>"
		}
	    }
	    append body_html $html
	}

	if {$add_admin_links} {
	    append body_html "
		  <td align=middle>
		    <input type='checkbox' name='delete_user' id='delete_user,$user_id' value='$user_id'>
		  </td>
	    "
	}
	append body_html "</tr>"
    }

    if { $body_html eq "" } {
	set body_html "<tr><td colspan=$colspan><i>[_ intranet-core.none]</i></td></tr>\n"
    }

    # ------------------ Format the table footer with buttons ------------
    set footer_html ""
    if {$add_admin_links} {
	append footer_html "
	    <tr>
	      <td align=left>
		<ul>
		<li><A HREF=\"/intranet/[export_vars -base member-add {object_id also_add_to_group_id limit_to_users_in_group_id return_url}]\">[_ intranet-core.Add_member]</A>
		</ul>
	      </td>
	"

	append footer_html "
	    <tr>
	      <td align=right colspan=$colspan>
		<select name=action>
	"
#		<option value=add_member>[_ intranet-core.Add_a_new_member]</option>


	if {$show_percentage_p} {
	    append footer_html "
		<option value=update_members>[_ intranet-core.Update_members]</option>
	    "
	}
	append footer_html "
		<option value=del_members>[_ intranet-core.Delete_members]</option>
		</select>
		<input type=submit value='[_ intranet-core.Apply]' name=submit_apply></td>
	      </td>
	    </tr>
	"
    }

    # ------------------ Join table header, body and footer ----------------
    set html "

    	<script type=\"text/javascript\" nonce=\"[im_csp_nonce] \">
	window.addEventListener('load', function() { 
	     document.getElementById('list_check_all').addEventListener('click', function() { acs_ListCheckAll('delete_user', this.checked) });
	});
	</script>

	<form method=POST action=/intranet/member-update>
	$output_hidden_vars
	[export_vars -form {object_id return_url}]
	    <table bgcolor=white cellpadding=1 cellspacing=1 border=0>
	      $header_html
	      $body_html
	      $footer_html
	    </table>
	</form>
    "
    return $html
}


ad_proc -public im_project_add_member { object_id user_id role} {
    Make a specified user a member of a (project) group
} {
    im_exec_dml "user_group_member_add(:object_id, :user_id, :role)"
}




ad_proc -public im_object_assoc_component { 
    -object_id:required 
} {
    Returns a formatted HTML component that allows associating the
    current object with another one via a "role".
} {
    set td_class(0) "class=roweven"
    set td_class(1) "class=rowodd"

    set assoc_sql "
	select	o.*,
		r.*,
		rtype.pretty_name as rel_pretty_name,
		otype.pretty_name as object_type_pretty_name,
		acs_object__name(o.object_id) as object_name
	from
		acs_objects o,
		(select	r.object_id_two as object_id,
			r.rel_id,
			r.rel_type
		from	acs_rels r
		where	object_id_one = :object_id
		UNION
		select	r.object_id_one as object_id,
			r.rel_id,
			r.rel_type
		from	acs_rels r
		where	object_id_two = :object_id
		) r,
		acs_object_types rtype,
		acs_object_types otype
	where
		r.object_id = o.object_id and
		r.rel_type = rtype.object_type and
		o.object_type = otype.object_type
    "

    set ctr 0
    set body_html ""
    db_foreach assoc $assoc_sql {
	append body_html "
		<tr $td_class([expr {$ctr % 2}])>
		<td>$rel_pretty_name</td>
		<td>$object_type_pretty_name</td>
		<td>[db_string name "select acs_object__name(:object_id)"]</td>
		</tr>
	"
    }

    set header_html "
	<tr class=rowtitle>
	<td>Rel</td>
	<td>OType</td>
	<td>Object</td>
	</tr>
    "

    set footer_html "
    "

    return "
	<table>
	$header_html
	$body_html
	$footer_html
	</table>
    "

}


ad_proc -public im_biz_object_member_list_format { 
    {-format_user "initials"}
    {-format_role_p 0}
    {-format_perc_p 1}
    bom_list 
} {
    Formats a list of business object memberships for display.
    Returns a piece of HTML suitable for the Gantt Task List for example.
    @param bom_list A list of {user_id role_id perc} entries
} {
    set member_list ""
    foreach entry $bom_list {
	set party_id [lindex $entry 0]
	set role_id [lindex $entry 1]
	set perc [lindex $entry 2]
	set party_name [im_name_from_user_id $party_id]
	switch $format_user {
	    initials {
		set party_pretty [im_initials_from_user_id $party_id]
	    }
	    email {
		set party_pretty [im_email_from_user_id $party_id]
	    }
	    default {
		set party_pretty [im_name_from_user_id $party_id]
	    }
	}
	# Skip the entry if we didn't manage to format the name
	if {"" == $party_pretty} { set party_id "" }

	# Add a link to the user's page
	set party_url [export_vars -base "/intranet/users/view" {{user_id $party_id}}]
	set party_pretty "<a href=\"$party_url\" title=\"$party_name\">$party_pretty</a>"

	if {$format_role_p && "" != $role_id} {
	    set role_name [im_category_from_id $role_id]
	    # ToDo: Add role to name using GIF
	}

	if {$format_perc_p && "" != $perc} {
	    set perc [expr {round($perc)}]
	    append party_pretty ":${perc}%"
	}
	if {"" != $party_id} {
	    lappend member_list "$party_pretty"
	}
    }
    return [join $member_list ", "]
}



# ---------------------------------------------------------------
# Component showing related objects
# ---------------------------------------------------------------

ad_proc -public im_biz_object_related_objects_component {
    { -include_membership_rels_p 0 }
    { -user_friendly_view_p 0  }
    { -show_projects_only 0 }
    { -show_only_object_type "" }
    { -show_companies_only 0 }
    { -hide_rel_name_p 0 }
    { -hide_object_chk_p 0 }
    { -hide_direction_pretty_p 0 }
    { -hide_object_type_pretty_p 0 }
    { -hide_object_name_p 0 }
    { -hide_creation_date_formatted_p 0 }
    { -suppress_invalid_objects_p 0 }
    { -sort_order "" }
    -object_id:required 
} {
    Returns a HTML component with the list of related objects.
    Named parameters 'show_projects_only' and show_companies_only are deprecated.
    Please use parameter: show_only_object_type instead
    @param include_membership_rels_p: Normally, membership rels
	   are handled by the "membership component". That's not
	   the case with users.
} {

    set params [list \
		    [list base_url "/intranet/"] \
		    [list include_membership_rels_p $include_membership_rels_p] \
		    [list user_friendly_view_p $user_friendly_view_p] \
		    [list show_projects_only $show_projects_only ] \
		    [list show_only_object_type $show_only_object_type ] \
		    [list show_companies_only $show_companies_only ] \
		    [list return_url [im_url_with_query]] \
		    [list hide_rel_name_p $hide_rel_name_p] \
		    [list hide_object_chk_p $hide_object_chk_p ] \
		    [list hide_direction_pretty_p $hide_direction_pretty_p ] \
		    [list hide_object_type_pretty_p $hide_object_type_pretty_p  ] \
		    [list hide_object_name_p $hide_object_name_p ] \
		    [list hide_creation_date_formatted_p $hide_creation_date_formatted_p ] \
                    [list suppress_invalid_objects_p $suppress_invalid_objects_p ] \
		    [list sort_order $sort_order ] \
		    [list object_id $object_id] \
		    ]

    set result [ad_parse_template -params $params "/packages/intranet-core/www/related-objects-component"]
    return [string trim $result]
}

# ---------------------------------------------------------------
# Allow the user to add profiles to tickets
# ---------------------------------------------------------------

ad_proc im_biz_object_add_profile_component {
    -object_id:required
} {
    Component that returns a formatted HTML form allowing
    users to add a profile to an object
} {
    # ------------------------------------------------
    # Applicability, Defauls & Security
    set current_user_id [ad_conn user_id]
    set object_type [util_memoize [list db_string acs_object_type "select object_type from acs_objects where object_id = $object_id" -default ""]]
    set perm_cmd "${object_type}_permissions \$current_user_id \$object_id view_p read_p write_p admin_p"
    eval $perm_cmd
    if {!$write_p} { return "" }

    set object_name [acs_object_name $object_id]
    set page_title [lang::message::lookup "" intranet-core.Add_profile "Add profile"]

    set notify_checked ""
    if {[parameter::get_from_package_key -package_key "intranet-core" -parameter "NotifyNewMembersDefault" -default "1"]} {
        set notify_checked "checked"
    }
    
    set bind_vars [ns_set create]
    set profiles_sql "
	select	g.group_id,
		g.group_name
	from	groups g,
		im_profiles p
	where	g.group_id = p.profile_id
	order by lower(g.group_name)
    "
    set default ""
    set list_box [im_selection_to_list_box -translate_p "0" $bind_vars profile_select $profiles_sql user_id_from_search $default 10 0]

    set passthrough {object_id return_url also_add_to_object_id limit_to_users_in_group_id}
    foreach var $passthrough {
	if {![info exists $var]} { set $var [im_opt_val -limit_to nohtml $var] }
    }

    # ToDo: Test

    set role_id [im_biz_object_role_full_member]
    set result "
	<form method=GET action=/intranet/member-add-2>
	[export_vars -form {passthrough}]
	[export_vars -form {{notify_asignee 0}}]
	[eval "export_vars -form {$passthrough}"]
	<table cellpadding=0 cellspacing=2 border=0>
	<tr><td>
	$list_box
	</td></tr>
	<tr><td>
	[_ intranet-core.add_as] [im_biz_object_roles_select role_id $object_id $role_id]
	</td></tr>
	<tr><td>
	<input type=submit value=\"[_ intranet-core.Add]\">
	</td></tr>
	</table>
	</form>
    "
    
    return $result
}





# ---------------------------------------------------------------
# Allow the user to add other groups to objects
# ---------------------------------------------------------------

ad_proc im_biz_object_add_group_component {
    { -group_type "im_biz_object_group" }
    { -group_name_prefix "" }
    -object_id:required
} {
    Component that returns a formatted HTML form allowing
    users to add groups to an object
} {
    # ------------------------------------------------
    # Applicability, Defauls & Security
    set current_user_id [ad_conn user_id]
    set object_type [util_memoize [list db_string acs_object_type "select object_type from acs_objects where object_id = $object_id" -default ""]]
    set perm_cmd "${object_type}_permissions \$current_user_id \$object_id view_p read_p write_p admin_p"
    eval $perm_cmd
    if {!$write_p} { return "" }

    set bind_vars [ns_set create]
    ns_set put $bind_vars group_type $group_type
    ns_set put $bind_vars group_name_prefix $group_name_prefix
    set groups_sql "
	select	g.group_id,
		g.group_name
	from	groups g,
		acs_objects o
	where	g.group_id = o.object_id and
		o.object_type = :group_type and
		substring(g.group_name for [string length $group_name_prefix]) = :group_name_prefix
	order by lower(g.group_name)
    "
#    ad_return_complaint 1 "<pre>$groups_sql\n\ngroup_name_prefix=$group_name_prefix\ngroup_type=$group_type\n[im_ad_hoc_query $groups_sql]</pre>"
    set default ""
    set list_box [im_selection_to_list_box -translate_p "0" $bind_vars groups_select $groups_sql user_id_from_search $default 10 0]
    set passthrough {object_id return_url also_add_to_object_id limit_to_users_in_group_id}
    foreach var $passthrough {
	if {![info exists $var]} { set $var [im_opt_val $var] }
    }

    set role_id [im_biz_object_role_full_member]
    set result "
	<form method=GET action=/intranet/member-add-2>
	[export_vars -form {passthrough}]
	[export_vars -form {{notify_asignee 0}}]
	[eval "export_vars -form {$passthrough}"]
	<table cellpadding=0 cellspacing=2 border=0>
	<tr><td>
	$list_box
	</td></tr>
	<tr><td>
	[_ intranet-core.add_as] [im_biz_object_roles_select role_id $object_id $role_id]
	</td></tr>
	<tr><td>
	<input type=submit value=\"[_ intranet-core.Add]\">
	</td></tr>
	</table>
	</form>
    "
    
    return $result
}






ad_proc -public im_biz_object_group_sweeper {
    {-object_id ""}
} {
    Sweeper that checks if an im_biz_object_group exists for the
    specified object_id. It then updates the group membership
    based on the business object members.
    This function is to be called from callbacks from both "view"
    and "after_update" of the respective business object.
} {
    ns_log Notice "im_biz_object_group_sweeper: object_id=$object_id"

    set group_id [db_string biz_object_group "select group_id from im_biz_object_groups where biz_object_id = :object_id" -default ""]
    set object_type_pretty [db_string otype "select pretty_name from acs_objects ao, acs_object_types aot where ao.object_id = :object_id and ao.object_type = aot.object_type" -default "Object"]

    if {"" == $group_id} {
	# The object group still needs to be created
	set object_name [acs_object_name $object_id]
	set object_type [db_string otype "select pretty_name from acs_objects ao, acs_object_types aot where ao.object_id = :object_id and ao.object_type = aot.object_type" -default "Object"]
	set group_name "$object_type: $object_name"
	set group_id [db_string new_biz_object_group "
	    	select	im_biz_object_group__new(
			null, :group_name, NULL, NULL, now(), '0.0.0.0',
			'im_biz_object_group', null, 0, now(), '0.0.0.0', 
			NULL, :object_id
		)
	    "]
    }

    # -----------------------------------------------------------------
    # Group_id is defined now
    # Now compare the buiness object members vs. the group members

    # Get the sorted list of biz_object_members
    set biz_object_members [db_list biz_object_members "
		select distinct
			r.object_id_two
		from	acs_rels r, 
			im_biz_object_members bom,
			persons p
		where	r.rel_id = bom.rel_id and 
			r.object_id_one = :object_id and
			r.object_id_two = p.person_id
    "]
    if {"Cost Center" eq $object_type_pretty} {
	# Cost center members are defined by im_employee.department_id == cost_center_id plus sub-CCs
	set cc_sql "
		select	e.employee_id
		from	im_cost_centers cc,
			im_cost_centers sub_cc,
			im_employees e
		where	cc.cost_center_id = :object_id and
			substring(sub_cc.cost_center_code for length(cc.cost_center_code)) = cc.cost_center_code and
			e.department_id = sub_cc.cost_center_id
        "
	append biz_object_members [db_list ccs $cc_sql]
    }
    set biz_object_members [lsort -unique -integer $biz_object_members]

    # Get the list of existing group members
    set group_members [db_list group_members "
		select	member_id
		from	group_distinct_member_map
		where	group_id = :group_id
	"]
    set group_members [lsort -unique -integer $group_members]

    # Form the union of the two sets of members
    set all_members [lsort -unique -integer [concat $biz_object_members $group_members]]

    # Loop through all members and check if we have to delete of create new group memberships
    foreach uid $all_members {
	set biz_member_p [expr [lsearch $biz_object_members $uid] > -1]
	set group_member_p [expr [lsearch $group_members $uid] > -1]
	ns_log Notice "im_biz_object_group_sweeper: uid=$uid, biz_member_p=$biz_member_p, group_member_p=$group_member_p"

	if {$biz_member_p && !$group_member_p} {
	    # Business object member, but not part of the group => Create group membership
	    ns_log Notice "im_biz_object_group_sweeper: uid=$uid: Adding to object group"
	    set rel_id [relation_add -member_state "approved" "membership_rel" $group_id $uid]
	    db_dml update_relation "update membership_rels set member_state = 'approved' where rel_id = :rel_id"
	}

	if {!$biz_member_p && $group_member_p} {
	    # Not a business object member, but part of the group => Delete from the group
	    ns_log Notice "im_biz_object_group_sweeper: uid=$uid: Deleting from object group"
	    group::remove_member -group_id $group_id -user_id $uid
	}
    }
    ns_log Notice "im_biz_object_group_sweeper: finished"
}

