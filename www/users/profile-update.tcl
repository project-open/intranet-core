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
    @param user_id

    @author Guillermo Belcic (guillermo.belcic@project-open.com)
    @author frank.bergmann@project-open.com
} {
    user_id:integer
    { profile:multiple ""}
    { return_url "" }
}

#--------------------------------------------------------------------
# Security and Defaults
#--------------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
set current_user_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]

if {!$current_user_admin_p} {
    ad_return_complaint "[_ intranet-core.lt_Insufficient_Privileg]" "<li>[_ intranet-core.lt_You_have_insufficient_7]"
    return
}

if {[string equal "" $return_url]} {
    set return_url "/intranet/users/view?user_id=$user_id"
}

#--------------------------------------------------------------------
# Update the user profile
#--------------------------------------------------------------------

if {$current_user_admin_p} {

    # get the list of all profiles in the system
    set all_profiles [im_profile::profile_options_all]
    set ap [list]
    foreach p $all_profiles { lappend ap [lindex $p 1] } 

    # Get the list of all profiles that the current_user can set
    set target_profiles [im_profiles_for_new_user $current_user_id]
    set tp [list]
    foreach p $target_profiles { lappend tp [lindex $p 0] } 

    # Get the list of current profiles
    set current_profiles [im_profile::profile_options_of_user $user_id]
    set cp [list]
    foreach p $current_profiles { lappend cp [lindex $p 1] } 

    set delete_rels_sql "
BEGIN
     FOR row IN (
	select
		r.rel_id
	from 
		acs_rels r,
		acs_objects o
	where
		object_id_two = :user_id
		and object_id_one = :group_id
		and r.object_id_one = o.object_id
		and o.object_type = 'im_profile'
		and rel_type = 'membership_rel'
     ) LOOP
        membership_rel.del(row.rel_id);
     END LOOP;
END;"

	    set add_rel_sql "
BEGIN
    :1 := membership_rel.new(
	object_id_one    => :group_id,
	object_id_two    => :user_id,
	member_state     => 'approved'
    );
END;"


    foreach option $target_profiles {
	set group_id [lindex $option 0]
	set group_name [lindex $option 1]

	set current [lsearch -exact $cp $group_id]
	set target [lsearch -exact $profile $group_id]

	ns_log Notice "Processing profile: group_id=$group_id, group_name=$group_name, current=$current, target=$target"

	# Two cases: We have either lost or gained a profile
	if {$current > -1 && $target == -1} {
	    ns_log Notice "removing profile $group_name from user $user_id"
	    db_dml delete_profile $delete_rel_sql
	}

	if {$current == -1 && $target > -1} {
	    ns_log Notice "adding profile $group_name from user $user_id"
	    db_exec_plsql insert_profile $delete_rel_sql
	    db_exec_plsql insert_profile $add_rel_sql
	}
    }
}

db_release_unused_handles
ad_returnredirect $return_url





