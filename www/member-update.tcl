# /packages/intranet-core/www/member-update.tcl
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
    Allows to delete project members and to update
    their time/cost estimates for this project.

    @author various@arsdigita.com
    @author frank.bergmann@project-open.com
} {
    object_id:integer
    days:array,optional
    hours:array,optional
    percentage:array,optional
    action
    { return_url "" }
    { submit "" }
    { submit_del "" }
    { delete_user:multiple,integer "" }
}

# -----------------------------------------------------------------
# Security
# -----------------------------------------------------------------

set current_user_id [auth::require_login]

# Determine our permissions for the current object_id.
# We can build the permissions command this ways because
# all ]project-open[ object types define procedures
# im_ObjectType_permissions $user_id $object_id view read write admin.
#
set object_name [acs_object_name $object_id]
set object_type [db_string acs_object_type "select object_type from acs_objects where object_id=:object_id"]
set perm_cmd "${object_type}_permissions \$current_user_id \$object_id view read write admin"
eval $perm_cmd

if {!$write} {
    ad_return_complaint 1 "You have no rights to modify members of this object."
    return
}

ns_log Notice "member-update: object_id=$object_id"
ns_log Notice "member-update: submit=$submit"
ns_log Notice "member-update: delete_user(multiple)=$delete_user"

# Maximum percentage
set max_perc 150


# Delete timephased data for the object.
# This has an effect only on projects that were imported from MS-Project.
im_biz_object_delete_timephased_data -task_id $object_id


# -----------------------------------------------------------------
# Action
# -----------------------------------------------------------------

