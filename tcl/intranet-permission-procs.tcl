# /packages/intranet-core/tcl/intranet-permissions-procs.tcl
#
# Copyright (C) 2004 various authors
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
    ]project-open[specific permissions routines.
    The P/O permission model is based on the OpenACS model,
    extending it by several concepts:
    <ul>
      <li>"Global Permissions":<br>
          These permissions are not related to any particular
          object. They are implemented as privileges on the
          "Main Site" object for the specific groups ("Profiles")
      <li>"Business Object Permissions":<br>
          Access permissions for Business Objects such as Projects, 
          Companies, Offices,... are defined in terms of the
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
    @author various@arsdigita.com
    @author frank.bergmann@project-open.com
}

# -------------------------------------------------
# Constant functions - group abreviations
# -------------------------------------------------

ad_proc -public im_admin_group_id { }		{ return [im_profile_po_admins] }
ad_proc -public im_employee_group_id { } 	{ return [im_profile_employees] }
ad_proc -public im_wheel_group_id { } 		{ return [im_profile_senior_managers] }
ad_proc -public im_pm_group_id { }		{ return [im_profile_project_managers] }
ad_proc -public im_accounting_group_id { }	{ return [im_profile_accounting] }
ad_proc -public im_customer_group_id { }	{ return [im_profile_customers] }
ad_proc -public im_inco_customer_group_id { }	{ return [im_profile_inco_customers] }
ad_proc -public im_hr_group_id { }		{ return [im_profile_hr_managers] }
ad_proc -public im_freelance_group_id { }	{ return [im_profile_freelancers] }
ad_proc -public im_partner_group_id { }		{ return [im_profile_partners] }
ad_proc -public im_registered_users_group_id {} { return [im_profile_registered_users] }

# ------------------------------------------------------------------
# Core Permissions
# ------------------------------------------------------------------

