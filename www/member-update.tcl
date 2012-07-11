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

set current_user_id [ad_maybe_redirect_for_registration]

# Determine our permissions for the current object_id.
# We can build the permissions command this ways because
# all ]project-open[ object types define procedures
# im_ObjectType_permissions $user_id $object_id view read write admin.
#
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

switch $action {
    "add_member" {
	ad_returnredirect [export_vars -base "/intranet/member-add" {return_url object_id}]
    }

    "update_members" {
	set debug ""
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
	ad_returnredirect $return_url
    }

    "del_members" {

	foreach user $delete_user {
	    im_exec_dml delete_user "user_group_member_del ($object_id, $user)"
	}

	# Remove all permission related entries in the system cache
	im_permission_flush

    }
}

ad_returnredirect $return_url

