# /packages/intranet-core/www/users/profile-update.tcl
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

ad_page_contract {
    Adding a user by an administrator

} {
    user_id:integer
    {return_url "/intranet/users/" }
    profile:multiple,optional
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
set user_is_employee_p [im_user_is_employee_p $current_user_id]
set user_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]

set page_title "Update Profile"
set context [list [list "." "Users"] $page_title]

if {$user_is_employee_p} {
    set context_bar [ad_context_bar [list /intranet/users/ "Users"] $page_title]
} else {
    set context_bar [ad_context_bar $page_title]
}


# ---------------------------------------------------------------
# Get the list of profiles that the current_user can create
# ---------------------------------------------------------------

set option_list [im_profiles_for_new_user $current_user_id]
set all_profiles_list [im_profiles_all_group_ids]

if {![llength $option_list]} {
    set err_msg "You have insufficient permissions to create a new user."
    ad_return_error "Insufficient Permissions" $err_msg
}

# Change the order of the inner list elements for
# the OpenACS 5.0 form elements:
#
set profile_list [list]
foreach option $option_list {
    set group_id [lindex $option 0]
    set group_name [lindex $option 1]
    lappend profile_list [list $group_name $group_id]
}

# ---------------------------------------------------------------
# Get users variables if called with a valid user_id
# ---------------------------------------------------------------

db_1row get_user_info "
select
	u.screen_name,
	pa.email,
	pa.url,
	pe.first_names,
	pe.last_name
from
	users u,
	parties pa,
	persons pe
where
	u.user_id = :user_id
	and u.user_id = pa.party_id
	and u.user_id = pe.person_id"

# get the list of group memberships of this user


if {[info exists profile]} {
    ns_log Notice "profile=$profile"
} else {
    ns_log Notice "profile=<does not exist>"

    # Set profile to the current list of groups
    set profile [im_user_profile_list $user_id]
    ns_log Notice "profile=$profile"
}



# ------------------------------------------------------
# Start the form
# ------------------------------------------------------

template::form create update_user

if {[template::form is_request update_user]} {

}

template::element create update_user user_id \
    -widget hidden \
    -datatype text \
    -value $user_id

template::element create update_user first_names \
    -widget text \
    -datatype text \
    -label "First Names" \
    -html { size 40 } \
    -value $first_names

template::element create update_user last_name \
    -widget text \
    -datatype text \
    -label "Last Name" \
    -html { size 40 } \
    -value $last_name

template::element create update_user profile \
    -widget multiselect \
    -datatype text \
    -label "Group Membership" \
    -html {size 8} \
    -options $profile_list \
    -values $profile


# ------------------------------------------------------
# Add/update the user
# ------------------------------------------------------

if [template::form is_valid update_user] {

#    form get_values update_user profile 

	foreach group_id [im_profiles_all_group_ids] {
	    ns_log Notice "group_id=$group_id"

	    set is_member 0
	    set is_member [db_string is_member "select count(*) from group_distinct_member_map where member_id=:user_id and group_id=:group_id"]

	    set should_be_member 0
	    if {[lsearch -exact $profile $group_id] >= 0} {
		set should_be_member 1
	    }

	    ns_log Notice "/users/new: group_id 	=$group_id"
	    ns_log Notice "/users/new: should_be_member	=$should_be_member"
	    ns_log Notice "/users/new: is_member	=$is_member"

	    if {$is_member && !$should_be_member} {
		# Remove the user from the group
		ns_log Notice "/users/new: => remove_member\n"
		group::remove_member \
		    -group_id $group_id \
		    -user_id $user_id
	    }


	    if {!$is_member && $should_be_member} {
		# Add the member to the specified group

		ns_log Notice "/users/new: => add_member\n"
		group::add_member \
		    -group_id $group_id \
		    -user_id $user_id \
		    -rel_type "membership_rel"
	    }
	}

	ad_returnredirect $return_url

}
    
db_release_unused_handles

