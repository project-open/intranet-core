# /www/admin/users/basic-info-update-2.tcl
#

ad_page_contract {
    @param user_id
    @param first_names
    @param last_names
    @param email
    @param url
    @param screen_name
    @author Guillermo Belcic
    @creation-date 13-10-2003
    @cvs-id basic-info-update-2.tcl,v 3.2.2.4.2.6 2000/09/12 20:11:22 cnk Exp
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
set user_is_employee_p [im_user_is_employee_p $current_user_id]
set user_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]
set yourself_p [expr $user_id == $current_user_id]

if {!$yourself_p && !$user_is_employee_p && !$user_admin_p} {
    ad_return_complaint "Insufficient Privileges" "<li>You have insufficient privileges to modify user $user_id."
    return
}

if {[string equal "" $return_url]} {
    set return_url "/intranet/users/view?user_id=$user_id"
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





