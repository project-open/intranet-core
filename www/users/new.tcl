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
} -query {
    { referer "/acs-admin/users" }
    { user_id "" }
    { profile:multiple,optional }
    { return_url "/intranet/users/" }
    { email ""}
    { first_names ""}
    { last_name ""}
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

set page_title "[_ intranet-core.Add_a_user]"
set context [list [list "." "[_ intranet-core.Users]"] "[_ intranet-core.Add_user]"]
set ip_address [ad_conn peeraddr]
set next_url user-add-2
set self_register_p 1


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
    set context_bar [ad_context_bar [list /intranet/users/ "Users"] $page_title]
} else {
    set context_bar [ad_context_bar $page_title]
}

# Check if we are editing an already existing user...
set editing_existing_user 0
if {"" != $user_id} { 
    set editing_existing_user [db_string get_user_count "select count(*) from users where user_id=:user_id"]
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
	u.screen_name
from
	persons pe,
	parties pa,
	users u
where
	pe.person_id = :user_id
	and pe.person_id = pa.party_id
	and pe.person_id = u.user_id
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
    {username:text(hidden),optional value {}}
    {first_names:text(text) {label "[_ intranet-core.First_names]"} {html {size 30}}}
    {last_name:text(text) {label "[_ intranet-core.Last_name]"} {html {size 30}}} 
}

if {!$editing_existing_user} {
    ad_form -extend -name register -form {
	{password:text(password),optional {label "[_ intranet-core.Password]"} {html {size 20}}} 
	{password_confirm:text(password),optional {label "[_ intranet-core.lt_Password_Confirmation]"} {html {size 20}}} 
	{secret_question:text(hidden),optional value {}} 
	{secret_answer:text(hidden),optional value {}}
    }
}

# Screen Name is not being used in P/O...
ad_form -extend -name register -form {
    {screen_name:text(hidden),optional {label "[_ intranet-core.Screen_name]"} {html {size 30}}} 
}

ad_form -extend -name register -form {
    {url:text(text),optional {label "[_ intranet-core.lt_Personal_Home_Page_UR]"} {html {size 50 value "http://"}}} 
}



# ad_form -name register -export {next_url user_id return_url} -form [auth::get_registration_form_elements]


ns_log Notice "/users/new: reg_elements=[auth::get_registration_form_elements]"

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


if {[llength $managable_profiles_reverse] > 0} {
    # fraber 20040123: Adding the list of profiles that
    # the current user can administer
    ad_form -extend -name register -form {
	{profile:text(multiselect),multiple
	    {label "[_ intranet-core.Group_Membership]"}
	    {options $managable_profiles_reverse }
	    {values $profile_values }
	    {-html {size 8}}
	}
    }
}


# ---------------------------------------------------------------
# Other elements...
# ---------------------------------------------------------------