set touched_p 0
switch $action {
    "add_member" {
	ad_returnredirect [export_vars -base "/intranet/member-add" {return_url object_id}]
    }

    "update_members" {
	set debug ""

	# Accept assignments based on percentages
	foreach user_id [array names percentage] {
	    set perc [string trim $percentage($user_id)]
	    if {![string is double $perc]} { 
		ad_return_complaint 1 "
		     <b>[lang::message::lookup "" intranet-core.Percentage_not_a_number "Percentage is not a number"]</b>:<br>
			[lang::message::lookup "" intranet-core.Percentage_not_a_number_msg "
				The percentage you have given ('%perc%') is not a number.<br>
				Please enter something like '12.5' or '100'.
			"]
		"
		ad_script_abort
	    }
	    if {"" != $perc && $perc < 0.0} { 
		ad_return_complaint 1 "
		     <b>[lang::message::lookup "" intranet-core.Percentage_negative "Percentage should not be negative"]</b>:<br>
			[lang::message::lookup "" intranet-core.Percentage_not_a_number_msg "
				The percentage you have given ('%perc%') is a negative number.<br>
				Please enter a positive number such as '12.5' or '100'.
			"]
		"
		ad_script_abort
	    }
	    if {$perc > $max_perc} { 
		ad_return_complaint 1 "
		     <b>[lang::message::lookup "" intranet-core.Percentage_too_bit "Percentage should not exceed %max_perc%"]</b>:<br>
			[lang::message::lookup "" intranet-core.Percentage_not_a_number_msg "
				The percentage you have given ('%perc%') exceeds the maximum percentage ('%max_perc%').<br>
				Please enter a positive number such as '12.5' or '100'.
			"]
		"
		ad_script_abort
	    }

	    set touched_p 1
	    db_dml update_perc "
		update im_biz_object_members
		set percentage = :perc
		where rel_id in (
			select	rel_id
			from	acs_rels
			where	object_id_two = :user_id
				and object_id_one = :object_id
		)
	    "
  	}

	# Accept assignments based on hours
	foreach user_id [array names hours] {
	    
	    set hour [string trim $hours($user_id)]
	    set work_days_string [db_string work_days "
		select	im_resource_mgmt_work_days (:user_id, coalesce(p.start_date, now())::date, coalesce(p.end_date,now())::date)
		from	im_projects p
		where	p.project_id = :object_id
	    "]
	    set work_days_array [lindex [split $work_days_string "="] 1]
	    regsub -all {,} $work_days_array " " work_days_array
	    set work_days_array [string range $work_days_array 1 end-1]
	    set work_days 0
	    foreach d $work_days_array { set work_days [expr $work_days + $d] }
	    set work_days [expr $work_days / 100.0]

	    if {0 == $work_days} { 
		ad_return_complaint 1 "
		     <b>[lang::message::lookup "" intranet-core.Zero_work_days "Zero Work Days"]</b>:<br>
			[lang::message::lookup "" intranet-core.Zero_work_days_msg "
				Your object ('%object_name%') has zero work days between it's start- and end-date.<br>
				For this reason we can not convert your specified number of hours into a percentage.<br>
		                Please modify the object and fix start- and end-date.
			"]
		"
		ad_script_abort
	    }
	    if {![string is double $hour]} { 
		ad_return_complaint 1 "
		     <b>[lang::message::lookup "" intranet-core.Hours_not_a_number "Hours is not a number"]</b>:<br>
			[lang::message::lookup "" intranet-core.Hours_not_a_number_msg "
				The hours you have given ('%hour%') is not a number.<br>
				Please enter something like '12.3'.
			"]
		"
		ad_script_abort
	    }
	    if {"" != $hour && $hour < 0.0} { 
		ad_return_complaint 1 "
		     <b>[lang::message::lookup "" intranet-core.Hours_negative "Hours should not be negative"]</b>:<br>
			[lang::message::lookup "" intranet-core.Hours_not_a_number_msg "
				The hours you have given ('%hour%') is a negative number.<br>
				Please enter a positive number such as '12.3'.
			"]
		"
		ad_script_abort
	    }

	    set perc ""
	    if {"" ne $hour} {
		set perc [expr round(100.0 * 100.0 * $hour / 8.0 / $work_days) / 100.0]
	    }

	    if {"" ne $perc && $perc > $max_perc} { 
		ad_return_complaint 1 "
		     <b>[lang::message::lookup "" intranet-core.Hour_percentage_too_big "Assignment too high"]</b>:<br>
			[lang::message::lookup "" intranet-core.Hour_percentage_too_big_msg "
		                The assigned hours (%hour%) on object '%object_name%' correspond to %perc% % assignment.<br>
		                This value is beyond %max_perc%.<br>
				Please enter a smaller value.
			"]
		"
		ad_script_abort
	    }

	    set touched_p 1
	    db_dml update_perc "
		update im_biz_object_members
		set percentage = :perc
		where rel_id in (
			select	rel_id
			from	acs_rels
			where	object_id_two = :user_id
				and object_id_one = :object_id
		)
	    "
	    ns_log Notice "member-update: object_id=$object_id, user_id=$user_id, perc=$perc, hour=$hour, work_days=$work_days"
  	}


	# Accept assignments based on days
	foreach user_id [array names days] {
	    
	    set day [string trim $days($user_id)]
	    set work_days_string [db_string work_days "
		select	im_resource_mgmt_work_days (:user_id, coalesce(p.start_date, now())::date, coalesce(p.end_date,now())::date)
		from	im_projects p
		where	p.project_id = :object_id
	    "]
	    set work_days_array [lindex [split $work_days_string "="] 1]
	    regsub -all {,} $work_days_array " " work_days_array
	    set work_days_array [string range $work_days_array 1 end-1]
	    set work_days 0
	    foreach d $work_days_array { set work_days [expr $work_days + $d] }
	    set work_days [expr $work_days / 100.0]

	    if {0 == $work_days} { 
		ad_return_complaint 1 "
		     <b>[lang::message::lookup "" intranet-core.Zero_work_days "Zero Work Days"]</b>:<br>
			[lang::message::lookup "" intranet-core.Zero_work_days_msg "
				Your object ('%object_name%') has zero work days between it's start- and end-date.<br>
				For this reason we can not convert your specified number of days into a percentage.<br>
		                Please modify the object and fix start- and end-date.
			"]
		"
		ad_script_abort
	    }
	    if {![string is double $day]} { 
		ad_return_complaint 1 "
		     <b>[lang::message::lookup "" intranet-core.Days_not_a_number "Days is not a number"]</b>:<br>
			[lang::message::lookup "" intranet-core.Days_not_a_number_msg "
				The number of days you have given ('%day%') is not a number.<br>
				Please enter something like '12.3'.
			"]
		"
		ad_script_abort
	    }
	    if {"" != $day && $day < 0.0} { 
		ad_return_complaint 1 "
		     <b>[lang::message::lookup "" intranet-core.Days_negative "Days should not be negative"]</b>:<br>
			[lang::message::lookup "" intranet-core.Days_not_a_number_msg "
				The number of days you have given ('%day%') is a negative number.<br>
				Please enter a positive number such as '12.3'.
			"]
		"
		ad_script_abort
	    }

	    set perc ""
	    if {"" ne $day} {
		set perc [expr round(100.0 * 100.0 * $day / $work_days) / 100.0]
	    }

	    if {"" ne $perc && $perc > $max_perc} { 
		ad_return_complaint 1 "
		     <b>[lang::message::lookup "" intranet-core.Day_percentage_too_big "Assignment too high"]</b>:<br>
			[lang::message::lookup "" intranet-core.Day_percentage_too_big_msg "
		                The assigned days (%day%) on object '%object_name%' correspond to %perc% % assignment.<br>
		                This value is beyond %max_perc%.<br>
				Please enter a smaller value.
			"]
		"
		ad_script_abort
	    }

	    set touched_p 1
	    db_dml update_perc "
		update im_biz_object_members
		set percentage = :perc
		where rel_id in (
			select	rel_id
			from	acs_rels
			where	object_id_two = :user_id
				and object_id_one = :object_id
		)
	    "
	    ns_log Notice "member-update: object_id=$object_id, user_id=$user_id, perc=$perc, day=$day, work_days=$work_days"
  	}

    }

    "del_members" {
	foreach user $delete_user {
	    db_string del_rel "select im_biz_object_member__delete($object_id, $user)"
#	    im_exec_dml delete_user "user_group_member_del ($object_id, $user)"
	    set touched_p 1
	}

	# Remove all permission related entries in the system cache
	im_permission_flush

    }
}


if {$touched_p} {
    # Record that the object has changed
    db_dml update_object "
	update acs_objects set 
		last_modified = now(),
		modifying_user = :current_user_id,
		modifying_ip = '[ad_conn peeraddr]'
	where object_id = :object_id"

    # Audit the object
    im_audit -object_id $object_id -action "after_update" -comment "After adding members"
}

ad_returnredirect $return_url