# Define the set of Core privileges
#
ad_proc -public im_core_privs {filter_str} {
    Returns the list of all available privileges for P/O Core.
    These privs only cover the core functionality, additional
    modules define their own privs with respect to their own
    "subsite" (package).<BR>
    The content of this list must by synced with the 
    /sql/intranet-permissions.sql file so that all privileges
    used here are defined.
} {

    if { ""==$filter_str } {
	set privilege_sql "select privilege from acs_privileges order by upper(privilege)"
    } else {	
	set privilege_sql "select privilege from acs_privileges where pretty_name ilike '%$filter_str%' order by upper(privilege)"
    }

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


ad_proc -public im_permission_flush {} {
    Cleanup the "memoize" cache for permissions.
    We have to call this routine after any change in the global
    permission system such as /admin/permissions/user_matrix/ or
    /admin/permissions/profiles/.
} {
    # Call the global "flusher" with the ".*" regexp which should
    # match all entries.

    util_memoize_flush_regexp "ad.*"
    util_memoize_flush_regexp "im.*"
    util_memoize_flush_regexp "db.*"
    util_memoize_flush_regexp "acs.*"
    util_memoize_flush_regexp "file.*"

    # ToDo: Remove this and replace by more controlled flushs
    util_memoize_flush_regexp ".*"

    # Clear the specific cache for profile - user rels
    im_profile::flush_cache

    # Clear company cache
    im_company::flush_cache

#    util_memoize_flush_regexp "ad_permission.*"
#    util_memoize_flush_regexp "im_permission.*"
#    util_memoize_flush_regexp "db_string.*"
#    util_memoize_flush_regexp "acs_user.*"
}


# Intranet permissions scheme:
# Permission refer to "privileges" or type of actions that 
# a user can perform
#
ad_proc -public im_permission {user_id privilege} {
    Returns true or false, depending whether the user can execute
    the specified action.<br>
    Uses a cache to reduce DB traffic.
} {
#    return [im_permission_helper $user_id $privilege]
    return [util_memoize "im_permission_helper $user_id $privilege" 3600]
}


ad_proc im_permission_helper {user_id privilege} {
    Cached helper for:
    Returns true or false, depending whether the user can execute
    the specified action.<br>
    Uses a cache to reduce DB traffic.
} {
    set subsite_id [util_memoize [list ad_conn subsite_id] 1000000]
    set result [permission::permission_p -no_cache -party_id $user_id -object_id $subsite_id -privilege $privilege]
    return $result
}


ad_proc -public im_object_permission {
    -object_id
    { -user_id "" }
    {-privilege "read"}
    {-max_age ""}
} {
    Returns 1 (true) or 0 (false), depending whether the user has the permission on the specified object.
} {
    if {"" == $user_id} { set user_id [ad_get_user_id] }
    set read_p [util_memoize "db_string operm {select im_object_permission_p($object_id, $user_id, '$privilege')}"]
    return [string equal $read_p "t"]
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
    Returns a rendered HTML component showing a user according to the
    viewing users permissions. There are three options:<br>
    The component can return a link to the UserViewPage if the current
    user has the permission to view it, it may return an empty string,
    if the current user has no permissions at all, and it may contain
    a name only for ???
} {
    if {$current_user_id == ""} { set current_user_id [ad_get_user_id] }
    if {$user_id == ""} { return "" }

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

ad_proc -public im_render_user_id2 { 
    user_id 
} {
    Returns a rendered HTML component showing a user according to the
    viewing users permissions. There are three options:<br>
    The component can return a link to the UserViewPage if the current
    user has the permission to view it, it may return an empty string,
    if the current user has no permissions at all, and it may contain
    a name only for ???
} {
    set current_user_id [ad_get_user_id]
    if {$user_id == ""} { return "" }

    # How to display? -1=name only, 0=none, 1=Link
    set group_id 0
    set show_user_style [im_show_user_style $user_id $current_user_id $group_id]

    if {$show_user_style == 0} { return "" }

    set user_name [util_memoize [list db_string uname "select im_name_from_user_id(:user_id)"]]

    if {$show_user_style == -1} {
	return $user_name
    }
    if {$show_user_style == 1} {
	return "<A HREF=/intranet/users/view?user_id=$user_id>$user_name</A>"
    }
    return ""
}


# ------------------------------------------------------------------
# 
# ------------------------------------------------------------------

# ToDo: Remove and replace by im_profile::member_p calls
ad_proc -public im_user_group_member_p { user_id group_id } {
    Returns 1 if specified user is a member of the specified group. 0 otherwise
} {
    return [im_profile::member_p -profile_id $group_id -user_id $user_id]
}


# ToDo: replace by im_profile::member_p 
ad_proc -public im_user_is_employee_p { user_id } {
    Returns 1 if a the user is in the employee group. 0 Otherwise
} {
    return [im_profile::member_p -profile_id [im_employee_group_id] -user_id $user_id]
}

# ToDo: replace by im_profile::member_p
ad_proc -public im_user_is_freelance_p { user_id } {
    Returns 1 if a the user is in the freelance group. 0 Otherwise
} {
    return [im_profile::member_p -profile_id [im_freelance_group_id] -user_id $user_id]
}

# ToDo: replace by im_profile::member_p
ad_proc -public im_user_is_customer_p { user_id } {
    Returns 1 if a the user is in a customer group. 0 Otherwise
} {
    return [im_profile::member_p -profile_id [im_customer_group_id] -user_id $user_id]
}

# ToDo: replace by im_profile::member_p
ad_proc -public im_user_is_inco_customer_p { user_id } {
    Returns 1 if a the user is in a inco customer group. 0 Otherwise
} {
    return [im_profile::member_p -profile_id [im_inco_customer_group_id] -user_id $user_id]
}

# ToDo: replace by im_profile::member_p
ad_proc -public im_user_is_hr_p { user_id } {
    Returns 1 if a the user is in the HR Managers group.
} {
    return [im_profile::member_p -profile_id [im_hr_group_id] -user_id $user_id]
}

# ToDo: replace by im_profile::member_p
ad_proc -public im_user_is_accounting_p { user_id } {
    Returns 1 if a the user is in the Accounting group.
} {
    return [im_profile::member_p -profile_id [im_accounting_group_id] -user_id $user_id]
}

# ToDo: replace by im_profile::member_p
ad_proc -public im_user_is_admin_p { user_id } {
    Returns 1 if a the user is in a customer group. 0 Otherwise
} {
    return [im_is_user_site_wide_or_intranet_admin $user_id]
}


# -----------------------------------------------------
# Deprecated procs
# -----------------------------------------------------

ad_proc -public im_is_user_site_wide_or_intranet_admin { 
    { user_id "" } 
} { 
    Returns 1 if a user is a site-wide administrator or a 
    member of the intranet administrative group 
} {
    if { [empty_string_p $user_id] } { set user_id [ad_verify_and_get_user_id] }
    if { $user_id == 0 } { return 0 }

    if { [util_memoize [list acs_user::site_wide_admin_p -user_id $user_id] 60] } { return 1 }
    if { [im_profile::member_p -profile_id [im_admin_group_id] -user_id $user_id] } { return 1 }
    return 0
}


