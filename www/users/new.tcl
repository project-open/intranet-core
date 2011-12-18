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

# ToDo:  
# set return_url [remove_var_from_url "feedback_message_key"] 

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
set user_feedback ""

if { [info exists profile] } {
    if { [lsearch -exact $profile [im_profile_freelancers]] >= 0 && [llength $profile] >1 } {
	set feedback_message_key "intranet-core.VerifyProfile" 
    }
}

# Should we show the "Username" field of the user?
set show_username_p [parameter::get_from_package_key -package_key intranet-core -parameter EnableUsersUsernameP -default 0]

# Should we show the "Authority" field of the user?
set show_authority_p [parameter::get_from_package_key -package_key intranet-core -parameter EnableUsersAuthorityP -default 0]

# We need the field if we go for non-email login...
if {![auth::UseEmailForLoginP]} { set show_username_p 1 }


# Get the list of profiles managable for current_user_id
set managable_profiles [im_profile::profile_options_managable_for_user $current_user_id]
ns_log Notice "/users/new: managable_profiles=$managable_profiles"

# Extract only the profile_ids from the managable profiles
set managable_profile_ids [list]
foreach g $managable_profiles {
    lappend managable_profile_ids [lindex $g 1]
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


# Set default authority to "local"
set authority_id [db_string auth "select min(authority_id) from auth_authorities"]

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
		u.username,
		u.authority_id
	from
		parties pa
		left outer join persons pe on (pa.party_id = pe.person_id)
		left outer join users u on (pa.party_id = u.user_id)
	where
		pa.party_id = :user_id
    "
    db_0or1row get_user_details $user_details_sql

    # The user already exists - let's get his list of profiles
    set users_profiles [im_profile::profile_options_of_user $user_id]
    ns_log Notice "/users/new: users_profiles=$users_profiles"
    set profile_values [list]
    foreach p $users_profiles { 
	lappend profile_values [lindex $p 1] 
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

if {$show_authority_p} {
    set auth_options [db_list_of_lists auth_options "
	select	short_name, authority_id
	from	auth_authorities
	order by short_name
    "]
    ad_form -extend -name register -form {
	{authority_id:text(select),optional {label "[lang::message::lookup {} intranet-core.Authority Authority]"} {options $auth_options }}
    }
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



# ad_form -name register -export {next_url user_id return_url} -form [auth::get_registration_form_elements]


ns_log Notice "/users/new: reg_elements=[auth::get_registration_form_elements]"

# ---------------------------------------------------------------
# Build a Multiple select box with the users profiles
# ---------------------------------------------------------------

# Fraber 051123: Don't show the profile to the user
# himself, unless it's an administrator.
set edit_profiles_p 0
if {[llength $managable_profiles] > 0} { set edit_profiles_p 1 }
if {!$current_user_is_admin_p && ($user_id == $current_user_id)} { set edit_profiles_p 0}

if {$edit_profiles_p} {
    ad_form -extend -name register -form {
	{profile:text(multiselect),multiple
	    {label "[_ intranet-core.Group_Membership]"}
	    {options $managable_profiles }
	    {values $profile_values }
	    {html {size 12}}
	}
    }
}


# Find out all the groups of the user and map these
# groups to im_category "Intranet User Type"

set user_subtypes [im_user_subtypes $user_id]

if { ""==$user_subtypes} {
    set user_subtypes $profile_org    
}

im_dynfield::append_attributes_to_form \
    -object_subtype_id $user_subtypes \
    -object_type "person" \
    -form_id "register" \
    -object_id $user_id \
    -page_url "/intranet/users/new" 


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

	    if {![info exists password] || [empty_string_p $password]} {
		set password [ad_generate_random_string]
		set password_confirm $password
	    }

	    ns_log Notice "/users/new: Before auth::create_user"
	    if {"" == $username} { set username $email}
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

	    # Update creation user to allow the creator to admin the user
	    db_dml update_creation_user_id "
		update acs_objects
		set creation_user = :current_user_id
		where object_id = :user_id
	    "

	} else {

	    # Existing user: Update variables
	    set auth [auth::get_register_authority]
	    set user_data [list]

	    # Make sure the "person" exists.
	    # This may be not the case when creating a user from a party.
	    set person_exists_p [db_string person_exists "select count(*) from persons where person_id = :user_id"]
	    if {!$person_exists_p} {
		db_dml insert_person "
		    insert into persons (
			person_id, first_names, last_name
		    ) values (
			:user_id, :first_names, :last_name
		    )
		"	
		# Convert the party into a person
		db_dml person2party "
		    update acs_objects
		    set object_type = 'person'
		    where object_id = :user_id
		"	
	    }

	    set user_exists_p [db_string user_exists "select count(*) from users where user_id = :user_id"]
	    if {!$user_exists_p} {
		if {"" == $username} { set username $email} 
		db_dml insert_user "
		    insert into users (
			user_id, username
		    ) values (
			:user_id, :username
		    )
		"
		# Convert the person into a user
		db_dml party2user "
		    update acs_objects
		    set object_type = 'user'
		    where object_id = :user_id
		"
	    }


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
		-screen_name $screen_name \
		-username $username
	}

        # Add the user to some companies or projects
        array set also_add_hash $also_add_to_biz_object
        foreach oid [array names also_add_hash] {
	    set object_type [db_string otype "select object_type from acs_objects where object_id=:oid"]
	    set perm_cmd "${object_type}_permissions \$current_user_id \$oid object_view object_read object_write object_admin"
	    eval $perm_cmd
	    if {$object_write} {
		set role_id $also_add_hash($oid)
		im_biz_object_add_role $user_id $oid $role_id
	    }
	}

	# For all users (new and existing one):
        # Add a users_contact record to the user since the 3.0 PostgreSQL
        # port, because we have dropped the outer join with it...
        catch { db_dml add_users_contact "insert into users_contact (user_id) values (:user_id)" } errmsg


        # Add the user to the "Registered Users" group, because
        # (s)he would get strange problems otherwise
        # Use a non-cached version here to avoid issues!
        set registered_users [im_registered_users_group_id]
        set reg_users_rel_exists_p [db_string member_of_reg_users "
		select	count(*) 
		from	group_member_map m, membership_rels mr
		where	m.member_id = :user_id
			and m.group_id = :registered_users
			and m.rel_id = mr.rel_id 
			and m.container_id = m.group_id 
			and m.rel_type::text = 'membership_rel'::text
	"]
	if {!$reg_users_rel_exists_p} {
	    relation_add -member_state "approved" "membership_rel" $registered_users $user_id
	}

	# Update users to set the user's authority
	db_dml update_users "
		update users
		set authority_id = :authority_id
		where user_id = :user_id
	"


	# TSearch2: We need to update "persons" in order to trigger the TSearch2
	# triggers
	db_dml update_persons "
		update persons
		set first_names = first_names
		where person_id = :user_id
        "

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

	foreach profile_tuple [im_profile::profile_options_all] {

	    # don't enter into setting and unsetting profiles
	    # if the user has no right to change profiles.
	    # Probably this is a freelancer or company
	    # who is editing himself.
	    if {!$edit_profiles_p} { break }

	    ns_log Notice "profile_tuple=$profile_tuple"
	    set profile_name [lindex $profile_tuple 0]
	    set profile_id [lindex $profile_tuple 1]
	    
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

		# Remove the user from the profile
		# (deals with special cases such as SysAdmin)
		im_profile::remove_member -profile_id $profile_id -user_id $user_id

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
		im_profile::add_member -profile_id $profile_id -user_id $user_id
		

		# Special logic for employees and P/O Admins:
		# PM, Sales, Accounting, SeniorMan => Employee
		# P/O Admin => Site Wide Admin
		if {$profile_id == [im_profile_project_managers]} { 
		    ns_log Notice "users/new: Project Managers => Employees"
		    im_profile::add_member -profile_id [im_profile_employees] -user_id $user_id
		}

		if {$profile_id == [im_profile_accounting]} { 
		    ns_log Notice "users/new: Accounting => Employees"
		    im_profile::add_member -profile_id [im_profile_employees] -user_id $user_id
		}

		if {$profile_id == [im_profile_sales]} { 
		    ns_log Notice "users/new: Sales => Employees"
		    im_profile::add_member -profile_id [im_profile_employees] -user_id $user_id
		}

		if {$profile_id == [im_profile_senior_managers]} { 
		    ns_log Notice "users/new: Senior Managers => Employees"
		    im_profile::add_member -profile_id [im_profile_employees] -user_id $user_id
		}
       
	    }
	}

	# Add a im_employees record to the user since the 3.0 PostgreSQL
	# port, because we have dropped the outer join with it...
	if {[im_table_exists im_employees]} {
	    
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
    

    # Store dynamic fields
    set form_id "register"
    set object_type "person"
    
    # Get (multiple!) object subtypes per user
    set user_subtypes [im_user_subtypes $user_id]

    im_dynfield::append_attributes_to_form \
	-object_subtype_id $user_subtypes \
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
	im_audit -object_type person -action after_update -object_id $user_id
    } else {
	im_user_exit_call user_create $user_id
	im_audit -object_type person -action after_create -object_id $user_id
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
	ad_returnredirect "$return_url&[export_url_vars feedback_message_key]"
    } else {
	ad_returnredirect "/intranet/users/?[export_url_vars feedback_message_key]"
    }
}


