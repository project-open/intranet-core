# /packages/intranet-core/tcl/intranet-profile-procs.tcl
#
# Copyright (C) 2004 - 2009 ]project-open[
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

# Profiles represent OpenACS groups used by ]project-open[
# However, for performance reasons we have introduced special
# caching and auxillary functions specific to ]po[.

# @author frank.bergmann@project-open.com


# ------------------------------------------------------------------
# Constant function
# ------------------------------------------------------------------

ad_proc -public im_profile_employees {} { 
     return [im_profile::profile_id_from_name -profile "Employees"]
}

ad_proc -public im_profile_project_managers {} { 
     return [im_profile::profile_id_from_name -profile "Project Managers"]
}

ad_proc -public im_profile_senior_managers {} { 
     return [im_profile::profile_id_from_name -profile "Senior Managers"] 
}

ad_proc -public im_profile_po_admins {} { 
     return [im_profile::profile_id_from_name -profile "P/O Admins"] 
}

ad_proc -public im_profile_customers {} { 
     return [im_profile::profile_id_from_name -profile "Customers"] 
}

ad_proc -public im_profile_inco_customers {} { 
     return [im_profile::profile_id_from_name -profile "InCo Customer"] 
}
ad_proc -public im_profile_freelancers {} { 
     return [im_profile::profile_id_from_name -profile "Freelancers"] 
}

ad_proc -public im_profile_accounting {} { 
     return [im_profile::profile_id_from_name -profile "Accounting"] 
}

ad_proc -public im_profile_sales {} { 
     return [im_profile::profile_id_from_name -profile "Sales"] 
}

ad_proc -public im_profile_hr_managers {} { 
     return [im_profile::profile_id_from_name -profile "HR Managers"] 
}

ad_proc -public im_profile_partners {} { 
     return [im_profile::profile_id_from_name -profile "Partners"] 
}

ad_proc -public im_profile_helpdesk {} { 
     return [im_profile::profile_id_from_name -profile "Helpdesk"] 
}

