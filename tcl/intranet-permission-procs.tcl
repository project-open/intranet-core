# /tcl/intranet-groups-permissions.tcl

ad_library {
    Intranet definitions wrt groups and permissions
    @author Frank Bergmann (fraber@fraber.de)
}

# ------------------------------------------------------------------
# Core Permissions
# ------------------------------------------------------------------

# Intranet permissions scheme - permissions are associated to groups.
#
ad_proc -public im_permission {user_id action} {
    Returns true or false, depending whether the user can execute
    the specified action.
    Uses a cache to reduce DB traffic.
} {
    set permission_list [im_permission_list $user_id]

    # The administrator can do all actions
    if { [lsearch -exact $permission_list admin] >= 0} {
	return 1
    }

    if { [lsearch -exact $permission_list $action] >= 0} {
	return 1
    } {
	return 0
    }
}

ad_proc -public im_permission_list {user_id} {
    Return a list of permission tokens based on the user profile.
    Uses a cache not to bring down the DB due to the amount of
    such queries.
} {
    return [util_memoize "im_permission_list_helper $user_id"]    
}


ad_proc -public im_permission_list_helper {user_id} {
    Return a list of permission tokens based on the user profile:

    Should not be used for permission handling:
    freelance:
    employee:
    customer:	This is a customer...
    wheel:	This is a Wheel...

    Forum Topic related permissions:
    The security is enforced by allowing different profiles to create
    topics with different scopes:
    view_forums:		View messages at all
    create_topic_scope_public:	Public messages, except customers
    create_topic_scope_group:	Messages for the entire group
    create_topic_scope_staff:	Messages to staff members of the group
    create_topic_scope_client:	Messages to the clients of the group
    create_topic_scope_non_client: Message to non-clients of the group
    create_topic_scope_pm:	Message to the project manager only

    Customer related permissions:
    In Translation the most critical are. We differentiate there between
    the customer list, contacts and details:
    add_customers:		Add new customers
    view_customers:		See the Name of a customer of a single project
    view_customer_contacts:	See customer contacts
    view_customer_details:	See the address details of a customer
    view_customer_crm:		"CRM Light" customer contact events

    Project related Permissions:
    add_projects
    view_projects
    view_project_members	See the project member list
    view_projects_of_others
    view_projects_history

    User related permissions:
    add_users
    view_users
    view_employees
    edit_freelancers
    view_freelancers
    view_admin
    view_freelance_fs
    view_employee_fs
    view_customer_fs
    edit_freelance_fs
    edit_employee_fs
    edit_customer_fs

    Finance related permissions: 
    Everybody should be able to see (and maintain) his own data
    view_finance
    add_hours			Employees, freelancers, Wheel, ...
    view_hours
    view_hours_of_others
    view_allocations

    Other:
    search_intranet   
} {

    set permissions [list]
    lappend permissions "user"

    if { [ad_user_group_member [im_freelance_group_id] $user_id] } {
	lappend permissions "freelance"

	# Limit the scope of forum topics:
	# Only allow to post to non-client project members
	lappend permissions "view_forums"
	lappend permissions "create_topic_scope_staff"
	lappend permissions "create_topic_scope_pm"
	lappend permissions "add_hours"
    }
    if { [ad_user_group_member [im_customer_group_id] $user_id] } {
	lappend permissions "customer"

	# Limit the scope of forum topics
	# Only allows to post to other clients the PM.
	lappend permissions "view_forums"
	lappend permissions "create_topic_scope_pm"
    }
    if { [ad_user_group_member [im_employee_group_id] $user_id] } {
	lappend permissions "employee"

	lappend permissions "view_projects"
	lappend permissions "view_project_members"
	lappend permissions "view_projects_of_others"
	lappend permissions "view_projects_history"
	lappend permissions "add_projects"
	lappend permissions "view_allocations"
	lappend permissions "search_intranet"
	lappend permissions "view_users"
	lappend permissions "view_employees"
	lappend permissions "add_users"
	lappend permissions "edit_freelancers"
	lappend permissions "view_freelancers"
	lappend permissions "view_freelance_fs"
	lappend permissions "edit_freelance_fs"
	lappend permissions "add_hours"
	lappend permissions "view_hours"

	# generally allowed to see customer names in specific
	# project, but not necessary allowed to see the list of 
	# customers, nor customer contacts.
	lappend permissions "view_customers"

	# Limit the scope of forum topics
	# No public postings and no postings to clients
	lappend permissions "view_forums"
	lappend permissions "create_topic_scope_staff"
	lappend permissions "create_topic_scope_pm"
	lappend permissions "create_topic_scope_non_client"
    }

    if { [ad_user_group_member [im_pm_group_id] $user_id] } {
	lappend permissions "pm"

	lappend permissions "view_projects"
	lappend permissions "view_project_members"
	lappend permissions "view_projects_of_others"
	lappend permissions "view_projects_history"
	lappend permissions "add_projects"
	lappend permissions "view_allocations"
	lappend permissions "search_intranet"
	lappend permissions "view_users"
	lappend permissions "view_employees"
	lappend permissions "add_users"
	lappend permissions "edit_freelancers"
	lappend permissions "view_freelancers"
	lappend permissions "view_freelance_fs"
	lappend permissions "edit_freelance_fs"
	lappend permissions "add_hours"
	lappend permissions "view_hours"

	# generally allowed to see customer names in specific
	# project, but not necessary allowed to see the list of 
	# customers, nor customer contacts.
	lappend permissions "view_customers"

	# Limit the scope of forum topics
	# No public postings, 
	lappend permissions "view_forums"
	lappend permissions "create_topic_scope_staff"
	lappend permissions "create_topic_scope_non_client"
	lappend permissions "create_topic_scope_pm"
    }

    if { [ad_user_group_member [im_wheel_group_id] $user_id] } {
	lappend permissions "wheel"

	lappend permissions "view_projects"
	lappend permissions "view_project_members"
	lappend permissions "view_projects_of_others"
	lappend permissions "view_projects_history"
	lappend permissions "view_hours_of_others"
	lappend permissions "add_projects"
	lappend permissions "view_allocations"
	lappend permissions "view_finance"
	lappend permissions "search_intranet"
	lappend permissions "view_employees"
	lappend permissions "view_users"
	lappend permissions "add_users"
	lappend permissions "edit_freelancers"
	lappend permissions "view_freelancers"
	lappend permissions "view_freelance_fs"
	lappend permissions "view_employee_fs"
	lappend permissions "view_customer_fs"
	lappend permissions "edit_freelance_fs"
	lappend permissions "edit_employee_fs"
	lappend permissions "edit_customer_fs"
	lappend permissions "view_admin"
	lappend permissions "add_hours"
	lappend permissions "view_hours"
	
	# Show the customer contact information in the CustomerViewPage?
	# ... and the ProjectMemberComponent?
	lappend permissions "view_customers"
	lappend permissions "view_customer_contacts"
	lappend permissions "view_customer_details"
	lappend permissions "view_customer_crm"

	# Limit the scope of forum topics
	lappend permissions "view_forums"
	lappend permissions "create_topic_scope_public"
	lappend permissions "create_topic_scope_group"
	lappend permissions "create_topic_scope_staff"
	lappend permissions "create_topic_scope_client"
	lappend permissions "create_topic_scope_non_client"
	lappend permissions "create_topic_scope_pm"
    }

    if { [ad_user_group_member [im_accounting_group_id] $user_id] } {
	lappend permissions "accounting"

	lappend permissions "view_projects"
	lappend permissions "view_project_members"
	lappend permissions "view_projects_of_others"
	lappend permissions "view_projects_history"
	lappend permissions "view_hours_of_others"
	lappend permissions "view_finance"
	lappend permissions "search_intranet"
	lappend permissions "view_admin"
	lappend permissions "view_users"
	lappend permissions "view_employees"
	lappend permissions "view_customers"
	lappend permissions "add_hours"
	lappend permissions "view_hours"

	# Limit the scope of forum topics
	lappend permissions "view_forums"
	lappend permissions "create_topic_scope_staff"
	lappend permissions "create_topic_scope_pm"
    }

    if {[im_is_user_site_wide_or_intranet_admin $user_id]} {
	lappend permissions "admin"
    }

    return $permissions
}

