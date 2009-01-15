# /packages/intranet-core/www/users/new.tcl
#
# Copyright (C) 2003-2004 various parties
# The code is based on OpenACS 5
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
    Adding a user

    @author unknown@openacs.org
    @author frank.bergmann@project-open.com

    @param also_add_to_biz_object Takes an array in "array get" format.
	   The array object_id -> role_id allows to add the user to
	   multiple business objects (project, company) in different roles.
	   The current_user_id must have write permissions to these objects.
} -query {
    { referer "/acs-admin/users" }
    { user_id "" }
    { profile:multiple,optional }
    { return_url "/intranet/users/" }
    { email ""}
    { first_names ""}
    { username ""}
    { last_name ""}
    { secret_question "" }
    { secret_answer "" }
    { also_add_to_biz_object "" }
} -properties {
    context:onevalue
    export_vars:onevalue
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

# "Profile" changes its value, possibly because of strange
# ad_form sideeffects
if {[exists_and_not_null profile]} {
    ns_log Notice "/users/new: profile=$profile"
    set profile_org $profile
} else {
    ns_log Notice "/users/new: profile=NULL"
    set profile_org [list]
}

set current_user_id [ad_maybe_redirect_for_registration]
set current_user_is_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]

set page_title "[_ intranet-core.Add_a_user]"
set context [list [list "." "[_ intranet-core.Users]"] "[_ intranet-core.Add_user]"]
set ip_address [ad_conn peeraddr]
set next_url user-add-2
set self_register_p 1

# Should we show the "Username" field of the user?
set show_username_p [parameter::get_from_package_key \
	-package_key intranet-core \
	-parameter EnableUsersUsernameP \
	-default 0]

# We need the field if we go for non-email login...
if {![auth::UseEmailForLoginP]} { set show_username_p 1 }


# Get the list of profiles managable for current_user_id
set managable_profiles [im_profiles_managable_for_user $current_user_id]
ns_log Notice "/users/new: managable_profiles=$managable_profiles"

# Extract only the profile_ids from the managable profiles
set managable_profile_ids [list]
foreach g $managable_profiles {
    lappend managable_profile_ids [lindex $g 0]
}
ns_log Notice "/users/new: managable_profile_ids=$managable_profile_ids"



if {[im_permission $current_user_id view_users]} {
    set context_bar [im_context_bar [list /intranet/users/ "Users"] $page_title]
} else {
    set context_bar [im_context_bar $page_title]
}

# Check if we are editing an already existing user...
set editing_existing_user 0
if {"" != $user_id} { 
    set editing_existing_user [db_string get_user_count "select count(*) from parties where party_id = :user_id"]
}
ns_log Notice "/users/new: editing_existing_user=$editing_existing_user, user_id=$user_id, email=$email"


if {$editing_existing_user} {

    # Permissions for existing user: We need to be able to admin him:
    im_user_permissions $current_user_id $user_id view read write admin

    if {!$write} {
	ad_return_complaint 1 "<li>[_ intranet-core.lt_You_have_insufficient_3]"
	return
    }

    set user_details_sql "
select
	pe.first_names,
	pe.last_name,
	pa.email,
	pa.url,
	u.screen_name,
	u.username
from
	parties pa
	left outer join persons pe on (pa.party_id = pe.person_id)
	left outer join users u on (pa.party_id = u.user_id)
where
	pa.party_id = :user_id
"
    db_0or1row get_user_details $user_details_sql

    # The user already exists - let's get his list of profiles
    set users_profiles [im_profiles_of_user $user_id]
    ns_log Notice "/users/new: users_profiles=$users_profiles"
    set profile_values [list]
    foreach p $users_profiles { 
	lappend profile_values [lindex $p 0] 
    }
    ns_log Notice "/users/new: profile_values=$profile_values"

} else {

    # Check if current_user_id can create new users
    if {![im_permission $current_user_id add_users]} {
	ad_return_complaint 1 "<li>[_ intranet-core.lt_You_have_insufficient_4]"
	return
    }

    # Pre-generate user_id for double-click protection
    set user_id [db_nextval acs_object_id_seq]

    # Empty set of default values for a new user
    set profile_values [list]
}
ns_log Notice "/users/new: user_id=$user_id, current_user_id=$current_user_id, email=$email"