ad_proc -public im_profile_registered_users {} { 
    return [util_memoize [list db_string registered_users "
		select	object_id 
		from	acs_magic_objects
		where	name='registered_users'
    "]]
}



# ------------------------------------------------------------------
# Operations on Profile
# ------------------------------------------------------------------


namespace eval im_profile {

    # ------------------------------------------------------------------
    # add_member & remove_member action
    # ------------------------------------------------------------------

    ad_proc -public add_member { 
	{ -profile "" }
	{ -profile_id "" }
	-user_id:required
    } {
	Add a new member to a profile.
	Resets the cache for access to this group
    } {
	# Add the user as an approved member of the profile
	if {"" != $profile} {
	    set profile_id [profile_id_from_name -profile $profile]
	}
	if {"" == $profile_id} { return 0 }

	# Add the member to the group.
	# ToDo: Is the update_elation update really necessary?
	set rel_id [relation_add -member_state "approved" "membership_rel" $profile_id $user_id]
	db_dml update_relation "update membership_rels set member_state = 'approved' where rel_id = :rel_id"

	# Special logic: Add a P/O Admin also as a site wide admin
	if {$profile_id == [im_profile_po_admins]} {
	    permission::grant -object_id [acs_magic_object "security_context_root"] -party_id $user_id -privilege "admin"
	    im_security_alert -severity "Info" -location "im_profile::add_member" -message "New P/O Admin" -value "[im_name_from_user_id $user_id] ([im_email_from_user_id $user_id])"
	}

	# Set the new value to the cache
	set key [list member_p $profile_id $user_id]
	ns_cache set im_profile $key 1

	# Delete the saved user_options cache
	user_options_flush_cache
    }

    ad_proc -public remove_member { 
	{ -profile "" }
	{ -profile_id "" }
	-user_id:required
    } { 
	Removes a member from a profile.
	Resets the cache for access to this group
    } {
	# Get the name of the profile
	if {"" != $profile} {
	    set profile_id [profile_id_from_name -profile $profile]
	}
	if {"" == $profile_id} { return 0 }

	# Remove the user from the group
	group::remove_member -group_id $profile_id -user_id $user_id

	# Special logic: Revoking P/O Admin privileges also removes Site-Wide-Admin privs
	if {$profile_id == [im_profile_po_admins]} {
	    ns_log Notice "im_profile::remove_member: Remove P/O Admins => Remove Site Wide Admins"
	    permission::revoke -object_id [acs_magic_object "security_context_root"] -party_id $user_id -privilege "admin"

	    # Flush cached SiteWide permissions
	    util_memoize_flush_regexp "acs_user::site_wide_admin_p.*"
	}

	# Cache the result
	set key [list member_p $profile_id $user_id]
	ns_cache set im_profile $key 0

	# Delete the saved user_options cache
	user_options_flush_cache
    }

    # ------------------------------------------------------------------
    # Cached version of checking for membership
    # ------------------------------------------------------------------

    ad_proc -public member_p { 
	{ -profile "" }
	{ -profile_id "" }
	-user_id:required
    } {
	Checks if a user is member of a profile.
    } {
	# Get the profile_id
	if {"" != $profile} {
	    set profile_id [profile_id_from_name -profile $profile]
	}
	if {"" == $profile_id} { return 0 }

	# Check if we find information in the cache
	set key [list member_p $profile_id $user_id]
	if {[ns_cache get im_profile $key value]} { return $value}

	# Value not found in the cache, so calculate the value
	set member_p [member_p_not_cached -profile_id $profile_id -user_id $user_id]
	
	# Store the value in the cache
	ns_cache set im_profile $key $member_p

	return $member_p
    }

    ad_proc -private member_p_not_cached { 
	-profile_id:required
	-user_id:required
    } { 
	Checks if a user is member of a profile.
    } {
	# We are looking for direct memberships (cascade = 0) for performance reasons
	# (profiles in ]po[ are not designed to be sub-groups of another group).
	set member_sql "
		select count(*) > 0
			from	acs_rels r, 
				membership_rels mr 
			where 	r.rel_id = mr.rel_id and 
				r.object_id_two = :user_id and 
				r.object_id_one = :profile_id and 
				mr.member_state = 'approved'
	"
	set member_flag [db_string member_p $member_sql]

	# Translate from database t/f to TCL 1/0 values
	switch $member_flag {
	    t { set member_p 1 }
	    default { set member_p 0 }
	}

	return $member_p
    }


    # ------------------------------------------------------------------
    # The list of group in which a user is an aproved member
    # ------------------------------------------------------------------

    ad_proc -public profiles_for_user { 
	-user_id:required
    } {
	Returns the list of groups in which a user is a member
    } {
	# Make sure nobody is playing around...
	im_security_alert_check_integer -location profiles_for_user -value $user_id

	set profiles_sql "
		select	r.object_id_one
		from	acs_rels r, 
			membership_rels mr 
		where 	r.rel_id = mr.rel_id and 
			r.object_id_two = $user_id and 
			mr.member_state = 'approved'
		order by r.object_id_one
	"
	return [util_memoize [list db_list profiles_for_user $profiles_sql]]
    }


    # ------------------------------------------------------------------
    # Cached list of group members
    # ------------------------------------------------------------------

    ad_proc -public user_options { 
	{-profile_ids 0}
    } {
	Returns a list of (user_id user_name) tuples for all users
	that are a member of the specified profiles.
    } {
	# Check if we have calculated this result already
	set key [list user_options $profile_ids]
	# if {[ns_cache get im_profile $key value]} { return $value}

	# Calculate the options
	set user_options [user_options_not_cached -profile_ids $profile_ids]
	ns_log Notice "im_profile::user_options: profile_ids=$profile_ids, options=$user_options"

	# Store the value in the cache
	ns_cache set im_profile $key $user_options

	return $user_options

    }

    ad_proc -public user_options_not_cached { 
	{ -profile_ids 0 }
    } { 
	Returns a list of (user_id user_name) tuples for all users
	that are a member of the specified profiles.
    } {
	if {"" == $profile_ids} { return "" }
	
	return [db_list_of_lists user_options "
		select distinct
		       im_name_from_user_id(u.user_id) as name,
		       u.user_id
		from
		       users_active u,
		       group_distinct_member_map m
		where
		       u.user_id = m.member_id
		       and m.group_id in ([join $profile_ids ","])
	"]
    }

    ad_proc -public user_options_flush_cache { 
    } {
	Flushes the cache for user_options.
	It is necessary to flush all user_options cache entries
	after adding or removing a user from any group.
    } {
	foreach name [ns_cache names im_profile] {
	    if { [regexp {user_options.*} $name] } {
		 ns_cache flush im_profile $name
	    }
	}
    }


    # ------------------------------------------------------------------
    # Get the ID of a profile
    # ------------------------------------------------------------------

    ad_proc -public profile_id_from_name { 
	-profile:required
    } { 
	Return the profile_id for a given profile name (as in the DB in English)
	or "" if the profile doesn't exist
    } {
	# Check if we have calculated this result already
	set key [list pid_from_name $profile]
	if {[ns_cache get im_profile $key value]} { return $value}

	# Calculate the profile_id
	set profile_id [profile_id_from_name_not_cached -profile $profile]
	if {"" == $profile_id} { return "" }

	if {![string is integer $profile_id]} { errrrr }

	# Store the value in the cache
	ns_cache set im_profile $key $profile_id

	return $profile_id
    }

    ad_proc -public profile_id_from_name_not_cached { 
	-profile:required
    } { 
	Return the profile_id for a given profile name.
	The problem is that group names are used as constants,
	while groups are defined dynamically. 
	@return Returns the profile_id or "" if the profile doesn't
		exist.
    } {
	set profile_id [db_string profile_id_not_cached "
		select	g.group_id 
		from	groups g,
			im_profiles p
		where	g.group_id = p.profile_id and
			group_name = :profile
	" -default 0]
	return $profile_id
    }


    # ------------------------------------------------------------------
    # Get the ID of a profile
    # ------------------------------------------------------------------

    ad_proc -public profile_name_from_id { 
	{-translate_p 1}
	{-locale ""}
	{-current_user_id 0}
	-profile_id:required
    } { 
	Return a translated profile name for an ID.
    } {
	# Get the user's locale
	if {0 == $current_user_id} { set current_user_id [ad_get_user_id] }
	if {"" == $locale} { set locale [lang::user::locale -user_id $current_user_id] }
	if {!$translate_p} { set locale "en_US" }

	# Check if we have calculated this result already
	set key [list profile_name_from_id $profile_id $locale]
	if {[ns_cache get im_profile $key value]} { return $value}

	# Calculate the profile
	set profile [profile_name_from_id_not_cached -locale $locale -profile_id $profile_id]
	if {"" == $profile} { return "" }

	# Store the value in the cache
	ns_cache set im_profile $key $profile

	return $profile
    }

    ad_proc -public profile_name_from_id_not_cached { 
	-locale:required
	-profile_id:required
    } { 
	Return the profile_id for a given profile name.
	The problem is that group names are used as constants,
	while groups are defined dynamically. 
	@return Returns the profile_id or "" if the profile doesn't
		exist.
    } {
	set group_name [db_string profile_id_not_cached "
		select	g.group_name 
		from	groups g
		where	g.group_id = :profile_id
	" -default ""]

	regsub -all {[ /]} $group_name "_" group_key
	set group_name [lang::message::lookup "" intranet-core.Profile_$group_key $group_name]

	return $group_name
    }

    # ------------------------------------------------------------------
    # Cache Maintenance
    # ------------------------------------------------------------------

    ad_proc -public flush_cache { } { 
	Remove all cache entries for debugging purposes.
	This should not be necessary during normal operations.
    } {
	foreach name [ns_cache names im_profile] {
	    ns_cache flush im_profile $name
	}
    }


    # ------------------------------------------------------------------
    # User Profile Box
    # ------------------------------------------------------------------

    ad_proc -public profile_component { 
	{-size 12} 
	user_id 
	{ disabled "" }
    } {
	Returns a piece of HTML representing a multi-
	select box with the profiles of the user.
	
	@param user_id User to show
	@param disabled Set to "disabled" to show the widget in a 
	disabled state.
    } {
	# get the current profile of this user
	set current_profiles [profile_options_of_user $user_id]
	
	set cp [list]
	foreach p $current_profiles { lappend cp [lindex $p 1] } 
	ns_log Notice "im_user_profile_component: current_profiles=$current_profiles"
	ns_log Notice "im_user_profile_component: cp=$cp"
	
	# A list of lists containing profile_id/profile_name tuples
	set all_profiles [profile_options_all]
	ns_log Notice "im_user_profile_component: all_profiles=$all_profiles"
	
	set profile_html "<select name=profile size=$size multiple $disabled>"
	
	foreach profile_tuple $all_profiles {

	    set group_name [lindex $profile_tuple 0]
	    set group_id [lindex $profile_tuple 1]

	    set selected [lsearch -exact $cp $group_id]
	    if {$selected > -1} {
		append profile_html "<option value=$group_id selected>$group_name</option>\n"
	    } else {
		append profile_html "<option value=$group_id>$group_name</option>\n"
	    }
	}
	append profile_html "</select>\n"
	
	return $profile_html
    }
    

    # ------------------------------------------------------------------
    # Options for option box
    # ------------------------------------------------------------------

    ad_proc -public profile_options_all {
	{ -translate_p 1 }
	{ -locale ""}
    } {
	Returns the list of all available profiles in the system.
	The returned list consists of (group_id - group_name) tuples.
    } {
	# Get the list of all profiles
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
	set options [list]

	db_foreach profile_options_of_user $profile_sql {
	    if {$translate_p} {
		regsub -all {[ /]} $group_name "_" group_key
		set group_name [lang::message::lookup $locale intranet-core.Profile_$group_key $group_name]
	    }
	    lappend options [list $group_name $group_id]
	}

	return $options
    }


    ad_proc -public profile_options_of_user { 
	user_id 
    } {
	Returns a list of the profiles of the current user.
	The returned list consists of (group_id - group_name) tuples.
    } {
	# Get the list of profiles for the current user
	set profile_sql {
	select DISTINCT
		g.group_name,
		g.group_id
	from
		acs_objects o,
		groups g,
		group_member_map m,
		membership_rels mr
	where
		m.member_id = :user_id
		and m.group_id = g.group_id
		and g.group_id = o.object_id
		and o.object_type = 'im_profile'
		and m.rel_id = mr.rel_id
		and mr.member_state = 'approved'
	}

	set options [list]
	db_foreach profile_options_of_user $profile_sql {
	    regsub -all {[ /]} $group_name "_" group_key
	    set group_name [lang::message::lookup "" intranet-core.Profile_$group_key $group_name]
	    lappend options [list $group_name $group_id]
	}

	return $options
    }

    ad_proc -public profile_options_managable_for_user { 
	{ -privilege "admin" }
	user_id 
    } {
	Returns the list of (group_name - group_id) tupels for
	all profiles that a user can manage.<br>
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
			and perm.privilege = :privilege
			and g.group_id = o.object_id
			and o.object_type = 'im_profile'
	"

	# We need a special treatment for Admin in order to
	# bootstrap the system...
	if {$user_is_admin_p} {
	    set profile_sql {
		select	g.group_name,
			g.group_id
		from	acs_objects o,
			groups g
		where	g.group_id = o.object_id
			and o.object_type = 'im_profile'
		order by lower(g.group_name)
	    }
	}

	set options [list]
	db_foreach profile_options_of_user $profile_sql {
	    regsub -all {[ /]} $group_name "_" group_key
	    set group_name [lang::message::lookup "" intranet-core.Profile_$group_key $group_name]
	    lappend options [list $group_name $group_id]
	}
	return $options
    }

}

