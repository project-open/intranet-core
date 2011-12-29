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


# The final customer of a project when the invoicing customer is
# in the middle
ad_proc -public im_biz_object_role_final_customer {} { return 1304 }

# A generic association between business objects.
# Don't know what this might be good for in the future...
ad_proc -public im_biz_object_role_generic {} { return 1305 }

# Associated Email
ad_proc -public im_biz_object_role_email {} { return 1306 }


ad_proc -public im_biz_object_url { object_id {url_type "view"} } {
    Returns a URL to a page to view a specific object_id,
    independent of the object type.
    @param object_id
    @param url_tpye is "view" or "edit", according to what you
	want to do with the object.
} {
    set url [util_memoize "db_string object_type_url \"
    	select	url
	from	im_biz_object_urls u,
		acs_objects o
	where	o.object_id = $object_id
		and o.object_type = u.object_type
		and u.url_type = '$url_type'
    \" -default {}"]
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
	where	object_id_one = :object_id
		and object_id_two = :user_id
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
	from 
		acs_rels r,
		im_biz_object_members m
	where
		r.object_id_one=:object_id
		and r.object_id_two=:user_id
		and r.rel_id = m.rel_id
		and m.object_role_id in (1301,1302,1303)
    "
    # 1301=PM, 1302=Key Account, 1303=Office Man.

    set result [db_string im_biz_object_member_p $sql]
    return $result
}

ad_proc -public im_biz_object_admin_ids { object_id } {
    Returns the list of administrators of the specified object_id
} {
    set sql "
select	object_id_two
from 
	acs_rels r,
	im_biz_object_members m
where
	r.object_id_one=:object_id
	and r.rel_id = m.rel_id
	and m.object_role_id in (1301,1302,1303)
"

    # 1301=PM, 1302=Key Account, 1303=Office Man.

    set result [db_list im_biz_object_admin_ids $sql]
    return $result
}