ad_proc -public im_view_user_permission {view_user_id current_user_id var_value perm_token} {
    Check wheter a user should be able to see a specific field of another user:
    Return 1 IF:
    - EITHER you have associated the $perm_token permission
    - OR you are the user himself (view_user == current_user)
    Return 0 IF:
    - if the above doesn't hold for your OR:
    - The variable $var_value is empty (don't show lines with empty variables)
} {
    if {[empty_string_p $var_value]} { return 0 }
    if {$view_user_id == $current_user_id} { return 1 }
    return [im_permission $current_user_id $perm_token]
}



# ------------------------------------------------------------------
# "im_group_member_component" widget
# Show the users in a project or customer plus a lot of added
# functionality.
# ------------------------------------------------------------------

ad_proc -public im_show_user_style {group_member_id current_user_id group_id} {
    Determine whether the current_user should be able to see
    the group member.
    Returns 1 the name can be shown with a link,
    Returns -1 if the name should be shown without link and
    Returns 0 if the name should not be shown at all.
} {
    return 1
    

    # Show the user itself with a link.
    if {$current_user_id == $group_member_id} { return 1}

    set group_member_is_customer_p [ad_user_group_member [im_customer_group_id] $group_member_id]
    set group_member_is_freelance_p [ad_user_group_member [im_freelance_group_id] $group_member_id]
    set group_member_is_employee_p [ad_user_group_member [im_employee_group_id] $group_member_id]

    set user_is_group_admin_p [im_can_user_administer_group $group_id $current_user_id]
    set user_is_employee_p [ad_user_group_member [im_employee_group_id] $current_user_id]

    ns_log Notice "im_show_user_style: group_member:$group_member_id, current_user_id:$current_user_id, group_id:$group_id, member_is_customer:$group_member_is_customer_p, member_is_freelance:$group_member_is_freelance_p, member_is_employee:$group_member_is_employee_p, user_is_employee:$user_is_employee_p"

    # Don't show even names of customer contacts to an unprivileged user.
    # ... except he's the administrator of this group...
    if {$group_member_is_customer_p} {
	return [expr $user_is_group_admin_p || [im_permission $current_user_id view_customer_contacts]]
    }

    # Show freelance names or links, depending on permissions
    if {$group_member_is_freelance_p} {
	if {[im_permission $current_user_id view_freelancers]} {
	    return 1
	} else {
	    return -1
	}
    }

    # Default for non-employees: show only names
    if {!$user_is_employee_p} {
	return -1
    }

    # Employees Default: show the link
    return 1
}


ad_proc -public im_render_user_id { user_id user_name current_user_id group_id } {
    
} {
    if {$current_user_id == ""} { set current_user_id [ad_get_user_id] }

    # How to display? -1=name only, 0=none, 1=Link
    set show_user_style [im_show_user_style $user_id $current_user_id $group_id]
    ns_log Notice "im_render_user_id: user_id=$user_id, show_user_style=$show_user_style"

    if {$show_user_style==-1} {
	return $user_name
    }
    if {$show_user_style==1} {
	return "<A HREF=/intranet/users/view?user_id=$user_id>$user_name</A>"
    }
    return ""
}


# set company_members [im_group_member_component $customer_id $user_id $user_admin_p $return_url [im_employee_group_id]]


ad_proc -public im_group_member_component { group_id current_user_id { add_admin_links 0 } { return_url "" } { limit_to_users_in_group_id "" } { dont_allow_users_in_group_id "" } {also_add_to_group_id "" } } {

    Returns an html formatted list of all the users in the specified
    group. 

    Required Arguments:
    -------------------
    - group_id: Group we're interested in.
    - current_user_id: The user_id of the person viewing the page that
      called this function. 

    Optional Arguments:
    -------------------
    - description: A description of the group. We use pass this to the
      spam function for UI
    - add_admin_links: Boolean. If 1, we add links to add/email
      people. Current user must be member of the specified group_id to add
      him/herself
    - return_url: Where to go after we do something like add a user
    - limit_to_users_in_group_id: Only shows users who belong to
      group_id and who are also members of the group specified in
      limit_to_users_in_group_id. For example, if group_id is an intranet
      project, and limit_to_users_group_id is the group_id of the employees
      group, we only display users who are members of both the employees and
      this project groups
    - dont_allow_users_in_group_id: Similar to
      limit_to_users_in_group_id, but says that if a user belongs to the
      group_id specified by dont_allow_users_in_group_id, then don't display
      that user.  
    - also_add_to_group_id: If we're adding users to a group, we might
      also want to add them to another group at the same time. If you set
      also _add_to_group_id to a group_id, the user will be added first to
      group_id, then to also_add_to_group_id. Note that adding the person to
      both groups is NOT atomic.

    Notes:
    -------------------
    This function has quickly become complicated. Any proposals to simplify
    are welcome...

} {

# ------------------------------------------------------------------
# Create the feature box for adding and removing employees
# ------------------------------------------------------------------

    # ------------------ limit_to_users_in_group_id ---------------------
    if { [empty_string_p $limit_to_users_in_group_id] } {
	set limit_to_group_id_sql ""
    } else {
	set limit_to_group_id_sql "
and exists (select 1 
	from 
		group_member_map map2,
		groups ug
	where 
		map2.group_id = ug.group_id
		and map2.member_id = users.user_id 
		and map2.group_id = :limit_to_users_in_group_id
	)
"
    } 


    # ------------------ dont_allow_users_in_group_id ---------------------
    if { [empty_string_p $dont_allow_users_in_group_id] } {
	set dont_allow_sql ""
    } else {
	set dont_allow_sql "
and not exists (
	select 1 
	from 
		group_member_map map2, 
		groups ug
	where 
		map2.group_id = ug.group_id
		and map2.member_id = users.user_id 
		and map2.group_id = :dont_allow_users_in_group_id
	)
"
    } 

    # ------------------ Main SQL ----------------------------------------
    # Old Comment: We need a "distinct" because there can be more than one
    # Old Comment: mapping between a user and a group, one for each role.
    # 
    # fraber: Abolished the "distinct" because the role assignment page 
    # now takes care that a user is assigned only once to a group.
    # We neeed this if we want to show the role of the user.
    #
    set sql_query "
select
	users.user_id, 
	im_email_from_user_id(users.user_id) as email,
	im_name_from_user_id(users.user_id) as name,
        map.rel_type as member_role
from
	users,
	group_member_map map
where
	map.member_id = users.user_id
	and map.group_id = :group_id
	$limit_to_group_id_sql 
	$dont_allow_sql
order by lower(name)"


    # ------------------ Format the table header ------------------------
    set colspan 1
    set header_html "
      <tr> 
        <td class=rowtitle align=middle>Name</td>"
if {$add_admin_links} {
    incr colspan
    append header_html "
        <td class=rowtitle align=middle>[im_gif delete]</td>"
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

	# Return the first letter of the role (admin, member, ...)
	# defaulting to a "-" if there was not role...
	append $member_role "-"
	set profile_letter [string toupper [string range $member_role 0 0]]

	incr count
	if { $current_user_id == $user_id } { set found 1 }

	# determine how to show the user: 
	# -1: Show name only, 0: don't show, 1:Show link
	set show_user [im_show_user_style $user_id $current_user_id $group_id]
	ns_log Notice "im_group_member_component: user_id=$user_id, show_user=$show_user"

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

	append body_html "($profile_letter)
  </td>"
	if {$add_admin_links} {
	    append body_html "
  <td align=middle>
    <input type=checkbox name=delete_user value=$user_id>
  </td>"
	}
	append body_html "</tr>"
    }

    if { [empty_string_p $body_html] } {
	set body_html "<tr><td colspan=$colspan><i>none</i></td></tr>\n"
    }


    # ------------------ Format the table footer with buttons ------------
    set footer_html ""
    if {$add_admin_links} {
	append footer_html "
    <tr>
      <td align=right>
        <A HREF=/intranet/member-add?[export_url_vars group_id also_add_to_group_id return_url]>
          Add member</A>&nbsp;
      </td>"
	append footer_html "
      <td><input type=submit value=Del name=submit></td>
      </td>
    </tr>"
}

    # ------------------ Join table header, body and footer ----------------
    set html "
<form method=POST action=/intranet/member-update>
[export_form_vars group_id return_url]
    <table bgcolor=white cellpadding=1 cellspacing=1 border=0>
      $header_html
      $body_html
      $footer_html
    </table>
</form>
"
    return $html
}


# ------------------------------------------------------------------
# 
# ------------------------------------------------------------------


# Find out the user name
ad_proc -public im_get_user_name {user_id} {
    return [util_memoize "im_get_user_name_helper $user_id"]
}


ad_proc -public im_get_user_name_helper {user_id} {
    set user_name "&lt;unknown&gt;"
    if ![catch { set user_name [db_string index_get_user_first_names {
select
	first_names || ' ' || last_name as name
from
	persons
where
	person_id = :user_id

}] } errmsg] {
        # no errors
    }
    return $user_name
}

ad_proc -public im_user_group_member_p { user_id group_id } {
    Returns 1 if specified user is a member of the specified group. 0 otherwise
} {
    return [util_memoize "db_string user_member_of_group \"select decode(ad_group_member_p($user_id, $group_id), 't', 1, 0) from dual\""]
}


ad_proc -public im_user_group_admin_p { user_id group_id } {
    Returns 1 if specified user is an administrator of the specified group. 
    0 otherwise
} {
    return [util_memoize "db_string user_member_of_group \"select decode(ad_group_member_admin_role_p($user_id, $group_id), 't', 1, 0) from dual\""]
}

ad_proc -public im_user_is_employee_p { user_id } {
    Returns 1 if a the user is in the employee group. 0 Otherwise
} {
    return [im_user_group_member_p $user_id [im_employee_group_id]]
}


ad_proc -public im_user_is_freelance_p { user_id } {
    Returns 1 if a the user is in the freelance group. 0 Otherwise
} {
    set freelance_group_id [im_freelance_group_id]
    ns_log Notice "freelance_group_id=$freelance_group_id"
    ns_log Notice "user_id=$user_id"
    return [im_user_group_member_p $user_id [im_freelance_group_id]]
}


# Check if a user is authorized to enter the Intranet pages
#
ad_proc -public im_user_is_authorized {conn args why} {
    Returns filter_ok if user is employee
} {
    set user_id [ad_verify_and_get_user_id]
    if { $user_id == 0 } {
	# Not logged in
	ad_returnredirect "/register/index?return_url=[ns_urlencode [ns_conn url]?[ns_conn query]]"
	return filter_return
    }

    set is_authorized_p [im_user_is_authorized_p $user_id]
    if { $is_authorized_p > 0 } {
	return filter_ok
    } else {
	ad_return_forbidden "Access denied" "You must be an employee or otherwise authorized member of [ad_system_name] to see this page. You can <a href=/register/index?return_url=[ad_urlencode [im_url_with_query]]>login</a> as someone else if you like."
	return filter_return	
    }
}

ad_proc -public im_user_is_customer_p { user_id } {
    Returns 1 if a the user is in a customer group. 0 Otherwise
} {
    set customer_group_id [im_customer_group_id]
    return [im_user_group_member_p $user_id [im_customer_group_id]]
}


ad_proc -public im_user_is_customer {conn args why} {
    Returns filter_of if user is customer
} {
    set user_id [ad_get_user_id]
    if { $user_id == 0 } {
	# Not logged in
	ad_returnredirect "/register/index?return_url=[ns_urlencode [ns_conn url]?[ns_conn query]]"
	return filter_return
    }
    
    set is_customer_p [im_user_is_customer_p $user_id]
    if { $is_customer_p > 0 } {
	return filter_ok
    } else {
	ad_return_forbidden "Access denied" "You must be a customer of [ad_system_name] to see this page"
	return filter_return	
    }
}

ad_proc -public im_verify_user_is_admin { conn args why } {
    Returns 1 if a the user is either a site-wide administrator or 
    in the Intranet administration group
} {
    set user_id [ad_verify_and_get_user_id]
    if { $user_id == 0 } {
	# Not logged in
	ad_returnredirect "/register/index?return_url=[ns_urlencode [ns_conn url]?[ns_conn query]]"
	return filter_return
    }
    
    set val [im_is_user_site_wide_or_intranet_admin $user_id]
    if { $val > 0 } {
	return filter_ok
    } else {
	ad_return_forbidden "Access denied" "You must be an administrator of [ad_system_name] to see this page"
	return filter_return	
    }
}

ad_proc -public im_group_id_from_parameter { parameter } {
    Returns the group_id for the group with the GroupShortName
    specified in the server .ini file for $parameter. That is, we look up
    the specified parameter in the intranet module of the parameters file,
    and use that short_name to find a group id. Memoizes the result
} {
    set short_name [ad_parameter $parameter intranet]
    if { [empty_string_p $short_name] } {
	ad_return_error "Error: Missing parameter" "The parameter \"$parameter\" is not defined in the intranet section of your server's parameters file. Please define this parameter, restart your server, and try again. 
<p>Note: You can find all the current intranet parameters at <a href=http://software.arsdigita.com/parameters/ad.ini>http://software.arsdigita.com/parameters/ad.ini</a>, though this file may be more recent than your version of the ACS."
	ad_script_abort
    }

    return [util_memoize "im_group_id_from_parameter_helper $short_name"]
}

ad_proc -public im_group_id_from_parameter_helper { short_name } {
    Returns the group_id for the user_group with the specified
    short_name. If no such group exists, returns 0 
} {
    return [db_string user_group_id_from_short_name \
 	     "select group_id 
                from user_groups 
               where short_name=:short_name" -default 0]
}


ad_proc -public im_project_add_member { group_id user_id role} {
    Make a specified user a member of a (project) group
} {
    
    db_transaction {
	db_exec_plsql insert_user_group_map "
begin
  user_group_member_add(:group_id, :user_id, :role);
end;
"
    }
    
    # Second, add an empty "estimations" field that is necessary
    # for every project group member.
#    set sql "
#	insert into user_group_member_field_map values
#	(:group_id, :user_id, 'estimation_days', '')"	
#    db_transaction {
#	db_dml insert_user_member_field_map $sql
#    }

    db_release_unused_handles
}


ad_proc -public im_can_user_administer_group { { group_id "" } { user_id "" } } { 
    An intranet user can administer a given group if thery are a site-wide 
    intranet user, a general site-wide administrator, or if they belong to 
    the specified user group 
} {
    if { [empty_string_p $user_id] } {
	set user_id [ad_get_user_id]
    }
    if { $user_id == 0 } {
	return 0
    }
    set site_wide_or_intranet_user [im_is_user_site_wide_or_intranet_admin $user_id] 
    
    if { $site_wide_or_intranet_user } {
	return 1
    }

    # Else, if the user is a group admin
    return [im_user_group_admin_p $user_id $group_id]
}

ad_proc -public im_is_user_site_wide_or_intranet_admin { { user_id "" } } { Returns 1 if a user is a site-wide administrator or a member of the intranet administrative group } {
    if { [empty_string_p $user_id] } {
	set user_id [ad_verify_and_get_user_id]
    }
    if { $user_id == 0 } {
	return 0
    }
    if { [im_site_wide_admin_p $user_id] } {
	return 1
    }
    if { [im_user_intranet_admin_p $user_id] } {
	return 1
    }
    return 0
}

ad_proc -public im_user_intranet_admin_p { user_id } {
    returns 1 if the user is an intranet admin 
} {
    return [ad_user_group_member [im_admin_group_id] $user_id]
}

ad_proc -public im_site_wide_admin_p { user_id } {
    returns 1 if the user is an intranet admin 
} {
    return [util_memoize "acs_user::site_wide_admin_p -user_id $user_id"]
}


ad_proc -public im_user_is_authorized_p { user_id { second_user_id "0" } } {
    Returns 1 if a the user is authorized for the system. 0
    Otherwise. Note that the second_user_id gives us a way to say that
    this user is inded authorized to see information about another
    particular user (by being in a common group with that user).
} {
    set employee_group_id [im_employee_group_id]
    set freelance_group_id [im_freelance_group_id]
    set customer_group_id [im_customer_group_id]
    set authorized_users_group_id [im_authorized_users_group_id]

    set authorized_p [db_string user_in_authorized_intranet_group \
	    "select decode(count(*),0,0,1) as authorized_p
             from group_member_map 
             where 
                    user_id=:user_id and
                    (group_id=:employee_group_id or
                     group_id=:authorized_users_group_id or
                     group_id=:freelance_group_id or
                     group_id=:customer_group_id
                    )"]

    if { $authorized_p == 0 } {
	set authorized_p [im_is_user_site_wide_or_intranet_admin $user_id]
    }
    if { $authorized_p == 0 && $second_user_id > 0 } {
	# Let's see if this user is looking at someone else in one of their groups...
	# We let people look at other people in the same groups as them.
	set authorized_p [db_string user_in_two_groups \
		"select decode(count(*),0,0,1) as authorized_p
                   from group_member_map ugm, group_member_map ugm2
                  where ugm.user_id=:user_id
                    and ugm2.user_id=:second_user_id
                    and ugm.group_id=ugm2.group_id"]
    }
    return $authorized_p 
}


ad_proc -public im_admin_group_id { } {Returns the group_id of administrators} {
    return [util_memoize "db_string project_group_id \"select group_id from groups where group_name='P/O Admins'\""]
}

ad_proc -public im_project_group_id { } {Returns the groud_id for projects} {
    return [util_memoize "db_string project_group_id \"select group_id from groups where group_name='Projects'\""]
}

ad_proc -public im_employee_group_id { } {Returns the groud_id for employees} {
    return [util_memoize "db_string project_group_id \"select group_id from groups where group_name='Employees'\""]
}

ad_proc -public im_wheel_group_id { } {Returns the groud_id for wheel (=senior managers)} {
    return [util_memoize "db_string project_group_id \"select group_id from groups where group_name='Senior Managers'\""]
}

ad_proc -public im_pm_group_id { } {Returns the groud_id for project managers} {
    return [util_memoize "db_string project_group_id \"select group_id from groups where group_name='Project Managers'\""]
}

ad_proc -public im_accounting_group_id { } {Returns the groud_id for employees} {
    return [util_memoize "db_string project_group_id \"select group_id from groups where group_name='Accounting'\""]
}

ad_proc -public im_customer_group_id { } {Returns the groud_id for customers} {
    return [util_memoize "db_string project_group_id \"select group_id from groups where group_name='Customers'\""]
}

ad_proc -public im_partner_group_id { } {Returns the groud_id for partners} {
    return [util_memoize "db_string project_group_id \"select group_id from groups where group_name='Partners'\""]
}

ad_proc -public im_office_group_id { } {Returns the groud_id for offices} {
    return [util_memoize "db_string project_group_id \"select group_id from groups where group_name='Offices'\""]
}

ad_proc -public im_team_group_id { } {Returns the groud_id for teams} {
    return [util_memoize "db_string project_group_id \"select group_id from groups where group_name='Team'\""]
}

ad_proc -public im_authorized_users_group_id { } {Returns the groud_id for offices} {
    return [util_memoize "db_string project_group_id \"select group_id from groups where group_name='Authorized Users'\""]
}

ad_proc -public im_freelance_group_id { } {Returns the groud_id for freelancers} {
    return [util_memoize "db_string project_group_id \"select group_id from groups where group_name='Freelancers'\""]
}


ad_proc -public im_user_profile_list { user_id } {
    Return the list of all group memberships
} {
    set all_list [im_profiles_all_group_ids]
    set group_mem_sql "
select
	group_id
from
	group_distinct_member_map
where
	member_id=:user_id"

    set list [list]
    db_foreach group_mem $group_mem_sql {
	if {[lsearch $all_list $group_id] >= 0} {
	    lappend list $group_id
	}
    }
    return $list
}



ad_proc -public im_profiles_all_group_ids {} {
    Returns the list of all profiles available.
} {
    # Determine group ids
    set admin [im_admin_group_id]
    set wheel [im_wheel_group_id]
    set pm [im_pm_group_id]
    set employee [im_employee_group_id]
    set accounting [im_accounting_group_id]
    set customer [im_customer_group_id]
    set freelance [im_freelance_group_id]

    set options [list]

    lappend options $admin
    lappend options $wheel
    lappend options $pm
    lappend options $accounting
    lappend options $employee
    lappend options $customer
    lappend options $freelance

    return $options

}


ad_proc -public im_profiles_for_new_user { user_id } {
    Returns the list of profiles of new users that a specific user
    is capable to create.
} {
    # Administrators and wheel can do everything
    # Employees can create new freelancers
    # Accounting can create new clients
    # Administrators of any group can create new members

    # Determine group ids
    set admin [im_admin_group_id]
    set wheel [im_wheel_group_id]
    set pm [im_pm_group_id]
    set employee [im_employee_group_id]
    set accounting [im_accounting_group_id]
    set customer [im_customer_group_id]
    set freelance [im_freelance_group_id]

    # Determine relevant membership
    set admin_member [ad_user_group_member $admin $user_id]
    set wheel_member [ad_user_group_member $wheel $user_id]
    set pm_member [ad_user_group_member $pm $user_id]
    set employee_member [ad_user_group_member $employee $user_id]
    set accounting_member [ad_user_group_member $accounting $user_id]
    set is_admin [expr $admin_member || $wheel_member || [im_is_user_site_wide_or_intranet_admin $user_id]]

    # Determine administratorship of groups
    set employee_admin [im_can_user_administer_group $employee $user_id]
    set accounting_admin [im_can_user_administer_group $accounting $user_id]
    set customer_admin [im_can_user_administer_group $customer $user_id]
    set accounting_admin [im_can_user_administer_group $accounting $user_id]

    set options [list]

    if {$is_admin} {
	lappend options [list $admin Administrator]
	lappend options [list $wheel "Senior Manager"]
	lappend options [list $pm "Project Manager"]
    }

    if {$is_admin || $accounting_admin} {
	lappend options [list $accounting Accountant]
    }

    if {$is_admin || $employee_admin || $pm_member} {
	lappend options [list $employee Employee]
    }

    if {$is_admin || $customer_admin || $accounting_member || $accounting_admin} {
	lappend options [list $customer Client]
    }

    if {$is_admin || $employee_member || $employee_admin} {
	lappend options [list $freelance Freelance]
    }

    return $options
}

ad_proc -public im_restricted_access {} {Returns an access denied message and blows out 2 levels} {
    ad_return_forbidden "Access denied" "You must be an authorized user of the [ad_system_name] intranet to see this page. You can <a href=/register/index?return_url=[ad_urlencode [im_url_with_query]]>login</a> as someone else if you like."
    return -code return
}

ad_proc -public im_allow_authorized_or_admin_only { group_id current_user_id } {Returns an error message if the specified user is not able to administer the specified group or the user is not a site-wide/intranet administrator} {

    set user_admin_p [im_can_user_administer_group $group_id $current_user_id]

    if { ! $user_admin_p } {
	# We let all authorized users have full administrative control
	set user_admin_p [im_user_is_authorized_p $current_user_id]
    }

    if { $user_admin_p == 0 } {
	im_restricted_access
	return
    }
}

ad_proc -public im_groups_url {{-section "" -group_id "" -short_name ""}} {Sets up the proper url for the /groups stuff in acs} {
    if { [empty_string_p $group_id] && [empty_string_p $short_name] } {
	ad_return_error "Missing group_id and short_name" "We need either the short name or the group id to set up the url for the /groups directory"
    }
    if { [empty_string_p $short_name] } {
	set short_name [db_string groups_get_short_name \
		"select short_name from user_groups where group_id=:group_id"]
    }
    if { ![empty_string_p $section] } {
	set section "/$section"
    }
    return "/groups/[ad_urlencode $short_name]$section"
}

ad_proc -public im_customer_group_id_from_user {} {Sets group_id and short_name in the calling environment of the first customer_id this proc finds for the logged in user} {
    uplevel {
	set customer_group_id [im_customer_group_id]
	set local_user_id [ad_get_user_id]
	if { ![db_0or1row customer_name_from_user \
		"select g.group_id, g.short_name
		   from user_groups g, group_member_map ugm 
		  where g.group_id=ugm.group_id
		    and g.parent_group_id = :customer_group_id
		    and ugm.user_id=:local_user_id
             	    and rownum<2"] } {
            # Define the variables so we won't have errors using them
	    set group_id ""
	    set short_name ""
	}
    }
}

ad_proc -public im_bboard_restrict_access_to_group args {
    BBoard security hack
    Restricts access to a bboard if it has a group_id set for the
    specified topic_id or msg_id
} {

    if { ![im_enabled_p] || ![ad_parameter EnableIntranetBBoardSecurityFiltersP intranet 0] } {
	# no need to check anything in this case!
	return filter_ok
    }

    set form [ns_getform]
    
    if { [empty_string_p $form] } {
	# The form is empty - presumably we're not accessing any 
	# bboard topic or message!
	return filter_ok
    }
    
    # 3 ways to identify a message - see if we have any of them!
    set topic_id [ns_set get $form topic_id]
    set msg_id [ns_set get $form msg_id]
    set refers_to [ns_set get $form refers_to]

    if { ![regexp {^[0-9]+$} $topic_id] } {
        # topic_id is not an integer
        set topic_id ""
    }
    
    if { [empty_string_p $topic_id] && [empty_string_p $msg_id]  && [empty_string_p $refers_to] } {
        # Don't have a msg_id or topic_id or refers_to - can't do anything... 
        # Grant access by default
        return filter_ok
    }

    if { [empty_string_p $topic_id] } {
        # Get the topic id from whatever identifier we have
        if { [empty_string_p $msg_id] } {
            set msg_id $refers_to
        }
        set topic_id [db_string bboard_topic_from_id \
                "select topic_id from bboard where msg_id=:msg_id" -default ""]
        if { [empty_string_p $topic_id] } {
            # still no way to determine the topic, let bboard handle it
            return filter_ok
        }
    }
    
    set user_id [ad_get_user_id]
    set has_access_p 0

    if { $user_id > 0 } {
	db_1row user_can_access_bboard_topic \
		"select decode(count(*),0,0,1) as has_access_p
	           from bboard_topics t
                  where t.topic_id = :topic_id
                  and (t.group_id is null
	               or ad_group_member_p(:user_id, t.group_id) = 't')"

	if { $has_access_p == 0 } {
	    # Check if this is an intranet authorized user - they
	    # get to see everything!
	    set has_access_p [im_user_is_authorized_p $user_id]
	}
    } elseif {$user_id == 0} {
        # the user isnt loged in
	db_1row user_can_access_this_bboard_topic \
		"select decode(count(*),0,0,1) as has_access_p
	           from bboard_topics t
                  where t.topic_id = :topic_id
                    and t.group_id is null"
    }

    if { $has_access_p } {
	return filter_ok
    } 
    ad_return_forbidden "Access denied" "This section of the bboard is restricted. You must either be a member of the group who owns this topic or an authorized user of the [ad_system_name] intranet. You can <a href=/register/index?return_url=[ad_urlencode [im_url_with_query]]>login</a> as someone else if you like."
    return filter_return	
}


ad_proc -public im_hours_verify_user_id { { user_id "" } } {
    Returns either the specified user_id or the currently logged in
    user's user_id. If user_id is null, throws an error unless the
    currently logged in user is a site-wide or intranet administrator.
} {

    # Let's make sure the 
    set caller_id [ad_verify_and_get_user_id]
    if { [empty_string_p $user_id] || $caller_id == $user_id } {
        return $caller_id
    } 
    # Only administrators can edit someone else's hours
    if { [im_is_user_site_wide_or_intranet_admin $caller_id] } {
        return $user_id
    }

    # return an error since the logged in user is not editing his/her own hours
    ad_return_error "You can't edit someone else's hours" "It looks like you're trying to edit someone else's hours. Unforunately, you're not authorized to do so. You can edit your <a href=time-entry?[export_ns_set_vars url [list user_id]]>own hours</a> if you like"
    return -code return
}


ad_proc -public cl_tec_user { } {
    return if one user is member of the tec group
} {
    set user_id [ad_get_user_id]
    if { [ad_user_group_member "305" $user_id] } {
	return "filter_ok"
    } else {
	set url [ns_conn url]
	if { ![empty_string_p [ns_conn query]] } {
	    append url "?[ns_conn query]"
	}
	ad_return_forbidden "You are not an Technician"  "Sorry, but you must be logged on as a Technician to visit these pages.
	
	<p>
	
	Visit <a href=\"/register/?return_url=[ns_urlencode $url]\">/register/</a> to log in now.
	"
	# have AOLserver abort the thread
	return "filter_return"
    }
}

