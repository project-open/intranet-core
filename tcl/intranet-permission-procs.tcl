# /packages/intranet-core/tcl/intranet-permissions-procs.tcl
#
# Copyright (C) 2004 Project/Open
# The code is based on work from ArsDigita ACS 3.4
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
    Project/Open specific permissions routines.
    The P/O permission model is based on the OpenACS model,
    extending it by several concepts:
    <ul>
      <li>"Global Permissions":<br>
          These permissions are not related to any particular
          object. They are implemented as privileges on the
          "Main Site" object for the specific groups ("Profiles")
      <li>"Business Object Permissions":<br>
          Access permissions for Business Objects such as Projects, 
          Customers, Offices,... are defined in terms of the
          membership of individual users to their "administration
          group". "Membership" in this context refers to a variety
          of relationship types with OpenACS the default types 
          membership_rel and admin_rel as predefined relationships.
	  However, other relationship types are specified by 
	  application modules, such as the translator_rel, editor_rel,
	  etc. by the translation modules or analyst_rel, designer_rel,
	  developer_rel etc. by a project methodology module. 
	  These relationship types have an effect on the behaviour of 
	  components  associated to the biz-objects such as the 
	  P/O Filestorage or the P/O Translation Workflow.
      <li>"User Permission Matrix":<BR>
	  Define what user group is allowed to manage what
	  other user group. For examples, "Employees" are may
	  be entiteled to manage "Freelancers".
    </ul>
    @author Frank Bergmann (fraber@fraber.de)
}


# ------------------------------------------------------------------
# Core Permissions
# ------------------------------------------------------------------

# Define the set of Core privileges
#
ad_proc -public im_core_privs {} {
    Returns the list of all available privileges for P/O Core.
    These privs only cover the core functionality, additional
    modules define their own privs with respect to their own
    "subsite" (package).<BR>
    The content of this list must by synced with the 
    /sql/intranet-permissions.sql file so that all privileges
    used here are defined.
} {
    set privilege_sql "select privilege from acs_privileges order by upper(privilege)"
    set privileges [list]
    db_foreach privileges_loop $privilege_sql {

	# Skip privileges that start with "acs_"
	if {[regexp {acs_.*} $privilege]} { continue }

	# Skip privileges view, read, write, admin, delete
	set plen [string length $privilege]
	if {$plen < 7} { continue }

	lappend privileges $privilege
    }
    return $privileges
}