# Check if there is an LDAP support module installed
set ldap_installed_p [db_string ldap_installed "
	select count(*) 
	from apm_enabled_package_versions 
	where package_key = 'intranet-ldap'
" -default 0]

# ---------------------------------------------------------------
# Continue with code from 
# /packages/acs-subsite/lib/user-new.tcl
# ---------------------------------------------------------------

# Redirect to HTTPS if so configured
if { [security::RestrictLoginToSSLP] } {
    security::require_secure_conn
}

ad_form -name register -export {next_url user_id return_url} -form { 
    {email:text(text) {label "[_ intranet-core.Email]"} {html {size 30}}}
}

ad_form -extend -name register -form {
    {username:text(text),optional {label "[lang::message::lookup {} intranet-core.Username Username]"} {html {size 30}}}
}

ad_form -extend -name register -form {
    {first_names:text(text) {label "[_ intranet-core.First_names]"} {html {size 30}}}
    {last_name:text(text) {label "[_ intranet-core.Last_name]"} {html {size 30}}} 
}

if {!$editing_existing_user && !$ldap_installed_p} {
    ad_form -extend -name register -form {
	{password:text(password),optional {label "[_ intranet-core.Password]"} {html {size 20}}} 
	{password_confirm:text(password),optional {label "[_ intranet-core.lt_Password_Confirmation]"} {html {size 20}}} 
	{secret_question:text(hidden),optional value {}} 
	{secret_answer:text(hidden),optional value {}}
	{also_add_to_biz_object:text(hidden),optional}
    }
}

# Screen Name is not being used in P/O...
ad_form -extend -name register -form {
    {screen_name:text(hidden),optional {label "[_ intranet-core.Screen_name]"} {html {size 30}}} 
}

ad_form -extend -name register -form {
    {url:text(text),optional {label "[_ intranet-core.lt_Personal_Home_Page_UR]"} {html {size 50 value "http://"}}} 
}


# ---------------------------------------------------------------
# Build a Multiple select box with the users profiles
# ---------------------------------------------------------------


# Change the order of the inner list elements for
# the OpenACS 5.0 form elements:
set managable_profiles_reverse [list]
foreach option $managable_profiles {
    set profile_id [lindex $option 0]
    set group_name [lindex $option 1]
    lappend managable_profiles_reverse [list $group_name $profile_id]
}
ns_log Notice "/users/new: managable_profiles_reverse=$managable_profiles_reverse"
ns_log Notice "/users/new: profile_values=$profile_values"



# Fraber 051123: Don't show the profile to the user
# himself, unless it's an administrator.
set edit_profiles_p 0
if {[llength $managable_profiles_reverse] > 0} { set edit_profiles_p 1 }
if {!$current_user_is_admin_p && ($user_id == $current_user_id)} { set edit_profiles_p 0}

if {$edit_profiles_p} {
    ad_form -extend -name register -form {
	{profile:text(multiselect),multiple
	    {label "[_ intranet-core.Group_Membership]"}
	    {options $managable_profiles_reverse }
	    {values $profile_values }
	    {html {size 12}}
	}
    }
}

im_dynfield::append_attributes_to_form \
    -object_type "person" \
    -form_id "register" \
    -object_id $user_id


# ---------------------------------------------------------------
# Other elements...
# ---------------------------------------------------------------

ad_form -extend -name register -on_request {
    # Populate elements from local variables
    
} -on_submit {
    
    if {[info exists password] && [info exists password_confirm] && ![string equal $password $password_confirm]} {
	ad_return_complaint 1 [lang::message::lookup "" intranet-core.Passwords_Dont_Match "The password confirmation doesn't match the password"]
	return
    }

    if {!$editing_existing_user} {

	set auth_info_hash [im_user_create_new_user \
				-username $username \
				-email $email \
				-first_names $first_names \
				-last_name $last_name \
				-url $url \
				-user_id $user_id \
				-screen_name $screen_name \
				-password $password \
				-password_confirm $password_confirm \
				-secret_question $secret_question \
				-secret_answer $secret_answer \
			       ]
	
	array set creation_info $auth_info_hash
	switch $creation_info(creation_status) {
	    ok {
		set user_id $creation_info(user_id)
		# Continue below
	    }
	    default {
		# Adding the error to the first element, but only 
		# if there are no element messages
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
	
    }

    # Store dynamic fields
    set form_id "register"
    set object_type "person"
    
    im_dynfield::append_attributes_to_form \
	-object_type $object_type \
	-form_id $form_id \
	-object_id $user_id
    
    im_dynfield::attribute_store \
	-object_type $object_type \
	-object_id $user_id \
	-form_id $form_id   

    # Call the "user_create" or "user_update" user_exit
    if {$editing_existing_user} {
	im_user_exit_call user_update $user_id
    } else {
	im_user_exit_call user_create $user_id
    }


} -after_submit {

    if {!$editing_existing_user} {
	if { ![empty_string_p $next_url] } {
	    # Add user_id and account_message to the URL
	    ad_returnredirect [export_vars -base $next_url {user_id password return_url {account_message $creation_info(account_message)}}]
	    ad_script_abort
	}
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
    if {!$editing_existing_user} {
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

    # Fallback:
    if { [exists_and_not_null return_url] } {
	ad_returnredirect $return_url
    } else {
	ad_returnredirect "/intranet/users/"
    }
}
