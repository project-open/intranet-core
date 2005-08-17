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

    set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]
    if {$user_is_admin_p} {
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


ad_proc -public im_employee_options { {include_empty 1} } {
    Cost provider options
} {
    set options [db_list_of_lists provider_options "
        select first_names || ' ' || last_name, user_id
        from im_employees_active
    "]
    if {$include_empty} { set options [linsert $options 0 { "" "" }] }
    return $options
}

ad_proc im_user_select { select_name { default "" } } {
    Returns an html select box named $select_name and defaulted to 
    $default with a list of all the available project_leads in 
    the system
} {
    # We need a "distinct" because there can be more than one
    # mapping between a user and a group, one for each role.
    #
    set bind_vars [ns_set create]
    ns_set put $bind_vars employee_group_id [im_employee_group_id]
    set sql "select emp.user_id, emp.last_name || ', ' || emp.first_names as name
from im_employees_active emp
order by lower(name)"
    return [im_selection_to_select_box $bind_vars project_lead_list $sql $select_name $default]
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
	if {"approved" != $member_state} { set approve_link "<a href=/acs-admin/users/member-state-change?member_state=approved&[export_url_vars user_id return_url]>[_ intranet-core.activate]</a>"
	}

	append rows_html "
<tr $bgcolor([expr $ctr % 2])>
  <td>$creation_date</td>
  <td><A href=$user_view_page?user_id=$user_id>$name</A></td>
  <td><A href=mailto:$email>$email_breakable</A></td>
  <td>$member_state $approve_link</td>
</tr>
"
	incr ctr
    }

    return "
<table border=0 cellspacing=1 cellpadding=1>
<tr class=rowtitle><td class=rowtitle align=center colspan=99>[_ intranet-core.Recent_Registrations]</td></tr>
<tr class=rowtitle>
  <td align=center class=rowtitle>[_ intranet-core.Date]</td>
  <td align=center class=rowtitle>[_ intranet-core.Name]</td>
  <td align=center class=rowtitle>[_ intranet-core.Email]</td>
  <td align=center class=rowtitle>[_ intranet-core.State]</td>
</tr>
$rows_html
<tr class=rowblank align=right>
  <td colspan=99>
    <a href=/intranet/users/index?view_name=user_community&order_by=Creation>[_ intranet-core.more]</a>
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
#	    return "<a href=/intranet/users/view?[export_url_vars user_id]>$employee_name</a><br><i>$job_title</i>\n"
#	} else {
	    return "<a href=/intranet/users/view?[export_url_vars user_id]>$employee_name</a><br>\n"
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