#!!! remove!
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

    set view 1
    set read 1
    set write 1
    set admin 1

    return

    # --------------------------------------------------
    # Start of logic for "view"
    # --------------------------------------------------

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

    # --------------------------------------------------
    # End of logic for "view"
    # --------------------------------------------------









    # Also accept "user_id_from_search" instead of user_id (the one to edit...)
    if [info exists user_id_from_search] { set user_id $user_id_from_search}
    
    set current_user_is_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]
    set current_user_is_wheel_p [ad_user_group_member [im_wheel_group_id] $current_user_id]
    set current_user_is_employee_p [im_user_is_employee_p $current_user_id]
    set current_user_admin_p [expr $current_user_is_admin_p || $current_user_is_wheel_p]
    
    set user_is_customer_p [ad_user_group_member [im_customer_group_id] $user_id]
    set user_is_freelance_p [ad_user_group_member [im_freelance_group_id] $user_id]
    set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
    set user_is_wheel_p [ad_user_group_member [im_wheel_group_id] $user_id]
    set user_is_employee_p [im_user_is_employee_p $user_id]

    # Determine the type of the user to view:
    set user_type "none"
    if {$user_is_freelance_p} { set user_type "freelance" }
    if {$user_is_employee_p} { set user_type "employee" }
    if {$user_is_customer_p} { set user_type "customer" }
    if {$user_is_wheel_p} { set user_type "wheel" }
    if {$user_is_admin_p} { set user_type "admin" }

    set yourself_p [expr $user_id == $current_user_id]

    # Determine the list of group memberships of this user
    
    set profile_list [list]

    if {[im_site_wide_admin_p $user_id]} {
	lappend profile_list "SiteAdmin"
    }

    foreach group_id [im_profiles_all_group_ids] {
	if {[ad_user_group_member $group_id $user_id]} {
	    lappend profile_list [db_string group_name "select group_name from groups where group_id=:group_id"]
	}
    }


    # --------------------------------------------------------
    # Check if "user" belongs to a group that is administered by 
    # the current users
    set administrated_user_ids [db_list administated_user_ids "
select distinct
	m2.member_id
from
	group_member_map m,
	group_distinct_member_map m2
where
	m.member_id=:current_user_id
	and m.rel_type='admin_rel'
	and m.group_id=m2.group_id
"]

    set user_in_administered_project 0
    if {[lsearch -exact $administrated_user_ids $user_id] > -1} { 
	set user_in_administered_project 1
    }

    # -------------- Permission Matrix ----------------

    set view_user 0
    set edit_user 0
    set show_admin_links $current_user_admin_p

    switch $user_type {
	freelance {
	    # Check the freelance access rights directy from im_permissions
	    set view_user [im_permission $current_user_id view_freelancers]
	    set edit_user [im_permission $current_user_id edit_freelancers]
	    if {$user_in_administered_project} {set view_user 1}

	    # Allows freelance administrators to delete/... 
	    if {$edit_user} {set show_admin_links 1}
	}

	employee {
	    set view_user [expr $current_user_is_employee_p || $current_user_admin_p]
	    set edit_user $current_user_admin_p
	    if {$user_in_administered_project} {set view_user 1}
	}

	customer {
	    set view_user [im_permission $current_user_id view_customer_contacts]
	    set edit_user $current_user_admin_p
	    if {$user_in_administered_project} {set view_user 1}
	}

	wheel {
	    set view_user [expr $current_user_is_employee_p || $current_user_admin_p]
	    set edit_user $current_user_is_admin_p
	}

	admin {
	    set view_user [expr $current_user_is_employee_p || $current_user_admin_p]
	    set edit_user $current_user_is_admin_p
	}

	none {
	    # a user who has registered from the web site
	    set view_user [expr $current_user_is_employee_p || $current_user_admin_p]
	    set edit_user $current_user_admin_p
	}

	default {
	    ad_return_complaint 1 "
        <li>Internal Error: Bad user type<br>
	User \#$user_id does not belong to a known group.<br>
	Please notify your system administrator."
	    return
	}
    }


    # Editing a user implies being able to see it.
    if {$edit_user} {
	set view_user 1
    }

    # Everybody is allowed to see and edit him/herself,
    # so skip all security checks if it's yourself.
    if {$yourself_p} {
	set view_user 1
	set edit_user 1
    }

    ns_log Notice "users/view: user_type=$user_type"
    ns_log Notice "users/view: yourself_p=$yourself_p"
    ns_log Notice "users/view: user_in_administered_project=$user_in_administered_project"
    ns_log Notice "users/view: view_user=$view_user"
    ns_log Notice "users/view: edit_user=$edit_user"
}



ad_proc -public im_project_permissions {user_id project_id view_var read_var write_var admin_var} {
    Fill the "by-reference" variables read, write and admin
    with the permissions of $user_id on $project_id
} {
    upvar $view_var view
    upvar $read_var read
    upvar $write_var write
    upvar $admin_var admin

    set view 1
    set read 0
    set write 0
    set admin 0

    set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
    set user_is_wheel_p [ad_user_group_member [im_wheel_group_id] $user_id]
    set user_is_group_member_p [ad_user_group_member $project_id $user_id]
    set user_is_group_admin_p [im_can_user_administer_group $project_id $user_id]
    set user_is_employee_p [im_user_is_employee_p $user_id]
    set user_in_project_group_p [db_string user_belongs_to_project "select decode ( ad_group_member_p ( :user_id, $project_id ), 'f', 0, 1 ) from dual" ]

    # Admin permissions to global + intranet admins + group administrators
    set user_admin_p [expr $user_is_admin_p || $user_is_group_admin_p]
    set user_admin_p [expr $user_admin_p || $user_is_wheel_p]

    set write $user_admin_p
    set admin $user_admin_p

    ns_log Notice "user_is_admin_p=$user_is_admin_p"
    ns_log Notice "user_is_group_member_p=$user_is_group_member_p"
    ns_log Notice "user_is_group_admin_p=$user_is_group_admin_p"
    ns_log Notice "user_is_employee_p=$user_is_employee_p"
    ns_log Notice "user_admin_p=$user_admin_p"

    # Let the customers see their projects.
    db_1row project_customer "select customer_id, project_status_id from im_projects where project_id=:project_id"

    set user_is_project_customer_p [ad_user_group_member $customer_id $user_id]

    if {$user_admin_p} { set read 1}
    if {$user_is_project_customer_p} { set read 1}
    if {$user_is_group_member_p} { set read 1}
    if {[im_permission $user_id view_projects_all]} { set read 1}

    # customers and freelancers are not allowed to see non-open projects.
    if {![im_permission $user_id view_projects_history] && $project_status_id != [ad_parameter "ProjectStatusOpen" "intranet" "0"]} {
	
	# Except their own projects...
	if {!$user_is_project_customer_p} {
	    set read 0
	}
    }

    # No read - no write...
    if {!$read} {
	set write 0
	set admin 0
    }
}



