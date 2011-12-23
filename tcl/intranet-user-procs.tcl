# /packages/intranet-core/tcl/intranet-user-procs.tcl
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

# @author various@arsdigita.com
# @author frank.bergmann@project-open.com




ad_proc -public im_user_permissions { 
    {-debug 0}
    current_user_id 
    user_id 
    view_var 
    read_var 
    write_var 
    admin_var 
} {
    Fill the "by-reference" variables read, write and admin
    with the permissions of $current_user_id on $user_id
} {
    ns_log Notice "im_user_permissions: current_user_id=$current_user_id, user_id=$user_id"
    upvar $view_var view
    upvar $read_var read
    upvar $write_var write
    upvar $admin_var admin

    set view 0
    set read 0
    set write 0
    set admin 0

    if {"" == $user_id} { return }
    if {"" == $current_user_id} { return }

    # Admins and creators can do everything
    set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]
    set creation_user_id [util_memoize "db_string creator {select creation_user from acs_objects where object_id = $user_id} -default 0"]
    if {$user_is_admin_p || $current_user_id == $creation_user_id} {
	set view 1
	set read 1
	set write 1
	set admin 1
	return
    }

    # Get the list of profiles of user_id (the one to be managed)
    # together with the information if current_user_id can read/write
    # it.
    # m.group_id are all the groups to whom user_id belongs
    set profile_perm_sql "
		select
			m.group_id,
			im_object_permission_p(m.group_id, :current_user_id, 'view') as view_p,
			im_object_permission_p(m.group_id, :current_user_id, 'read') as read_p,
			im_object_permission_p(m.group_id, :current_user_id, 'write') as write_p,
			im_object_permission_p(m.group_id, :current_user_id, 'admin') as admin_p
		from
			acs_objects o,
			group_distinct_member_map m
		where
			m.member_id = :user_id
		     	and m.group_id = o.object_id
			and o.object_type = 'im_profile'
    "
    set first_loop 1
    db_foreach profile_perm_check $profile_perm_sql {
	if {$debug} { ns_log Notice "im_user_permissions: $group_id: view=$view_p read=$read_p write=$write_p admin=$admin_p" }
	if {$first_loop} {
	    # set the variables to 1 if current_user_id is member of atleast
	    # one group. Otherwise, an unpriviliged user could read the data
	    # of another unpriv user
	    set view 1
	    set read 1
	    set write 1
	    set admin 1
	}

	if {[string equal f $view_p]} { set view 0 }
	if {[string equal f $read_p]} { set read 0 }
	if {[string equal f $write_p]} { set write 0 }
	if {[string equal f $admin_p]} { set admin 0 }
	set first_loop 0
    }

    # Myself - I can read and write its data
    if { $user_id == $current_user_id } { 
		set read 1
		set write 1
		set admin 0
    }


    if {$admin} {
		set read 1
		set write 1
    }
    if {$read} { set view 1 }

    if {$debug} { ns_log Notice "im_user_permissions: cur=$current_user_id, user=$user_id, view=$view, read=$read, write=$write, admin=$admin" }

}


ad_proc -public user_permissions { current_user_id user_id view_var read_var write_var admin_var } {
    Helper being called when calling dynamic permissions
    for objects (im_biz_objects...).<br>
    This procedure is identical to im_user_permissions.
} {
    upvar $view_var view
    upvar $read_var read
    upvar $write_var write
    upvar $admin_var admin

    im_user_permissions $current_user_id $user_id view read write admin
}



ad_proc -public im_user_base_info_component { 
    -user_id:required
    { -return_url ""}
} {
    Returns a formatted piece of HTML showing the user's name and email
} {
    if {"" == $return_url} { set return_url [im_url_with_query] }
    set params [list \
		    [list user_id $user_id] \
		    [list return_url [im_url_with_query]] \
    ]

    set result [ad_parse_template -params $params "/packages/intranet-core/www/users/base-info-component"]
    return [string trim $result]
}


ad_proc -public im_sysadmin_user_default { } {
    Determines the default system Administrator account
    Just takes the lowest user_id from the members of
    the Admin group...
} {

    set user_id [util_memoize "db_string default_admin \"
	select
		min(user_id) as user_id
	from
		acs_rels ar,
		membership_rels mr,
		users u
	where
		ar.rel_id = mr.rel_id
		and u.user_id = ar.object_id_two
		and ar.object_id_one = [im_admin_group_id]
		and mr.member_state = 'approved'
    \" -default 0" 60]

    return $user_id
}