ad_proc -public im_biz_object_member_ids { object_id } {
    Returns the list of members of the specified object_id
} {
    set sql "
	select	object_id_two
	from 
		acs_rels r
	where
		r.object_id_one=:object_id
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
    {-propagate_superproject_p 1}
    user_id 
    object_id 
    role_id 
} {
    Adds a user in a role to a Business Object.
    @param propagate_superproject Should we check the superprojects 
           and add the user there as well? This is the default,
	   because otherwise members of subprojects wouldn't even
	   be able to get to their subproject.
} {
    if {$debug_p} { ns_log Notice "im_biz_object_add_role: percentage=$percentage, propagate=$propagate_superproject_p, user_id=$user_id, object_id=$object_id, role_id=$role_id" }

    if {"" == $user_id || 0 == $user_id} { return }
    set user_ip [ad_conn peeraddr]

    # Check if user is already a member and only continue
    # if the new role is "higher":
    set admins [im_biz_object_admin_ids $object_id]
    if {[lsearch $admins $user_id] >= 0} { return }

    # Determine the object's type
    if {![string is integer $object_id]} { im_security_alert -location "im_biz_object_add_role" -message "Found non-integer object_id" -value $object_id }
    set object_type [util_memoize [list db_string object_type "select object_type from acs_objects where object_id = $object_id"]]

    # Add the user in a im_biz_object_membership relationship

    set org_percentage ""
    set org_role_id ""
    db_0or1row relationship_info "
	select	r.rel_id,
		bom.percentage as org_percentage,
		bom.object_role_id as org_role_id
	from	acs_rels r,
		im_biz_object_members bom
	where	r.rel_id = bom.rel_id and
		object_id_one = :object_id and 
		object_id_two = :user_id
    "

    if {![info exists rel_id] || 0 == $rel_id || "" == $rel_id} {
	ns_log Notice "im_biz_object_add_role: oid=$object_id, uid=$user_id, rid=$role_id"
	set rel_id [db_string create_rel "
		select im_biz_object_member__new (
                        null,
                        'im_biz_object_member',
                        :object_id,
                        :user_id,
                        :role_id,
                        :user_id,
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

	default {
	    # Nothing.
	    # In the future we may want to add more specific rels here.
	}
    }
   
    # Remove all permission related entries in the system cache
    im_permission_flush

    return
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

# --------------------------------------------------------------
# Show the members of the Admin Group of the current Business Object.
# --------------------------------------------------------------


ad_proc -public im_group_member_component { 
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
    # Settings ans Defaults
    set name_order [parameter::get -package_id [apm_package_id_from_key intranet-core] -parameter "NameOrder" -default 1]

    # Check if there is a percentage column from intranet-ganttproject
    set show_percentage_p [im_column_exists im_biz_object_members percentage]
    set object_type [util_memoize "db_string otype \"select object_type from acs_objects where object_id=$object_id\" -default \"\""]
    if {$object_type != "im_project" & $object_type != "im_timesheet_task"} { set show_percentage_p 0 }

    # ------------------ limit_to_users_in_group_id ---------------------
    set limit_to_group_id_sql ""
    if {![empty_string_p $limit_to_users_in_group_id]} {
	set limit_to_group_id_sql "
	and rels.object_id_two in (
		select	gdmm.member_id
		from	group_distinct_member_map gdmm
		where	gdmm.group_id = :limit_to_users_in_group_id
	)"
    } 

    # ------------------ dont_allow_users_in_group_id ---------------------
    set dont_allow_sql ""
    if {![empty_string_p $dont_allow_users_in_group_id]} {
	set dont_allow_sql "
	and rels.object_id_two not in (
		select	gdmm.member_id
		from	group_distinct_member_map gdmm
		where	gdmm.group_id = :dont_allow_users_in_group_id
	)"
    } 

    set bo_rels_percentage_sql ""
    if {$show_percentage_p} {
	set bo_rels_percentage_sql ",round(bo_rels.percentage) as percentage"
    }

    # ------------------ Main SQL ----------------------------------------
    set sql_query "
	select
		rels.object_id_two as user_id, 
		rels.object_id_two as party_id, 
		im_email_from_user_id(rels.object_id_two) as email,
		im_name_from_user_id(rels.object_id_two, $name_order) as name,
		im_category_from_id(c.category_id) as member_role,
		c.category_gif as role_gif,
		c.category_description as role_description
		$bo_rels_percentage_sql
	from
		acs_rels rels
		LEFT OUTER JOIN im_biz_object_members bo_rels ON (rels.rel_id = bo_rels.rel_id)
		LEFT OUTER JOIN im_categories c ON (c.category_id = bo_rels.object_role_id)
	where
		rels.object_id_one = :object_id and
		rels.object_id_two in (select party_id from parties) and
		rels.object_id_two not in (
			-- Exclude banned or deleted users
			select	m.member_id
			from	group_member_map m,
				membership_rels mr
			where	m.rel_id = mr.rel_id and
				m.group_id = acs__magic_object_id('registered_users') and
				m.container_id = m.group_id and
				mr.member_state != 'approved'
		)
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
    if {$add_admin_links} {
        incr colspan
        append header_html "<td class=rowtitle align=middle>[im_gif delete]</td>"
    }
    append header_html "
      </tr>"

    # ------------------ Format the table body ----------------
    set td_class(0) "class=roweven"
    set td_class(1) "class=rowodd"
    set found 0
    set count 0
    set body_html ""
    db_foreach users_in_group $sql_query {

	# Make up a GIF with ALT text to explain the role (Member, Key 
	# Account, ...
	set descr $role_description
	if {"" == $descr} { set descr $member_role }
	set descr_tr [lang::util::suggest_key $descr]
	set profile_gif [im_gif $role_gif $descr_tr]

	incr count
	if { $current_user_id == $user_id } { set found 1 }

	# determine how to show the user: 
	# -1: Show name only, 0: don't show, 1:Show link
	set show_user [im_show_user_style $user_id $current_user_id $object_id]
	if {$debug} { ns_log Notice "im_group_member_component: user_id=$user_id, show_user=$show_user" }

	if {$show_user == 0} { continue }

	append body_html "
<tr $td_class([expr $count % 2])>
  <input type=hidden name=member_id value=$user_id>
  <td>"
	if {$show_user > 0} {
append body_html "<A HREF=/intranet/users/view?user_id=$user_id>$name</A>"
	} else {
append body_html $name
	}

	append body_html "$profile_gif</td>"
	if {$show_percentage_p} {
	    append body_html "
		  <td align=middle>
		    <input type=input size=4 maxlength=4 name=\"percentage.$user_id\" value=\"$percentage\">
		  </td>
	    "
	}
	if {$add_admin_links} {
	    append body_html "
		  <td align=middle>
		    <input type=checkbox name=delete_user value=$user_id>
		  </td>
	    "
	}
	append body_html "</tr>"
    }

    if { [empty_string_p $body_html] } {
	set body_html "<tr><td colspan=$colspan><i>[_ intranet-core.none]</i></td></tr>\n"
    }

    # ------------------ Format the table footer with buttons ------------
    set footer_html ""
    if {$add_admin_links} {

	set spam_members_html ""
	if {[im_table_exists spam_messages]} {
	    set spam_members_html "<li><A HREF=\"[spam_base]spam-add?[export_url_vars object_id sql_query]\">[_ intranet-core.Spam_Members]</A>&nbsp;"
	    set spam_members_html "<option value=spam_members>[_ intranet-core.Spam_Members]</option>\n"
	}


	append footer_html "
	    <tr>
	      <td align=left>
		<ul>
		<li><A HREF=\"/intranet/member-add?[export_url_vars object_id also_add_to_group_id return_url]\">[_ intranet-core.Add_member]</A>
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
		$spam_members_html
		</select>
		<input type=submit value='[_ intranet-core.Apply]' name=submit_apply></td>
	      </td>
	    </tr>
	"
    }

    # ------------------ Join table header, body and footer ----------------
    set html "
	<form method=POST action=/intranet/member-update>
	[export_form_vars object_id return_url]
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
		<tr $td_class([expr $ctr % 2])>
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
    Returns a piece of HTML suitable for the Timesheet Task List for example.
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
	    set perc [expr round($perc)]
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
    -object_id:required
} {
    Returns a HTML component with the list of related objects.
    @param include_membership_rels_p: Normally, membership rels
           are handled by the "membership component". That's not
           the case with users.
} {
    set params [list \
                    [list base_url "/intranet/"] \
                    [list object_id $object_id] \
		    [list include_membership_rels_p $include_membership_rels_p] \
                    [list return_url [im_url_with_query]] \
		    ]

    set result [ad_parse_template -params $params "/packages/intranet-core/www/related-objects-component"]
    return [string trim $result]
}