ad_proc -public im_office_permissions {user_id office_id view_var read_var write_var admin_var} {
    Fill the "by-reference" variables read, write and admin
    with the permissions of $user_id on $office_id.<BR>
    The permissions depend on whether the office is a customers office or
    an internal office:
    <ul>
      <li>Internal Offices:<br>
	  Are readable by all employees
      <li>Customer Offices:<br>
	  Need either global customer access permissions
	  or the user needs to be in the admin_group of
	  the respective customer.
    </ul>
    Write and administration rights are only for administrators
    and the customer key account managers.

} {
    upvar $view_var view
    upvar $read_var read
    upvar $write_var write
    upvar $admin_var admin

    set view 1
    set read 0
    set write 0
    set admin 0

    # Check if the customer is "internal"
    set customer_type [db_1row customer_type "
select
	im_category_from_id(c.customer_type_id) as customer_type,
	o.admin_group_id as office_admin_group_id,
	c.admin_group_id as customer_admin_group_id
from
	im_offices o,
	im_customers c
where
	o.office_id = :office_id
	and o.customer_id = c.customer_id(+)
"]

    if {"" == $office_admin_group_id} { set office_admin_group_id 0}
    if {"" == $customer_admin_group_id} { set customer_admin_group_id 0}

    ns_log Notice "im_office_permission: customer_type=$customer_type"

    # Now there are three options:
    # NULL: not assigned to any customer yet
    # 'internal': An internal office and
    # != 'internal': A customers office

    # Internal office: Allow employees to see the offices and
    # Senior Managers to change them (or similar, as defined
    # in the permission module)
    if {[string equal "internal" $customer_type]} {
	set user_is_office_member_p [ad_user_group_member $office_admin_group_id $user_id]
	set user_is_office_admin_p [im_can_user_administer_group $office_admin_group $user_id]

	set admin [im_permission $user_id edit_internal_offices]
	set read [im_permission $user_id view_internal_offices]

	if {$user_is_office_admin_p} { set admin 1 }
	if {$user_is_office_member_p} { set read 1}

	if {$admin} { set read 1}
	set write $admin
	return
    }
    
    # The office if a customers office or a "dangeling" office
    # (office without a customer)

    set user_is_customer_member_p [ad_user_group_member $customer_admin_group_id $user_id]
    set user_is_customer_admin_p [im_can_user_administer_group $customer_admin_group_id $user_id]

    set read [expr $user_is_customer_member_p || [im_permission $user_id view_customer_contacts]]
    set admin $user_is_customer_admin_p
    set write $admin

    if {$admin} { set read 1 }
}



# Intranet permissions scheme - permissions are associated to groups.
#
ad_proc -public im_permission {user_id action} {
    Returns true or false, depending whether the user can execute
    the specified action.
    Uses a cache to reduce DB traffic.

<pre>
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
    view_projects_all
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
    view_hours_all
    view_allocations

    Other:
    search_intranet  
</pre>
} {
    set subsite_id [ad_conn subsite_id]
    set result [ad_permission_p $subsite_id $action]
    ns_log Notice "im_permission($action)=$result"
    return $result
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

# ------------------------------------------------------------------
# 
# ------------------------------------------------------------------

#!!!
ad_proc -public im_user_group_member_p { user_id group_id } {
    Returns 1 if specified user is a member of the specified group. 0 otherwise
} {
    return [util_memoize "db_string user_member_of_group \"select decode(ad_group_member_p($user_id, $group_id), 't', 1, 0) from dual\""]
}


#!!!
ad_proc -public im_user_group_admin_p { user_id group_id } {
    Returns 1 if specified user is an administrator of the specified group. 
    0 otherwise
} {
    return [util_memoize "db_string user_member_of_group \"select decode(ad_group_member_admin_role_p($user_id, $group_id), 't', 1, 0) from dual\""]
}

#!!!
ad_proc -public im_user_is_employee_p { user_id } {
    Returns 1 if a the user is in the employee group. 0 Otherwise
} {
    return [im_user_group_member_p $user_id [im_employee_group_id]]
}


#!!!
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
#!!!
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

#!!!
ad_proc -public im_user_is_customer_p { user_id } {
    Returns 1 if a the user is in a customer group. 0 Otherwise
} {
    set customer_group_id [im_customer_group_id]
    return [im_user_group_member_p $user_id [im_customer_group_id]]
}


#!!!
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

#!!!
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

#!!!
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

#!!!
ad_proc -public im_group_id_from_parameter_helper { short_name } {
    Returns the group_id for the user_group with the specified
    short_name. If no such group exists, returns 0 
} {
    return [db_string user_group_id_from_short_name \
 	     "select group_id 
		from user_groups 
	       where short_name=:short_name" -default 0]
}


#!!!
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

#!!!
ad_proc -public im_user_intranet_admin_p { user_id } {
    returns 1 if the user is an intranet admin 
} {
    return [ad_user_group_member [im_admin_group_id] $user_id]
}

#!!!
ad_proc -public im_site_wide_admin_p { user_id } {
    returns 1 if the user is an intranet admin 
} {
    return [util_memoize "acs_user::site_wide_admin_p -user_id $user_id"]
}


#!!!
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


#!!!
ad_proc -public im_admin_group_id { } {Returns the group_id of administrators} {
    return [util_memoize "db_string project_group_id \"select group_id from groups where group_name='P/O Admins'\""]
}

#!!!
ad_proc -public im_employee_group_id { } {Returns the groud_id for employees} {
    return [util_memoize "db_string project_group_id \"select group_id from groups where group_name='Employees'\""]
}

#!!!
ad_proc -public im_wheel_group_id { } {Returns the groud_id for wheel (=senior managers)} {
    return [util_memoize "db_string project_group_id \"select group_id from groups where group_name='Senior Managers'\""]
}

#!!!
ad_proc -public im_pm_group_id { } {Returns the groud_id for project managers} {
    return [util_memoize "db_string project_group_id \"select group_id from groups where group_name='Project Managers'\""]
}

#!!!
ad_proc -public im_accounting_group_id { } {Returns the groud_id for employees} {
    return [util_memoize "db_string project_group_id \"select group_id from groups where group_name='Accounting'\""]
}

#!!!
ad_proc -public im_customer_group_id { } {Returns the groud_id for customers} {
    return [util_memoize "db_string project_group_id \"select group_id from groups where group_name='Customers'\""]
}

#!!!
ad_proc -public im_partner_group_id { } {Returns the groud_id for partners} {
    return [util_memoize "db_string project_group_id \"select group_id from groups where group_name='Partners'\""]
}

#!!!
ad_proc -public im_office_group_id { } {Returns the groud_id for offices} {
    return [util_memoize "db_string project_group_id \"select group_id from groups where group_name='Offices'\""]
}

#!!!
ad_proc -public im_freelance_group_id { } {Returns the groud_id for freelancers} {
    return [util_memoize "db_string project_group_id \"select group_id from groups where group_name='Freelancers'\""]
}

#!!!
ad_proc -public im_restricted_access {} {Returns an access denied message and blows out 2 levels} {
    ad_return_forbidden "Access denied" "You must be an authorized user of the [ad_system_name] intranet to see this page. You can <a href=/register/index?return_url=[ad_urlencode [im_url_with_query]]>login</a> as someone else if you like."
    return -code return
}

#!!!
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

#!!!
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

#!!!
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