ad_proc -public im_user_options { 
    {-include_empty_p 1} 
    {-include_empty_name ""}
    {-group_id 0}
    {-group_name ""}
    {-biz_object_id ""}
} {
    Returns the options for a select box.
} {
    if {"" != $group_name} {
	set group_id [util_memoize "db_string group \"select group_id from groups where group_name = '$group_name'\" -default 0"]
    }

    set group_select_sql ""
    set biz_object_select_sql ""
    if {0 != $group_id && "" != $group_id} { 
	set group_select_sql "and user_id in (select member_id from group_distinct_member_map where group_id = :group_id)" 
    }
    if {0 != $biz_object_id && "" != $biz_object_id} { 
	set biz_object_select_sql "and user_id in (select object_id_two from acs_rels where object_id_one = :biz_object_id)" 
    }

    set options [db_list_of_lists provider_options "
		select
			im_name_from_user_id(u.user_id) as name, 
			u.user_id
		from
			cc_users u
		where
			1=1
			$group_select_sql
			$biz_object_select_sql
		order by name
    "]
    if {$include_empty_p} { set options [linsert $options 0 [list $include_empty_name "" ]] }
    return $options
}

ad_proc -public im_employee_options { {include_empty 1} } {
    Cost provider options
} {
    set options [db_list_of_lists provider_options "
	select	im_name_from_user_id(user_id) as name, 
		user_id
	from	im_employees_active
	order by name
    "]
    if {$include_empty} { set options [linsert $options 0 { "" "" }] }
    return $options
}

ad_proc -public im_project_manager_options { 
    {-include_empty 1} 
    {-current_pm_id 0}
} {
    Cost provider options
} {
    set options [db_list_of_lists provider_options "
	select * from (
		select	im_name_from_user_id(user_id) as name, user_id
		from	im_employees_active
	    UNION
		select	im_name_from_user_id(user_id) as name, user_id
		from	users_active u,
			group_distinct_member_map gm
		where	u.user_id = gm.member_id
			and gm.group_id = [im_pm_group_id]
	    UNION
		select	im_name_from_user_id(user_id) as name, user_id
		from	users_active u
		where	u.user_id = :current_pm_id
	) t
	order by name
    "]
    if {$include_empty} { set options [linsert $options 0 { "" "" }] }
    return $options
}

ad_proc im_user_select { 
    {-include_empty_p 0}
    {-include_empty_name "All"}
    {-group_id 0 }
    select_name 
    { default "" } 
} {
    Returns an html select box named $select_name and defaulted to 
    $default with a list of all the available project_leads in 
    the system
} {
    if {0 == $group_id} { set group_id [im_employee_group_id] }

    # Check if somebody tries to fiddle with SQL
    foreach id $group_id {
	if {![string is integer $id]} {
	    ad_return_complaint 1 "Please notify Frank"
	    ad_script_abort
	}
    }

    set user_options [im_profile::user_options -profile_ids $group_id]
    if {$include_empty_p} { set user_options [linsert $user_options 0 [list $include_empty_name ""]] }
    return [im_options_to_select_box $select_name $user_options $default]
}


ad_proc im_employee_select_multiple { select_name { defaults "" } { size "6"} {multiple ""}} {
    set bind_vars [ns_set create]
    set employee_group_id [im_employee_group_id]
    set name_order [parameter::get -package_id [apm_package_id_from_key intranet-core] -parameter "NameOrder" -default 1]
    set sql "
	select
		u.user_id,
		im_name_from_user_id(u.user_id, $name_order) as employee_name
	from
		registered_users u,
		group_distinct_member_map gm
	where
		u.user_id = gm.member_id
		and gm.group_id = $employee_group_id
	order by lower(im_name_from_user_id(u.user_id, $name_order))
    "
    return [im_selection_to_list_box -translate_p "0" $bind_vars category_select $sql $select_name $defaults $size $multiple]
}    


ad_proc im_pm_select_multiple { select_name { defaults "" } { size "6"} {multiple ""}} {
    set bind_vars [ns_set create]
    set pm_group_id [im_pm_group_id]
    set sql "
select
        u.user_id,
        im_name_from_user_id(u.user_id) as employee_name
from
        registered_users u,
        group_distinct_member_map gm
where
        u.user_id = gm.member_id
        and gm.group_id = $pm_group_id
order by lower(im_name_from_user_id(u.user_id))
"
    return [im_selection_to_list_box -translate_p "0" $bind_vars category_select $sql $select_name $defaults $size $multiple]
}

ad_proc im_active_pm_select_multiple { 
	select_name 
	{ defaults "" } 
	{ size "6"} {multiple ""} 
} { 
	returns html widget with employees having the PM role (im_projects::im_project_lead_id) in currently open projects
} {
    set bind_vars [ns_set create]
    set sql "
        select distinct
                pe.person_id,
                im_name_from_user_id(pe.person_id) as employee_name
        from
                persons pe,
                im_projects p,
                registered_users u
        where
                p.project_lead_id = pe.person_id and
                u.user_id = pe.person_id and
                p.project_status_id not in ([im_project_status_deleted]);
	"
    return [im_selection_to_list_box -translate_p "0" $bind_vars category_select $sql $select_name $defaults $size $multiple]
}

# ------------------------------------------------------
# User Community Component
# Show the most recent user registrations.
# This allows to detect duplicat registrations
# of users with multiple emails
# ------------------------------------------------------

ad_proc -public im_user_registration_component { current_user_id { max_rows 8} } {
    Shows the list of the last n registrations

    This allows to detect duplicat registrations
    of users with multiple emails
} {
    set date_format "YYYY-MM-DD"
    set bgcolor(0) " class=roweven"
    set bgcolor(1) " class=rowodd"
    set user_view_page "/intranet/users/view"
    set return_url [ad_conn url]?[ad_conn query]
    
    set user_id [ad_get_user_id]
    
    if {![im_permission $user_id view_user_regs]} { return "" }

    set rows_html ""
    set ctr 1
    db_foreach registered_users "" {

	regexp {(.*)\@(.*)} $email match email_name email_url
	set email_breakable "$email_name \@ $email_url"

	# Allow to approve non-approved members
	set approve_link ""
	if {"approved" != $member_state} { set approve_link "<a href=\"/acs-admin/users/member-state-change?member_state=approved&amp;[export_url_vars user_id return_url]\">[_ intranet-core.activate]</a>"
	}

	append rows_html "
<tr $bgcolor([expr $ctr % 2])>
  <td>$creation_date</td>
  <td><A href=\"$user_view_page?user_id=$user_id\">$name</A></td>
  <td><A href=\"mailto:$email\">$email_breakable</A></td>
  <td>$member_state $approve_link</td>
</tr>
"
	incr ctr
    }

    return "
<table border=0 cellspacing=1 cellpadding=1>
<tr class=rowtitle><td class=rowtitle align=center colspan=5>[_ intranet-core.Recent_Registrations]</td></tr>
<tr class=rowtitle>
  <td align=center class=rowtitle>[_ intranet-core.Date]</td>
  <td align=center class=rowtitle>[_ intranet-core.Name]</td>
  <td align=center class=rowtitle>[_ intranet-core.Email]</td>
  <td align=center class=rowtitle>[_ intranet-core.State]</td>
</tr>
$rows_html
<tr class=rowblank align=right>
  <td colspan=5>
    <a href=\"/intranet/users/index?view_name=user_community&amp;user_group_name=all&amp;order_by=Creation\">[_ intranet-core.more]</a>
  </td>
</tr>
</table>
"
}


# ------------------------------------------------------------------------
# Create a new user
# ------------------------------------------------------------------------

ad_proc -public im_user_create_new_user { 
    -username:required
    -email:required
    -first_names:required
    -last_name:required
    {-user_id "" }
    {-screen_name ""}
    {-password ""}
    {-password_confirm ""}
    {-url "" }
    {-secret_question ""}
    {-secret_answer "" }
    {-ignore_duplicate_user_p 0}
} {
    Create a new user from scratch
} {
    set current_user_id [ad_get_user_id]
    set email [string trim $email]
    set similar_user_id [db_string similar_user "select party_id from parties where lower(email) = lower(:email)" -default 0]
    
    if {0 != $similar_user_id} {
	if {$ignore_duplicate_user_p} {
	    return [list creation_status ok]
	} else {
	    set view_similar_user_link "<A href=/intranet/users/view?user_id=$similar_user_id>[_ intranet-core.user]</A>"
	    ad_return_complaint 1 "<li><b>[_ intranet-core.Duplicate_UserB]<br>[_ intranet-core.lt_There_is_already_a_vi]<br>"
	    ad_script_abort
	}
    }
    
    if {"" == $password} {
	set password [ad_generate_random_string]
	set password_confirm $password
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
				 -secret_answer $secret_answer \
    ]

    set creation_status $creation_info(creation_status)
    if {"ok" == $creation_status} {

	set user_id $creation_info(user_id);

	# Update creation user to allow the creator to admin the user
	db_dml update_creation_user_id "
		update acs_objects
		set creation_user = :current_user_id
		where object_id = :user_id
	"

	# Call the "user_create" or "user_update" user_exit
	im_user_exit_call user_create $user_id
	im_audit -object_type person -action after_create -object_id $user_id
    }

    return [array get creation_info]
}




ad_proc -public im_user_update_existing_user { 
    -user_id:required
    -username:required
    -email:required
    -first_names:required
    -last_name:required
    {-screen_name ""}
    {-url "" }
    {-also_add_to_biz_object ""}
    {-profiles ""}
    {-edit_profiles_p 0}
    {-debug 0}
} {
    Update an existing user and make sure he's member of all relevant tables
} {
    # Profile changes its value, possibly because of strange
    # ad_form sideeffects
    set profile_org $profiles

    set current_user_id [ad_get_user_id]

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

    if {$debug} { ns_log Notice "/users/new: person::update -person_id=$user_id -first_names=$first_names -last_name=$last_name" }
    person::update \
	-person_id $user_id \
	-first_names $first_names \
	-last_name $last_name
    
    if {$debug} { ns_log Notice "/users/new: party::update -party_id=$user_id -url=$url -email=$email" }
    party::update \
	-party_id $user_id \
	-url $url \
	-email $email
    
    if {$debug} { ns_log Notice "/users/new: acs_user::update -user_id=$user_id -screen_name=$screen_name" }
    acs_user::update \
	-user_id $user_id \
	-screen_name $screen_name \
	-username $username


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
    set registered_users [db_string registered_users "select object_id from acs_magic_objects where name='registered_users'"]
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


    # TSearch2: We need to update "persons" in order to trigger the TSearch2
    # triggers
    db_dml update_persons "
		update persons
		set first_names = first_names
		where person_id = :user_id
    "

	
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


    # Get the list of profiles managable for current_user_id
    set managable_profiles [im_profile::profile_options_managable_for_user $current_user_id]

    # Extract only the profile_ids from the managable profiles
    set managable_profile_ids [list]
    foreach g $managable_profiles {
	lappend managable_profile_ids [lindex $g 1]
    }

    foreach profile_tuple [im_profile::profile_options_all] {

	# don't enter into setting and unsetting profiles
	# if the user has no right to change profiles.
	# Probably this is a freelancer or company
	# who is editing himself.
	if {!$edit_profiles_p} { break }
	
	if {$debug} { ns_log Notice "profile_tuple=$profile_tuple" }
	set profile_name [lindex $profile_tuple 0]
	set profile_id [lindex $profile_tuple 1]

	set is_member [db_string is_member "
		select count(*) 
		from group_distinct_member_map 
		where member_id=:user_id and group_id=:profile_id
	"]

	set should_be_member 0
	if {[lsearch -exact $profile_org $profile_id] >= 0} {
	    set should_be_member 1
	}
	
	if {$is_member && !$should_be_member} {
	    if {$debug} { ns_log Notice "/users/new: => remove_member from $profile_name\n" }
	    
	    if {[lsearch -exact $managable_profile_ids $profile_id] < 0} {
		ad_return_complaint 1 "<li>
		    [_ intranet-core.lt_You_are_not_allowed_t]"
		return
	    }
	    
	    # db_dml delete_profile $delete_rel_sql
	    db_foreach membership_del $membership_del_sql {
		if {$debug} { ns_log Notice "/users/new: Going to delete rel_id=$rel_id" }
		membership_rel::delete -rel_id $rel_id
	    }
	    
	    # Special logic: Revoking P/O Admin privileges also removes
	    # Site-Wide-Admin privs
	    if {$profile_id == [im_profile_po_admins]} { 
		if {$debug} { ns_log Notice "users/new: Remove P/O Admins => Remove Site Wide Admins" }
		permission::revoke -object_id [acs_magic_object "security_context_root"] -party_id $user_id -privilege "admin"
	    }
	    
	    # Remove all permission related entries in the system cache
	    im_permission_flush
	}
	
	
	if {!$is_member && $should_be_member} {
	    if {$debug} { ns_log Notice "/users/new: => add_member to profile $profile_name\n" }
	    
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
	    if {$debug} { ns_log Notice "/users/new: => relation_add $profile_id $user_id" }
	    set rel_id [relation_add -member_state "approved" "membership_rel" $profile_id $user_id]
	    db_dml update_relation "update membership_rels set member_state='approved' where rel_id=:rel_id"
	    
	    
	    # Special logic for employees and P/O Admins:
	    # PM, Sales, Accounting, SeniorMan => Employee
	    # P/O Admin => Site Wide Admin
	    if {$profile_id == [im_profile_project_managers]} { 
		if {$debug} { ns_log Notice "users/new: Project Managers => Employees" }
		set rel_id [relation_add -member_state "approved" "membership_rel" [im_profile_employees] $user_id]
		db_dml update_relation "update membership_rels set member_state='approved' where rel_id=:rel_id"
	    }
	    
	    if {$profile_id == [im_profile_accounting]} { 
		if {$debug} { ns_log Notice "users/new: Accounting => Employees" }
		set rel_id [relation_add -member_state "approved" "membership_rel" [im_profile_employees] $user_id]
		db_dml update_relation "update membership_rels set member_state='approved' where rel_id=:rel_id"
	    }
	    
	    if {$profile_id == [im_profile_sales]} { 
		if {$debug} { ns_log Notice "users/new: Sales => Employees" }
		set rel_id [relation_add -member_state "approved" "membership_rel" [im_profile_employees] $user_id]
		db_dml update_relation "update membership_rels set member_state='approved' where rel_id=:rel_id"
	    }
	    
	    if {$profile_id == [im_profile_senior_managers]} { 
		if {$debug} { ns_log Notice "users/new: Senior Managers => Employees" }
		set rel_id [relation_add -member_state "approved" "membership_rel" [im_profile_employees] $user_id]
		db_dml update_relation "update membership_rels set member_state='approved' where rel_id=:rel_id"
	    }
	    
	    if {$profile_id == [im_profile_po_admins]} { 
		if {$debug} { ns_log Notice "users/new: P/O Admins => Site Wide Admins" }
		permission::grant -object_id [acs_magic_object "security_context_root"] -party_id $user_id -privilege "admin"
		im_security_alert -severity "Info" -location "users/new" -message "New P/O Admin" -value $email
	    }
	    
	    # Remove all permission related entries in the system cache
	    im_permission_flush
	    
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


    # Call the "user_create" or "user_update" user_exit
    im_user_exit_call user_update $user_id
    callback person_after_update -object_id $user_id

}








# ------------------------------------------------------------------------
# functions for printing the org chart
# ------------------------------------------------------------------------

ad_proc im_print_employee {person rowspan} "print function for org chart" {
    set user_id [fst $person]
    set employee_name [snd $person]
    set currently_employed_p [thd $person]

# Removed job title display
#    set job_title [lindex $person 3]

    if { $currently_employed_p == "t" } {

# Removed job title display
#	if { $rowspan>=2 } {
#	    return "<a href=\"/intranet/users/view?[export_url_vars user_id]\">$employee_name</a><br><i>$job_title</i>\n"
#	} else {
	    return "<a href=\"/intranet/users/view?[export_url_vars user_id]\">$employee_name</a><br>\n"
#	}
    } else {
	return "<i>[_ intranet-core.Position_Vacant]</i>"
    }
}

ad_proc im_prune_org_chart {tree} "deletes all leaves where currently_employed_p is set to vacant position" {
    set result [list [head $tree]]
    # First, recursively process the sub-trees.
    foreach subtree [tail $tree] {
	set new_subtree [im_prune_org_chart $subtree]
	if { ![null_p $new_subtree] } {
	    lappend result $new_subtree
	}
    }
    # Now, delete vacant leaves.
    # We also delete vacant inner nodes that have only one child.
    # 1. if the tree only consists of one vacant node
    #    -> return an empty tree
    # 2. if the tree has a vacant root and only one child
    #    -> return the child 
    # 3. otherwise
    #    -> return the tree 
    if { [thd [head $result]] == "f" } {
	switch [llength $result] {
	    1       { return [list] }
	    2       { return [snd $result] }
	    default { return $result }
	}
    } else {
	return $result
    }
}


# ------------------------------------------------------------------------
# Find out the user's subtypes (mapped from groups)
# ------------------------------------------------------------------------

ad_proc -public im_user_subtypes {
    user_id
} { 
    Returns a list of categories representing the user's subtypes.
    The list is derived from mapping users' groups to categories
} {
    # Find out all the groups of the user and map these
    # groups to im_category "Intranet User Type"
    set user_subtypes [db_list user_subtypes "
	select
		c.category_id
	from
		im_categories c,
		group_distinct_member_map gdmm
	where
		member_id = :user_id and
		c.aux_int1 = gdmm.group_id
    "]

    return $user_subtypes
}


# ------------------------------------------------------------------------
# Nuke a User
# ------------------------------------------------------------------------

ad_proc -public user_nuke {
    {-current_user_id 0}
    user_id
} { 
    Alias for im_user_nuke.
} {
    return [im_user_nuke -current_user_id $current_user_id $user_id]
}

ad_proc -public im_user_nuke {
    {-current_user_id 0}
    user_id
} { 
    Delete a user from the database -
    Extremely dangerous!
} {
    ns_log Notice "im_user_nuke: user_id=$user_id"
    
    # Use a predefined user_id to avoid a call to ad_get_user_id.
    # ad_get_user_id's connection isn't defined during a DELETE REST request.
    if {0 == $current_user_id} { 
	ns_log Notice "im_user_nuke: No current_user_id specified - using ad_get_user_id"
	set current_user_id [ad_get_user_id] 
    }

    # Check for permissions
    im_user_permissions $current_user_id $user_id view read write admin
    if {!$admin} { return "User #$currrent_user_id isn't a system administrator" }

    # You can't delete an adminstrator
    set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
    if {$user_is_admin_p} {
	return "User is an administrator - you can't nuke an administrator"
    }

    # Write Audit Trail
    im_audit -object_type person -action before_nuke -object_id $user_id

    # Get default user for replacement
    set result ""
    set default_user [db_string default_user "
	select	min(person_id)
	from	persons
	where	person_id > 0
    "]

    db_transaction {
	
	# bboard system
	ns_log Notice "users/nuke2: bboard_email_alerts"
	if {[im_table_exists bboard_email_alerts]} {
	    db_dml delete_user_bboard_email_alerts "delete from bboard_email_alerts where user_id = :user_id"
	    db_dml delete_user_bboard_thread_email_alerts "delete from bboard_thread_email_alerts where user_id = :user_id"
	    db_dml delete_user_bboard_unified "delete from bboard_unified where user_id = :user_id"
	    
	    # deleting from bboard is hard because we have to delete not only a user's
	    # messages but also subtrees that refer to them
	    bboard_delete_messages_and_subtrees_where  -bind [list user_id $user_id] "user_id = :user_id"
	}
    
	# let's do the classifieds now
	ns_log Notice "users/nuke2: classified_auction_bids"
	if {[im_table_exists classified_auction_bids]} {
	    db_dml delete_user_classified_auction_bids "delete from classified_auction_bids where user_id = :user_id"
	    db_dml delete_user_classified_ads "delete from classified_ads where user_id = :user_id"
	    db_dml delete_user_classified_email_alerts "delete from classified_email_alerts where user_id = :user_id"
	    db_dml delete_user_neighbor_to_neighbor_comments "
	delete from general_comments 
	where
		on_which_table = 'neighbor_to_neighbor'
		and on_what_id in (select neighbor_to_neighbor_id 
	from neighbor_to_neighbor 
	where poster_user_id = :user_id)"
	    db_dml delete_user_neighbor_to_neighbor "delete from neighbor_to_neighbor where poster_user_id = :user_id"
	}

	# now the calendar
	ns_log Notice "users/nuke2: calendar"
	if {[im_table_exists calendar]} {
	    db_dml delete_user_calendar "delete from calendar where creation_user = :user_id"
	}

	# contest tables are going to be tough
	ns_log Notice "users/nuke2: entrants_table_name"
	if {[im_table_exists entrants_table_name]} {
	    set all_contest_entrants_tables [db_list unused "select entrants_table_name from contest_domains"]
	    foreach entrants_table $all_contest_entrants_tables {
		db_dml delete_user_contest_entries "delete from $entrants_table where user_id = :user_id"
	    }
	}

	# Component Plugins
	ns_log Notice "users/nuke2: im_component_plugin_user_map"
	db_dml del_comp_map "delete from im_component_plugin_user_map where user_id = :user_id"

	
	# spam history
	ns_log Notice "users/nuke2: spam_history"
	if {[im_table_exists spam_history]} {
	    db_dml delete_user_spam_history "delete from spam_history where creation_user = :user_id"
	    db_dml delete_user_spam_history_sent "update spam_history set last_user_id_sent = NULL
		    where last_user_id_sent = :user_id"
	}
	
	# calendar
	ns_log Notice "users/nuke2: calendar_categories"
	if {[im_table_exists calendar_categories]} {
	    db_dml delete_user_calendar_categories "delete from calendar_categories where user_id = :user_id"
	}
	
	# sessions
	ns_log Notice "users/nuke2: sec_sessions"
	if {[im_table_exists sec_sessions]} {
	    db_dml delete_user_sec_sessions "delete from sec_sessions where user_id = :user_id"
	    db_dml delete_user_sec_login_tokens "delete from sec_login_tokens where user_id = :user_id"
	}
    
	# general comments
	ns_log Notice "users/nuke2: general_comments"
	if {[im_table_exists general_comments]} {
	    db_dml delete_user_general_comments "delete from general_comments where object_id = :user_id"
	}

	ns_log Notice "users/nuke2: comments"
	if {[im_table_exists comments]} {
	    db_dml delete_user_comments "delete from comments where object_id = :user_id"
	}

	ns_log Notice "users/nuke2: links"
	if {[im_table_exists links]} {
	    db_dml delete_user_links "delete from links where user_id = :user_id"
	}
	ns_log Notice "users/nuke2: chat_msgs"
	if {[im_table_exists chat_msgs]} {
	    db_dml delete_user_chat_msgs "delete from chat_msgs where creation_user = :user_id"
	}
	ns_log Notice "users/nuke2: query_strings"
	if {[im_table_exists query_strings]} {
	    db_dml delete_user_query_strings "delete from query_strings where user_id = :user_id"
	}
	ns_log Notice "users/nuke2: user_curriculum_map"
	if {[im_table_exists user_curriculum_map]} {
	    db_dml delete_user_user_curriculum_map "delete from user_curriculum_map where user_id = :user_id"
	}
	ns_log Notice "users/nuke2: user_content_map"
	if {[im_table_exists user_content_map]} {
	    db_dml delete_user_user_content_map "delete from user_content_map where user_id = :user_id"
	}
	ns_log Notice "users/nuke2: user_group_map"
	if {[im_table_exists user_group_map]} {
	    db_dml delete_user_user_group_map "delete from user_group_map where user_id = :user_id"
	}
	
	ns_log Notice "users/nuke2: users_interests"
	if {[im_table_exists users_interests]} {
	    db_dml delete_user_users_interests "delete from users_interests where user_id = :user_id"
	}
	
	ns_log Notice "users/nuke2: users_charges"
	if {[im_table_exists users_charges]} {
	    db_dml delete_user_users_charges "delete from users_charges where user_id = :user_id"
	}
	
	ns_log Notice "users/nuke2: users_demographics"
	if {[im_table_exists users_demographics]} {
	    db_dml set_referred_null_user_users_demographics "update users_demographics set referred_by = null where referred_by = :user_id"
	    db_dml delete_user_users_demographics "delete from users_demographics where user_id = :user_id"
	}
	
	ns_log Notice "users/nuke2: users_preferences"
	if {[im_table_exists users_preferences]} {
	    db_dml delete_user_users_preferences "delete from users_preferences where user_id = :user_id"
	}
	
	if {[im_table_exists user_preferences]} {
	    db_dml delete_user_user_preferences "delete from user_preferences where user_id = :user_id"
	}
	
	if {[im_table_exists users_contact]} {
	    db_dml delete_user_users_contact "delete from users_contact where user_id = :user_id"
	}
    
	# Permissions
	db_dml perms "delete from acs_permissions where grantee_id = :user_id"
	db_dml perms "delete from acs_permissions where object_id = :user_id"
	

	# Reassign objects to a default user...
	db_dml reassign_objects "update acs_objects set modifying_user = :default_user where modifying_user = :user_id"
	db_dml reassign_projects "update acs_objects set creation_user = :default_user where creation_user = :user_id"
	
	# Lang_message_audit
	db_dml lang_message_audit "update lang_messages_audit set overwrite_user = null where overwrite_user = :user_id"
	db_dml lang_message "update lang_messages set creation_user = null where creation_user = :user_id"
	
	# Deleting cost entries in acs_objects that are "dangeling", i.e. that don't have an
	# entry in im_costs. These might have been created during manual deletion of objects
	# Very dirty...
	db_dml dangeling_costs "delete from acs_objects where object_type = 'im_cost' and object_id not in (select cost_id from im_costs)"
	
	# Costs
	db_dml invoice_references "update im_invoices set company_contact_id = null where company_contact_id = :user_id"
	db_dml cuase_objects "update im_costs set cause_object_id = :default_user where cause_object_id = :user_id"
	db_dml cost_providers "update im_costs set provider_id = :default_user where provider_id = :user_id"

	# Cost Centers
	db_dml reset_cost_center_managers "update im_cost_centers set manager_id = null where manager_id = :user_id"

	# Payments
	db_dml reset_payments "update im_payments set last_modifying_user = :default_user where last_modifying_user = :user_id"
	
	# Forum
	db_dml forum "delete from im_forum_topic_user_map where user_id = :user_id"
	db_dml forum "update im_forum_topics set owner_id = :default_user where owner_id = :user_id"
	db_dml forum "update im_forum_topics set asignee_id = null where asignee_id = :user_id"
	db_dml forum "update im_forum_topics set object_id = :default_user where object_id = :user_id"

	# Timesheet
	db_dml timesheet "delete from im_hours where user_id = :user_id"
	db_dml timesheet "delete from im_user_absences where owner_id = :user_id"
	
	# Remove user from business objects that we don't want to delete...
	db_dml remove_from_companies "update im_companies set manager_id = null where manager_id = :user_id"
	db_dml remove_from_companies "update im_companies set accounting_contact_id = null where accounting_contact_id = :user_id"
	db_dml remove_from_companies "update im_companies set primary_contact_id = null where primary_contact_id = :user_id"
	db_dml remove_from_projects "update im_projects set supervisor_id = null where supervisor_id = :user_id"
	db_dml remove_from_projects "update im_projects set project_lead_id = null where project_lead_id = :user_id"
	
    	db_dml reassign_projects "update acs_objects set creation_user = :default_user where object_type = 'im_office' and creation_user = :user_id"
	db_dml reassign_projects "update acs_objects set creation_user = :default_user where object_type = 'im_company' and creation_user = :user_id"
	db_dml remove_from_companies "update im_offices set contact_person_id = null where contact_person_id = :user_id"


	# Freelance
	if {[im_table_exists im_freelance_skills]} {
	    db_dml trans_tasks "delete from im_freelance_skills where user_id = :user_id"
	    db_dml freelance "delete from im_freelancers where user_id = :user_id"
	    db_dml freelance_conf "update im_freelance_skills set confirmation_user_id = null where confirmation_user_id = :user_id"
	}

	# Gantt Projects
	if {[im_table_exists im_gantt_persons]} {
	    db_dml im_gantt_persons "delete from im_gantt_persons where person_id = :user_id"
	}

	# Helpdesk + ConfDB
	if {[im_table_exists im_tickets]} {
	    db_dml assignees "update im_tickets set ticket_assignee_id = :default_user where ticket_assignee_id = :user_id"
	    db_dml assignees "update im_tickets set ticket_customer_contact_id = :default_user where ticket_customer_contact_id = :user_id"
	}

	# Configuration Items
	if {[im_table_exists im_conf_items]} {
	    db_dml assignees "update im_conf_items set conf_item_owner_id = :default_user where conf_item_owner_id = :user_id"
	}

	# Simple Survey
	if {[im_table_exists survsimp_responses]} {
	    db_dml assignees "update survsimp_responses set related_context_id = :default_user where related_context_id = :user_id"
	    db_dml assignees "update survsimp_responses set related_object_id = :default_user where related_object_id = :user_id"
	}

	
	# Translation
	if {[im_table_exists im_trans_tasks]} {
	    db_dml remove_from_projects "update im_projects set company_contact_id = null where company_contact_id = :user_id"
	    db_dml trans_tasks "update im_trans_tasks set trans_id = null where trans_id = :user_id"
	    db_dml trans_tasks "update im_trans_tasks set edit_id = null where edit_id = :user_id"
	    db_dml trans_tasks "update im_trans_tasks set proof_id = null where proof_id = :user_id"
	    db_dml trans_tasks "update im_trans_tasks set other_id = null where other_id = :user_id"
	    db_dml task_actions "delete from im_task_actions where user_id = :user_id"
	}
	
	# Translation RFQs
	if {[im_table_exists im_trans_rfq_answers]} {
	    db_dml rfq_answers "update im_trans_rfq_answers set answer_user_id = :default_user where answer_user_id = :user_id"
	}
	if {[im_table_exists im_freelance_rfq_answers]} {
	    db_dml rfq_answers "update im_freelance_rfq_answers set answer_user_id = :default_user where answer_user_id = :user_id"
	}

	if {[im_table_exists im_trans_quality_reports]} {
	    db_dml trans_quality "delete from im_trans_quality_entries where report_id in (
		select report_id from im_trans_quality_reports where reviewer_id = :user_id
	    )"
	    db_dml trans_quality "delete from im_trans_quality_reports where reviewer_id = :user_id"
	}

	# Workflow
	db_dml wf "update wf_tasks set holding_user = :default_user where holding_user = :user_id"
	db_dml wf "update wf_case_assignments set party_id = :default_user where party_id = :user_id"
	db_dml wf "update wf_context_assignments set party_id = :default_user where party_id = :user_id"

	
	# Filestorage
	db_dml filestorage "delete from im_fs_folder_status where user_id = :user_id"
	db_dml filestorage "delete from im_fs_actions where user_id = :user_id"
	db_dml filestorage "update im_fs_folders set object_id = null where object_id = :user_id"

	# Bug-Tracker
        if {[im_table_exists bt_user_prefs]} {
	    db_dml bt_prefs "delete from bt_user_prefs where user_id = :user_id"
	}
        if {[im_table_exists bt_components]} {
	    db_dml bt_comps "update bt_components set maintainer = null where maintainer = :user_id"
	}
        if {[im_table_exists bt_patch_actions]} {
	    db_dml bt_patch_actions "update bt_patch_actions set actor = :default_user where actor = :user_id"
	}

	set rels [db_list rels "select rel_id from acs_rels where object_id_one = :user_id or object_id_two = :user_id"]
	foreach rel_id $rels {
	    db_dml del_rels "delete from group_element_index where rel_id = :rel_id"
	    db_dml del_rels "delete from im_biz_object_members where rel_id = :rel_id"
	    db_dml del_rels "delete from membership_rels where rel_id = :rel_id"
	    db_dml del_rels "delete from acs_rels where rel_id = :rel_id"
	    db_dml del_rels "delete from acs_objects where object_id = :rel_id"
	}
	
	db_dml party_approved_member_map "delete from party_approved_member_map where party_id = :user_id"
	db_dml party_approved_member_map "delete from party_approved_member_map where member_id = :user_id"
	
	if {[im_table_exists im_employees]} {
	    db_dml update_dependent_employees "update im_employees set supervisor_id = null where supervisor_id = :user_id"
	    db_dml delete_employees "delete from im_employees where employee_id = :user_id"
	}
	
	ns_log Notice "users/nuke2: Main user tables"
	db_dml update_creation_users "update acs_objects set creation_user = null where creation_user = :user_id"
	db_dml delete_user "delete from users where user_id = :user_id"
	db_dml delete_user "delete from persons where person_id = :user_id"
	db_dml delete_user "delete from parties where party_id = :user_id"
	db_dml delete_user "delete from acs_objects where object_id = :user_id"

	# Returning empty string - everything went OK
	return ""	

    } on_error {
	
	set detailed_explanation ""
	if {[ regexp {integrity constraint \([^.]+\.([^)]+)\)} $errmsg match constraint_name]} {
	    set sql "
		select table_name 
		from user_constraints 
		where constraint_name=:constraint_name
	    "
	    db_foreach user_constraints_by_name $sql {
		set detailed_explanation "<p>
	    [_ intranet-core.lt_It_seems_the_table_we]"
	    }
	}

	# Return the error string - indicates that there were errors    
	set result "
	[_ intranet-core.lt_The_nuking_of_user_us]
	$detailed_explanation<p>
	[_ intranet-core.lt_For_good_measure_here]
	<blockquote><pre>\n$errmsg\n</pre></blockquote>
	"
    }

    return $result
}



ad_proc im_upload_cvs_translate_varname { var_name} {
    Translate German var names to English.
    In the future we'll also support translations from other
    Office versions...
} {
    set name [string tolower [im_l10n_normalize_string $var_name]]

    switch $var_name {
	anrede { return "title" }
	vorname { return "first_name" }
	weitere_vornamen { return "middle_name" }
	nachname { return "last_name" }
	suffix { return "suffix" }
	emailadresse { return "e_mail_address" }
	firma { return "company" }
	abteilung { return "department" }
	position { return "job_title" }
	strase_geschaftlich { return "business_street" }
	strase_geschaftlich_2 { return "business_street_2" }
	strase_geschaftlich_3 { return "business_street_3" }
	ort_geschaftlich { return "business_city" }
	region_geschaftlich { return "business_state" }
	postleitzahl_geschaftlich { return "business_postal_code" }
	land_geschaftlich { return "business_country" }
	strase_privat { return "home_street" }
	strase_privat_2 { return "home_street_2" }
	strase_privat_3 { return "home_street_3" }
	ort_privat { return "home_city" }
	region_privat { return "home_state" }
	postleitzahl_privat { return "home_postal_code" }
	land_privat { return "home_country" }
	weitere_strase { return "other_street" }
	weitere_strase_2 { return "other_street_2" }
	weitere_strase_3 { return "other_street_3" }
	weiterer_ort { return "other_city" }
	weitere_region { return "other_state" }
	weitere_postleitzahl { return "other_postal_code" }
	weiteres_land { return "other_country" }
	telefon_assistent { return "assistants_phone" }
	fax_geschaftlich { return "business_fax" }
	telefon_geschaftlich { return "business_phone" }
	telefon_geschaftlich_2 { return "business_phone_2" }
	ruckmeldung { return "callback" }
	autotelefon { return "car_phone" }
	telefon_firma { return "company_main_phone" }
	fax_privat { return "home_fax" }
	telefon_privat { return "home_phone" }
	telefon_privat_2 { return "home_phone_2" }
	isdn { return "isdn" }
	mobiltelefon { return "mobile_phone" }
	weiteres_fax { return "other_fax" }
	weiteres_telefon { return "other_phone" }
	pager { return "pager" }
	haupttelefon { return "primary_phone" }
	mobiltelefon_2 { return "radio_phone" }
	telefon_fur_horbehinderte { return "tty_tdd_phone" }
	telex { return "telex" }
	abrechnungsinformation { return "account" }
	benutzer_1 { return "user_1" }
	benutzer_2 { return "user_2" }
	benutzer_3 { return "user_3" }
	benutzer_4 { return "user_4" }
	beruf { return "job_title" }
	buro { return "office_location" }
	e_mail_adresse { return "e_mail_address" }
	e_mail_typ { return "e_mail_type" }
	e_mail_angezeigter_name { return "e_mail_display_name" }
	e_mail_2_adresse { return "e_mail_2_address" }
	e_mail_2_typ { return "e_mail_2_type" }
	e_mail_2_angezeigter_name { return "e_mail_2_display_name" }
	e_mail_3_adresse { return "e_mail_3_address" }
	e_mail_3_typ { return "e_mail_3_type" }
	e_mail_3_angezeigter_name { return "e_mail_3_display_name" }
	empfohlen_von { return "referred_by" }
	geburtstag { return "birthday" }
	geschlecht { return "gender" }
	hobby { return "hobby" }
	initialen { return "initials" }
	internet_frei_gebucht { return "internet_free_busy" }
	jahrestag { return "anniversary" }
	kategorien { return "categories" }
	kinder { return "children" }
	konto { return "account" }
	name_assistent { return "assistant_s_name" }
	name_des_der_vorgesetzten { return "manager_s_name" }
	notizen { return "notes" }
	organisations_nr { return "organizational_id_number" }
	ort { return "location" }
	partner { return "spouse" }
	postfach_geschaftlich { return "po_box" }
	postfach_privat { return "ttt" }
	prioritat { return "priority" }
	privat { return "private" }
	regierungs_nr { return "government_id_number" }
	reisekilometer { return "mileage" }
	sprache { return "language" }
	stichworter { return "ttt" }
	vertraulichkeit { return "sensitivity" }
	verzeichnisserver { return "directory_server" }
	webseite { return "web_page" }
	weiteres_postfach  { return "po_box" }
    }
    return $var_name
}




# More component to intranet/users/view
ad_proc -public im_user_contact_info_component { 
    user_id
    return_url
} {
    returns contact information of the user
} {
    set params [list [list base_url "intranet-core"] [list user_id $user_id] [list return_url $return_url]]
    set result [ad_parse_template -params $params "/packages/intranet-core/lib/user-contact-info"]
    return [string trim $result]
}
 
ad_proc -public im_user_basic_info_component {
    user_id
    return_url
} { 
    returns basic information of the user
    @author iuri sampaio (iuri.sampaio@gmail.com)
    @date 2010-10-28
} {
    set params [list [list base_url "/intranet-core/"] [list user_id $user_id] [list return_url $return_url]]
    set result [ad_parse_template -params $params "/packages/intranet-core/lib/user-basic-info"]
    return [string trim $result]
}

ad_proc -public im_user_admin_info_component { 
    user_id
    return_url
} {
    returns admin information of the user 
    @author iuri sampaio (iuri.sampaio@gmail.com)
    @date 2010-10-29
} {
    set params [list [list base_url "intranet-core"] [list user_id $user_id] [list return_url $return_url]]
    set result [ad_parse_template -params $params "/packages/intranet-core/lib/user-admin-info"]
    return [string trim $result]
}


ad_proc -public im_user_localization_component {
    user_id
    return_url
} {
    returns localization info of the user
    @author iuri sampaio (iuri.sampaio@gmail.com)
    @date 2010-10-29
} {
    set params [list [list base_url "intranet-core"] [list user_id $user_id] [list return_url $return_url]]
    set result [ad_parse_template -params $params "/packages/intranet-core/lib/user-localization"]
    return [string trim $result]
}

