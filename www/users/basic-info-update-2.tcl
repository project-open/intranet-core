# /packages/intranet-core/www/users/basic-info-update-2.tcl
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
    @param user_id
    @param first_names
    @param last_names
    @param email
    @param url
    @param screen_name

    @author Guillermo Belcic (guillermo.belcic@project-open.com)
    @author frank.bergmann@project-open.com
} {
    user_id:integer,optional
    first_names:optional
    last_name:optional
    email:optional
    { url "" }
    { screen_name "" }
    { profile:multiple ""}
    { return_url "" }
    { update_note "" }
    { notes ""}
}

#--------------------------------------------------------------------
# Security and Defaults
#--------------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
if {"" == $return_url} { set return_url "/intranet/users/view?user_id=$user_id" }

im_user_permissions $current_user_id $user_id view read write admin
if {!write} {
    ad_return_complaint 1 "<li>You have insufficient privileges to pursue this operation."
}


#--------------------------------------------------------------------
# Check the input parameters
#--------------------------------------------------------------------

set exception_text ""
set exception_count 0

if { ![info exists first_names] || $first_names == "" } {
    append exception_text "<li>You need to type in a first name\n"
    incr exception_count
}

if { ![info exists last_name] || $last_name == "" } {
    append exception_text "<li>You need to type in a last name\n"
    incr exception_count
}

if { ![info exists email] || $email == "" } {
    append exception_text "<li>You need to type in an email address\n"
    incr exception_count
}

if { [db_string check_email_in_use "select count(user_id) from users where upper(email) = upper(:email) and user_id <> :user_id"] > 0 } {
    append exception_text "<li>the email $email is already in the database\n"
    incr exception_count
}

if {![empty_string_p $screen_name]} {
    # screen name was specified.
    set sn_unique_p [db_string check_screen_name_in_use "
    select count(*) from users where screen_name = :screen_name and user_id != :user_id"]
    if {$sn_unique_p != 0} {
	append exception_text "<li>The screen name you have selected is already taken.\n"
	incr exception_count
    }
}

if { $exception_count > 0 } {
    db_release_unused_handles
    ad_return_complaint $exception_count $exception_text
    return
}

#--------------------------------------------------------------------
# Update the base data
#--------------------------------------------------------------------

if {[empty_string_p $screen_name]} {
    set sql "
update 
	users
set 
	first_names = :first_names,
    	last_name = :last_name,
    	email = :email,
    	url = :url,
    	screen_name = null
where 
	user_id = :user_id"
} else {
    set sql "
update 
	users
set 
	first_names = :first_names,
    	last_name = :last_name,
    	email = :email,
    	url = :url,
    	screen_name = :screen_name
where 
	user_id = :user_id"
}

if [catch { db_dml set_user_info $sql } errmsg] {
    db_release_unused_handles
    ad_return_error "Ouch!"  "The database choked on our update:
<blockquote>
$errmsg
</blockquote>
"
}

#--------------------------------------------------------------------
# Update the user profile
#--------------------------------------------------------------------

if {$user_admin_p} {
    # Get the list of all profiles that the current_user can set
    set option_list [im_profiles_for_new_user $current_user_id]

    # Get the list of current profiles
    set current_profile_list [db_list current_profiles "select unique group_id from user_group_map where group_id < 20 and user_id=:user_id"]

    foreach option $option_list {
	set group_id [lindex $option 0]
	set group_name [lindex $option 1]

	set before [lsearch -exact $current_profile_list $group_id]
	set after [lsearch -exact $profile $group_id]

	ns_log Notice "Processing profile: group_id=$group_id, group_name=$group_name, before=$before, after=$after"

	# Two cases: We have either lost or gained a profile
	if {$before > -1 && $after == -1} {
	    ns_log Notice "removing profile $group_name from user $user_id"
	    set sql "delete from user_group_map where user_id=:user_id and group_id=:group_id"
	    db_dml delete_profile $sql
	}
	if {$before == -1 && $after > -1} {
	    ns_log Notice "adding profile $group_name from user $user_id"
	    set sql "delete from user_group_map where user_id=:user_id and group_id=:group_id"
	    db_dml delete_profile $sql

	    set sql "insert into user_group_map values
             (:group_id, :user_id, 'member', sysdate, 1, '0.0.0.0')"
	    db_dml insert_profile $sql


	    # Add the user to "employees" if specified
#	    if {$group_id == [im_employee_group_id]} {
#		db_dml insert_employee_info {
#		    insert into im_employees (user_id, start_date)
#		    select :user_id, sysdate from dual
#		    where not exists (select user_id from im_employees
#				      where user_id=:user_id)
#		}
#	    }

#	    # Add the user to "freelancers" if specified
#	    if {$group_id == [im_freelance_group_id]} {
#		db_dml insert_freelancers {
#		    insert into im_freelancers (user_id)
#		    select :user_id from dual
#		    where not exists (select user_id from im_freelancers
#				      where user_id=:user_id)
#		}
#	    }


	}
    }
}

db_release_unused_handles
ad_returnredirect $return_url





