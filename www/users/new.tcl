# /packages/intranet-core/www/users/new.tcl
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

    @author unknown@arsdigita.com
    @author frank.bergmann@project-open.com

} -query {
    { referer "/acs-admin/users" }
    { user_id 0 }
} -properties {
    context:onevalue
    export_vars:onevalue
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
set user_is_employee_p [im_user_is_employee_p $current_user_id]
set user_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]

set page_title "Add a user"
set context [list [list "." "Users"] "Add user"]

set next_url user-add-2
set self_register_p 1
set return_url "/intranet/users/"


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
# Continue with code from 
# /packages/acs-subsite/lib/user-new.tcl
# ---------------------------------------------------------------

# Redirect to HTTPS if so configured
if { [security::RestrictLoginToSSLP] } {
    security::require_secure_conn
}

# Pre-generate user_id for double-click protection
set user_id [db_nextval acs_object_id_seq]

ad_form -name register -export {next_url user_id return_url} -form [auth::get_registration_form_elements]


# fraber 20040123: Adding the list of profiles that
# the current user can administer
ad_form -extend -name register -form {
    {profile:text(multiselect),multiple
        {label "Group Membership"}
        {options $profile_list }
	{-html {size 8}}
    }
}


if { [exists_and_not_null rel_group_id] } {
    ad_form -extend -name register -form {
        {rel_group_id:integer(hidden),optional}
    }

    if { [permission::permission_p -object_id $rel_group_id -privilege "admin"] } {
        ad_form -extend -name register -form {
            {rel_type:text(select)
                {label "Role"}
                {options {[group::get_rel_types_options -group_id $rel_group_id]}}
            }
        }
    } else {
        ad_form -extend -name register -form {
            {rel_type:text(hidden)
                {value "membership_rel"}
            }
        }
    }
}

ad_form -extend -name register -on_request {
    # Populate elements from local variables

} -on_submit {

    db_transaction {
        array set creation_info [auth::create_user \
                                     -user_id $user_id \
                                     -verify_password_confirm \
                                     -username $username \
                                     -email $email \
                                     -first_names $first_names \
                                     -last_name $last_name \
                                     -screen_name $screen_name \
                                     -password $password \
                                     -password_confirm $password_confirm \
                                     -url $url \
                                     -secret_question $secret_question \
                                     -secret_answer $secret_answer]
     
        if { [string equal $creation_info(creation_status) "ok"] && [exists_and_not_null rel_group_id] } {
            group::add_member \
                -group_id $rel_group_id \
                -user_id $user_id \
                -rel_type $rel_type
        }

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

		ns_log Notice "/users/new: => del_member\n"
		group::add_member \
		    -group_id $group_id \
		    -user_id $user_id \
		    -rel_type "membership_rel"
	    }

	}

    }


if {0} {


    # Handle registration problems
    
    switch $creation_info(creation_status) {
        ok {
            # Continue below
        }
        default {
            # Adding the error to the first element, but only if there are no element messages
            if { [llength $creation_info(element_messages)] == 0 } {
                array set reg_elms [auth::get_registration_elements]
                set first_elm [lindex [concat $reg_elms(required) $reg_elms(optional)] 0]
                form set_error register $first_elm $creation_info(creation_message)
            }
                
            # Element messages
            foreach { elm_name elm_error } $creation_info(element_messages) {
                form set_error register $elm_name $elm_error
            }
            break
        }
    }

    switch $creation_info(account_status) {
        ok {
            # Continue below
        }
        default {
            # Display the message on a separate page
            ad_returnredirect [export_vars -base "[subsite::get_element -element url]register/account-closed" { { message $creation_info(account_message) } }]
            ad_script_abort
        }
    }


}


} -after_submit {



if {0} {

    if { ![empty_string_p $next_url] } {
        # Add user_id and account_message to the URL
        
        ad_returnredirect [export_vars -base $next_url {user_id password {account_message $creation_info(account_message)}}]
        ad_script_abort
    } 


    # User is registered and logged in
    if { ![exists_and_not_null return_url] } {
        # Redirect to subsite home page.
        set return_url [subsite::get_element -element url]
    }

    # If the user is self registering, then try to set the preferred
    # locale (assuming the user has set it as a anonymous visitor
    # before registering).
    if { $self_register_p } {
	# We need to explicitly get the cookie and not use
	# lang::user::locale, as we are now a registered user,
	# but one without a valid locale setting.
	set locale [ad_get_cookie "ad_locale"]
	if { ![empty_string_p $locale] } {
	    lang::user::set_locale $locale
	    ad_set_cookie -replace t -max_age 0 "ad_locale" ""
	}
    }

    # Handle account_message
    if { ![empty_string_p $creation_info(account_message)] && $self_register_p } {
        # Only do this if user is self-registering
        # as opposed to creating an account for someone else
        ad_returnredirect [export_vars -base "[subsite::get_element -element url]register/account-message" { { message $creation_info(account_message) } return_url }]
        ad_script_abort
    } else {
        # No messages
        ad_returnredirect $return_url
        ad_script_abort
    }

}

}








