# /packages/intranet-core/tcl/intranet-profile-procs.tcl
#
# Copyright (C) 2004 Project/Open
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

# @author frank.bergmann@project-open.com


# ------------------------------------------------------------------
# User Profile Box
# ------------------------------------------------------------------

ad_proc -public im_user_profile_component { user_id { disabled "" }} {
    Returns a piece of HTML representing a multi-
    select box with the profiles of the user.

    @param user_id User to show
    @param disabled Set to "disabled" to show the widget in a 
    disabled state.
} {
    # get the current profile of this user
    set current_profiles [im_profiles_of_user $user_id]
    set cp [list]
    foreach p $current_profiles { lappend cp [lindex $p 0] } 
    ns_log Notice "/users/view: current_profiles=$current_profiles"
    ns_log Notice "/users/view: cp=$cp"

    # A list of lists containing profile_id/profile_name tuples
    set all_profiles [im_profiles_all]
    ns_log Notice "/users/view: all_profiles=$all_profiles"
    
    set profile_html "
<select name=profile size=8 multiple $disabled>
"

    foreach profile $all_profiles {
        set group_id [lindex $profile 0]
        set group_name [lindex $profile 1]
        set selected [lsearch -exact $cp $group_id]
        if {$selected > -1} {
	    append profile_html "<option value=$group_id selected>$group_name</option>\n"
        } else {
	    append profile_html "<option value=$group_id>$group_name</option>\n"
        }
    }
    append profile_html "</select>\n"
}


# ------------------------------------------------------------------
# Get various sets of profiles
# ------------------------------------------------------------------

ad_proc -public im_profiles_all {} {
    Returns the list of all available profiles in the system.
    The returned list consists of (group_id - group_name) tuples.
} {
    # Get the list of all profiles
    set profile_sql {
select
	g.group_id,
	g.group_name
from
	acs_objects o,
	groups g
where
	g.group_id = o.object_id
	and o.object_type = 'im_profile'
order by lower(g.group_name)
}
    # Make a list
    set options [list]
    db_foreach profiles $profile_sql {
	lappend options [list $group_id "$group_name"]
    }
    return $options
}


ad_proc -public im_profiles_of_user { user_id } {
    Returns a list of the profiles of the current user.
    The returned list consists of (group_id - group_name) tuples.
} {
    # Get the list of profiles for the current user
    set profile_sql {
select DISTINCT
        g.group_id,
	g.group_name
from
        acs_objects o,
        groups g,
        group_member_map m
where
        m.member_id = :user_id
        and m.group_id = g.group_id
        and g.group_id = o.object_id
        and o.object_type = 'im_profile'
    }

    # Make a list
    set options [list]
    db_foreach profiles $profile_sql {
	lappend options [list $group_id "$group_name"]
    }
    return $options
}


ad_proc -public im_profiles_managable_for_user { user_id } {
    Returns the list of (group_name - group_id) tupels for
    all profiles that a user can manage<br>
    This function allows for a kind of "sub-administrators"
    where for example Employees are able to manage Freelancers.<BR>
    This list may be empty in the case of unprivileged users
    such as companies or freelancers.
} {
    set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]

    # Get the list of all profiles administratable
    # by the current user.
    set profile_sql "
select DISTINCT
	g.group_name,
	g.group_id
from
	acs_objects o,
	groups g,
	all_object_party_privilege_map perm
where
	perm.object_id = g.group_id
	and perm.party_id = :user_id
	and perm.privilege = 'admin'
	and g.group_id = o.object_id
	and o.object_type = 'im_profile'
order by lower(g.group_name)
"

    # We need a special treatment for Admin in order to
    # bootstrap the system...
    if {$user_is_admin_p} {
	set profile_sql {
select
        g.group_name,
	g.group_id
from
        acs_objects o,
        groups g
where
        g.group_id = o.object_id
        and o.object_type = 'im_profile'
order by lower(g.group_name)
	}
    }

    # Make a list
    set options [list]
    db_foreach profiles $profile_sql {
	lappend options [list $group_id "$group_name"]
    }
    return $options
}

