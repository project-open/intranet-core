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

    util_memoize_flush_regexp ".*"

#    util_memoize_flush_regexp "ad_permission.*"
#    util_memoize_flush_regexp "im_permission.*"
#    util_memoize_flush_regexp "db_string.*"
#    util_memoize_flush_regexp "acs_user.*"
}


# Intranet permissions scheme - permissions are associated to groups.
#
ad_proc -public im_permission {user_id privilege} {
    Returns true or false, depending whether the user can execute
    the specified action.<br>
    Uses a cache to reduce DB traffic.
} {
    return [util_memoize "im_permission_helper $user_id $privilege" 60]
#    return [im_permission_helper $user_id $privilege]
}


ad_proc im_permission_helper {user_id privilege} {
    Cached helper for:
    Returns true or false, depending whether the user can execute
    the specified action.<br>
    Uses a cache to reduce DB traffic.
} {
    set subsite_id [ad_conn subsite_id]
    set result [permission::permission_p -no_cache -party_id $user_id -object_id $subsite_id -privilege $privilege]
    return $result
}


ad_proc -public im_object_permission {
    -object_id
    -user_id 
    {-privilege "read"}
    {-max_age ""}
} {
    Returns 1 (true) or 0 (false), depending whether the user has the permission on the specified object.
} {
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

# ------------------------------------------------------------------
# 
# ------------------------------------------------------------------

#!!!
ad_proc -public im_user_group_member_p { user_id group_id } {
    Returns 1 if specified user is a member of the specified group. 0 otherwise
} {
    return [string equal "t" [util_memoize "db_string user_member_of_group \"select ad_group_member_p($user_id, $group_id) from dual\""]]
}


###!!!
ad_proc -public im_user_group_admin_p { user_id group_id } {
    Returns 1 if specified user is an administrator of the specified group. 
    0 otherwise
} {
    return [string equal "t" [util_memoize "db_string user_member_of_group \"select ad_group_member_admin_role_p($user_id, $group_id) from dual\""]]
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


#!!!
ad_proc -public im_user_is_customer_p { user_id } {
    Returns 1 if a the user is in a customer group. 0 Otherwise
} {
    set customer_group_id [im_customer_group_id]
    return [im_user_group_member_p $user_id [im_customer_group_id]]
}


#!!!
ad_proc -public im_user_is_hr_p { user_id } {
    Returns 1 if a the user is in the HR Managers group.
} {
    return [im_user_group_member_p $user_id [im_hr_group_id]]
}


ad_proc -public im_is_user_site_wide_or_intranet_admin { { user_id "" } } { 
    Returns 1 if a user is a site-wide administrator or a 
    member of the intranet administrative group 
} {
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
    return [util_memoize "acs_user::site_wide_admin_p -user_id $user_id" 60]
}


ad_proc -public im_admin_group_id { } {Returns the group_id of administrators} {
    return [util_memoize "db_string project_group_id \"select group_id from groups where group_name='P/O Admins'\" -default 0"]
}

ad_proc -public im_employee_group_id { } {Returns the group_id for employees} {
    return [util_memoize "db_string project_group_id \"select group_id from groups where group_name='Employees'\" -default 0"]
}

ad_proc -public im_wheel_group_id { } {Returns the group_id for wheel (=senior managers)} {
    return [util_memoize "db_string project_group_id \"select group_id from groups where group_name='Senior Managers'\" -default 0"]
}

ad_proc -public im_pm_group_id { } {Returns the group_id for project managers} {
    return [util_memoize "db_string project_group_id \"select group_id from groups where group_name='Project Managers'\" -default 0"]
}

ad_proc -public im_accounting_group_id { } {Returns the group_id for employees} {
    return [util_memoize "db_string project_group_id \"select group_id from groups where group_name='Accounting'\" -default 0"]
}

ad_proc -public im_customer_group_id { } {Returns the group_id for customers} {
    return [util_memoize "db_string project_group_id \"select group_id from groups where group_name='Customers'\" -default 0"]
}

ad_proc -public im_partner_group_id { } {Returns the group_id for partners} {
    return [util_memoize "db_string project_group_id \"select group_id from groups where group_name='Partners'\" -default 0"]
}

ad_proc -public im_office_group_id { } {Returns the group_id for offices} {
    return [util_memoize "db_string project_group_id \"select group_id from groups where group_name='Offices'\" -default 0"]
}

ad_proc -public im_freelance_group_id { } {Returns the group_id for freelancers} {
    return [util_memoize "db_string project_group_id \"select group_id from groups where group_name='Freelancers'\" -default 0"]
}

ad_proc -public im_hr_group_id { } {Returns the group_id for Human Resources} {
    return [util_memoize "db_string project_group_id \"select group_id from groups where group_name='HR Managers'\" -default 0"]
}