ad_form -extend -name register -on_request {
    # Populate elements from local variables

} -on_submit {

#	20041124 fraber: disabled db_transaction because of problems with PostgreSQL?
#    db_transaction {
	
	# Do we create a new user or do we edit an existing one?
	ns_log Notice "/users/new: editing_existing_user=$editing_existing_user"
	
	if {!$editing_existing_user} {

	    # New user: create from scratch
	    set email [string trim $email]
	    set similar_user [db_string similar_user "select party_id from parties where lower(email) = lower(:email)" -default 0]
	    
	    if {$similar_user > 0} {
			set view_similar_user_link "<A href=/intranet/users/view?user_id=$similar_user>[_ intranet-core.user]</A>"
			ad_return_complaint 1 "<li><b>[_ intranet-core.Duplicate_UserB]<br>
        	        [_ intranet-core.lt_There_is_already_a_vi]<br>"
			return
	    }

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


	    # Add the user to the "Registered Users" group, because
	    # (s)he would get strange problems otherwise
	    set registered_users [db_string registered_users "select object_id from acs_magic_objects where name='registered_users'"]
	    relation_add -member_state "approved" "membership_rel" $registered_users $user_id

	    # Add a users_contact record to the user since the 3.0 PostgreSQL
	    # port, because we have dropped the outer join with it...
	    catch { db_dml add_users_contact "insert into users_contact (user_id) values (:user_id)" } errmsg
	    catch { db_dml add_user_preferences "insert into user_preferences (user_id) values (:user_id)" } errmsg

	} else {

	    # Existing user: Update variables
	    set auth [auth::get_register_authority]
	    set user_data [list]

	    ns_log Notice "/users/new: person::update -person_id=$user_id -first_names=$first_names -last_name=$last_name"
	    person::update \
		-person_id $user_id \
		-first_names $first_names \
		-last_name $last_name
	    
	    ns_log Notice "/users/new: party::update -party_id=$user_id -url=$url -email=$email"
	    party::update \
		-party_id $user_id \
		-url $url \
		-email $email
	    
	    ns_log Notice "/users/new: acs_user::update -user_id=$user_id -screen_name=$screen_name"
	    acs_user::update \
		-user_id $user_id \
		-screen_name $screen_name
	    
	}

	ns_log Notice "/users/new: finished big IF clause"

	
        set membership_del_sql "
        select
                r.rel_id
        from
                acs_rels r,
                acs_objects o
        where
                object_id_two = :user_id
                and object_id_one = :profile_id
                and r.object_id_one = o.object_id
                and o.object_type = 'im_profile'
                and rel_type = 'membership_rel'
        "

	# Profile changes its value, possibly because of strange
	# ad_form sideeffects
	ns_log Notice "/users/new: profile=$profile"
	ns_log Notice "/users/new: profile_org=$profile_org"

	foreach profile_tuple [im_profiles_all] {

	    # don't enter into setting and unsetting profiles
	    # if the user has no right to change profiles.
	    # Probably this is a freelancer or company
	    # who is editing himself.
	    if {0 == [llength $managable_profiles]} { break }

	    ns_log Notice "profile_tuple=$profile_tuple"
	    set profile_id [lindex $profile_tuple 0]
	    set profile_name [lindex $profile_tuple 1]
	    
	    set is_member [db_string is_member "select count(*) from group_distinct_member_map where member_id=:user_id and group_id=:profile_id"]

	    set should_be_member 0
	    if {[lsearch -exact $profile_org $profile_id] >= 0} {
		set should_be_member 1
	    }
	    
	    ns_log Notice "/users/new: profile_name=$profile_name, profile_id=$profile_id, should_be_member=$should_be_member, is_member=$is_member"

	    if {$is_member && !$should_be_member} {
		ns_log Notice "/users/new: => remove_member from $profile_name\n"

		if {[lsearch -exact $managable_profile_ids $profile_id] < 0} {
		    ad_return_complaint 1 "<li>
                    [_ intranet-core.lt_You_are_not_allowed_t]"
                   return
		}

		# db_dml delete_profile $delete_rel_sql
		db_foreach membership_del $membership_del_sql {
		    ns_log Notice "/users/new: Going to delete rel_id=$rel_id"
		    membership_rel::delete -rel_id $rel_id
		}

		# Special logic: Revoking P/O Admin privileges also removes
		# Site-Wide-Admin privs
		if {$profile_id == [im_profile_po_admins]} { 
		    ns_log Notice "users/new: Remove P/O Admins => Remove Site Wide Admins"
		    permission::revoke -object_id [acs_magic_object "security_context_root"] -party_id $user_id -privilege "admin"
		}



	    }

	    
	    if {!$is_member && $should_be_member} {
		ns_log Notice "/users/new: => add_member to profile $profile_name\n"

		# Check if the profile_id belongs to the managable profiles of
		# the current user. Normally, only the managable profiles are
		# shown, which means that a user must have played around with
		# the HTTP variables in oder to fool us...
		if {[lsearch -exact $managable_profile_ids $profile_id] < 0} {
		    ad_return_complaint 1 "<li>
                    [_ intranet-core.lt_You_are_not_allowed_t_1]"
		    return
		}

		# Make the user a member of the group (=profile)
		ns_log Notice "/users/new: => relation_add $profile_id $user_id"
		set rel_id [relation_add -member_state "approved" "membership_rel" $profile_id $user_id]
		db_dml update_relation "update membership_rels set member_state='approved' where rel_id=:rel_id"
		

		# Special logic for employees and P/O Admins:
		# PM, Sales, Accounting, SeniorMan => Employee
		# P/O Admin => Site Wide Admin
		if {$profile_id == [im_profile_project_managers]} { 
		    ns_log Notice "users/new: Project Managers => Employees"
		    set rel_id [relation_add -member_state "approved" "membership_rel" [im_profile_employees] $user_id]
		    db_dml update_relation "update membership_rels set member_state='approved' where rel_id=:rel_id"
		}

		if {$profile_id == [im_profile_accounting]} { 
		    ns_log Notice "users/new: Accounting => Employees"
		    set rel_id [relation_add -member_state "approved" "membership_rel" [im_profile_employees] $user_id]
		    db_dml update_relation "update membership_rels set member_state='approved' where rel_id=:rel_id"
		}

		if {$profile_id == [im_profile_sales]} { 
		    ns_log Notice "users/new: Sales => Employees"
		    set rel_id [relation_add -member_state "approved" "membership_rel" [im_profile_employees] $user_id]
		    db_dml update_relation "update membership_rels set member_state='approved' where rel_id=:rel_id"
		}

		if {$profile_id == [im_profile_senior_managers]} { 
		    ns_log Notice "users/new: Senior Managers => Employees"
		    set rel_id [relation_add -member_state "approved" "membership_rel" [im_profile_employees] $user_id]
		    db_dml update_relation "update membership_rels set member_state='approved' where rel_id=:rel_id"
		}

		if {$profile_id == [im_profile_po_admins]} { 
		    ns_log Notice "users/new: P/O Admins => Site Wide Admins"
		    permission::grant -object_id [acs_magic_object "security_context_root"] -party_id $user_id -privilege "admin"
		}

		
	    }
	}


	# Add a im_employees record to the user since the 3.0 PostgreSQL
	# port, because we have dropped the outer join with it...
	if {[db_table_exists im_employees]} {
	    
	    # Simply add the record to all users, even it they are not employees...
	    set im_employees_exist [db_string im_employees_exist "select count(*) from im_employees where employee_id = :user_id"]
	    if {!$im_employees_exist} {
		db_dml add_im_employees "insert into im_employees (employee_id) values (:user_id)"
	    }
	}

# 20041124 fraber: disabled db_transaction for PostgreSQL
	# Close db_transaction
#    }
    

    # Handle registration problems
    if {!$editing_existing_user} {
	
	switch $creation_info(creation_status) {
	    ok {
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

    if {!$editing_existing_user} {
	if { ![empty_string_p $next_url] } {
	    # Add user_id and account_message to the URL
	    ad_returnredirect [export_vars -base $next_url {user_id password {account_message $creation_info(account_message)}}]
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









